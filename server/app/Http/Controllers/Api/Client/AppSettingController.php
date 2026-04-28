<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Review;

class AppSettingController extends Controller
{
    public function index()
    {
        $setting = AppSetting::current();

        return response()->json([
            'message' => 'Pengaturan aplikasi berhasil diambil',
            'data' => $setting->toClientArray(),
        ]);
    }

    public function publicReviews()
    {
        $setting = AppSetting::current();

        if (!$setting->review_is_active || !$setting->show_reviews_on_client) {
            return response()->json([
                'message' => 'Review publik sedang tidak ditampilkan',
                'data' => [],
            ]);
        }

        $minimumRating = (int) $setting->minimum_rating_display;

        $reviews = Review::query()
            ->with(['client', 'booking.package'])
            ->where('rating', '>=', $minimumRating)
            ->latest()
            ->limit(10)
            ->get()
            ->map(function (Review $review) {
                return [
                    'id' => $review->id,
                    'rating' => (int) $review->rating,
                    'comment' => $review->comment,
                    'client_name' => $review->client?->name ?? 'Klien Monoframe',
                    'package_name' => $review->booking?->package?->name,
                    'created_at' => optional($review->created_at)->toIso8601String(),
                ];
            })
            ->values();

        return response()->json([
            'message' => 'Review publik berhasil diambil',
            'data' => $reviews,
        ]);
    }
}
