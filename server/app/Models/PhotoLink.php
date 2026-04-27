<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PhotoLink extends Model
{
  use HasFactory;

  protected $fillable = [
    'schedule_booking_id',
    'photographer_user_id',
    'drive_url',
    'drive_label',
    'notes',
    'uploaded_at',
    'is_active',
  ];

  protected $casts = [
    'uploaded_at' => 'datetime',
    'is_active' => 'boolean',
  ];

  public function booking()
  {
    return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
  }

  public function photographer()
  {
    return $this->belongsTo(User::class, 'photographer_user_id');
  }
}
