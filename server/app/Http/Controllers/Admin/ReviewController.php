<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Review;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index(Request $request)
    {
        $query = Review::query()
            ->with([
                'client',
                'booking.package',
                'booking.photographerUser',
            ])
            ->latest();

        if ($request->filled('search')) {
            $search = trim($request->search);

            $query->where(function (Builder $q) use ($search) {
                $q->where('comment', 'like', "%{$search}%")
                    ->orWhereHas('client', function (Builder $clientQuery) use ($search) {
                        $clientQuery->where('name', 'like', "%{$search}%")
                            ->orWhere('email', 'like', "%{$search}%")
                            ->orWhere('phone', 'like', "%{$search}%");
                    })
                    ->orWhereHas('booking', function (Builder $bookingQuery) use ($search) {
                        $bookingQuery->where('client_name', 'like', "%{$search}%")
                            ->orWhere('client_phone', 'like', "%{$search}%")
                            ->orWhere('booking_date', 'like', "%{$search}%")
                            ->orWhereHas('package', function (Builder $packageQuery) use ($search) {
                                $packageQuery->where('name', 'like', "%{$search}%")
                                    ->orWhere('location_type', 'like', "%{$search}%");
                            });
                    });
            });
        }

        if ($request->filled('rating') && $request->rating !== 'Semua Rating') {
            $query->where('rating', (int) $request->rating);
        }

        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $reviews = $query->paginate(10)->withQueryString();

        $totalReviews = Review::count();
        $averageRating = Review::count() > 0
            ? round((float) Review::avg('rating'), 1)
            : 0;

        $todayReviews = Review::whereDate('created_at', now()->toDateString())->count();
        $lowRatingReviews = Review::where('rating', '<=', 2)->count();

        return view('admin.reviews.index', compact(
            'reviews',
            'totalReviews',
            'averageRating',
            'todayReviews',
            'lowRatingReviews'
        ));
    }

    public function destroy(Review $review)
    {
        $review->delete();

        return redirect()
            ->route('admin.reviews.index')
            ->with('success', 'Review klien berhasil dihapus.');
    }
}
