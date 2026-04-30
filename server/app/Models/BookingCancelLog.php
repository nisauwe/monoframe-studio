<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookingCancelLog extends Model
{
    protected $fillable = [
        'client_user_id',
        'schedule_booking_id',
        'package_id',
        'package_name',
        'client_name',
        'client_phone',
        'booking_date',
        'start_time',
        'end_time',
        'location_type',
        'location_name',
        'duration_minutes',
        'extra_duration_minutes',
        'extra_duration_fee',
        'video_addon_name',
        'video_addon_price',
        'total_booking_amount',
        'notes',
        'cancel_reason',
        'snapshot',
        'cancelled_at',
    ];

    protected $casts = [
        'snapshot' => 'array',
        'cancelled_at' => 'datetime',
    ];

    public function clientUser()
    {
        return $this->belongsTo(User::class, 'client_user_id');
    }
}
