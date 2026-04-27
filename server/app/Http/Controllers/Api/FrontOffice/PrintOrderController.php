<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Models\PrintOrder;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PrintOrderController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->query('status');

        $query = PrintOrder::with([
            'booking.package',
            'booking.clientUser',
            'client',
            'items.printPrice',
            'payment',
        ])
            ->whereIn('payment_status', ['paid', 'settlement', 'capture'])
            ->latest();

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        } else {
            $query->whereIn('status', ['paid', 'processing', 'completed']);
        }

        $orders = $query->get()
            ->map(fn (PrintOrder $order) => $this->formatPrintOrder($request, $order))
            ->values();

        return response()->json([
            'message' => 'Daftar pesanan cetak berhasil diambil',
            'data' => $orders,
        ]);
    }

    public function show(Request $request, PrintOrder $printOrder)
    {
        $printOrder->load([
            'booking.package',
            'booking.clientUser',
            'client',
            'items.printPrice',
            'payment',
        ]);

        return response()->json([
            'message' => 'Detail pesanan cetak berhasil diambil',
            'data' => $this->formatPrintOrder($request, $printOrder),
        ]);
    }

    public function markProcessing(
        Request $request,
        PrintOrder $printOrder,
        BookingTrackingService $trackingService
    ) {
        if (!$printOrder->isPaid()) {
            return response()->json([
                'message' => 'Pesanan cetak belum dibayar.',
            ], 422);
        }

        if ($printOrder->status === 'completed') {
            return response()->json([
                'message' => 'Pesanan cetak sudah selesai.',
            ], 422);
        }

        $printOrder->update([
            'status' => 'processing',
            'processed_at' => $printOrder->processed_at ?: now(),
        ]);

        if ($printOrder->booking) {
            $trackingService->markCurrent(
                $printOrder->booking,
                'print',
                'Pesanan cetak sedang diproses oleh Front Office.'
            );
        }

        $printOrder = $printOrder->fresh([
            'booking.package',
            'booking.clientUser',
            'client',
            'items.printPrice',
            'payment',
        ]);

        return response()->json([
            'message' => 'Pesanan cetak sedang diproses',
            'data' => $this->formatPrintOrder($request, $printOrder),
        ]);
    }

    public function complete(
        Request $request,
        PrintOrder $printOrder,
        BookingTrackingService $trackingService
    ) {
        $request->validate([
            'completion_photo' => [
                'required_without:delivery_proof',
                'nullable',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:4096',
            ],
            'delivery_proof' => [
                'nullable',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:4096',
            ],
        ]);

        if (!$printOrder->isPaid()) {
            return response()->json([
                'message' => 'Pesanan cetak belum dibayar.',
            ], 422);
        }

        if ($printOrder->status === 'completed') {
            return response()->json([
                'message' => 'Pesanan cetak sudah selesai.',
            ], 422);
        }

        $completionPhotoPath = $printOrder->completion_photo_path;
        $completionPhotoUrl = $printOrder->completion_photo_url;

        $completionFile = $request->file('completion_photo')
            ?: $request->file('delivery_proof');

        if ($completionFile) {
            $completionPhotoPath = $completionFile->store(
                'print-completion-photos',
                'public'
            );

            // Simpan URL relatif saja. URL absolut akan dibuat saat response.
            $completionPhotoUrl = Storage::url($completionPhotoPath);
        }

        $deliveryProofPath = $printOrder->delivery_proof_path;
        $deliveryProofUrl = $printOrder->delivery_proof_url;

        if ($request->hasFile('delivery_proof')) {
            $deliveryProofPath = $request->file('delivery_proof')->store(
                'delivery-proofs',
                'public'
            );

            $deliveryProofUrl = Storage::url($deliveryProofPath);
        }

        if (
            $printOrder->delivery_method === 'delivery' &&
            !$deliveryProofPath &&
            $completionPhotoPath
        ) {
            $deliveryProofPath = $completionPhotoPath;
            $deliveryProofUrl = $completionPhotoUrl;
        }

        $printOrder->update([
            'status' => 'completed',
            'completed_at' => now(),

            'completion_photo_path' => $completionPhotoPath,
            'completion_photo_url' => $completionPhotoUrl,

            'delivery_proof_path' => $deliveryProofPath,
            'delivery_proof_url' => $deliveryProofUrl,
        ]);

        $message = $printOrder->delivery_method === 'delivery'
            ? 'Pesanan cetak selesai dan foto cetakan selesai sudah diupload.'
            : 'Pesanan cetak selesai. Klien dapat mengambil cetakan di studio.';

        if ($printOrder->booking) {
            $trackingService->markDone(
                $printOrder->booking,
                'print',
                $message
            );

            $trackingService->markCurrent(
                $printOrder->booking,
                'review',
                'Silakan berikan review untuk pelayanan dan hasil foto Monoframe.'
            );
        }

        $printOrder = $printOrder->fresh([
            'booking.package',
            'booking.clientUser',
            'client',
            'items.printPrice',
            'payment',
        ]);

        return response()->json([
            'message' => 'Pesanan cetak berhasil diselesaikan',
            'data' => $this->formatPrintOrder($request, $printOrder),
        ]);
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
}
