<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\BookingAddonSetting;
use App\Models\Package;
use App\Models\ScheduleBooking;
use App\Models\BookingCancelLog;
use App\Services\BookingTrackingService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    public function index(Request $request, BookingTrackingService $trackingService)
    {
        $bookings = ScheduleBooking::with([
                'package',
                'latestPayment',
                'payments',
                'moodboards',
                'photographerUser',
                'photoLink',
                'editRequest',
                'printOrder',
                'review',
                'trackings',
            ])
            ->where('client_user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'message' => 'Daftar booking berhasil diambil',
            'data' => $bookings->map(function ($booking) use ($trackingService) {
                $trackingService->syncTrackingState($booking);

                $booking->refresh();

                $booking->load([
                    'package',
                    'latestPayment',
                    'payments',
                    'moodboards',
                    'photographerUser',
                    'photoLink',
                    'editRequest',
                    'printOrder',
                    'review',
                    'trackings',
                ]);

                $latestPayment = $booking->latestPayment;

                $timeline = $booking->trackings
                    ->sortBy('stage_order')
                    ->values();

                $currentStage = $timeline->firstWhere('status', 'current');

                if (!$currentStage) {
                    $currentStage = $timeline->lastWhere('status', 'done');
                }

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

                    'duration_minutes' => $booking->duration_minutes,
                    'extra_duration_units' => $booking->extra_duration_units ?? 0,
                    'extra_duration_minutes' => $booking->extra_duration_minutes ?? 0,
                    'extra_duration_fee' => $booking->extra_duration_fee ?? 0,

                    'video_addon_type' => $booking->video_addon_type,
                    'video_addon_name' => $booking->video_addon_name,
                    'video_addon_price' => $booking->video_addon_price ?? 0,

                    'location_type' => $booking->location_type,
                    'location_name' => $booking->location_name,

                    'status' => $booking->status,
                    'payment_status' => $booking->payment_status ?? 'unpaid',

                    'latest_payment_status' => $latestPayment?->transaction_status,
                    'latest_payment_stage' => $latestPayment?->payment_stage,
                    'latest_payment_order_id' => $latestPayment?->order_id,

                    'source' => $booking->source,
                    'notes' => $booking->notes,

                    'package' => $booking->package,
                    'latest_payment' => $latestPayment,
                    'moodboards' => $booking->moodboards,

                    'total_booking_amount' => $booking->total_booking_amount,
                    'paid_booking_amount' => $booking->paid_booking_amount,
                    'minimum_dp_amount' => $booking->minimum_dp_amount,
                    'remaining_booking_amount' => $booking->remaining_booking_amount,
                    'is_dp_paid' => $booking->isDpPaid(),
                    'is_fully_paid' => $booking->isFullyPaid(),

                    'has_photo_link' => (bool) $booking->photoLink,
                    'edit_request_status' => $booking->editRequest?->status,
                    'print_order_status' => $booking->printOrder?->status,
                    'has_review' => (bool) $booking->review,

                    'current_stage' => $currentStage ? [
                        'stage_key' => $currentStage->stage_key,
                        'stage_name' => $currentStage->stage_name,
                        'status' => $currentStage->status,
                        'description' => $currentStage->description,
                    ] : [
                        'stage_key' => 'assign_photographer',
                        'stage_name' => 'Assign Fotografer',
                        'status' => 'current',
                        'description' => 'Booking menunggu proses Front Office',
                    ],

                    'timeline' => $timeline,
                ];
            })->values(),
        ]);
    }

    public function show(Request $request, ScheduleBooking $booking)
    {
        if ($booking->client_user_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak'
            ], 403);
        }

        return response()->json([
            'message' => 'Detail booking berhasil diambil',
            'data' => $booking->load(['package', 'payments', 'photographerUser', 'moodboards'])
        ]);
    }

    public function store(Request $request)
    {
        $setting = AppSetting::current();

        if (!$setting->booking_is_active) {
            return response()->json([
                'message' => $setting->booking_closed_message ?: 'Booking sementara dinonaktifkan oleh admin.',
            ], 403);
        }

        $maxMoodboards = max(0, (int) $setting->max_moodboard_upload);
        $maxExtraUnits = max(0, (int) $setting->max_extra_duration_units);

        $validated = $request->validate([
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:' . $maxExtraUnits],
            'location_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'video_addon_type' => ['nullable', 'in:iphone,camera'],
            'moodboards' => ['nullable', 'array', 'max:' . $maxMoodboards],
            'moodboards.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ]);

        $user = $request->user();
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
                'start_time' => 'Jadwal ini sudah tidak tersedia. Pilih jadwal lain.'
            ]);
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
            'client_user_id' => $user->id,
            'photographer_user_id' => null,
            'client_name' => $user->name,
            'client_phone' => $user->phone,
            'photographer_name' => null,
            'booking_date' => Carbon::parse($validated['booking_date'])->toDateString(),
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
            'status' => 'pending',
            'source' => 'client',
            'notes' => $validated['notes'] ?? null,
        ]);

        $this->persistMoodboards($booking, $request->file('moodboards', []));

        app(\App\Services\BookingTrackingService::class)->initializeForBooking($booking);

        return response()->json([
          'message' => 'Booking berhasil dibuat',
          'data' => [
              'booking' => $booking->load([
                  'package',
                  'moodboards',
                  'photographerUser',
                  'payments',
              ]),
              'summary' => [
                  'package_name' => $booking->package->name ?? '-',
                  'client_name' => $booking->client_name,
                  'client_phone' => $booking->client_phone,
                  'location_type' => $booking->location_type,
                  'location_name' => $booking->location_name,
                  'booking_date' => $booking->booking_date,
                  'start_time' => $booking->start_time,
                  'end_time' => $booking->end_time,
                  'video_addon_name' => $booking->video_addon_name,
                  'video_addon_price' => (int) $booking->video_addon_price,
                  'extra_duration_minutes' => (int) $booking->extra_duration_minutes,
                  'extra_duration_fee' => (int) $booking->extra_duration_fee,
                  'total_booking_amount' => (int) $booking->total_booking_amount,
                  'minimum_dp_amount' => (int) $booking->minimum_dp_amount,
              ],
              'next_action' => 'payment',
          ]
      ], 201);
    }

    public function destroy(Request $request, ScheduleBooking $booking)
    {
        if ($booking->client_user_id !== $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak'
            ], 403);
        }

        $booking->load(['package', 'payments', 'moodboards', 'trackings']);

        if ($booking->isDpPaid() || $booking->isFullyPaid()) {
            return response()->json([
                'message' => 'Booking tidak bisa dicancel karena pembayaran DP atau lunas sudah masuk.',
            ], 422);
        }

        $hasSuccessfulPayment = $booking->payments()
            ->whereIn('transaction_status', ['settlement', 'capture'])
            ->exists();

        if ($hasSuccessfulPayment) {
            return response()->json([
                'message' => 'Booking tidak bisa dicancel karena pembayaran sudah berhasil.',
            ], 422);
        }

        $reason = trim((string) $request->input('reason', ''));

        DB::transaction(function () use ($booking, $request, $reason) {
            BookingCancelLog::create([
                'client_user_id' => $booking->client_user_id,
                'schedule_booking_id' => $booking->id,
                'package_id' => $booking->package_id,
                'package_name' => $booking->package?->name,
                'client_name' => $booking->client_name,
                'client_phone' => $booking->client_phone,
                'booking_date' => $booking->booking_date,
                'start_time' => $booking->start_time,
                'end_time' => $booking->end_time,
                'location_type' => $booking->location_type,
                'location_name' => $booking->location_name,
                'duration_minutes' => (int) $booking->duration_minutes,
                'extra_duration_minutes' => (int) $booking->extra_duration_minutes,
                'extra_duration_fee' => (int) $booking->extra_duration_fee,
                'video_addon_name' => $booking->video_addon_name,
                'video_addon_price' => (int) $booking->video_addon_price,
                'total_booking_amount' => (int) $booking->total_booking_amount,
                'notes' => $booking->notes,
                'cancel_reason' => $reason !== '' ? $reason : null,
                'snapshot' => [
                    'booking' => $booking->toArray(),
                    'package' => $booking->package?->toArray(),
                    'payments' => $booking->payments->toArray(),
                    'moodboards' => $booking->moodboards->toArray(),
                    'trackings' => $booking->trackings->toArray(),
                    'cancelled_by' => [
                        'id' => $request->user()->id,
                        'name' => $request->user()->name,
                        'email' => $request->user()->email,
                        'role' => $request->user()->role,
                    ],
                ],
                'cancelled_at' => now(),
            ]);

            $booking->payments()
                ->whereNotIn('transaction_status', ['settlement', 'capture'])
                ->delete();

            $booking->delete();
        });

        return response()->json([
            'message' => 'Booking berhasil dicancel dan dihapus dari riwayat klien.',
        ]);
    }

    private function resolveChoiceFromScheduleEngine(
        int $packageId,
        string $bookingDate,
        string $startTime,
        int $extraUnits
    ): ?array {
        $request = Request::create('/api/schedules', 'GET', [
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
