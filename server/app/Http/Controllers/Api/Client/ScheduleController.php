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
            'booking_date' => ['required', 'date', 'after:today'],
            'add_extra_duration' => ['nullable', 'boolean'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
        ], [
            'booking_date.after' => 'Jadwal hanya bisa dipilih minimal H-1. Silakan pilih tanggal mulai besok.',
        ]);

        $adminScheduleController = app(\App\Http\Controllers\Admin\ScheduleController::class);

        return $adminScheduleController->availableSlots($request);
    }
}
