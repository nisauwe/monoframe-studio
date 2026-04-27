<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\AssignPhotographerRequest;
use App\Models\ScheduleBooking;
use App\Models\User;
use App\Services\BookingTrackingService;
use App\Services\PhotographerAvailabilityService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class PhotographerAssignmentController extends Controller
{
    private array $paidBookingStatuses = [
        'dp_paid',
        'partially_paid',
        'paid',
        'fully_paid',
    ];

    private array $successfulPaymentStatuses = [
        'settlement',
        'capture',
    ];

    public function assignableBookings(Request $request)
    {
        $bookings = ScheduleBooking::with([
                'package',
                'clientUser',
                'latestPayment',
                'payments',
            ])
            ->whereNull('photographer_user_id')
            ->whereNotIn('status', ['cancelled', 'completed'])
            ->where(function (Builder $query) {
                $query->whereIn('payment_status', $this->paidBookingStatuses)
                    ->orWhereHas('payments', function (Builder $paymentQuery) {
                        $paymentQuery
                            ->whereNull('print_order_id')
                            ->whereIn('transaction_status', $this->successfulPaymentStatuses);
                    });
            })
            ->orderBy('booking_date')
            ->orderBy('start_time')
            ->get();

        $data = $bookings->map(function ($booking) {
            return [
                'id' => $booking->id,
                'package_id' => $booking->package_id,
                'client_user_id' => $booking->client_user_id,
                'photographer_user_id' => $booking->photographer_user_id,

                'client_name' => $booking->client_name,
                'client_phone' => $booking->client_phone,

                'booking_date' => $booking->booking_date,
                'start_time' => $booking->start_time,
                'end_time' => $booking->end_time,
                'blocked_until' => $booking->blocked_until,

                'location_type' => $booking->location_type,
                'location_name' => $booking->location_name,

                'status' => $booking->status,
                'payment_status' => $booking->payment_status,

                'duration_minutes' => (int) $booking->duration_minutes,
                'extra_duration_units' => (int) ($booking->extra_duration_units ?? 0),
                'extra_duration_minutes' => (int) ($booking->extra_duration_minutes ?? 0),
                'extra_duration_fee' => (int) ($booking->extra_duration_fee ?? 0),

                'video_addon_type' => $booking->video_addon_type,
                'video_addon_name' => $booking->video_addon_name,
                'video_addon_price' => (int) ($booking->video_addon_price ?? 0),

                'package' => $booking->package,
                'latest_payment' => $booking->latestPayment,

                'total_booking_amount' => (int) $booking->total_booking_amount,
                'paid_booking_amount' => (int) $booking->paid_booking_amount,
                'minimum_dp_amount' => (int) $booking->minimum_dp_amount,
                'remaining_booking_amount' => (int) $booking->remaining_booking_amount,

                'can_assign' => $this->canAssignPhotographer($booking),
            ];
        })->values();

        return response()->json([
            'message' => 'Daftar booking yang bisa diproses berhasil diambil',
            'data' => $data,
        ]);
    }

    public function availablePhotographers(
        ScheduleBooking $booking,
        PhotographerAvailabilityService $availabilityService
    ) {
        if (!$this->canAssignPhotographer($booking)) {
            return response()->json([
                'message' => 'Fotografer hanya boleh dipilih untuk booking yang sudah membayar DP atau sudah lunas.',
            ], 422);
        }

        $photographers = $availabilityService->getAvailablePhotographers(
            $booking->booking_date,
            $booking->start_time,
            $booking->end_time,
            $booking->id
        );

        return response()->json([
            'message' => 'Daftar fotografer tersedia berhasil diambil',
            'booking' => $booking->load(['package']),
            'data' => $photographers->where('is_available', true)->values(),
        ]);
    }

    public function assign(
        AssignPhotographerRequest $request,
        ScheduleBooking $booking,
        PhotographerAvailabilityService $availabilityService,
        BookingTrackingService $trackingService
    ) {
        if (!$this->canAssignPhotographer($booking)) {
            return response()->json([
                'message' => 'Fotografer hanya boleh di-assign untuk booking yang sudah membayar DP atau sudah lunas.',
            ], 422);
        }

        if ($booking->photographer_user_id) {
            return response()->json([
                'message' => 'Booking ini sudah memiliki fotografer.',
            ], 422);
        }

        $photographer = User::query()
            ->where('id', $request->photographer_user_id)
            ->where('role', 'Fotografer')
            ->where('is_active', true)
            ->firstOrFail();

        $isAvailable = $availabilityService->isPhotographerAvailable(
            $photographer->id,
            $booking->booking_date,
            $booking->start_time,
            $booking->end_time,
            $booking->id
        );

        if (!$isAvailable) {
            return response()->json([
                'message' => 'Fotografer ini sudah memiliki jadwal pada slot tersebut.',
            ], 409);
        }

        $booking->update([
            'photographer_user_id' => $photographer->id,
            'photographer_name' => $photographer->name,
        ]);

        $booking->refresh();

        $trackingService->syncTrackingState($booking);

        return response()->json([
            'message' => 'Fotografer berhasil di-assign',
            'data' => $booking->fresh([
                'package',
                'clientUser',
                'photographerUser',
                'latestPayment',
                'payments',
                'trackings',
            ]),
        ]);
    }

    private function canAssignPhotographer(ScheduleBooking $booking): bool
    {
        return $booking->isDpPaid() || $booking->isFullyPaid();
    }
}
