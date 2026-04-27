<?php

namespace App\Http\Controllers\Api\Photographer;

use App\Http\Controllers\Controller;
use App\Models\ScheduleBooking;
use Illuminate\Http\Request;

class AssignedBookingController extends Controller
{
    public function index(Request $request)
    {
        $bookings = ScheduleBooking::with(['package', 'photoLink', 'moodboards'])
            ->where('photographer_user_id', $request->user()->id)
            ->where('status', '!=', 'cancelled')
            ->orderBy('booking_date')
            ->orderBy('start_time')
            ->get();

        return response()->json([
            'message' => 'Jadwal fotografer berhasil diambil',
            'data' => $bookings
        ]);
    }

    public function show(Request $request, ScheduleBooking $booking)
    {
        if ($booking->photographer_user_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak'
            ], 403);
        }

        return response()->json([
            'message' => 'Detail jadwal fotografer berhasil diambil',
            'data' => $booking->load(['package', 'photoLink', 'clientUser', 'moodboards'])
        ]);
    }
}
