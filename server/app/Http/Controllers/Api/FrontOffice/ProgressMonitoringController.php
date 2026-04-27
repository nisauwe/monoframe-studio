<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Models\ScheduleBooking;
use Illuminate\Http\Request;

class ProgressMonitoringController extends Controller
{
  public function index(Request $request)
  {
    $request->validate([
      'booking_date' => ['nullable', 'date'],
      'status' => ['nullable', 'string'],
      'photographer_user_id' => ['nullable', 'exists:users,id'],
      'search' => ['nullable', 'string'],
    ]);

    $query = ScheduleBooking::with([
      'package',
      'clientUser',
      'photographerUser',
      'latestPayment',
      'photoLink',
      'editRequest',
      'trackings',
    ])->whereNotIn('status', ['cancelled']);

    if ($request->filled('booking_date')) {
      $query->whereDate('booking_date', $request->booking_date);
    }

    if ($request->filled('status')) {
      $query->where('status', $request->status);
    }

    if ($request->filled('photographer_user_id')) {
      $query->where('photographer_user_id', $request->photographer_user_id);
    }

    if ($request->filled('search')) {
      $search = $request->search;
      $query->where(function ($q) use ($search) {
        $q->where('client_name', 'like', "%{$search}%")
          ->orWhereHas('package', function ($qq) use ($search) {
            $qq->where('name', 'like', "%{$search}%");
          })
          ->orWhereHas('photographerUser', function ($qq) use ($search) {
            $qq->where('name', 'like', "%{$search}%");
          });
      });
    }

    $bookings = $query
      ->orderByDesc('booking_date')
      ->orderByDesc('start_time')
      ->get();

    $data = $bookings->map(function ($booking) {
      $currentStage = $booking->trackings->firstWhere('status', 'current');

      return [
        'id' => $booking->id,
        'client_name' => $booking->client_name,
        'booking_date' => $booking->booking_date,
        'start_time' => $booking->start_time,
        'end_time' => $booking->end_time,
        'status' => $booking->status,
        'package' => $booking->package,
        'photographer' => $booking->photographerUser,
        'payment' => $booking->latestPayment ? [
          'transaction_status' => $booking->latestPayment->transaction_status,
          'is_paid' => $booking->latestPayment->isPaid(),
          'gross_amount' => $booking->latestPayment->gross_amount,
        ] : null,
        'current_stage' => $currentStage ? [
          'stage_key' => $currentStage->stage_key,
          'stage_name' => $currentStage->stage_name,
          'description' => $currentStage->description,
        ] : null,
        'has_photo_link' => (bool) $booking->photoLink,
        'edit_request_status' => $booking->editRequest?->status,
        'timeline' => $booking->trackings->values(),
      ];
    });

    return response()->json([
      'message' => 'Monitoring progres layanan berhasil diambil',
      'data' => $data,
    ]);
  }

  public function show(ScheduleBooking $booking)
  {
    $booking->load([
      'package',
      'clientUser',
      'photographerUser',
      'latestPayment',
      'photoLink',
      'editRequest',
      'trackings',
    ]);

    return response()->json([
      'message' => 'Detail monitoring progres berhasil diambil',
      'data' => $booking,
    ]);
  }
}
