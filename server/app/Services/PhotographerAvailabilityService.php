<?php

namespace App\Services;

use App\Models\ScheduleBooking;
use App\Models\User;

class PhotographerAvailabilityService
{
    public function getAvailablePhotographers(
        string $bookingDate,
        string $startTime,
        string $endTime,
        ?int $excludeBookingId = null
    ) {
        $photographers = User::query()
            ->where('role', 'Fotografer')
            ->where('is_active', true)
            ->get();

        return $photographers->map(function ($photographer) use (
            $bookingDate,
            $startTime,
            $endTime,
            $excludeBookingId
        ) {
            $isAvailable = $this->isPhotographerAvailable(
                $photographer->id,
                $bookingDate,
                $startTime,
                $endTime,
                $excludeBookingId
            );

            return [
                'id' => $photographer->id,
                'name' => $photographer->name,
                'email' => $photographer->email,
                'phone' => $photographer->phone,
                'is_available' => $isAvailable,
                'availability_label' => $isAvailable ? 'Tersedia' : 'Bentrok Jadwal',
            ];
        })->values();
    }

    public function isPhotographerAvailable(
        int $photographerUserId,
        string $bookingDate,
        string $startTime,
        string $endTime,
        ?int $excludeBookingId = null
    ): bool {
        $query = ScheduleBooking::query()
            ->where('photographer_user_id', $photographerUserId)
            ->whereDate('booking_date', $bookingDate)
            ->whereNotIn('status', ['cancelled', 'canceled'])
            ->where(function ($q) use ($startTime, $endTime) {
                $q->where('start_time', '<', $endTime)
                    ->whereRaw('COALESCE(blocked_until, end_time) > ?', [$startTime]);
            });

        if ($excludeBookingId) {
            $query->where('id', '!=', $excludeBookingId);
        }

        return !$query->exists();
    }
}
