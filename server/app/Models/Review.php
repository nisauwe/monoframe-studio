<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Review extends Model
{
    use HasFactory;

    protected $fillable = [
        'schedule_booking_id',
        'client_user_id',
        'rating',
        'comment',
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    public function booking()
    {
        return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
    }

    public function client()
    {
        return $this->belongsTo(User::class, 'client_user_id');
    }
}
