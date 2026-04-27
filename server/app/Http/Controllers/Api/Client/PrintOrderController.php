<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\PrintOrder;
use App\Models\PrintPrice;
use App\Models\ScheduleBooking;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PrintOrderController extends Controller
{
    public function prices()
    {
        $prices = PrintPrice::query()
            ->where(function ($query) {
                $query->where('is_available', true)
                    ->orWhereNull('is_available');
            })
            ->where(function ($query) {
                $query->where('is_active', true)
                    ->orWhereNull('is_active');
            })
            ->orderByRaw('COALESCE(size_name, size_label) ASC')
            ->get()
            ->map(fn (PrintPrice $price) => $this->formatPrintPrice($price))
            ->values();

        return response()->json([
            'message' => 'Daftar harga cetak berhasil diambil',
            'data' => $prices,
        ]);
    }

    public function show(Request $request, ScheduleBooking $booking)
    {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load([
            'package',
            'editRequest',
            'printOrder.items.printPrice',
            'printOrder.payment',
        ]);

        $printOrder = $booking->printOrder
            ? $this->formatPrintOrder($request, $booking->printOrder)
            : null;

        return response()->json([
            'message' => 'Data pesanan cetak berhasil diambil',
            'data' => [
                'booking_id' => $booking->id,
                'can_order_print' => $this->canOrderPrint($booking),
                'print_order' => $printOrder,
            ],
        ]);
    }

    public function store(Request $request, BookingTrackingService $trackingService)
    {
        $validated = $request->validate([
            'booking_id' => ['required', 'exists:schedule_bookings,id'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.print_price_id' => ['required', 'exists:print_prices,id'],
            'items.*.file_name' => ['required', 'string', 'max:255'],
            'items.*.qty' => ['nullable', 'integer', 'min:1', 'max:100'],
            'items.*.use_frame' => ['required', 'boolean'],

            'delivery_method' => ['required', Rule::in(['pickup', 'delivery'])],
            'recipient_name' => ['nullable', 'string', 'max:255'],
            'recipient_phone' => ['nullable', 'string', 'max:50'],
            'delivery_address' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $user = $request->user();

        $booking = ScheduleBooking::with([
            'editRequest',
            'printOrder',
        ])->findOrFail($validated['booking_id']);

        if ((int) $booking->client_user_id !== (int) $user->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        if (!$this->canOrderPrint($booking)) {
            throw ValidationException::withMessages([
                'booking_id' => 'Pesanan cetak hanya bisa dibuat setelah hasil edit selesai.',
            ]);
        }

        if ($booking->printOrder && !in_array($booking->printOrder->status, ['cancelled'], true)) {
            throw ValidationException::withMessages([
                'booking_id' => 'Pesanan cetak untuk booking ini sudah dibuat.',
            ]);
        }

        if ($validated['delivery_method'] === 'delivery') {
            if (
                empty($validated['recipient_name']) ||
                empty($validated['recipient_phone']) ||
                empty($validated['delivery_address'])
            ) {
                throw ValidationException::withMessages([
                    'delivery_address' => 'Nama penerima, nomor HP, dan alamat wajib diisi jika memilih diantar.',
                ]);
            }
        }

        $itemsInput = collect($validated['items'])
            ->map(function ($item) {
                return [
                    'print_price_id' => (int) $item['print_price_id'],
                    'file_name' => trim((string) $item['file_name']),
                    'qty' => max(1, (int) ($item['qty'] ?? 1)),
                    'use_frame' => (bool) $item['use_frame'],
                ];
            })
            ->filter(fn ($item) => $item['file_name'] !== '')
            ->values();

        if ($itemsInput->isEmpty()) {
            throw ValidationException::withMessages([
                'items' => 'Minimal isi 1 item cetak.',
            ]);
        }

        $priceIds = $itemsInput->pluck('print_price_id')->unique()->values();

        $prices = PrintPrice::query()
            ->whereIn('id', $priceIds)
            ->where(function ($query) {
                $query->where('is_available', true)
                    ->orWhereNull('is_available');
            })
            ->where(function ($query) {
                $query->where('is_active', true)
                    ->orWhereNull('is_active');
            })
            ->get()
            ->keyBy('id');

        if ($prices->count() !== $priceIds->count()) {
            throw ValidationException::withMessages([
                'items' => 'Ada ukuran cetak yang tidak aktif atau tidak ditemukan.',
            ]);
        }

        $preparedItems = [];
        $selectedFiles = [];

        $totalQuantity = 0;
        $subtotalPrint = 0;
        $subtotalFrame = 0;
        $totalAmount = 0;
        $anyFrame = false;

        foreach ($itemsInput as $item) {
            $price = $prices->get($item['print_price_id']);
            $priceData = $this->formatPrintPrice($price);

            $unitPrintPrice = (int) $priceData['print_price'];
            $unitFramePrice = $item['use_frame'] ? (int) $priceData['frame_price'] : 0;

            if ($unitPrintPrice <= 0) {
                throw ValidationException::withMessages([
                    'items' => 'Harga cetak ukuran ' . $priceData['size_name'] . ' belum valid.',
                ]);
            }

            $qty = (int) $item['qty'];
            $linePrint = $unitPrintPrice * $qty;
            $lineFrame = $unitFramePrice * $qty;
            $lineTotal = $linePrint + $lineFrame;

            $preparedItems[] = [
                'print_price_id' => $price->id,
                'file_name' => $item['file_name'],
                'qty' => $qty,
                'use_frame' => (bool) $item['use_frame'],
                'unit_print_price' => $unitPrintPrice,
                'unit_frame_price' => $unitFramePrice,
                'line_total' => $lineTotal,
            ];

            $selectedFiles[] = $item['file_name'];

            $totalQuantity += $qty;
            $subtotalPrint += $linePrint;
            $subtotalFrame += $lineFrame;
            $totalAmount += $lineTotal;

            if ($item['use_frame']) {
                $anyFrame = true;
            }
        }

        if ($totalAmount <= 0) {
            throw ValidationException::withMessages([
                'items' => 'Total pembayaran cetak tidak valid.',
            ]);
        }

        return DB::transaction(function () use (
            $request,
            $booking,
            $user,
            $validated,
            $preparedItems,
            $selectedFiles,
            $totalQuantity,
            $subtotalPrint,
            $subtotalFrame,
            $totalAmount,
            $anyFrame,
            $trackingService
        ) {
            $firstPrice = PrintPrice::find($preparedItems[0]['print_price_id']);
            $firstPriceData = $this->formatPrintPrice($firstPrice);

            $order = PrintOrder::create([
                'schedule_booking_id' => $booking->id,
                'client_user_id' => $user->id,

                'selected_files' => array_values($selectedFiles),
                'quantity' => $totalQuantity,

                'size_name' => count($preparedItems) === 1
                    ? $firstPriceData['size_name']
                    : 'Multi Ukuran',
                'paper_type' => count($preparedItems) === 1
                    ? $firstPriceData['paper_type']
                    : null,
                'use_frame' => $anyFrame,

                'print_unit_price' => $preparedItems[0]['unit_print_price'],
                'frame_unit_price' => $preparedItems[0]['unit_frame_price'],
                'subtotal_print' => $subtotalPrint,
                'subtotal_frame' => $subtotalFrame,
                'total_amount' => $totalAmount,

                'delivery_method' => $validated['delivery_method'],
                'recipient_name' => $validated['recipient_name'] ?? null,
                'recipient_phone' => $validated['recipient_phone'] ?? null,
                'delivery_address' => $validated['delivery_address'] ?? null,

                'status' => 'pending_payment',
                'payment_status' => 'unpaid',
                'notes' => $validated['notes'] ?? null,
            ]);

            foreach ($preparedItems as $item) {
                $order->items()->create($item);
            }

            $trackingService->markCurrent(
                $booking,
                'print',
                'Pesanan cetak berhasil dibuat. Silakan lakukan pembayaran biaya cetak.'
            );

            $order = $order->fresh([
                'items.printPrice',
                'payment',
            ]);

            return response()->json([
                'message' => 'Pesanan cetak berhasil dibuat',
                'data' => $this->formatPrintOrder($request, $order),
            ], 201);
        });
    }

    public function skip(Request $request, ScheduleBooking $booking, BookingTrackingService $trackingService)
    {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load(['editRequest']);

        if (!$this->canOrderPrint($booking)) {
            throw ValidationException::withMessages([
                'booking_id' => 'Tahap cetak hanya bisa dilewati setelah hasil edit selesai.',
            ]);
        }

        $trackingService->markSkipped(
            $booking,
            'print',
            'Klien memilih untuk tidak mencetak foto.'
        );

        $trackingService->markCurrent(
            $booking,
            'review',
            'Silakan berikan review untuk pelayanan dan hasil foto Monoframe.'
        );

        return response()->json([
            'message' => 'Tahap cetak dilewati. Silakan lanjut ke review.',
        ]);
    }

    private function canOrderPrint(ScheduleBooking $booking): bool
    {
        return $booking->editRequest
            && $booking->editRequest->status === 'completed';
    }

    private function formatPrintOrder(Request $request, PrintOrder $order): array
    {
        $data = $order->toArray();

        $data['completion_photo_url'] = $this->publicFileUrl(
            $request,
            $order->completion_photo_path,
            $order->completion_photo_url
        );

        $data['delivery_proof_url'] = $this->publicFileUrl(
            $request,
            $order->delivery_proof_path,
            $order->delivery_proof_url
        );

        return $data;
    }

    private function publicFileUrl(
        Request $request,
        ?string $path,
        ?string $storedUrl
    ): string {
        $baseUrl = rtrim($request->getSchemeAndHttpHost(), '/');

        if ($path) {
            $cleanPath = ltrim($path, '/');

            if (str_starts_with($cleanPath, 'storage/')) {
                return $baseUrl . '/' . $cleanPath;
            }

            return $baseUrl . Storage::url($cleanPath);
        }

        if (!$storedUrl) {
            return '';
        }

        if (str_starts_with($storedUrl, '/')) {
            return $baseUrl . $storedUrl;
        }

        $parsed = parse_url($storedUrl);

        if (!$parsed) {
            return $storedUrl;
        }

        $host = $parsed['host'] ?? '';
        $storedPath = $parsed['path'] ?? '';

        if (
            in_array($host, ['localhost', '127.0.0.1'], true) &&
            str_starts_with($storedPath, '/storage/')
        ) {
            return $baseUrl . $storedPath;
        }

        return $storedUrl;
    }

    private function formatPrintPrice(PrintPrice $price): array
    {
        $sizeName = $price->size_name ?: $price->size_label ?: '';
        $paperType = $price->paper_type ?: $price->notes ?: '';

        $printPrice = (int) ($price->print_price ?? 0);

        if ($printPrice <= 0) {
            $printPrice = (int) ($price->base_price ?? 0);
        }

        $framePrice = (int) ($price->frame_price ?? 0);

        $isAvailable = true;

        if ($price->is_available !== null) {
            $isAvailable = (bool) $price->is_available;
        }

        if ($price->is_active !== null) {
            $isAvailable = $isAvailable && (bool) $price->is_active;
        }

        return [
            'id' => $price->id,

            'size_name' => $sizeName,
            'paper_type' => $paperType,
            'print_price' => $printPrice,
            'frame_price' => $framePrice,
            'is_available' => $isAvailable,

            'size_label' => $price->size_label,
            'base_price' => (int) ($price->base_price ?? 0),
            'is_active' => (bool) ($price->is_active ?? true),
            'notes' => $price->notes,
        ];
    }
}
