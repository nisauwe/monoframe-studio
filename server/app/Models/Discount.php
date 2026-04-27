<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Discount extends Model
{
  use HasFactory;

  protected $fillable = [
    'category_id',
    'promo_name',
    'discount_percent',
    'discount_start_at',
    'discount_end_at',
    'is_active',
  ];

  protected $casts = [
    'is_active' => 'boolean',
    'discount_start_at' => 'date',
    'discount_end_at' => 'date',
  ];

  protected $appends = [
    'is_currently_active',
  ];

  public function category()
  {
    return $this->belongsTo(Category::class);
  }

  public function packages()
  {
    return $this->belongsToMany(Package::class)->withTimestamps();
  }

  public function getIsCurrentlyActiveAttribute(): bool
  {
    if (!$this->is_active) {
      return false;
    }

    $today = Carbon::today();

    if ($this->discount_start_at && $today->lt($this->discount_start_at)) {
      return false;
    }

    if ($this->discount_end_at && $today->gt($this->discount_end_at)) {
      return false;
    }

    return true;
  }
}
