<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Package;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class PackageController extends Controller
{
  public function index()
  {
    $today = Carbon::today();

    $packages = Package::with([
      'category',
      'discounts' => function ($query) use ($today) {
        $query
          ->where('is_active', true)
          ->where(function (Builder $query) use ($today) {
            $query
              ->whereNull('discount_start_at')
              ->orWhereDate('discount_start_at', '<=', $today);
          })
          ->where(function (Builder $query) use ($today) {
            $query
              ->whereNull('discount_end_at')
              ->orWhereDate('discount_end_at', '>=', $today);
          })
          ->latest('discounts.updated_at');
      },
    ])
      ->where('is_active', true)
      ->whereHas('category', function (Builder $query) {
        $query->where('is_active', true);
      })
      ->orderBy('name')
      ->get()
      ->map(function (Package $package) {
        return $this->formatPackage($package);
      })
      ->values();

    return response()->json([
      'message' => 'Daftar paket berhasil diambil',
      'data' => $packages,
    ]);
  }

  public function show(Package $package)
  {
    if (!$package->is_active) {
      return response()->json([
        'message' => 'Paket tidak tersedia',
      ], 404);
    }

    if ($package->category && !$package->category->is_active) {
      return response()->json([
        'message' => 'Paket tidak tersedia',
      ], 404);
    }

    $today = Carbon::today();

    $package->load([
      'category',
      'discounts' => function ($query) use ($today) {
        $query
          ->where('is_active', true)
          ->where(function (Builder $query) use ($today) {
            $query
              ->whereNull('discount_start_at')
              ->orWhereDate('discount_start_at', '<=', $today);
          })
          ->where(function (Builder $query) use ($today) {
            $query
              ->whereNull('discount_end_at')
              ->orWhereDate('discount_end_at', '>=', $today);
          })
          ->latest('discounts.updated_at');
      },
    ]);

    return response()->json([
      'message' => 'Detail paket berhasil diambil',
      'data' => $this->formatPackage($package),
    ]);
  }

  private function formatPackage(Package $package): array
  {
    $currentDiscount = $package->discounts
      ->sortByDesc(function ($discount) {
        return optional($discount->updated_at)->timestamp ?? 0;
      })
      ->first();

    $price = (int) $package->price;
    $discountedPrice = $price;

    if ($currentDiscount) {
      $discountAmount = ($price * (int) $currentDiscount->discount_percent) / 100;
      $discountedPrice = (int) round($price - $discountAmount);
    }

    return [
      'id' => $package->id,
      'category_id' => $package->category_id,
      'category' => $package->category,
      'category_name' => $package->category?->name ?? 'Tanpa Kategori',

      'name' => $package->name,
      'description' => $package->description,
      'price' => $price,
      'discounted_price' => $discountedPrice,

      'photo_count' => (int) $package->photo_count,
      'duration_minutes' => (int) $package->duration_minutes,
      'location_type' => $package->location_type,
      'person_count' => $package->person_count ? (int) $package->person_count : null,
      'is_active' => (bool) $package->is_active,

      'portfolio' => $package->portfolio ?? [],
      'portfolio_urls' => $this->portfolioUrls($package),

      'discounts' => $package->discounts->values(),
      'current_discount' => $currentDiscount,
      'created_at' => optional($package->created_at)->toIso8601String(),
      'updated_at' => optional($package->updated_at)->toIso8601String(),
    ];
  }

  private function portfolioUrls(Package $package): array
  {
    $portfolio = $package->portfolio ?? [];

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
