<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ScheduleBooking extends Model
{
    use HasFactory;

    protected $fillable = [
        'package_id',
        'client_user_id',
        'photographer_user_id',

        'client_name',
        'client_phone',
        'photographer_name',

        'booking_date',
        'start_time',
        'end_time',
        'blocked_until',
        'duration_minutes',

        'extra_duration_units',
        'extra_duration_minutes',
        'extra_duration_fee',

        'video_addon_type',
        'video_addon_name',
        'video_addon_price',

        'location_type',
        'location_name',

        'status',
        'payment_status',
        'payment_order_id',
        'payment_due_at',
        'payment_paid_at',

        'source',
        'notes',
    ];

    protected $casts = [
        'payment_due_at' => 'datetime',
        'payment_paid_at' => 'datetime',
    ];

    protected $appends = [
        'package_base_price',
        'total_booking_amount',
        'paid_booking_amount',
        'minimum_dp_amount',
        'remaining_booking_amount',
        'is_dp_paid',
        'is_fully_paid',
    ];

    public function package()
    {
        return $this->belongsTo(Package::class);
    }

    public function clientUser()
    {
        return $this->belongsTo(User::class, 'client_user_id');
    }

    public function photographerUser()
    {
        return $this->belongsTo(User::class, 'photographer_user_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'schedule_booking_id');
    }

    public function latestPayment()
    {
        return $this->hasOne(Payment::class, 'schedule_booking_id')->latestOfMany();
    }

    public function successfulBookingPayments()
    {
        return $this->hasMany(Payment::class, 'schedule_booking_id')
            ->whereNull('print_order_id')
            ->whereIn('transaction_status', ['settlement', 'capture']);
    }

    public function getPackageBasePriceAttribute(): int
    {
        return (int) (
            $this->package?->discounted_price
            ?? $this->package?->price
            ?? 0
        );
    }

    public function getTotalBookingAmountAttribute(): int
    {
        return (int) $this->package_base_price
            + (int) $this->extra_duration_fee
            + (int) $this->video_addon_price;
    }

    public function getPaidBookingAmountAttribute(): int
    {
        return (int) $this->successfulBookingPayments()->sum('base_amount');
    }

    public function getMinimumDpAmountAttribute(): int
    {
        return (int) ceil($this->total_booking_amount * 0.5);
    }

    public function getRemainingBookingAmountAttribute(): int
    {
        return max(0, $this->total_booking_amount - $this->paid_booking_amount);
    }

    public function isDpPaid(): bool
    {
        return $this->paid_booking_amount >= $this->minimum_dp_amount;
    }

    public function isFullyPaid(): bool
    {
        return $this->paid_booking_amount >= $this->total_booking_amount;
    }

    public function getIsDpPaidAttribute(): bool
    {
        return $this->isDpPaid();
    }

    public function getIsFullyPaidAttribute(): bool
    {
        return $this->isFullyPaid();
    }

    public function trackings()
    {
        return $this->hasMany(BookingTracking::class, 'schedule_booking_id')
            ->orderBy('stage_order');
    }

    public function trackingByKey(string $key)
    {
        return $this->trackings()->where('stage_key', $key)->first();
    }

    public function photoLink()
    {
        return $this->hasOne(PhotoLink::class, 'schedule_booking_id');
    }

    public function editRequest()
    {
        return $this->hasOne(EditRequest::class, 'schedule_booking_id');
    }

    public function printOrder()
    {
        return $this->hasOne(PrintOrder::class, 'schedule_booking_id');
    }

    public function review()
    {
        return $this->hasOne(Review::class, 'schedule_booking_id');
    }

    public function moodboards()
    {
        return $this->hasMany(BookingMoodboard::class, 'schedule_booking_id')
            ->orderBy('sort_order');
    }
}
