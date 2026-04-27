<?php

namespace App\Services;

use App\Models\BookingTracking;
use App\Models\ScheduleBooking;
use Illuminate\Support\Carbon;

class BookingTrackingService
{
    protected array $defaultStages = [
        ['order' => 1, 'key' => 'booking', 'name' => 'Pemesanan'],
        ['order' => 2, 'key' => 'dp_payment', 'name' => 'Pembayaran DP'],
        ['order' => 3, 'key' => 'photographer_assignment', 'name' => 'Assign Fotografer'],
        ['order' => 4, 'key' => 'full_payment', 'name' => 'Pelunasan'],
        ['order' => 5, 'key' => 'shooting', 'name' => 'Pemotretan'],
        ['order' => 6, 'key' => 'photo_upload', 'name' => 'Upload Foto'],
        ['order' => 7, 'key' => 'edit_upload', 'name' => 'Upload Edit'],
        ['order' => 8, 'key' => 'print', 'name' => 'Cetak'],
        ['order' => 9, 'key' => 'review', 'name' => 'Review'],
    ];

    public function initializeForBooking(ScheduleBooking $booking): void
    {
        $this->ensureInitialized($booking);

        $this->markDone(
            $booking,
            'booking',
            'Booking berhasil dibuat oleh klien.',
            now()
        );

        $this->markCurrent(
            $booking,
            'dp_payment',
            'Menunggu pembayaran DP.'
        );
    }

    public function ensureInitialized(ScheduleBooking $booking): void
    {
        foreach ($this->defaultStages as $stage) {
            BookingTracking::updateOrCreate(
                [
                    'schedule_booking_id' => $booking->id,
                    'stage_key' => $stage['key'],
                ],
                [
                    'stage_order' => $stage['order'],
                    'stage_name' => $stage['name'],
                ]
            );
        }
    }

    public function syncTrackingState(ScheduleBooking $booking): void
    {
        $booking->loadMissing(['package', 'photographerUser', 'successfulBookingPayments']);

        $this->ensureInitialized($booking);

        $this->markDone(
            $booking,
            'booking',
            'Booking berhasil dibuat oleh klien.',
            $booking->created_at
        );

        if (!$booking->isDpPaid()) {
            $this->markCurrent(
                $booking,
                'dp_payment',
                'Menunggu pembayaran DP.'
            );

            $this->markPending(
                $booking,
                'photographer_assignment',
                'Menunggu DP dibayar sebelum Front Office memilih fotografer.'
            );

            $this->markPending(
                $booking,
                'full_payment',
                'Pelunasan dapat dilakukan setelah DP dibayar dan fotografer ditentukan.'
            );

            return;
        }

        $this->markDone(
            $booking,
            'dp_payment',
            'DP booking sudah dibayar.',
            now()
        );

        if (!$booking->photographer_user_id) {
            $this->markCurrent(
                $booking,
                'photographer_assignment',
                'Menunggu Front Office memilih fotografer untuk booking ini.'
            );

            $this->markPending(
                $booking,
                'full_payment',
                'Pelunasan dapat dilakukan setelah fotografer ditentukan.'
            );

            return;
        }

        $photographerName = $booking->photographerUser?->name ?? $booking->photographer_name ?? 'Fotografer';

        $this->markDone(
            $booking,
            'photographer_assignment',
            'Fotografer sudah ditentukan: ' . $photographerName . '.',
            now()
        );

        if (!$booking->isFullyPaid()) {
            $this->markCurrent(
                $booking,
                'full_payment',
                'Menunggu pelunasan sisa pembayaran.'
            );

            return;
        }

        $this->markDone(
            $booking,
            'full_payment',
            'Pelunasan booking sudah dibayar.',
            now()
        );

        $shooting = $this->getTracking($booking, 'shooting');

        if ($shooting->status === 'pending') {
            $this->markCurrent(
                $booking,
                'shooting',
                'Menunggu jadwal pemotretan.'
            );
        }
    }

    public function markDone(
        ScheduleBooking $booking,
        string $stageKey,
        ?string $description = null,
        ?Carbon $occurredAt = null,
        array $meta = []
    ): void {
        $tracking = $this->getTracking($booking, $stageKey);

        $tracking->update([
            'status' => 'done',
            'description' => $description,
            'occurred_at' => $occurredAt ?? now(),
            'meta' => $meta ?: $tracking->meta,
        ]);
    }

    public function markCurrent(
        ScheduleBooking $booking,
        string $stageKey,
        ?string $description = null,
        array $meta = []
    ): void {
        $tracking = $this->getTracking($booking, $stageKey);

        $tracking->update([
            'status' => 'current',
            'description' => $description,
            'meta' => $meta ?: $tracking->meta,
        ]);
    }

    public function markPending(
        ScheduleBooking $booking,
        string $stageKey,
        ?string $description = null
    ): void {
        $tracking = $this->getTracking($booking, $stageKey);

        $tracking->update([
            'status' => 'pending',
            'description' => $description,
            'occurred_at' => null,
        ]);
    }

    public function markSkipped(
        ScheduleBooking $booking,
        string $stageKey,
        ?string $description = null
    ): void {
        $tracking = $this->getTracking($booking, $stageKey);

        $tracking->update([
            'status' => 'skipped',
            'description' => $description,
            'occurred_at' => now(),
        ]);
    }

    public function moveToNext(
        ScheduleBooking $booking,
        string $doneStageKey,
        string $nextStageKey,
        ?string $doneDescription = null,
        ?string $nextDescription = null
    ): void {
        $this->markDone($booking, $doneStageKey, $doneDescription, now());
        $this->markCurrent($booking, $nextStageKey, $nextDescription);
    }

    public function getTimeline(ScheduleBooking $booking)
    {
        $this->syncTrackingState($booking);

        return $booking->trackings()
            ->orderBy('stage_order')
            ->get();
    }

    protected function getTracking(ScheduleBooking $booking, string $stageKey): BookingTracking
    {
        $this->ensureInitialized($booking);

        return $booking->trackings()
            ->where('stage_key', $stageKey)
            ->firstOrFail();
    }
}
