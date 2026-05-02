<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BookingAddonSetting;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\ScheduleRule;
use App\Models\User;
use App\Services\BookingTrackingService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class ScheduleController extends Controller
{
    public function index(Request $request, BookingTrackingService $trackingService)
    {
        $this->seedDefaultRules();

        $selectedDate = $request->get('date', now()->toDateString());
        $selectedTab = $request->get('tab', 'daily');

        $dayRule = $this->ruleForDate($selectedDate);
        $rules = ScheduleRule::orderBy('day_of_week')->get();

        $dayBookings = ScheduleBooking::with(['package', 'clientUser', 'photographerUser'])
            ->whereDate('booking_date', $selectedDate)
            ->whereIn('status', ['pending', 'confirmed', 'completed'])
            ->orderBy('start_time')
            ->get();

        $clients = User::where('role', 'Klien')
            ->orderBy('email')
            ->get(['id', 'name', 'email', 'phone']);

        $photographers = $this->activePhotographers()
            ->orderBy('name')
            ->get(['id', 'name', 'email']);

        $packages = Package::where('is_active', true)
            ->orderBy('name')
            ->get();

        $videoAddons = $this->videoAddons();

        $timeRows = $this->buildTimeRowsFromRule($selectedDate, $dayRule);
        $board = $this->buildDailyBoard($timeRows, $photographers, $dayBookings, $selectedDate);
        $daySlots = $this->buildIndoorSummaryRows($timeRows, $dayBookings, $dayRule, $selectedDate);

        $activeDays = $rules->where('is_active', true)->count();
        $totalSlotsToday = $timeRows->count();
        $extraDurationMinutes = (int) ($dayRule?->extra_duration_minutes ?? 30);
        $extraDurationFee = (int) ($dayRule?->extra_duration_fee ?? 150000);
        $bookedSessionsToday = $dayBookings->count();

        $availableStudioSlots = $daySlots
            ->where('is_active', true)
            ->filter(fn ($slot) => $slot->booked_count < $slot->capacity_total)
            ->count();

        $bookingMonitoringFilter = $request->get('booking_filter', 'need_payment');
        $bookingMonitoringSearch = trim((string) $request->get('booking_search', ''));

        $allowedBookingMonitoringFilters = [
            'all',
            'need_payment',
            'running',
            'completed',
        ];

        if (!in_array($bookingMonitoringFilter, $allowedBookingMonitoringFilters, true)) {
            $bookingMonitoringFilter = 'need_payment';
        }

        $bookingMonitoringQuery = ScheduleBooking::with([
            'package',
            'clientUser',
            'photographerUser',
            'payments',
            'photoLink',
            'editRequest.editor',
            'printOrder',
            'review',
            'trackings',
        ])
            ->whereIn('status', ['pending', 'confirmed', 'completed']);

        if ($bookingMonitoringSearch !== '') {
            $bookingMonitoringQuery->where(function ($query) use ($bookingMonitoringSearch) {
                $query->where('client_name', 'like', '%' . $bookingMonitoringSearch . '%')
                    ->orWhere('client_phone', 'like', '%' . $bookingMonitoringSearch . '%')
                    ->orWhere('photographer_name', 'like', '%' . $bookingMonitoringSearch . '%')
                    ->orWhereHas('package', function ($packageQuery) use ($bookingMonitoringSearch) {
                        $packageQuery->where('name', 'like', '%' . $bookingMonitoringSearch . '%');
                    });
            });
        }

        $bookingMonitoringAll = $bookingMonitoringQuery
            ->orderByDesc('booking_date')
            ->orderByDesc('start_time')
            ->get()
            ->map(function (ScheduleBooking $booking) use ($trackingService) {
                $trackingService->syncTrackingState($booking);

                $booking->load([
                    'package',
                    'clientUser',
                    'photographerUser',
                    'payments',
                    'photoLink',
                    'editRequest.editor',
                    'printOrder',
                    'review',
                    'trackings',
                ]);

                $timeline = $booking->trackings
                    ->sortBy('stage_order')
                    ->values();

                $category = $this->bookingMonitoringCategory($booking, $timeline);
                $currentTracking = $timeline->firstWhere('status', 'current');
                $doneCount = $timeline
                    ->whereIn('status', ['done', 'skipped'])
                    ->count();

                $progressPercent = $timeline->count() > 0
                    ? (int) round(($doneCount / $timeline->count()) * 100)
                    : 0;

                return [
                    'booking' => $booking,
                    'timeline' => $timeline,
                    'category' => $category,
                    'category_label' => $this->bookingMonitoringCategoryLabel($category),
                    'category_badge' => $this->bookingMonitoringCategoryBadge($category),
                    'current_tracking' => $currentTracking,
                    'progress_percent' => $progressPercent,
                    'payment_label' => $this->bookingPaymentStatusLabel($booking),
                    'payment_badge' => $this->bookingPaymentStatusBadge($booking),
                ];
            });

        $bookingMonitoringStats = [
            'all' => $bookingMonitoringAll->count(),
            'need_payment' => $bookingMonitoringAll->where('category', 'need_payment')->count(),
            'running' => $bookingMonitoringAll->where('category', 'running')->count(),
            'completed' => $bookingMonitoringAll->where('category', 'completed')->count(),
        ];

        $bookingMonitoringList = $bookingMonitoringFilter === 'all'
            ? $bookingMonitoringAll
            : $bookingMonitoringAll->where('category', $bookingMonitoringFilter)->values();

        return view('admin.schedules.index', compact(
            'rules',
            'selectedDate',
            'selectedTab',
            'daySlots',
            'dayBookings',
            'packages',
            'clients',
            'photographers',
            'activeDays',
            'totalSlotsToday',
            'extraDurationMinutes',
            'extraDurationFee',
            'timeRows',
            'board',
            'bookedSessionsToday',
            'availableStudioSlots',
            'videoAddons',
            'bookingMonitoringFilter',
            'bookingMonitoringSearch',
            'bookingMonitoringStats',
            'bookingMonitoringList'
        ));
    }

    private function bookingMonitoringCategory(ScheduleBooking $booking, Collection $timeline): string
    {
        $reviewDone = $timeline
            ->where('stage_key', 'review')
            ->where('status', 'done')
            ->isNotEmpty();

        $printDoneOrSkipped = $timeline
            ->where('stage_key', 'print')
            ->whereIn('status', ['done', 'skipped'])
            ->isNotEmpty();

        if (
            $booking->status === 'completed'
            || $booking->review
            || $reviewDone
            || (
                $booking->editRequest
                && $booking->editRequest->status === 'completed'
                && $printDoneOrSkipped
            )
        ) {
            return 'completed';
        }

        if (!$booking->isFullyPaid()) {
            return 'need_payment';
        }

        return 'running';
    }

    private function bookingMonitoringCategoryLabel(string $category): string
    {
        return match ($category) {
            'need_payment' => 'Belum Pelunasan',
            'running' => 'Sedang Berjalan',
            'completed' => 'Selesai',
            default => 'Semua Booking',
        };
    }

    private function bookingMonitoringCategoryBadge(string $category): string
    {
        return match ($category) {
            'need_payment' => 'warning',
            'running' => 'info',
            'completed' => 'success',
            default => 'secondary',
        };
    }

    private function bookingPaymentStatusLabel(ScheduleBooking $booking): string
    {
        if ($booking->isFullyPaid()) {
            return 'Lunas';
        }

        if ($booking->isDpPaid()) {
            return 'DP Dibayar';
        }

        return match ($booking->payment_status) {
            'unpaid' => 'Belum Bayar',
            'pending' => 'Menunggu Pembayaran',
            'failed' => 'Pembayaran Gagal',
            'dp_paid' => 'DP Dibayar',
            'partially_paid' => 'Sebagian Dibayar',
            'paid', 'fully_paid' => 'Lunas',
            default => ucfirst((string) ($booking->payment_status ?? 'Belum Bayar')),
        };
    }

    private function bookingPaymentStatusBadge(ScheduleBooking $booking): string
    {
        if ($booking->isFullyPaid()) {
            return 'success';
        }

        if ($booking->isDpPaid()) {
            return 'warning';
        }

        return match ($booking->payment_status) {
            'unpaid', 'pending' => 'danger',
            'failed' => 'danger',
            'dp_paid', 'partially_paid' => 'warning',
            'paid', 'fully_paid' => 'success',
            default => 'secondary',
        };
    }

    public function updateRules(Request $request)
    {
        $request->validate([
            'rules' => ['required', 'array'],
            'rules.*.id' => ['required', 'exists:schedule_rules,id'],
            'rules.*.is_active' => ['nullable'],
            'rules.*.indoor_open_time' => ['nullable'],
            'rules.*.indoor_close_time' => ['nullable'],
            'rules.*.outdoor_open_time' => ['nullable'],
            'rules.*.outdoor_close_time' => ['nullable'],
            'rules.*.indoor_capacity' => ['required', 'integer', 'min:1'],
            'rules.*.indoor_buffer_minutes' => ['required', 'integer', 'min:0'],
            'rules.*.outdoor_buffer_minutes' => ['required', 'integer', 'min:0'],
            'rules.*.extra_duration_minutes' => ['required', 'integer', 'min:0'],
            'rules.*.extra_duration_fee' => ['required', 'numeric', 'min:0'],
        ]);

        foreach ($request->rules as $ruleData) {
            $rule = ScheduleRule::findOrFail($ruleData['id']);

            $rule->update([
                'is_active' => isset($ruleData['is_active']),
                'indoor_open_time' => $ruleData['indoor_open_time'] ?? null,
                'indoor_close_time' => $ruleData['indoor_close_time'] ?? null,
                'outdoor_open_time' => $ruleData['outdoor_open_time'] ?? null,
                'outdoor_close_time' => $ruleData['outdoor_close_time'] ?? null,
                'indoor_capacity' => (int) $ruleData['indoor_capacity'],
                'indoor_buffer_minutes' => (int) $ruleData['indoor_buffer_minutes'],
                'outdoor_buffer_minutes' => (int) $ruleData['outdoor_buffer_minutes'],
                'extra_duration_minutes' => (int) $ruleData['extra_duration_minutes'],
                'extra_duration_fee' => (int) $ruleData['extra_duration_fee'],
            ]);
        }

        return back()->with('success', 'Pengaturan operasional berhasil diperbarui.');
    }

    public function updateAddonSettings(Request $request)
    {
        $validated = $request->validate([
            'addons' => ['required', 'array'],
            'addons.iphone.price' => ['required', 'numeric', 'min:0'],
            'addons.camera.price' => ['required', 'numeric', 'min:0'],
        ]);

        if (!Schema::hasTable('booking_addon_settings')) {
            return back()->withErrors([
                'addons' => 'Tabel booking_addon_settings belum tersedia. Jalankan migration terlebih dahulu.'
            ]);
        }

        foreach (['iphone', 'camera'] as $key) {
            BookingAddonSetting::query()->updateOrCreate(
                ['addon_key' => $key],
                [
                    'addon_name' => $key === 'iphone'
                        ? 'Video Cinematic - iPhone'
                        : 'Video Cinematic - Camera',
                    'price' => (int) $validated['addons'][$key]['price'],
                    'is_active' => true,
                ]
            );
        }

        return back()->with('success', 'Harga add-on video berhasil diperbarui.');
    }

    public function availableSlots(Request $request)
    {
        $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
            'add_extra_duration' => ['nullable'],
            'exclude_booking_id' => ['nullable', 'exists:schedule_bookings,id'],
        ]);

        $package = Package::findOrFail($request->package_id);
        $bookingDate = Carbon::parse($request->booking_date)->toDateString();
        $this->ensureBookingMinimumHMinusOne($bookingDate);
        $extraUnits = $this->requestExtraUnits($request);
        $excludeBookingId = $request->filled('exclude_booking_id')
            ? (int) $request->exclude_booking_id
            : null;

        $this->ensureBookingMinimumHMinusOne($bookingDate, $excludeBookingId);

        $choices = $this->buildAvailableSlotChoices(
            $package,
            $bookingDate,
            $extraUnits,
            false,
            $excludeBookingId
        );

        return response()->json($choices);
    }

    public function availablePhotographers(Request $request)
    {
        $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
            'add_extra_duration' => ['nullable'],
            'exclude_booking_id' => ['nullable', 'exists:schedule_bookings,id'],
        ]);

        $package = Package::findOrFail($request->package_id);
        $bookingDate = Carbon::parse($request->booking_date)->toDateString();
        $extraUnits = $this->requestExtraUnits($request);
        $excludeBookingId = $request->filled('exclude_booking_id')
            ? (int) $request->exclude_booking_id
            : null;

        $choice = $this->findChoiceByStartTime(
            $package,
            $bookingDate,
            $extraUnits,
            $request->start_time,
            false,
            $excludeBookingId
        );

        if (!$choice) {
            return response()->json([]);
        }

        $photographers = $this->readyPhotographersForChoice(
            $bookingDate,
            $choice,
            false,
            $excludeBookingId
        );

        return response()->json(
            $photographers->map(function ($photographer) {
                return [
                    'id' => $photographer->id,
                    'name' => $photographer->name,
                    'email' => $photographer->email,
                ];
            })->values()
        );
    }

    public function storeManualRequest(Request $request)
    {
        $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'client_user_id' => ['required', 'exists:users,id'],
            'photographer_user_id' => ['required', 'exists:users,id'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
            'video_addon_type' => ['nullable', 'in:iphone,camera'],
            'moodboards' => ['nullable', 'array', 'max:10'],
            'moodboards.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'notes' => ['nullable', 'string'],
        ]);

        $package = Package::findOrFail($request->package_id);
        $client = User::findOrFail($request->client_user_id);
        $photographer = User::findOrFail($request->photographer_user_id);
        $bookingDate = Carbon::parse($request->booking_date)->toDateString();
        $extraUnits = $this->requestExtraUnits($request);
        $videoAddon = $this->resolveVideoAddon($request->input('video_addon_type'));

        DB::transaction(function () use (
            $request,
            $package,
            $client,
            $photographer,
            $bookingDate,
            $extraUnits,
            $videoAddon
        ) {
            $choice = $this->findChoiceByStartTime($package, $bookingDate, $extraUnits, $request->start_time, true);

            if (!$choice) {
                throw ValidationException::withMessages([
                    'start_time' => 'Jadwal ini sudah tidak tersedia. Pilih jadwal lain.'
                ]);
            }

            $readyPhotographers = $this->readyPhotographersForChoice($bookingDate, $choice, true);

            if (!$readyPhotographers->contains('id', $photographer->id)) {
                throw ValidationException::withMessages([
                    'photographer_user_id' => 'Fotografer ini tidak tersedia di jadwal yang dipilih.'
                ]);
            }

            $locationType = $this->normalizedLocationType($package);
            $locationName = $locationType === 'indoor'
                ? 'Indoor Studio Monoframe'
                : trim((string) $request->location_name);

            if ($locationType === 'outdoor' && $locationName === '') {
                throw ValidationException::withMessages([
                    'location_name' => 'Lokasi outdoor wajib diisi.'
                ]);
            }

            $booking = ScheduleBooking::create([
                'package_id' => $package->id,
                'client_user_id' => $client->id,
                'photographer_user_id' => $photographer->id,
                'client_name' => $client->name,
                'client_phone' => $client->phone,
                'photographer_name' => $photographer->name,
                'booking_date' => $bookingDate,
                'start_time' => $choice['start_time'],
                'end_time' => $choice['end_time'],
                'blocked_until' => $choice['blocked_until'],
                'duration_minutes' => (int) $package->duration_minutes,
                'extra_duration_units' => $extraUnits,
                'extra_duration_minutes' => (int) ($choice['extra_duration_minutes'] ?? 0),
                'extra_duration_fee' => (int) ($choice['extra_duration_fee'] ?? 0),
                'video_addon_type' => $videoAddon?->addon_key,
                'video_addon_name' => $videoAddon?->addon_name,
                'video_addon_price' => (int) ($videoAddon?->price ?? 0),
                'location_type' => $locationType,
                'location_name' => $locationName,
                'status' => 'confirmed',
                'source' => 'manual_request',
                'notes' => $request->notes,
            ]);

            $this->persistMoodboards($booking, $request->file('moodboards', []));

            app(BookingTrackingService::class)->initializeForBooking($booking);
        });

        return back()->with('success', 'Booking manual berhasil disimpan.');
    }

    public function editBooking(ScheduleBooking $scheduleBooking)
    {
        $scheduleBooking->load(['package', 'clientUser', 'photographerUser', 'moodboards']);

        $clients = User::where('role', 'Klien')
            ->orderBy('email')
            ->get(['id', 'name', 'email', 'phone']);

        $photographers = $this->activePhotographers()
            ->orderBy('name')
            ->get(['id', 'name', 'email']);

        $packages = Package::where('is_active', true)
            ->orderBy('name')
            ->get();

        $videoAddons = $this->videoAddons();

        $selectedDate = $scheduleBooking->booking_date
            ? Carbon::parse($scheduleBooking->booking_date)->toDateString()
            : now()->toDateString();

        $dayRule = $this->ruleForDate($selectedDate);

        $extraDurationMinutes = (int) ($dayRule?->extra_duration_minutes ?? 30);
        $extraDurationFee = (int) ($dayRule?->extra_duration_fee ?? 150000);

        return view('admin.schedules.edit-booking', compact(
            'scheduleBooking',
            'clients',
            'photographers',
            'packages',
            'videoAddons',
            'extraDurationMinutes',
            'extraDurationFee'
        ));
    }

    public function updateBooking(Request $request, ScheduleBooking $scheduleBooking)
    {
        $validated = $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'client_user_id' => ['required', 'exists:users,id'],
            'client_name' => ['required', 'string', 'max:255'],
            'client_phone' => ['nullable', 'string', 'max:30'],
            'photographer_user_id' => ['required', 'exists:users,id'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
            'video_addon_type' => ['nullable', 'in:iphone,camera'],
            'location_name' => ['nullable', 'string', 'max:255'],
            'status' => ['required', 'in:pending,confirmed,completed,cancelled'],
            'payment_status' => ['nullable', 'in:unpaid,pending,failed,dp_paid,partially_paid,paid,fully_paid'],
            'notes' => ['nullable', 'string'],
        ], [
            'package_id.required' => 'Paket foto wajib dipilih.',
            'booking_date.required' => 'Tanggal booking wajib dipilih.',
            'start_time.required' => 'Jadwal booking wajib dipilih.',
            'client_user_id.required' => 'Klien wajib dipilih.',
            'client_name.required' => 'Nama klien wajib diisi.',
            'photographer_user_id.required' => 'Fotografer wajib dipilih.',
            'status.required' => 'Status booking wajib dipilih.',
        ]);

        $package = Package::findOrFail($validated['package_id']);
        $client = User::findOrFail($validated['client_user_id']);
        $photographer = User::findOrFail($validated['photographer_user_id']);
        $bookingDate = Carbon::parse($validated['booking_date'])->toDateString();
        $this->ensureBookingMinimumHMinusOne($bookingDate, $scheduleBooking->id);
        $extraUnits = max(0, min(10, (int) ($validated['extra_duration_units'] ?? 0)));
        $videoAddon = $this->resolveVideoAddon($request->input('video_addon_type'));

        DB::transaction(function () use (
            $request,
            $validated,
            $scheduleBooking,
            $package,
            $client,
            $photographer,
            $bookingDate,
            $extraUnits,
            $videoAddon
        ) {
            $choice = $this->findChoiceByStartTime(
                $package,
                $bookingDate,
                $extraUnits,
                $request->start_time,
                true,
                $scheduleBooking->id
            );

            if (!$choice) {
                throw ValidationException::withMessages([
                    'start_time' => 'Jadwal ini sudah tidak tersedia. Pilih jadwal lain.'
                ]);
            }

            $readyPhotographers = $this->readyPhotographersForChoice(
                $bookingDate,
                $choice,
                true,
                $scheduleBooking->id
            );

            if (!$readyPhotographers->contains('id', $photographer->id)) {
                throw ValidationException::withMessages([
                    'photographer_user_id' => 'Fotografer ini tidak tersedia di jadwal yang dipilih.'
                ]);
            }

            $locationType = $this->normalizedLocationType($package);
            $locationName = $locationType === 'indoor'
                ? 'Indoor Studio Monoframe'
                : trim((string) $request->location_name);

            if ($locationType === 'outdoor' && $locationName === '') {
                throw ValidationException::withMessages([
                    'location_name' => 'Lokasi outdoor wajib diisi.'
                ]);
            }

            $scheduleBooking->update([
                'package_id' => $package->id,
                'client_user_id' => $client->id,
                'photographer_user_id' => $photographer->id,

                'client_name' => $validated['client_name'],
                'client_phone' => $validated['client_phone'] ?? $client->phone,
                'photographer_name' => $photographer->name,

                'booking_date' => $bookingDate,
                'start_time' => $choice['start_time'],
                'end_time' => $choice['end_time'],
                'blocked_until' => $choice['blocked_until'],
                'duration_minutes' => (int) $package->duration_minutes,

                'extra_duration_units' => $extraUnits,
                'extra_duration_minutes' => (int) ($choice['extra_duration_minutes'] ?? 0),
                'extra_duration_fee' => (int) ($choice['extra_duration_fee'] ?? 0),

                'video_addon_type' => $videoAddon?->addon_key,
                'video_addon_name' => $videoAddon?->addon_name,
                'video_addon_price' => (int) ($videoAddon?->price ?? 0),

                'location_type' => $locationType,
                'location_name' => $locationName,

                'status' => $validated['status'],
                'payment_status' => $validated['payment_status'] ?? $scheduleBooking->payment_status,
                'notes' => $validated['notes'] ?? null,
            ]);

            app(BookingTrackingService::class)->syncTrackingState($scheduleBooking->fresh());
        });

        return redirect()
            ->route('admin.schedules.index', [
                'tab' => 'booking-monitoring',
                'booking_filter' => 'all',
                'booking_search' => $validated['client_name'],
            ])
            ->with('success', 'Data booking berhasil diperbarui.');
    }

    public function destroyBooking(ScheduleBooking $scheduleBooking)
    {
        $clientName = $scheduleBooking->client_name ?: 'Klien';

        DB::transaction(function () use ($scheduleBooking) {
            $scheduleBooking->load([
                'payments',
                'trackings',
                'moodboards',
                'photoLink',
                'editRequest',
                'printOrder',
                'review',
            ]);

            /*
            * Riwayat payment jangan dihapus, supaya data transaksi tetap aman.
            * Migration payments sudah nullable + nullOnDelete, tapi kita null-kan manual
            * agar lebih jelas dan aman.
            */
            $scheduleBooking->payments()->update([
                'schedule_booking_id' => null,
            ]);

            /*
            * Hapus file moodboard dari storage/public.
            * Record moodboard sebenarnya cascadeOnDelete, tapi file fisiknya tetap harus dihapus manual.
            */
            foreach ($scheduleBooking->moodboards as $moodboard) {
                if ($moodboard->file_path && Storage::disk('public')->exists($moodboard->file_path)) {
                    Storage::disk('public')->delete($moodboard->file_path);
                }
            }

            /*
            * Hapus data turunan yang berkaitan langsung dengan booking.
            * Sebagian tabel sudah cascade, tapi delete manual ini membuat proses lebih aman
            * kalau ada migration lama yang belum cascade.
            */
            $scheduleBooking->trackings()->delete();
            $scheduleBooking->moodboards()->delete();
            $scheduleBooking->photoLink()->delete();
            $scheduleBooking->editRequest()->delete();
            $scheduleBooking->printOrder()->delete();
            $scheduleBooking->review()->delete();

            $scheduleBooking->delete();
        });

        return redirect()
            ->route('admin.schedules.index', [
                'tab' => 'booking-monitoring',
                'booking_filter' => 'all',
            ])
            ->with('success', 'Booking atas nama ' . $clientName . ' berhasil dihapus.');
    }

    private function activePhotographers()
    {
        $query = User::where('role', 'Fotografer');

        if (Schema::hasColumn('users', 'is_active')) {
            $query->where('is_active', true);
        }

        return $query;
    }

    private function videoAddons(): Collection
    {
        if (!Schema::hasTable('booking_addon_settings')) {
            return collect();
        }

        return BookingAddonSetting::query()
            ->where('is_active', true)
            ->orderBy('addon_key')
            ->get();
    }

    private function resolveVideoAddon(?string $addonKey): ?BookingAddonSetting
    {
        if (!$addonKey || !Schema::hasTable('booking_addon_settings')) {
            return null;
        }

        return BookingAddonSetting::query()
            ->where('addon_key', $addonKey)
            ->where('is_active', true)
            ->first();
    }

    private function persistMoodboards(ScheduleBooking $booking, array $files = []): void
    {
        if (empty($files) || !method_exists($booking, 'moodboards')) {
            return;
        }

        foreach ($files as $index => $file) {
            $path = $file->store('booking-moodboards', 'public');

            $booking->moodboards()->create([
                'file_path' => $path,
                'file_name' => $file->getClientOriginalName(),
                'file_size' => $file->getSize(),
                'sort_order' => $index + 1,
            ]);
        }
    }

    private function requestExtraUnits(Request $request): int
    {
        if ($request->filled('extra_duration_units')) {
            return max(0, min(10, (int) $request->input('extra_duration_units')));
        }

        return $request->boolean('add_extra_duration') ? 1 : 0;
    }

    private function ensureBookingMinimumHMinusOne(string $bookingDate, ?int $excludeBookingId = null): void
    {
        $selectedDate = Carbon::parse($bookingDate)->startOfDay();
        $minimumDate = now()->addDay()->startOfDay();

        if ($selectedDate->gte($minimumDate)) {
            return;
        }

        /*
        * Untuk edit booking:
        * Kalau booking lama memang sudah berada di tanggal hari ini,
        * admin masih boleh menyimpan perubahan lain tanpa mengganti tanggal.
        */
        if ($excludeBookingId) {
            $existingBooking = ScheduleBooking::find($excludeBookingId);

            if (
                $existingBooking
                && Carbon::parse($existingBooking->booking_date)->toDateString() === $selectedDate->toDateString()
            ) {
                return;
            }
        }

        throw ValidationException::withMessages([
            'booking_date' => 'Booking hanya bisa dibuat minimal H-1. Silakan pilih tanggal mulai besok.',
        ]);
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

    private function usesStudioCapacity(Package $package): bool
    {
        return $this->normalizedLocationType($package) === 'indoor';
    }

    private function indoorBufferMinutes(ScheduleRule $rule): int
    {
        return (int) ($rule->indoor_buffer_minutes ?? 15);
    }

    private function outdoorBufferMinutes(ScheduleRule $rule): int
    {
        return (int) ($rule->outdoor_buffer_minutes ?? 45);
    }

    private function serviceMinutes(Package $package, ScheduleRule $rule, int $extraUnits): int
    {
        $minutes = (int) $package->duration_minutes;

        if ($extraUnits > 0) {
            $minutes += $extraUnits * (int) ($rule->extra_duration_minutes ?? 30);
        }

        return $minutes;
    }

    private function operationalWindowsForLocation(string $bookingDate, ScheduleRule $rule, string $locationType): array
    {
        if (!$rule->is_active) {
            return [];
        }

        if ($locationType === 'indoor') {
            $openTime = $rule->indoor_open_time;
            $closeTime = $rule->indoor_close_time;
        } else {
            $openTime = $rule->outdoor_open_time;
            $closeTime = $rule->outdoor_close_time;
        }

        if (!$openTime || !$closeTime) {
            return [];
        }

        $start = Carbon::parse($bookingDate . ' ' . $openTime);
        $end = Carbon::parse($bookingDate . ' ' . $closeTime);

        if (!$start->lt($end)) {
            return [];
        }

        return [[
            'start' => $start,
            'end' => $end,
        ]];
    }

    private function buildAvailableSlotChoices(
        Package $package,
        string $bookingDate,
        int $extraUnits,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): array {
        $rule = $this->ruleForDate($bookingDate);

        if (!$rule) {
            return [];
        }

        $serviceMinutes = $this->serviceMinutes($package, $rule, $extraUnits);
        if ($serviceMinutes <= 0) {
            return [];
        }

        $locationType = $this->normalizedLocationType($package);
        $usesStudioCapacity = $this->usesStudioCapacity($package);

        $operationalWindows = $this->operationalWindowsForLocation($bookingDate, $rule, $locationType);

        if (empty($operationalWindows)) {
            return [];
        }

        $resourceWindows = $operationalWindows;

        if ($usesStudioCapacity) {
            $indoorCapacity = max(1, (int) ($rule->indoor_capacity ?? 1));
            $resourceWindows = $this->indoorAvailableWindows(
                $bookingDate,
                $operationalWindows,
                $indoorCapacity,
                $lock,
                $excludeBookingId
            );
        }

        $candidates = $this->generateCandidatesFromWindows($resourceWindows, $serviceMinutes);
        $choices = [];

        foreach ($candidates as $candidate) {
            $start = $candidate['start'];
            $end = $candidate['end'];

            $bufferMinutes = $locationType === 'indoor'
                ? $this->indoorBufferMinutes($rule)
                : $this->outdoorBufferMinutes($rule);

            $blockedUntil = $end->copy()->addMinutes($bufferMinutes);
            $remainingCapacity = null;

            if ($usesStudioCapacity) {
                $indoorCapacity = max(1, (int) ($rule->indoor_capacity ?? 1));
                $indoorOverlapCount = $this->indoorOverlapCount(
                    $bookingDate,
                    $start,
                    $blockedUntil,
                    $lock,
                    $excludeBookingId
                );

                if ($indoorOverlapCount >= $indoorCapacity) {
                    continue;
                }

                $remainingCapacity = max(0, $indoorCapacity - $indoorOverlapCount);
            }

            $choice = [
                'start_time' => $start->format('H:i:s'),
                'end_time' => $end->format('H:i:s'),
                'blocked_until' => $blockedUntil->format('H:i:s'),
                'label' => $start->format('H:i') . ' - ' . $end->format('H:i'),
                'remaining_capacity' => $remainingCapacity,
                'extra_duration_units' => $extraUnits,
                'extra_duration_minutes' => $extraUnits * (int) ($rule->extra_duration_minutes ?? 30),
                'extra_duration_fee' => $extraUnits * (int) ($rule->extra_duration_fee ?? 150000),
            ];

            $readyCount = $this->readyPhotographersForChoice(
                $bookingDate,
                $choice,
                $lock,
                $excludeBookingId
            )->count();

            if ($readyCount <= 0) {
                continue;
            }

            $choice['ready_photographers_count'] = $readyCount;
            $choices[] = $choice;
        }

        return $choices;
    }

    private function findChoiceByStartTime(
        Package $package,
        string $bookingDate,
        int $extraUnits,
        string $startTime,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): ?array {
        $normalizedStartTime = strlen($startTime) === 5
            ? $startTime . ':00'
            : $startTime;

        return collect($this->buildAvailableSlotChoices(
            $package,
            $bookingDate,
            $extraUnits,
            $lock,
            $excludeBookingId
        ))->firstWhere('start_time', $normalizedStartTime);
    }

    private function readyPhotographersForChoice(
        string $bookingDate,
        array $choice,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): Collection {
        $start = Carbon::parse($bookingDate . ' ' . $choice['start_time']);
        $blockedUntil = Carbon::parse($bookingDate . ' ' . $choice['blocked_until']);

        return $this->activePhotographers()
            ->orderBy('name')
            ->get(['id', 'name', 'email'])
            ->filter(function ($photographer) use ($bookingDate, $start, $blockedUntil, $lock, $excludeBookingId) {
                return !$this->hasPhotographerConflict(
                    $photographer->id,
                    $bookingDate,
                    $start,
                    $blockedUntil,
                    $lock,
                    $excludeBookingId
                );
            })
            ->values();
    }

    private function photographerBlockedIntervals(
        int $photographerId,
        string $bookingDate,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): array {
        $query = ScheduleBooking::whereDate('booking_date', $bookingDate)
            ->where('photographer_user_id', $photographerId)
            ->whereIn('status', ['pending', 'confirmed', 'completed']);

        if ($excludeBookingId) {
            $query->where('id', '!=', $excludeBookingId);
        }

        if ($lock) {
            $query->lockForUpdate();
        }

        return $query->get()->map(function ($booking) use ($bookingDate) {
            return [
                'start' => Carbon::parse($bookingDate . ' ' . $booking->start_time),
                'end' => Carbon::parse($bookingDate . ' ' . ($booking->blocked_until ?: $booking->end_time)),
            ];
        })->all();
    }

    private function indoorBlockedIntervals(
        string $bookingDate,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): array {
        $query = ScheduleBooking::whereDate('booking_date', $bookingDate)
            ->where('location_type', 'indoor')
            ->whereIn('status', ['pending', 'confirmed', 'completed']);

        if ($excludeBookingId) {
            $query->where('id', '!=', $excludeBookingId);
        }

        if ($lock) {
            $query->lockForUpdate();
        }

        return $query->get()->map(function ($booking) use ($bookingDate) {
            return [
                'start' => Carbon::parse($bookingDate . ' ' . $booking->start_time),
                'end' => Carbon::parse($bookingDate . ' ' . ($booking->blocked_until ?: $booking->end_time)),
            ];
        })->all();
    }

    private function indoorAvailableWindows(
        string $bookingDate,
        array $operationalWindows,
        int $capacity,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): array {
        $intervals = $this->indoorBlockedIntervals($bookingDate, $lock, $excludeBookingId);

        if ($capacity <= 1) {
            return $this->subtractIntervals($operationalWindows, $intervals);
        }

        $free = [];

        foreach ($operationalWindows as $window) {
            $boundaries = [
                $window['start']->timestamp,
                $window['end']->timestamp,
            ];

            foreach ($intervals as $interval) {
                $start = $interval['start']->gt($window['start']) ? $interval['start'] : $window['start'];
                $end = $interval['end']->lt($window['end']) ? $interval['end'] : $window['end'];

                if ($start->lt($end)) {
                    $boundaries[] = $start->timestamp;
                    $boundaries[] = $end->timestamp;
                }
            }

            $boundaries = array_values(array_unique($boundaries));
            sort($boundaries);

            for ($i = 0; $i < count($boundaries) - 1; $i++) {
                $segStart = Carbon::createFromTimestamp($boundaries[$i]);
                $segEnd = Carbon::createFromTimestamp($boundaries[$i + 1]);

                if (!$segStart->lt($segEnd)) {
                    continue;
                }

                $count = 0;

                foreach ($intervals as $interval) {
                    if ($interval['start']->lt($segEnd) && $interval['end']->gt($segStart)) {
                        $count++;
                    }
                }

                if ($count < $capacity) {
                    $free[] = [
                        'start' => $segStart,
                        'end' => $segEnd,
                    ];
                }
            }
        }

        return $this->mergeAdjacentWindows($free);
    }

    private function generateCandidatesFromWindows(array $windows, int $serviceMinutes): array
    {
        $candidates = [];

        foreach ($windows as $window) {
            $cursor = $window['start']->copy();

            while ($cursor->copy()->addMinutes($serviceMinutes)->lte($window['end'])) {
                $candidates[] = [
                    'start' => $cursor->copy(),
                    'end' => $cursor->copy()->addMinutes($serviceMinutes),
                ];

                $cursor->addMinutes($serviceMinutes);
            }
        }

        return $candidates;
    }

    private function subtractIntervals(array $windows, array $intervals): array
    {
        if (empty($intervals)) {
            return $windows;
        }

        usort($intervals, fn ($a, $b) => $a['start']->timestamp <=> $b['start']->timestamp);

        $result = [];

        foreach ($windows as $window) {
            $segments = [[
                'start' => $window['start']->copy(),
                'end' => $window['end']->copy(),
            ]];

            foreach ($intervals as $interval) {
                $nextSegments = [];

                foreach ($segments as $segment) {
                    if ($interval['end']->lte($segment['start']) || $interval['start']->gte($segment['end'])) {
                        $nextSegments[] = $segment;
                        continue;
                    }

                    if ($interval['start']->gt($segment['start'])) {
                        $nextSegments[] = [
                            'start' => $segment['start']->copy(),
                            'end' => $interval['start']->copy(),
                        ];
                    }

                    if ($interval['end']->lt($segment['end'])) {
                        $nextSegments[] = [
                            'start' => $interval['end']->copy(),
                            'end' => $segment['end']->copy(),
                        ];
                    }
                }

                $segments = $nextSegments;

                if (empty($segments)) {
                    break;
                }
            }

            foreach ($segments as $segment) {
                if ($segment['start']->lt($segment['end'])) {
                    $result[] = $segment;
                }
            }
        }

        return $this->mergeAdjacentWindows($result);
    }

    private function mergeAdjacentWindows(array $windows): array
    {
        if (empty($windows)) {
            return [];
        }

        usort($windows, fn ($a, $b) => $a['start']->timestamp <=> $b['start']->timestamp);

        $merged = [];
        $current = array_shift($windows);

        foreach ($windows as $window) {
            if ($window['start']->lte($current['end'])) {
                if ($window['end']->gt($current['end'])) {
                    $current['end'] = $window['end']->copy();
                }
            } elseif ($window['start']->equalTo($current['end'])) {
                $current['end'] = $window['end']->copy();
            } else {
                $merged[] = [
                    'start' => $current['start']->copy(),
                    'end' => $current['end']->copy(),
                ];
                $current = $window;
            }
        }

        $merged[] = [
            'start' => $current['start']->copy(),
            'end' => $current['end']->copy(),
        ];

        return $merged;
    }

    private function hasPhotographerConflict(
        int $photographerId,
        string $bookingDate,
        Carbon $start,
        Carbon $blockedUntil,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): bool {
        foreach ($this->photographerBlockedIntervals($photographerId, $bookingDate, $lock, $excludeBookingId) as $interval) {
            if ($interval['start']->lt($blockedUntil) && $interval['end']->gt($start)) {
                return true;
            }
        }

        return false;
    }

    private function indoorOverlapCount(
        string $bookingDate,
        Carbon $start,
        Carbon $blockedUntil,
        bool $lock = false,
        ?int $excludeBookingId = null
    ): int {
        $count = 0;

        foreach ($this->indoorBlockedIntervals($bookingDate, $lock, $excludeBookingId) as $interval) {
            if ($interval['start']->lt($blockedUntil) && $interval['end']->gt($start)) {
                $count++;
            }
        }

        return $count;
    }

    private function buildTimeRowsFromRule(string $bookingDate, ?ScheduleRule $rule): Collection
    {
        if (!$rule || !$rule->is_active) {
            return collect();
        }

        $times = collect([
            $rule->indoor_open_time,
            $rule->outdoor_open_time,
        ])->filter()->values();

        $closes = collect([
            $rule->indoor_close_time,
            $rule->outdoor_close_time,
        ])->filter()->values();

        if ($times->isEmpty() || $closes->isEmpty()) {
            return collect();
        }

        $grid = 60;

        $start = Carbon::parse($bookingDate . ' ' . $times->sort()->first());
        $end = Carbon::parse($bookingDate . ' ' . $closes->sortDesc()->first());

        $rows = collect();
        $index = 1;

        while ($start->copy()->addMinutes($grid)->lte($end)) {
            $rowEnd = $start->copy()->addMinutes($grid);

            $rows->push((object) [
                'id' => $index++,
                'start_time' => $start->format('H:i:s'),
                'end_time' => $rowEnd->format('H:i:s'),
                'label' => $start->format('H:i') . ' - ' . $rowEnd->format('H:i'),
            ]);

            $start->addMinutes($grid);
        }

        return $rows;
    }

    private function buildIndoorSummaryRows(
        Collection $timeRows,
        Collection $dayBookings,
        ?ScheduleRule $rule,
        string $bookingDate
    ): Collection {
        $capacity = max(1, (int) ($rule?->indoor_capacity ?? 1));

        return $timeRows->map(function ($row) use ($dayBookings, $capacity, $bookingDate, $rule) {
            $slotStart = Carbon::parse($bookingDate . ' ' . $row->start_time);
            $slotEnd = Carbon::parse($bookingDate . ' ' . $row->end_time);

            $indoorOpen = $rule?->indoor_open_time ? Carbon::parse($bookingDate . ' ' . $rule->indoor_open_time) : null;
            $indoorClose = $rule?->indoor_close_time ? Carbon::parse($bookingDate . ' ' . $rule->indoor_close_time) : null;

            $isActive = $indoorOpen && $indoorClose
                ? ($slotStart->gte($indoorOpen) && $slotEnd->lte($indoorClose))
                : false;

            $bookedCount = $dayBookings
                ->where('location_type', 'indoor')
                ->filter(function ($booking) use ($bookingDate, $slotStart, $slotEnd) {
                    $bookingStart = Carbon::parse($bookingDate . ' ' . $booking->start_time);
                    $bookingBlockedEnd = Carbon::parse($bookingDate . ' ' . ($booking->blocked_until ?: $booking->end_time));

                    return $bookingStart < $slotEnd && $bookingBlockedEnd > $slotStart;
                })
                ->count();

            return (object) [
                'id' => $row->id,
                'start_time' => $row->start_time,
                'end_time' => $row->end_time,
                'capacity_total' => $capacity,
                'booked_count' => $bookedCount,
                'is_active' => $isActive,
            ];
        });
    }

    private function buildDailyBoard(
        Collection $timeRows,
        Collection $photographers,
        Collection $dayBookings,
        string $selectedDate
    ): array {
        $board = [];

        foreach ($photographers as $photographer) {
            $photographerBookings = $dayBookings
                ->where('photographer_user_id', $photographer->id)
                ->values();

            foreach ($timeRows as $row) {
                $slotStart = Carbon::parse($selectedDate . ' ' . $row->start_time);
                $slotEnd = Carbon::parse($selectedDate . ' ' . $row->end_time);

                $cell = [
                    'type' => 'available',
                    'title' => 'Kosong',
                    'subtitle' => 'Bisa dibooking',
                ];

                $activeBooking = $photographerBookings->first(function ($booking) use ($selectedDate, $slotStart, $slotEnd) {
                    $bookingStart = Carbon::parse($selectedDate . ' ' . $booking->start_time);
                    $bookingEnd = Carbon::parse($selectedDate . ' ' . $booking->end_time);

                    return $bookingStart < $slotEnd && $bookingEnd > $slotStart;
                });

                if ($activeBooking) {
                    $cell = [
                        'type' => 'booking',
                        'title' => $activeBooking->client_name,
                        'subtitle' => ($activeBooking->package->name ?? 'Paket') . ' | ' .
                            Carbon::parse($selectedDate . ' ' . $activeBooking->start_time)->format('H:i') . ' - ' .
                            Carbon::parse($selectedDate . ' ' . $activeBooking->end_time)->format('H:i'),
                    ];
                } else {
                    $bufferBooking = $photographerBookings->first(function ($booking) use ($selectedDate, $slotStart) {
                        $serviceEnd = Carbon::parse($selectedDate . ' ' . $booking->end_time);
                        $blockedEnd = Carbon::parse($selectedDate . ' ' . ($booking->blocked_until ?: $booking->end_time));

                        return $serviceEnd <= $slotStart && $blockedEnd > $slotStart;
                    });

                    if ($bufferBooking) {
                        $cell = [
                            'type' => 'buffer',
                            'title' => 'Buffer',
                            'subtitle' => 'Jeda setelah booking sebelumnya',
                        ];
                    }
                }

                $board[$photographer->id][$row->id] = $cell;
            }
        }

        return $board;
    }

    private function seedDefaultRules(): void
    {
        if (ScheduleRule::count() > 0) {
            return;
        }

        $days = [
            ['day_of_week' => 0, 'day_name' => 'Minggu', 'is_active' => false],
            ['day_of_week' => 1, 'day_name' => 'Senin', 'is_active' => true],
            ['day_of_week' => 2, 'day_name' => 'Selasa', 'is_active' => true],
            ['day_of_week' => 3, 'day_name' => 'Rabu', 'is_active' => true],
            ['day_of_week' => 4, 'day_name' => 'Kamis', 'is_active' => true],
            ['day_of_week' => 5, 'day_name' => 'Jumat', 'is_active' => true],
            ['day_of_week' => 6, 'day_name' => 'Sabtu', 'is_active' => true],
        ];

        foreach ($days as $day) {
            ScheduleRule::create([
                'day_of_week' => $day['day_of_week'],
                'day_name' => $day['day_name'],
                'is_active' => $day['is_active'],
                'indoor_open_time' => '06:00',
                'indoor_close_time' => '21:00',
                'outdoor_open_time' => '06:00',
                'outdoor_close_time' => '21:00',
                'indoor_capacity' => 1,
                'indoor_buffer_minutes' => 15,
                'outdoor_buffer_minutes' => 45,
                'extra_duration_minutes' => 30,
                'extra_duration_fee' => 150000,
            ]);
        }
    }
}
