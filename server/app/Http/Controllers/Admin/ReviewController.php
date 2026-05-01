<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Review;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index(Request $request)
    {
        $baseQuery = Review::query()
            ->with([
                'client',
                'booking.package',

                // penting agar total cetak bisa dibaca di index review
                'booking.printOrder.items.printPrice',
                'booking.printOrder.payment',
            ]);

        $totalReviews = (clone $baseQuery)->count();

        $averageRating = (clone $baseQuery)->avg('rating') ?? 0;

        $todayReviews = (clone $baseQuery)
            ->whereDate('created_at', Carbon::today())
            ->count();

        $lowRatingReviews = (clone $baseQuery)
            ->whereIn('rating', [1, 2])
            ->count();

        $reviews = $baseQuery
            ->when($request->filled('search'), function ($query) use ($request) {
                $search = trim($request->search);

                $query->where(function ($q) use ($search) {
                    $q->where('comment', 'like', "%{$search}%")
                        ->orWhereHas('client', function ($clientQuery) use ($search) {
                            $clientQuery
                                ->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%")
                                ->orWhere('phone', 'like', "%{$search}%");
                        })
                        ->orWhereHas('booking', function ($bookingQuery) use ($search) {
                            $bookingQuery
                                ->where('client_name', 'like', "%{$search}%")
                                ->orWhere('client_phone', 'like', "%{$search}%")
                                ->orWhere('location_name', 'like', "%{$search}%");
                        })
                        ->orWhereHas('booking.package', function ($packageQuery) use ($search) {
                            $packageQuery->where('name', 'like', "%{$search}%");
                        });
                });
            })
            ->when($request->filled('rating'), function ($query) use ($request) {
                $query->where('rating', (int) $request->rating);
            })
            ->when($request->filled('date_from'), function ($query) use ($request) {
                $query->whereDate('created_at', '>=', $request->date_from);
            })
            ->when($request->filled('date_to'), function ($query) use ($request) {
                $query->whereDate('created_at', '<=', $request->date_to);
            })
            ->latest()
            ->paginate(9)
            ->withQueryString();

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