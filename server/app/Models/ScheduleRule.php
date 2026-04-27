<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ScheduleRule extends Model
{
  use HasFactory;

  protected $fillable = [
    'day_of_week',
    'day_name',
    'is_active',
    'indoor_open_time',
    'indoor_close_time',
    'outdoor_open_time',
    'outdoor_close_time',
    'indoor_capacity',
    'indoor_buffer_minutes',
    'outdoor_buffer_minutes',
    'extra_duration_minutes',
    'extra_duration_fee',
  ];
}
