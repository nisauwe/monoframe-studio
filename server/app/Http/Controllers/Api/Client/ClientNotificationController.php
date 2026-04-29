<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Services\BookingTrackingService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class ClientNotificationController extends Controller
{
    public function index(Request $request, BookingTrackingService $trackingService)
    {
        $user = $request->user();

        $notifications = collect();

        $this->appendDiscountNotifications($notifications);

        $bookings = ScheduleBooking::query()
            ->with([
                'package.category',
                'successfulBookingPayments',
                'photographerUser',
                'photoLink',
                'editRequest.editor',
                'printOrder.payment',
                'review',
                'trackings',
            ])
            ->where('client_user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();

        foreach ($bookings as $booking) {
            $trackingService->syncTrackingState($booking);
            $booking->refresh();
            $booking->load([
                'package.category',
                'successfulBookingPayments',
                'photographerUser',
                'photoLink',
                'editRequest.editor',
                'printOrder.payment',
                'review',
                'trackings',
            ]);

            $this->appendBookingNotifications($notifications, $booking);
        }

        $sorted = $notifications
            ->sortByDesc(fn ($item) => $item['created_at'] ?? now()->toIso8601String())
            ->values();

        return response()->json([
            'message' => 'Notifikasi klien berhasil diambil.',
            'unread_count' => $sorted->count(),
            'data' => $sorted,
        ]);
    }

    private function appendDiscountNotifications(Collection $notifications): void
    {
        $packages = Package::query()
            ->with(['category', 'discounts'])
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        foreach ($packages as $package) {
            $discount = $package->current_discount;

            if (!$discount) {
                continue;
            }

            $notifications->push($this->makeNotification(
                id: 'discount-' . $package->id . '-' . $discount->id,
                type: 'discount',
                title: 'Promo paket foto',
                body: 'Diskon ' . (int) $discount->discount_percent . '% untuk paket foto '
                    . $package->name . ', jangan sampai ketinggalan, diskon terbatas!',
                icon: 'discount',
                createdAt: optional($discount->updated_at ?? $discount->created_at)->toIso8601String() ?? now()->toIso8601String(),
                actionType: 'package',
                actionId: $package->id,
            ));
        }
    }

    private function appendBookingNotifications(Collection $notifications, ScheduleBooking $booking): void
    {
        $packageName = $booking->package?->name ?? 'Paket Foto';
        $bookingDate = $booking->booking_date
            ? Carbon::parse($booking->booking_date)->locale('id')->translatedFormat('d F Y')
            : 'tanggal yang dipilih';

        $notifications->push($this->makeNotification(
            id: 'booking-created-' . $booking->id,
            type: 'booking',
            title: 'Booking berhasil dibuat',
            body: 'Booking paket ' . $packageName . ' berhasil dibuat untuk tanggal ' . $bookingDate . '.',
            icon: 'booking',
            createdAt: optional($booking->created_at)->toIso8601String() ?? now()->toIso8601String(),
            actionType: 'booking',
            actionId: $booking->id,
        ));

        if ($booking->isDpPaid()) {
            $notifications->push($this->makeNotification(
                id: 'booking-dp-paid-' . $booking->id,
                type: 'payment',
                title: 'DP sudah dibayar',
                body: 'DP untuk paket ' . $packageName . ' sudah berhasil dibayar.',
                icon: 'payment',
                createdAt: $this->trackingTime($booking, 'dp_payment') ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }

        if ($booking->photographer_user_id) {
            $photographerName = $booking->photographerUser?->name
                ?? $booking->photographer_name
                ?? 'Fotografer';

            $notifications->push($this->makeNotification(
                id: 'booking-photographer-' . $booking->id,
                type: 'photographer',
                title: 'Fotografer sudah ditentukan',
                body: $photographerName . ' sudah ditugaskan untuk sesi foto paket ' . $packageName . '.',
                icon: 'camera',
                createdAt: $this->trackingTime($booking, 'photographer_assignment') ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }

        if ($booking->isFullyPaid()) {
            $notifications->push($this->makeNotification(
                id: 'booking-fully-paid-' . $booking->id,
                type: 'payment',
                title: 'Pembayaran sudah lunas',
                body: 'Pembayaran paket ' . $packageName . ' sudah lunas. Terima kasih.',
                icon: 'paid',
                createdAt: $this->trackingTime($booking, 'full_payment') ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }

        if ($booking->booking_date && Carbon::parse($booking->booking_date)->isToday()) {
            $time = trim(($booking->start_time ?? '') . ' - ' . ($booking->end_time ?? ''));

            $notifications->push($this->makeNotification(
                id: 'booking-shooting-today-' . $booking->id,
                type: 'shooting',
                title: 'Hari ini jadwal fotomu',
                body: 'Hari ini jadwal foto paket ' . $packageName . ($time ? ' pukul ' . $time : '') . '. Jangan sampai terlambat ya.',
                icon: 'calendar',
                createdAt: now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }

        if ($booking->photoLink && $booking->photoLink->is_active) {
            $notifications->push($this->makeNotification(
                id: 'booking-photo-link-' . $booking->id,
                type: 'photo_link',
                title: 'Link foto sudah dikirim',
                body: 'Fotografer sudah mengirim link hasil foto untuk paket ' . $packageName . '.',
                icon: 'photo',
                createdAt: optional($booking->photoLink->updated_at ?? $booking->photoLink->created_at)->toIso8601String() ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }

        if ($booking->editRequest) {
            $editStatus = $booking->editRequest->status;

            if (in_array($editStatus, ['submitted', 'assigned', 'in_progress'], true)) {
                $notifications->push($this->makeNotification(
                    id: 'booking-edit-process-' . $booking->id,
                    type: 'edit',
                    title: 'Edit foto sedang diproses',
                    body: 'Permintaan edit untuk paket ' . $packageName . ' sedang diproses.',
                    icon: 'edit',
                    createdAt: optional(
                        $booking->editRequest->started_at
                        ?? $booking->editRequest->assigned_at
                        ?? $booking->editRequest->created_at
                    )->toIso8601String() ?? now()->toIso8601String(),
                    actionType: 'booking',
                    actionId: $booking->id,
                ));
            }

            if ($editStatus === 'completed') {
                $notifications->push($this->makeNotification(
                    id: 'booking-edit-completed-' . $booking->id,
                    type: 'edit',
                    title: 'Edit foto sudah selesai',
                    body: 'Hasil edit untuk paket ' . $packageName . ' sudah selesai.',
                    icon: 'done',
                    createdAt: optional($booking->editRequest->completed_at ?? $booking->editRequest->updated_at)->toIso8601String() ?? now()->toIso8601String(),
                    actionType: 'booking',
                    actionId: $booking->id,
                ));
            }
        }

        if ($booking->printOrder) {
            $printStatus = $booking->printOrder->status;

            if (in_array($printStatus, ['pending', 'paid', 'processing'], true)) {
                $notifications->push($this->makeNotification(
                    id: 'booking-print-process-' . $booking->id,
                    type: 'print',
                    title: 'Cetak foto sedang diproses',
                    body: 'Permintaan tambah cetak untuk paket ' . $packageName . ' sedang diproses.',
                    icon: 'print',
                    createdAt: optional(
                        $booking->printOrder->processed_at
                        ?? $booking->printOrder->paid_at
                        ?? $booking->printOrder->created_at
                    )->toIso8601String() ?? now()->toIso8601String(),
                    actionType: 'booking',
                    actionId: $booking->id,
                ));
            }

            if ($printStatus === 'completed') {
                $notifications->push($this->makeNotification(
                    id: 'booking-print-completed-' . $booking->id,
                    type: 'print',
                    title: 'Cetak foto selesai',
                    body: 'Cetak foto untuk paket ' . $packageName . ' sudah selesai.',
                    icon: 'done',
                    createdAt: optional($booking->printOrder->completed_at ?? $booking->printOrder->updated_at)->toIso8601String() ?? now()->toIso8601String(),
                    actionType: 'booking',
                    actionId: $booking->id,
                ));
            }
        }

        if ($booking->review) {
            $notifications->push($this->makeNotification(
                id: 'booking-review-' . $booking->id,
                type: 'review',
                title: 'Review berhasil dikirim',
                body: 'Terima kasih sudah memberi review untuk pengalaman foto di Monoframe Studio.',
                icon: 'review',
                createdAt: optional($booking->review->created_at)->toIso8601String() ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));

            $notifications->push($this->makeNotification(
                id: 'booking-thanks-' . $booking->id,
                type: 'thanks',
                title: 'Terima kasih dari Monoframe',
                body: 'Terima kasih karena sudah menyelesaikan sesi foto di Monoframe Studio.',
                icon: 'heart',
                createdAt: optional($booking->review->created_at)->toIso8601String() ?? now()->toIso8601String(),
                actionType: 'booking',
                actionId: $booking->id,
            ));
        }
    }

    private function trackingTime(ScheduleBooking $booking, string $stageKey): ?string
    {
        $tracking = $booking->trackings
            ->firstWhere('stage_key', $stageKey);

        if (!$tracking || !$tracking->occurred_at) {
            return null;
        }

        return Carbon::parse($tracking->occurred_at)->toIso8601String();
    }

    private function makeNotification(
        string $id,
        string $type,
        string $title,
        string $body,
        string $icon,
        string $createdAt,
        ?string $actionType = null,
        ?int $actionId = null,
    ): array {
        return [
            'id' => $id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'icon' => $icon,
            'created_at' => $createdAt,
            'action_type' => $actionType,
            'action_id' => $actionId,
            'is_read' => false,
        ];
    }
}
