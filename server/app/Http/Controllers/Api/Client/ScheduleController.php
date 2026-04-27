<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
  public function index(Request $request)
  {
    $request->validate([
      'package_id' => ['required', 'exists:packages,id'],
      'booking_date' => ['required', 'date'],
      'add_extra_duration' => ['nullable', 'boolean'],
    ]);

    // Reuse sementara logic admin agar hasil slot sama persis.
    $adminScheduleController = app(\App\Http\Controllers\Admin\ScheduleController::class);

    return $adminScheduleController->availableSlots($request);
  }
}
