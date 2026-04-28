<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Review;
use App\Models\ScheduleBooking;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ReviewController extends Controller
{
    public function show(Request $request, ScheduleBooking $booking)
    {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load([
            'review',
            'printOrder',
            'trackings',
        ]);

        $setting = AppSetting::current();

        return response()->json([
            'message' => 'Data review berhasil diambil',
            'data' => [
                'booking_id' => $booking->id,
                'review_enabled' => (bool) $setting->review_is_active,
                'review_message' => $setting->review_invitation_message,
                'can_review' => $setting->review_is_active && $this->canReview($booking),
                'review' => $booking->review ? $this->formatReview($booking->review) : null,
            ],
        ]);
    }

    public function store(Request $request, BookingTrackingService $trackingService)
    {
        $setting = AppSetting::current();

        if (!$setting->review_is_active) {
            return response()->json([
                'message' => 'Fitur review sedang dinonaktifkan oleh admin.',
            ], 403);
        }

        $validated = $request->validate([
            'booking_id' => ['required', 'exists:schedule_bookings,id'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
        ]);

        $booking = ScheduleBooking::with([
            'printOrder',
            'review',
            'trackings',
        ])->findOrFail($validated['booking_id']);

        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        if (!$this->canReview($booking) && !$booking->review) {
            throw ValidationException::withMessages([
                'booking_id' => 'Review hanya bisa diberikan setelah tahap cetak selesai atau dilewati.',
            ]);
        }

        $review = Review::updateOrCreate(
            [
                'schedule_booking_id' => $booking->id,
                'client_user_id' => $request->user()->id,
            ],
            [
                'rating' => (int) $validated['rating'],
                'comment' => $validated['comment'] ?? null,
            ]
        );

        $trackingService->markDone(
            $booking,
            'review',
            'Klien telah memberikan review.'
        );

        return response()->json([
            'message' => 'Review berhasil dikirim',
            'data' => $this->formatReview($review->fresh(['booking', 'client'])),
        ]);
    }

    private function canReview(ScheduleBooking $booking): bool
    {
        if ($booking->review) {
            return false;
        }

        if ($booking->printOrder) {
            return $booking->printOrder->status === 'completed';
        }

        $printTracking = $booking->trackings()
            ->where('stage_key', 'print')
            ->first();

        return $printTracking && in_array($printTracking->status, ['done', 'skipped'], true);
    }

    private function formatReview(Review $review): array
    {
        return [
            'id' => $review->id,
            'schedule_booking_id' => $review->schedule_booking_id,
            'client_user_id' => $review->client_user_id,
            'rating' => (int) $review->rating,
            'comment' => $review->comment,
            'created_at' => optional($review->created_at)->toIso8601String(),
            'updated_at' => optional($review->updated_at)->toIso8601String(),
        ];
    }
}
