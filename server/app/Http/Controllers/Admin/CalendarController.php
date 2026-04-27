<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\ScheduleRule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class CalendarController extends Controller
{
  public function index(Request $request)
  {
    Carbon::setLocale('id');

    $viewMode = $request->get('view', 'month');
    if (!in_array($viewMode, ['month', 'week', 'day'])) {
      $viewMode = 'month';
    }

    $anchorDate = $request->filled('date')
      ? Carbon::parse($request->get('date'))
      : now();

    [$periodStart, $periodEnd, $title, $prevDate, $nextDate] = $this->resolvePeriod($viewMode, $anchorDate);

    $bookings = ScheduleBooking::with(['package', 'clientUser', 'photographerUser'])
      ->whereBetween('booking_date', [
        $periodStart->toDateString(),
        $periodEnd->toDateString(),
      ])
      ->whereIn('status', ['pending', 'confirmed', 'completed'])
      ->orderBy('booking_date')
      ->orderBy('start_time')
      ->get();

    $bookingsByDate = $bookings
      ->groupBy(fn($booking) => Carbon::parse($booking->booking_date)->toDateString());

    $selectedDate = $request->get('selected_date', $anchorDate->toDateString());

    if (!$request->filled('selected_date') && !$bookingsByDate->has($selectedDate)) {
      $selectedDate = $bookingsByDate->keys()->first() ?? $anchorDate->toDateString();
    }

    $selectedDateBookings = collect($bookingsByDate->get($selectedDate, collect()))
      ->sortBy('start_time')
      ->values();

    $selectedBookingId = $request->integer('selected_booking_id');
    $selectedBooking = null;

    if ($selectedBookingId) {
      $selectedBooking = $selectedDateBookings->firstWhere('id', $selectedBookingId);
    }

    if (!$selectedBooking) {
      $selectedBooking = $selectedDateBookings->first();
    }

    $statsMonth = $anchorDate->copy()->startOfMonth();
    $statsBookings = ScheduleBooking::whereBetween('booking_date', [
      $statsMonth->copy()->startOfMonth()->toDateString(),
      $statsMonth->copy()->endOfMonth()->toDateString(),
    ])
      ->whereIn('status', ['pending', 'confirmed', 'completed'])
      ->get();

    $totalSchedules = $statsBookings->count();
    $totalBookedDays = $statsBookings->groupBy('booking_date')->count();

    $packages = Package::where('is_active', true)
      ->orderBy('name')
      ->get();

    $clients = User::where('role', 'Klien')
      ->orderBy('email')
      ->get(['id', 'name', 'email', 'phone']);

    $photographers = $this->activePhotographers()
      ->orderBy('name')
      ->get(['id', 'name', 'email']);

    $monthDays = $this->buildMonthCells($anchorDate);
    $weekDays = $this->buildWeekDays($anchorDate);

    $dayStartHour = 6;
    $dayEndHour = 22;
    $hourRowHeight = 72;

    return view('admin.calendar.index', compact(
      'viewMode',
      'anchorDate',
      'periodStart',
      'periodEnd',
      'title',
      'prevDate',
      'nextDate',
      'bookings',
      'bookingsByDate',
      'selectedDate',
      'selectedDateBookings',
      'selectedBooking',
      'totalSchedules',
      'totalBookedDays',
      'packages',
      'clients',
      'photographers',
      'monthDays',
      'weekDays',
      'dayStartHour',
      'dayEndHour',
      'hourRowHeight'
    ));
  }

  public function store(Request $request)
  {
    $request->validate([
      'package_id' => ['required', 'exists:packages,id'],
      'client_user_id' => ['required', 'exists:users,id'],
      'photographer_user_id' => ['required', 'exists:users,id'],
      'booking_date' => ['required', 'date'],
      'start_time' => ['required'],
      'add_extra_duration' => ['nullable'],
      'location_name' => ['nullable', 'string'],
      'notes' => ['nullable', 'string'],
    ]);

    $package = Package::findOrFail($request->package_id);
    $client = User::findOrFail($request->client_user_id);
    $photographer = User::findOrFail($request->photographer_user_id);

    $bookingDate = Carbon::parse($request->booking_date)->toDateString();
    $rule = $this->ruleForDate($bookingDate);

    if (!$rule || !$rule->is_active) {
      throw ValidationException::withMessages([
        'booking_date' => 'Hari ini tidak aktif untuk operasional booking.',
      ]);
    }

    $locationType = $this->normalizedLocationType($package);
    [$openTime, $closeTime] = $this->locationWindow($rule, $locationType);

    if (!$openTime || !$closeTime) {
      throw ValidationException::withMessages([
        'booking_date' => 'Jam operasional untuk lokasi ini belum diatur.',
      ]);
    }

    $serviceMinutes = (int) $package->duration_minutes;
    $extraMinutes = 0;
    $extraFee = 0;

    if ($request->boolean('add_extra_duration')) {
      $extraMinutes = (int) ($rule->extra_duration_minutes ?? 30);
      $extraFee = (int) ($rule->extra_duration_fee ?? 150000);
      $serviceMinutes += $extraMinutes;
    }

    $start = Carbon::parse($bookingDate . ' ' . $request->start_time);
    $end = $start->copy()->addMinutes($serviceMinutes);

    $bufferMinutes = $locationType === 'indoor'
      ? $this->indoorBufferMinutes($rule)
      : $this->outdoorBufferMinutes($rule);

    $blockedUntil = $end->copy()->addMinutes($bufferMinutes);

    $open = Carbon::parse($bookingDate . ' ' . $openTime);
    $close = Carbon::parse($bookingDate . ' ' . $closeTime);

    if ($start->lt($open) || $end->gt($close)) {
      throw ValidationException::withMessages([
        'start_time' => 'Jam booking berada di luar jam operasional.',
      ]);
    }

    DB::transaction(function () use (
      $request,
      $package,
      $client,
      $photographer,
      $bookingDate,
      $start,
      $end,
      $blockedUntil,
      $serviceMinutes,
      $extraMinutes,
      $extraFee,
      $locationType,
      $rule
    ) {
      if ($this->hasPhotographerConflict($photographer->id, $bookingDate, $start, $blockedUntil, true)) {
        throw ValidationException::withMessages([
          'photographer_user_id' => 'Fotografer ini bentrok dengan jadwal lain.',
        ]);
      }

      if ($locationType === 'indoor') {
        $capacity = max(1, (int) ($rule->indoor_capacity ?? 1));
        $overlapCount = $this->indoorOverlapCount($bookingDate, $start, $blockedUntil, true);

        if ($overlapCount >= $capacity) {
          throw ValidationException::withMessages([
            'start_time' => 'Kapasitas indoor pada jam ini sudah penuh.',
          ]);
        }
      }

      $locationName = $locationType === 'indoor'
        ? 'Indoor Studio Monoframe'
        : trim((string) $request->location_name);

      if ($locationType === 'outdoor' && $locationName === '') {
        throw ValidationException::withMessages([
          'location_name' => 'Lokasi outdoor wajib diisi.',
        ]);
      }

      ScheduleBooking::create([
        'package_id' => $package->id,
        'client_user_id' => $client->id,
        'photographer_user_id' => $photographer->id,
        'client_name' => $client->name,
        'client_phone' => $client->phone,
        'photographer_name' => $photographer->name,
        'booking_date' => $bookingDate,
        'start_time' => $start->format('H:i:s'),
        'end_time' => $end->format('H:i:s'),
        'blocked_until' => $blockedUntil->format('H:i:s'),
        'duration_minutes' => (int) $package->duration_minutes,
        'extra_duration_minutes' => $extraMinutes,
        'extra_duration_fee' => $extraFee,
        'location_type' => $locationType,
        'location_name' => $locationName,
        'status' => 'confirmed',
        'source' => 'calendar_manual',
        'notes' => $request->notes,
      ]);
    });

    return redirect()->route('admin.calendar.index', [
      'view' => $request->get('view', 'month'),
      'date' => $bookingDate,
      'selected_date' => $bookingDate,
    ])->with('success', 'Jadwal berhasil ditambahkan ke kalender.');
  }

  private function resolvePeriod(string $viewMode, Carbon $anchorDate): array
  {
    if ($viewMode === 'week') {
      $start = $anchorDate->copy()->startOfWeek(Carbon::SUNDAY);
      $end = $anchorDate->copy()->endOfWeek(Carbon::SATURDAY);
      $title = $start->translatedFormat('d') . ' - ' . $end->translatedFormat('d F Y');
      $prev = $anchorDate->copy()->subWeek();
      $next = $anchorDate->copy()->addWeek();

      return [$start, $end, $title, $prev, $next];
    }

    if ($viewMode === 'day') {
      $start = $anchorDate->copy()->startOfDay();
      $end = $anchorDate->copy()->endOfDay();
      $title = $anchorDate->translatedFormat('l, d F Y');
      $prev = $anchorDate->copy()->subDay();
      $next = $anchorDate->copy()->addDay();

      return [$start, $end, $title, $prev, $next];
    }

    $start = $anchorDate->copy()->startOfMonth()->startOfWeek(Carbon::SUNDAY);
    $end = $anchorDate->copy()->endOfMonth()->endOfWeek(Carbon::SATURDAY);
    $title = $anchorDate->translatedFormat('F Y');
    $prev = $anchorDate->copy()->subMonthNoOverflow();
    $next = $anchorDate->copy()->addMonthNoOverflow();

    return [$start, $end, $title, $prev, $next];
  }

  private function buildMonthCells(Carbon $anchorDate): Collection
  {
    $start = $anchorDate->copy()->startOfMonth()->startOfWeek(Carbon::SUNDAY);
    $end = $anchorDate->copy()->endOfMonth()->endOfWeek(Carbon::SATURDAY);

    $days = collect();
    $cursor = $start->copy();

    while ($cursor->lte($end)) {
      $days->push($cursor->copy());
      $cursor->addDay();
    }

    return $days;
  }

  private function buildWeekDays(Carbon $anchorDate): Collection
  {
    $start = $anchorDate->copy()->startOfWeek(Carbon::SUNDAY);

    return collect(range(0, 6))->map(function ($offset) use ($start) {
      return $start->copy()->addDays($offset);
    });
  }

  private function activePhotographers()
  {
    $query = User::where('role', 'Fotografer');

    if (Schema::hasColumn('users', 'is_active')) {
      $query->where('is_active', true);
    }

    return $query;
  }

  private function ruleForDate(string $bookingDate): ?ScheduleRule
  {
    $date = Carbon::parse($bookingDate);

    return ScheduleRule::where('day_of_week', $date->dayOfWeek)->first();
  }

  private function normalizedLocationType(Package $package): string
  {
    return $package->location_type === 'outdoor' ? 'outdoor' : 'indoor';
  }

  private function locationWindow(ScheduleRule $rule, string $locationType): array
  {
    if ($locationType === 'outdoor') {
      return [$rule->outdoor_open_time, $rule->outdoor_close_time];
    }

    return [$rule->indoor_open_time, $rule->indoor_close_time];
  }

  private function indoorBufferMinutes(ScheduleRule $rule): int
  {
    return (int) ($rule->indoor_buffer_minutes ?? 15);
  }

  private function outdoorBufferMinutes(ScheduleRule $rule): int
  {
    return (int) ($rule->outdoor_buffer_minutes ?? 45);
  }

  private function hasPhotographerConflict(
    int $photographerId,
    string $bookingDate,
    Carbon $start,
    Carbon $blockedUntil,
    bool $lock = false
  ): bool {
    $query = ScheduleBooking::where('booking_date', $bookingDate)
      ->where('photographer_user_id', $photographerId)
      ->whereIn('status', ['pending', 'confirmed', 'completed']);

    if ($lock) {
      $query->lockForUpdate();
    }

    return $query->get()->contains(function ($booking) use ($bookingDate, $start, $blockedUntil) {
      $existingStart = Carbon::parse($bookingDate . ' ' . $booking->start_time);
      $existingEnd = Carbon::parse($bookingDate . ' ' . ($booking->blocked_until ?: $booking->end_time));

      return $existingStart < $blockedUntil && $existingEnd > $start;
    });
  }

  private function indoorOverlapCount(
    string $bookingDate,
    Carbon $start,
    Carbon $blockedUntil,
    bool $lock = false
  ): int {
    $query = ScheduleBooking::where('booking_date', $bookingDate)
      ->where('location_type', 'indoor')
      ->whereIn('status', ['pending', 'confirmed', 'completed']);

    if ($lock) {
      $query->lockForUpdate();
    }

    return $query->get()->filter(function ($booking) use ($bookingDate, $start, $blockedUntil) {
      $existingStart = Carbon::parse($bookingDate . ' ' . $booking->start_time);
      $existingEnd = Carbon::parse($bookingDate . ' ' . ($booking->blocked_until ?: $booking->end_time));

      return $existingStart < $blockedUntil && $existingEnd > $start;
    })->count();
  }
}
