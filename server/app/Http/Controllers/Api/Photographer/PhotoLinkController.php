<?php

namespace App\Http\Controllers\Api\Photographer;

use App\Http\Controllers\Controller;
use App\Models\PhotoLink;
use App\Models\ScheduleBooking;
use Illuminate\Http\Request;

class PhotoLinkController extends Controller
{
  public function store(Request $request)
  {
    $validated = $request->validate([
      'booking_id' => ['required', 'exists:schedule_bookings,id'],
      'drive_url' => ['required', 'url'],
      'drive_label' => ['nullable', 'string', 'max:255'],
      'notes' => ['nullable', 'string'],
    ]);

    $user = $request->user();
    $booking = ScheduleBooking::with('package')->findOrFail($validated['booking_id']);

    if ($booking->photographer_user_id !== $user->id) {
      return response()->json([
        'message' => 'Booking ini bukan tugas fotografer yang login'
      ], 403);
    }

    $photoLink = PhotoLink::updateOrCreate(
      ['schedule_booking_id' => $booking->id],
      [
        'photographer_user_id' => $user->id,
        'drive_url' => $validated['drive_url'],
        'drive_label' => $validated['drive_label'] ?? null,
        'notes' => $validated['notes'] ?? null,
        'uploaded_at' => now(),
        'is_active' => true,
      ]
    );

    $trackingService = app(\App\Services\BookingTrackingService::class);
    $trackingService->markDone($booking, 'shooting', 'Sesi pemotretan telah selesai.');
    $trackingService->markDone($booking, 'photo_upload', 'Link hasil foto telah tersedia untuk klien.');
    $trackingService->markCurrent($booking, 'edit_upload', 'Menunggu klien mengirim daftar foto yang akan diedit.');

    return response()->json([
      'message' => 'Link Google Drive berhasil disimpan',
      'data' => $photoLink
    ], 201);
  }
}
