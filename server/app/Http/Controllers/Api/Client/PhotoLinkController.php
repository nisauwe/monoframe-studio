<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ScheduleBooking;
use Illuminate\Http\Request;

class PhotoLinkController extends Controller
{
  public function show(Request $request, ScheduleBooking $booking)
{
    if ($booking->client_user_id !== $request->user()->id) {
        return response()->json([
            'message' => 'Akses ditolak'
        ], 403);
    }

    if ($booking->payment_status !== 'paid') {
        return response()->json([
            'message' => 'Pelunasan belum lunas. Link hasil foto belum bisa dibuka.'
        ], 403);
    }

    $photoLink = $booking->photoLink;

    if (!$photoLink || !$photoLink->is_active) {
        return response()->json([
            'message' => 'Link hasil foto belum tersedia'
        ], 404);
    }

    return response()->json([
        'message' => 'Link hasil foto berhasil diambil',
        'data' => $photoLink
    ]);
}
}
