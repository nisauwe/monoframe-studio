<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\User;
use App\Services\BookingTrackingService;
use App\Services\PhotographerAvailabilityService;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

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
      'payments',
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

    $data = $bookings->map(function (ScheduleBooking $booking) {
      $currentStage = $booking->trackings->firstWhere('status', 'current');

      return [
        'id' => $booking->id,
        'package_id' => $booking->package_id,
        'client_user_id' => $booking->client_user_id,
        'photographer_user_id' => $booking->photographer_user_id,

        'client_name' => $booking->client_name,
        'client_phone' => $booking->client_phone,
        'booking_date' => $booking->booking_date,
        'start_time' => $booking->start_time,
        'end_time' => $booking->end_time,
        'blocked_until' => $booking->blocked_until,

        'location_type' => $booking->location_type,
        'location_name' => $booking->location_name,

        'duration_minutes' => (int) $booking->duration_minutes,
        'extra_duration_units' => (int) ($booking->extra_duration_units ?? 0),
        'extra_duration_minutes' => (int) ($booking->extra_duration_minutes ?? 0),
        'extra_duration_fee' => (int) ($booking->extra_duration_fee ?? 0),

        'video_addon_type' => $booking->video_addon_type,
        'video_addon_name' => $booking->video_addon_name,
        'video_addon_price' => (int) ($booking->video_addon_price ?? 0),

        'status' => $booking->status,
        'payment_status' => $booking->payment_status,
        'payment_status_label' => $this->paymentStatusLabel($booking),
        'is_dp_paid' => $booking->isDpPaid(),
        'is_fully_paid' => $booking->isFullyPaid(),

        'notes' => $booking->notes,

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
        ] : [
          'stage_key' => 'assign_photographer',
          'stage_name' => 'Assign Fotografer',
          'description' => 'Booking menunggu proses Front Office',
        ],

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
      'payments',
      'photoLink',
      'editRequest',
      'trackings',
    ]);

    return response()->json([
      'message' => 'Detail monitoring progres berhasil diambil',
      'data' => $booking,
    ]);
  }

  public function availableSlotsForEdit(Request $request, ScheduleBooking $booking)
  {
    $request->validate([
      'package_id' => ['required', 'exists:packages,id'],
      'booking_date' => ['required', 'date'],
      'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
    ]);

    $adminScheduleController = app(\App\Http\Controllers\Admin\ScheduleController::class);

    $response = $adminScheduleController->availableSlots($request);
    $slots = $response->getData(true);

    $bookingDate = Carbon::parse($request->booking_date)->toDateString();
    $extraUnits = (int) $request->integer('extra_duration_units', 0);

    $sameOriginalCondition =
      (int) $booking->package_id === (int) $request->package_id
      && Carbon::parse($booking->booking_date)->toDateString() === $bookingDate
      && (int) ($booking->extra_duration_units ?? 0) === $extraUnits;

    if ($sameOriginalCondition) {
      $originalStart = $this->normalizeTime($booking->start_time);
      $exists = collect($slots)->contains(function ($slot) use ($originalStart) {
        return $this->normalizeTime($slot['start_time'] ?? '') === $originalStart;
      });

      if (!$exists) {
        array_unshift($slots, [
          'start_time' => $this->normalizeTime($booking->start_time, true),
          'end_time' => $this->normalizeTime($booking->end_time, true),
          'blocked_until' => $this->normalizeTime($booking->blocked_until ?: $booking->end_time, true),
          'label' => $this->normalizeTime($booking->start_time) . ' - ' . $this->normalizeTime($booking->end_time),
          'remaining_capacity' => null,
          'extra_duration_units' => (int) ($booking->extra_duration_units ?? 0),
          'extra_duration_minutes' => (int) ($booking->extra_duration_minutes ?? 0),
          'extra_duration_fee' => (int) ($booking->extra_duration_fee ?? 0),
          'ready_photographers_count' => 1,
          'is_current_booking_slot' => true,
        ]);
      }
    }

    return response()->json([
      'message' => 'Slot edit booking berhasil diambil',
      'data' => array_values($slots),
    ]);
  }

  public function availablePhotographersForEdit(
    Request $request,
    ScheduleBooking $booking,
    PhotographerAvailabilityService $availabilityService
  ) {
    $request->validate([
      'booking_date' => ['required', 'date'],
      'start_time' => ['required'],
      'end_time' => ['required'],
    ]);

    $bookingDate = Carbon::parse($request->booking_date)->toDateString();
    $startTime = $this->normalizeTime($request->start_time, true);
    $endTime = $this->normalizeTime($request->end_time, true);

    $photographers = $availabilityService->getAvailablePhotographers(
      $bookingDate,
      $startTime,
      $endTime,
      $booking->id
    );

    return response()->json([
      'message' => 'Daftar fotografer edit booking berhasil diambil',
      'data' => $photographers->where('is_available', true)->values(),
    ]);
  }

  public function updateBooking(
    Request $request,
    ScheduleBooking $booking,
    PhotographerAvailabilityService $availabilityService,
    BookingTrackingService $trackingService
  ) {
    $validated = $request->validate([
      'package_id' => ['required', 'exists:packages,id'],
      'booking_date' => ['required', 'date'],
      'start_time' => ['required'],
      'end_time' => ['required'],
      'blocked_until' => ['nullable'],
      'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
      'extra_duration_minutes' => ['nullable', 'integer', 'min:0'],
      'extra_duration_fee' => ['nullable', 'numeric', 'min:0'],
      'photographer_user_id' => ['nullable', 'exists:users,id'],
      'location_name' => ['nullable', 'string', 'max:255'],
      'notes' => ['nullable', 'string'],
    ]);

    $package = Package::where('is_active', true)->findOrFail($validated['package_id']);

    $bookingDate = Carbon::parse($validated['booking_date'])->toDateString();
    $startTime = $this->normalizeTime($validated['start_time'], true);
    $endTime = $this->normalizeTime($validated['end_time'], true);
    $blockedUntil = $this->normalizeTime($validated['blocked_until'] ?? $validated['end_time'], true);

    $locationType = $package->location_type === 'outdoor' ? 'outdoor' : 'indoor';

    $locationName = $locationType === 'indoor'
      ? 'Indoor Studio Monoframe'
      : trim((string) ($validated['location_name'] ?? ''));

    if ($locationType === 'outdoor' && $locationName === '') {
      throw ValidationException::withMessages([
        'location_name' => 'Lokasi outdoor wajib diisi.',
      ]);
    }

    $photographer = null;

    if (!empty($validated['photographer_user_id'])) {
      $photographer = User::query()
        ->where('id', $validated['photographer_user_id'])
        ->where('role', 'Fotografer')
        ->where('is_active', true)
        ->firstOrFail();

      $isAvailable = $availabilityService->isPhotographerAvailable(
        $photographer->id,
        $bookingDate,
        $startTime,
        $endTime,
        $booking->id
      );

      if (!$isAvailable) {
        throw ValidationException::withMessages([
          'photographer_user_id' => 'Fotografer ini tidak tersedia pada slot yang dipilih.',
        ]);
      }
    }

    DB::transaction(function () use (
      $booking,
      $package,
      $validated,
      $bookingDate,
      $startTime,
      $endTime,
      $blockedUntil,
      $locationType,
      $locationName,
      $photographer
    ) {
      $booking->update([
        'package_id' => $package->id,
        'photographer_user_id' => $photographer?->id,
        'photographer_name' => $photographer?->name,

        'booking_date' => $bookingDate,
        'start_time' => $startTime,
        'end_time' => $endTime,
        'blocked_until' => $blockedUntil,

        'duration_minutes' => (int) $package->duration_minutes,
        'extra_duration_units' => (int) ($validated['extra_duration_units'] ?? 0),
        'extra_duration_minutes' => (int) ($validated['extra_duration_minutes'] ?? 0),
        'extra_duration_fee' => (int) ($validated['extra_duration_fee'] ?? 0),

        'location_type' => $locationType,
        'location_name' => $locationName,
        'notes' => $validated['notes'] ?? null,
      ]);
    });

    $booking->refresh();

    $trackingService->syncTrackingState($booking);

    return response()->json([
      'message' => 'Detail booking berhasil diperbarui oleh Front Office',
      'data' => $booking->fresh([
        'package',
        'clientUser',
        'photographerUser',
        'latestPayment',
        'payments',
        'photoLink',
        'editRequest',
        'trackings',
      ]),
    ]);
  }

  private function paymentStatusLabel(ScheduleBooking $booking): string
  {
    if ($booking->isFullyPaid()) {
      return 'Lunas';
    }

    if ($booking->isDpPaid()) {
      return 'DP Terbayar';
    }

    return match ($booking->payment_status) {
      'unpaid' => 'Belum Bayar',
      'pending' => 'Menunggu Pembayaran',
      'failed' => 'Pembayaran Gagal',
      'dp_paid', 'partially_paid' => 'DP Terbayar',
      'paid', 'fully_paid' => 'Lunas',
      default => ucfirst((string) ($booking->payment_status ?? 'Belum Bayar')),
    };
  }

  private function normalizeTime(?string $value, bool $withSeconds = false): string
  {
    $value = trim((string) $value);

    if ($value === '') {
      return $withSeconds ? '00:00:00' : '00:00';
    }

    $parts = explode(':', $value);

    $hour = str_pad((string) ((int) ($parts[0] ?? 0)), 2, '0', STR_PAD_LEFT);
    $minute = str_pad((string) ((int) ($parts[1] ?? 0)), 2, '0', STR_PAD_LEFT);
    $second = str_pad((string) ((int) ($parts[2] ?? 0)), 2, '0', STR_PAD_LEFT);

    return $withSeconds ? "{$hour}:{$minute}:{$second}" : "{$hour}:{$minute}";
  }
}
