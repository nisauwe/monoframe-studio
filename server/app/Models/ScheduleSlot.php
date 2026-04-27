<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ScheduleSlot extends Model
{
  use HasFactory;

  protected $fillable = [
    'schedule_date',
    'start_time',
    'end_time',
    'capacity_total',
    'booked_count',
    'is_active',
    'source',
    'notes',
  ];

  public function bookings()
  {
    return $this->belongsToMany(
      ScheduleBooking::class,
      'schedule_booking_slot',
      'schedule_slot_id',
      'schedule_booking_id'
    );
  }
}
