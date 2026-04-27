<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\CalendarFilterRequest;
use App\Models\ScheduleBooking;
use App\Models\User;
use Carbon\Carbon;

class CalendarController extends Controller
{
  public function index(CalendarFilterRequest $request)
  {
    $validated = $request->validated();

    $startDate = $validated['start_date'] ?? now()->startOfMonth()->toDateString();
    $endDate = $validated['end_date'] ?? now()->endOfMonth()->toDateString();

    $query = ScheduleBooking::with(['package', 'photographerUser'])
      ->whereBetween('booking_date', [$startDate, $endDate])
      ->whereNotNull('photographer_user_id')
      ->whereNotIn('status', ['cancelled']);

    if (!empty($validated['photographer_user_id'])) {
      $query->where('photographer_user_id', $validated['photographer_user_id']);
    }

    $bookings = $query
      ->orderBy('booking_date')
      ->orderBy('start_time')
      ->get();

    $events = $bookings->map(function ($booking) {
      return [
        'id' => $booking->id,
        'title' => $booking->client_name . ' - ' . ($booking->package->name ?? 'Paket'),
        'start' => Carbon::parse($booking->booking_date . ' ' . $booking->start_time)->toIso8601String(),
        'end' => Carbon::parse($booking->booking_date . ' ' . $booking->end_time)->toIso8601String(),
        'photographer' => [
          'id' => $booking->photographerUser?->id,
          'name' => $booking->photographerUser?->name,
        ],
        'package' => $booking->package?->name,
        'status' => $booking->status,
        'location_name' => $booking->location_name,
        'source' => $booking->source,
      ];
    });

    $photographers = User::query()
      ->where('role', 'Fotografer')
      ->where('is_active', true)
      ->orderBy('name')
      ->get(['id', 'name', 'email']);

    return response()->json([
      'message' => 'Kalender fotografer berhasil diambil',
      'filters' => [
        'start_date' => $startDate,
        'end_date' => $endDate,
        'photographer_user_id' => $validated['photographer_user_id'] ?? null,
      ],
      'photographers' => $photographers,
      'data' => $events,
    ]);
  }
}
