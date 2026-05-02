<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\StoreManualBookingRequest;
use App\Models\BookingAddonSetting;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\User;
use App\Services\BookingTrackingService;
use App\Services\PhotographerAvailabilityService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ManualBookingController extends Controller
{
    public function packages()
    {
        $packages = Package::with(['category', 'discounts'])
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        return response()->json([
            'message' => 'Daftar paket berhasil diambil',
            'data' => $packages,
        ]);
    }

    public function packageShow(Package $package)
    {
        if (!$package->is_active) {
            return response()->json([
                'message' => 'Paket tidak tersedia',
            ], 404);
        }

        return response()->json([
            'message' => 'Detail paket berhasil diambil',
            'data' => $package->load(['category', 'discounts']),
        ]);
    }

    public function availableSlots(Request $request)
    {
        $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date', 'after:today'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
        ], [
            'booking_date.after' => 'Jadwal hanya bisa dipilih minimal H-1. Silakan pilih tanggal mulai besok.',
        ]);

        $adminScheduleController = app(\App\Http\Controllers\Admin\ScheduleController::class);

        return $adminScheduleController->availableSlots($request);
    }

    public function availablePhotographers(
        Request $request,
        PhotographerAvailabilityService $availabilityService
    ) {
        $validated = $request->validate([
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'end_time' => ['required'],
        ]);

        $bookingDate = Carbon::parse($validated['booking_date'])->toDateString();

        $photographers = $availabilityService->getAvailablePhotographers(
            $bookingDate,
            $this->normalizeTime($validated['start_time'], true),
            $this->normalizeTime($validated['end_time'], true),
            null
        );

        return response()->json([
            'message' => 'Daftar fotografer tersedia berhasil diambil',
            'data' => $photographers->values(),
        ]);
    }

    public function addonSettings()
    {
        $settings = BookingAddonSetting::query()
            ->where('is_active', true)
            ->orderBy('addon_key')
            ->get();

        return response()->json([
            'message' => 'Daftar add-on video berhasil diambil',
            'data' => $settings,
        ]);
    }

    public function store(
        StoreManualBookingRequest $request,
        PhotographerAvailabilityService $availabilityService,
        BookingTrackingService $trackingService
    ) {
        $validated = $request->validated();

        $package = Package::where('is_active', true)->findOrFail($validated['package_id']);
        $extraUnits = (int) $request->integer('extra_duration_units', 0);

        $choice = $this->resolveChoiceFromScheduleEngine(
            $package->id,
            $validated['booking_date'],
            $validated['start_time'],
            $extraUnits
        );

        if (!$choice) {
            throw ValidationException::withMessages([
                'start_time' => 'Slot yang dipilih sudah tidak tersedia.',
            ]);
        }

        $bookingDate = Carbon::parse($validated['booking_date'])->toDateString();
        $startTime = $this->normalizeTime($choice['start_time'] ?? $validated['start_time'], true);
        $endTime = $this->normalizeTime(
            $choice['blocked_until'] ?? $choice['end_time'] ?? $validated['start_time'],
            true
        );

        $photographer = User::query()
            ->where('id', $validated['photographer_user_id'])
            ->where('role', 'Fotografer')
            ->where('is_active', true)
            ->first();

        if (!$photographer) {
            throw ValidationException::withMessages([
                'photographer_user_id' => 'Fotografer tidak ditemukan atau tidak aktif.',
            ]);
        }

        $isAvailable = $availabilityService->isPhotographerAvailable(
            $photographer->id,
            $bookingDate,
            $startTime,
            $endTime,
            null
        );

        if (!$isAvailable) {
            throw ValidationException::withMessages([
                'photographer_user_id' => 'Fotografer ini tidak tersedia pada slot yang dipilih.',
            ]);
        }

        $clientUser = null;

        if (!empty($validated['client_email'])) {
            $clientUser = User::query()
                ->where('email', $validated['client_email'])
                ->where('role', 'Klien')
                ->first();
        }

        $locationType = $this->normalizedLocationType($package);

        $locationName = $locationType === 'indoor'
            ? 'Indoor Studio Monoframe'
            : trim((string) ($validated['location_name'] ?? ''));

        if ($locationType === 'outdoor' && $locationName === '') {
            throw ValidationException::withMessages([
                'location_name' => 'Lokasi outdoor wajib diisi.',
            ]);
        }

        $videoAddon = null;

        if ($request->filled('video_addon_type')) {
            $videoAddon = BookingAddonSetting::query()
                ->where('addon_key', $request->video_addon_type)
                ->where('is_active', true)
                ->first();
        }

        $booking = ScheduleBooking::create([
            'package_id' => $package->id,
            'client_user_id' => $clientUser?->id,
            'photographer_user_id' => $photographer->id,

            'client_name' => $validated['client_name'],
            'client_phone' => $validated['client_phone'],
            'photographer_name' => $photographer->name,

            'booking_date' => $bookingDate,
            'start_time' => $choice['start_time'],
            'end_time' => $choice['end_time'],
            'blocked_until' => $choice['blocked_until'] ?? null,

            'duration_minutes' => (int) $package->duration_minutes,
            'extra_duration_units' => $extraUnits,
            'extra_duration_minutes' => (int) ($choice['extra_duration_minutes'] ?? 0),
            'extra_duration_fee' => (int) ($choice['extra_duration_fee'] ?? 0),

            'video_addon_type' => $videoAddon?->addon_key,
            'video_addon_name' => $videoAddon?->addon_name,
            'video_addon_price' => (int) ($videoAddon?->price ?? 0),

            'location_type' => $locationType,
            'location_name' => $locationName,

            'status' => 'pending',
            'source' => 'manual_request',
            'notes' => $validated['notes'] ?? null,
        ]);

        $this->persistMoodboards($booking, $request->file('moodboards', []));

        $trackingService->initializeForBooking($booking);
        $trackingService->syncTrackingState($booking);

        return response()->json([
            'message' => 'Booking manual berhasil dibuat dan fotografer berhasil ditentukan',
            'data' => $booking->load([
                'package',
                'photographerUser',
                'trackings',
                'moodboards',
            ]),
        ], 201);
    }

    private function resolveChoiceFromScheduleEngine(
        int $packageId,
        string $bookingDate,
        string $startTime,
        int $extraUnits
    ): ?array {
        $request = Request::create('/api/front-office/available-slots', 'GET', [
            'package_id' => $packageId,
            'booking_date' => $bookingDate,
            'extra_duration_units' => $extraUnits,
        ]);

        $response = app(\App\Http\Controllers\Admin\ScheduleController::class)->availableSlots($request);
        $choices = $response->getData(true);

        foreach ($choices as $choice) {
            if (($choice['start_time'] ?? null) === $startTime) {
                return $choice;
            }
        }

        return null;
    }

    private function normalizedLocationType(Package $package): string
    {
        return $package->location_type === 'outdoor' ? 'outdoor' : 'indoor';
    }

    private function persistMoodboards(ScheduleBooking $booking, array $files = []): void
    {
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
