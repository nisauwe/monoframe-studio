<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\StoreManualBookingRequest;
use App\Models\BookingAddonSetting;
use App\Models\BookingMoodboard;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
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
                'message' => 'Paket tidak tersedia'
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
            'booking_date' => ['required', 'date'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],
        ]);

        $adminScheduleController = app(\App\Http\Controllers\Admin\ScheduleController::class);

        return $adminScheduleController->availableSlots($request);
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

    public function store(StoreManualBookingRequest $request)
    {
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
                'start_time' => 'Slot yang dipilih sudah tidak tersedia.'
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
                'location_name' => 'Lokasi outdoor wajib diisi.'
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
            'photographer_user_id' => null,

            'client_name' => $validated['client_name'],
            'client_phone' => $validated['client_phone'],
            'photographer_name' => null,

            'booking_date' => Carbon::parse($validated['booking_date'])->toDateString(),
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

        app(\App\Services\BookingTrackingService::class)->initializeForBooking($booking);

        return response()->json([
            'message' => 'Booking manual berhasil dibuat',
            'data' => $booking->load(['package', 'trackings', 'moodboards']),
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
}
