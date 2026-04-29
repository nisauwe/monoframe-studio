<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Support\Str;

class Package extends Model
{
  use HasFactory;

  protected $fillable = [
    'category_id',
    'name',
    'price',
    'photo_count',
    'duration_minutes',
    'location_type',
    'person_count',
    'portfolio',
    'description',
    'is_active',
  ];

  protected $casts = [
    'is_active' => 'boolean',
    'portfolio' => 'array',
  ];

  protected $appends = [
    'current_discount',
    'discounted_price',
    'portfolio_urls',
  ];

  public function isIndoor(): bool
  {
    return $this->location_type === 'indoor';
  }

  public function isOutdoor(): bool
  {
    return $this->location_type === 'outdoor';
  }

  public function category()
  {
    return $this->belongsTo(Category::class);
  }

  public function discounts()
  {
    return $this->belongsToMany(Discount::class)->withTimestamps();
  }

  public function getCurrentDiscountAttribute()
  {
    return $this->discounts
      ->sortByDesc(function ($discount) {
        return optional($discount->updated_at)->timestamp ?? 0;
      })
      ->first(function ($discount) {
        return $discount->is_currently_active;
      });
  }

  public function getDiscountedPriceAttribute(): int
  {
    $discount = $this->current_discount;

    if (!$discount) {
      return (int) $this->price;
    }

    $discountAmount = ($this->price * $discount->discount_percent) / 100;

    return (int) round($this->price - $discountAmount);
  }

  public function getPortfolioUrlsAttribute(): array
  {
    $portfolio = $this->portfolio ?? [];

    if (!is_array($portfolio)) {
      return [];
    }

    return collect($portfolio)
      ->filter(fn ($path) => filled($path))
      ->map(function ($path) {
        $path = str_replace('\\', '/', trim((string) $path));

        if (Str::startsWith($path, ['http://', 'https://'])) {
          return $path;
        }

        $path = ltrim($path, '/');

        if (Str::startsWith($path, 'storage/')) {
          return url('/' . $path);
        }

        return url('/storage/' . $path);
      })
      ->values()
      ->toArray();
  }
}
