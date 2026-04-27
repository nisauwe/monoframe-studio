<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\EditRequest;
use App\Models\ScheduleBooking;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Validation\ValidationException;

class EditRequestController extends Controller
{
    public function show(Request $request, ScheduleBooking $booking)
    {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load([
            'package',
            'photoLink',
            'editRequest.editor',
        ]);

        $maxFiles = (int) ($booking->package?->photo_count ?? 0);

        return response()->json([
            'message' => 'Data permintaan edit berhasil diambil',
            'data' => [
                'booking_id' => $booking->id,
                'package_name' => $booking->package?->name,
                'max_photo_count' => $maxFiles,
                'has_photo_link' => (bool) $booking->photoLink,
                'can_submit_edit_request' => $this->canSubmitEditRequest($booking),
                'edit_request' => $booking->editRequest,
                'photo_link' => $booking->photoLink,
            ],
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'booking_id' => ['required', 'exists:schedule_bookings,id'],
            'selected_files' => ['required', 'array', 'min:1'],
            'selected_files.*' => ['required', 'string', 'max:255'],
            'request_notes' => ['nullable', 'string'],
        ]);

        $user = $request->user();

        $booking = ScheduleBooking::with([
            'package',
            'photoLink',
            'editRequest',
        ])->findOrFail($validated['booking_id']);

        if ((int) $booking->client_user_id !== (int) $user->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        if (!$this->isFullyPaid($booking)) {
            throw ValidationException::withMessages([
                'booking_id' => 'Pelunasan belum lunas, jadi belum bisa kirim daftar foto edit.',
            ]);
        }

        if (!$booking->photoLink) {
            throw ValidationException::withMessages([
                'booking_id' => 'Link hasil foto belum tersedia, jadi belum bisa kirim daftar foto edit.',
            ]);
        }

        $selectedFiles = collect($validated['selected_files'])
            ->map(fn ($item) => trim((string) $item))
            ->filter()
            ->values()
            ->all();

        if (empty($selectedFiles)) {
            throw ValidationException::withMessages([
                'selected_files' => 'Minimal isi 1 nama file foto.',
            ]);
        }

        $normalizedFiles = collect($selectedFiles)
            ->map(fn ($item) => strtoupper($item))
            ->values()
            ->all();

        if (count($normalizedFiles) !== count(array_unique($normalizedFiles))) {
            throw ValidationException::withMessages([
                'selected_files' => 'Ada nama file yang duplikat. Setiap nama file harus berbeda.',
            ]);
        }

        $maxFiles = (int) ($booking->package?->photo_count ?? 0);

        if ($maxFiles <= 0) {
            throw ValidationException::withMessages([
                'selected_files' => 'Jumlah foto edit pada paket belum valid.',
            ]);
        }

        if (count($selectedFiles) > $maxFiles) {
            throw ValidationException::withMessages([
                'selected_files' => "Maksimal file edit untuk paket ini adalah {$maxFiles} file.",
            ]);
        }

        if ($booking->editRequest && $booking->editRequest->status !== 'submitted') {
            throw ValidationException::withMessages([
                'booking_id' => 'Daftar foto edit sudah diproses dan tidak bisa diubah melalui aplikasi.',
            ]);
        }

        $editRequest = EditRequest::updateOrCreate(
            [
                'schedule_booking_id' => $booking->id,
            ],
            [
                'photo_link_id' => $booking->photoLink->id,
                'client_user_id' => $user->id,
                'editor_user_id' => null,
                'selected_files' => $selectedFiles,
                'request_notes' => Arr::get($validated, 'request_notes'),
                'status' => 'submitted',
                'assigned_at' => null,
                'edit_deadline_at' => null,
                'started_at' => null,
                'completed_at' => null,
                'editor_notes' => null,
            ]
        );

        app(BookingTrackingService::class)->markCurrent(
            $booking,
            'edit_upload',
            'Daftar foto edit sudah dikirim. Menunggu Front Office memilih editor.'
        );

        return response()->json([
            'message' => 'Daftar foto edit berhasil dikirim. Menunggu Front Office memilih editor.',
            'data' => $editRequest->fresh([
                'booking.package',
                'photoLink',
                'editor',
            ]),
        ], 201);
    }

    private function canSubmitEditRequest(ScheduleBooking $booking): bool
    {
        return $this->isFullyPaid($booking)
            && (bool) $booking->photoLink
            && (!$booking->editRequest || $booking->editRequest->status === 'submitted');
    }

    private function isFullyPaid(ScheduleBooking $booking): bool
    {
        return in_array($booking->payment_status, ['paid', 'fully_paid'], true)
            || $booking->isFullyPaid();
    }
}
