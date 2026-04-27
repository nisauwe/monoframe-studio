<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BookingTracking extends Model
{
  use HasFactory;

  protected $fillable = [
    'schedule_booking_id',
    'stage_order',
    'stage_key',
    'stage_name',
    'status',
    'description',
    'occurred_at',
    'meta',
  ];

  protected $casts = [
    'occurred_at' => 'datetime',
    'meta' => 'array',
  ];

  public function booking()
  {
    return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
  }
}
