<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookingMoodboard extends Model
{
    protected $fillable = [
        'schedule_booking_id',
        'file_path',
        'file_name',
        'file_size',
        'sort_order',
    ];

    protected $appends = ['file_url'];

    public function booking()
    {
        return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
    }

    public function getFileUrlAttribute(): string
    {
        return asset('storage/' . $this->file_path);
    }
}
