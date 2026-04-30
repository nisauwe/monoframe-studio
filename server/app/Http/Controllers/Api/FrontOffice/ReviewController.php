<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Models\Review;

class ReviewController extends Controller
{
    public function summary()
    {
        $totalReviews = Review::count();

        $averageRating = $totalReviews > 0
            ? round((float) Review::avg('rating'), 1)
            : 0;

        $todayReviews = Review::whereDate('created_at', now()->toDateString())->count();

        $lowRatingReviews = Review::where('rating', '<=', 2)->count();

        return response()->json([
            'message' => 'Ringkasan review berhasil diambil',
            'summary' => [
                'total_reviews' => $totalReviews,
                'average_rating' => $averageRating,
                'today_reviews' => $todayReviews,
                'low_rating_reviews' => $lowRatingReviews,
            ],
        ]);
    }
}
