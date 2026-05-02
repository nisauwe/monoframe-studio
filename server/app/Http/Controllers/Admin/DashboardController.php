<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\EditRequest;
use App\Models\Payment;
use App\Models\PhotoLink;
use App\Models\PrintOrder;
use App\Models\Review;
use App\Models\ScheduleBooking;
use App\Models\BookingCancelLog;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    private array $paidBookingStatuses = [
        'dp_paid',
        'partially_paid',
        'paid',
        'fully_paid',
    ];

    private array $successfulPaymentStatuses = [
        'settlement',
        'capture',
    ];

    public function index()
    {
        $today = Carbon::today();

        $baseBookingQuery = ScheduleBooking::query()
            ->whereNotIn('status', ['completed', 'cancelled']);

        $bookingAktif = (clone $baseBookingQuery)
            ->where(function (Builder $query) {
                $this->applyPaidBookingFilter($query);
            })
            ->count();

        $belumBayar = (clone $baseBookingQuery)
            ->where(function (Builder $query) {
                if ($this->hasBookingPaymentColumns()) {
                    $query->whereNull('payment_status')
                        ->orWhereIn('payment_status', ['unpaid', 'pending', 'failed']);
                } else {
                    $query->whereDoesntHave('payments', function (Builder $paymentQuery) {
                        $paymentQuery
                            ->whereNull('print_order_id')
                            ->whereIn('transaction_status', $this->successfulPaymentStatuses);
                    });
                }
            })
            ->whereDoesntHave('payments', function (Builder $paymentQuery) {
                $paymentQuery
                    ->whereNull('print_order_id')
                    ->whereIn('transaction_status', $this->successfulPaymentStatuses);
            })
            ->count();

        $jadwalHariIni = ScheduleBooking::query()
            ->whereDate('booking_date', $today)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->where(function (Builder $query) {
                $this->applyPaidBookingFilter($query);
            })
            ->count();

        $reviewCount = Review::query()->count();

        $pemasukanHariIni = (int) Payment::query()
            ->whereIn('transaction_status', $this->successfulPaymentStatuses)
            ->where(function (Builder $query) use ($today) {
                $query->whereDate('paid_at', $today)
                    ->orWhereDate('settled_at', $today);
            })
            ->sum('base_amount');

        $totalPemasukan = (int) Payment::query()
            ->whereIn('transaction_status', $this->successfulPaymentStatuses)
            ->sum('base_amount');

        $pengeluaranHariIni = $this->resolveExpenseForDate($today);
        $totalPengeluaran = $this->resolveTotalExpense();
        $saldoKeseluruhan = $totalPemasukan - $totalPengeluaran;

        $activityNotifications = $this->buildUserActivityNotifications(250);
        $activityNotificationsPreview = $activityNotifications->take(5)->values();

        return view('admin.dashboard', compact(
            'bookingAktif',
            'belumBayar',
            'jadwalHariIni',
            'reviewCount',
            'pemasukanHariIni',
            'pengeluaranHariIni',
            'saldoKeseluruhan',
            'activityNotifications',
            'activityNotificationsPreview'
        ));
    }

    private function applyPaidBookingFilter(Builder $query): void
    {
        $query->where(function (Builder $subQuery) {
            if ($this->hasBookingPaymentColumns()) {
                $subQuery->whereIn('payment_status', $this->paidBookingStatuses);
            }

            $subQuery->orWhereHas('payments', function (Builder $paymentQuery) {
                $paymentQuery
                    ->whereNull('print_order_id')
                    ->whereIn('transaction_status', $this->successfulPaymentStatuses);
            });
        });
    }

    private function buildUserActivityNotifications(int $limit = 250): Collection
    {
        $activities = collect();

        $activities = $activities
            ->merge($this->bookingActivities())
            ->merge($this->bookingCancelActivities())
            ->merge($this->photographerAssignmentActivities())
            ->merge($this->paymentActivities())
            ->merge($this->failedPaymentActivities())
            ->merge($this->photoLinkActivities())
            ->merge($this->editRequestActivities())
            ->merge($this->printOrderActivities())
            ->merge($this->reviewActivities());

        return $activities
            ->filter(fn ($activity) => !empty($activity['occurred_at']))
            ->sortByDesc(function ($activity) {
                return $activity['occurred_at'] instanceof Carbon
                    ? $activity['occurred_at']->timestamp
                    : Carbon::parse($activity['occurred_at'])->timestamp;
            })
            ->take($limit)
            ->values();
    }

    private function bookingActivities(): Collection
    {
        if (!Schema::hasTable('schedule_bookings')) {
            return collect();
        }

        return ScheduleBooking::with(['package', 'clientUser'])
            ->latest('created_at')
            ->limit(120)
            ->get()
            ->map(function (ScheduleBooking $booking) {
                $clientName = $booking->clientUser?->name
                    ?? $booking->client_name
                    ?? 'Klien';

                $role = ($booking->source ?? null) === 'manual_request'
                    ? 'Front Office'
                    : 'Klien';

                $actorName = ($booking->source ?? null) === 'manual_request'
                    ? 'Front Office'
                    : $clientName;

                $activity = ($booking->source ?? null) === 'manual_request'
                    ? 'membuat booking manual untuk klien ' . $clientName . ' ' . $this->bookingScheduleSentence($booking)
                    : 'melakukan booking ' . $this->bookingScheduleSentence($booking);

                return $this->activityRow(
                    name: $actorName,
                    role: $role,
                    activity: $activity,
                    occurredAt: $booking->created_at,
                    type: 'booking'
                );
            });
    }

    private function bookingCancelActivities(): Collection
    {
        if (!Schema::hasTable('booking_cancel_logs')) {
            return collect();
        }

        return BookingCancelLog::with(['clientUser'])
            ->latest('cancelled_at')
            ->latest('created_at')
            ->limit(160)
            ->get()
            ->map(function (BookingCancelLog $cancelLog) {
                $clientName = $cancelLog->clientUser?->name
                    ?? $cancelLog->client_name
                    ?? data_get($cancelLog->snapshot, 'cancelled_by.name')
                    ?? 'Klien';

                $reason = trim((string) ($cancelLog->cancel_reason ?? ''));

                $activity = 'membatalkan booking ' . $this->bookingCancelScheduleSentence($cancelLog);

                if ($reason !== '') {
                    $activity .= '. Alasan: ' . $reason;
                }

                return $this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: $activity,
                    occurredAt: $cancelLog->cancelled_at ?? $cancelLog->created_at,
                    type: 'booking_cancel'
                );
            });
    }

    private function photographerAssignmentActivities(): Collection
    {
        if (!Schema::hasTable('schedule_bookings')) {
            return collect();
        }

        return ScheduleBooking::with(['package', 'clientUser', 'photographerUser'])
            ->whereNotNull('photographer_user_id')
            ->latest('updated_at')
            ->limit(120)
            ->get()
            ->map(function (ScheduleBooking $booking) {
                $clientName = $booking->clientUser?->name
                    ?? $booking->client_name
                    ?? 'klien';

                $photographerName = $booking->photographerUser?->name
                    ?? $booking->photographer_name
                    ?? 'fotografer';

                return $this->activityRow(
                    name: 'Front Office',
                    role: 'Front Office',
                    activity: 'meng-assign fotografer ' . $photographerName . ' untuk booking klien ' . $clientName . ' ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $booking->updated_at,
                    type: 'assignment'
                );
            });
    }

    private function paymentActivities(): Collection
    {
        if (!Schema::hasTable('payments')) {
            return collect();
        }

        return Payment::with([
                'scheduleBooking.package',
                'scheduleBooking.clientUser',
                'printOrder.client',
            ])
            ->whereIn('transaction_status', $this->successfulPaymentStatuses)
            ->latest('updated_at')
            ->limit(160)
            ->get()
            ->map(function (Payment $payment) {
                $booking = $payment->scheduleBooking;
                $client = $booking?->clientUser ?? $payment->printOrder?->client;

                $clientName = $client?->name
                    ?? $booking?->client_name
                    ?? 'Klien';

                $amount = (int) ($payment->base_amount ?: $payment->gross_amount);

                if ($payment->print_order_id) {
                    $activity = 'membayar tagihan cetak foto sebesar Rp ' . number_format($amount, 0, ',', '.');
                } elseif ($payment->payment_stage === 'dp') {
                    $activity = 'membayar DP untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                } elseif (in_array($payment->payment_stage, ['full', 'pelunasan', 'remaining'], true)) {
                    $activity = 'membayar pelunasan untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                } else {
                    $activity = 'melakukan pembayaran untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                }

                return $this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: $activity,
                    occurredAt: $payment->paid_at ?? $payment->settled_at ?? $payment->updated_at ?? $payment->created_at,
                    type: 'payment'
                );
            });
    }

    private function failedPaymentActivities(): Collection
    {
        if (!Schema::hasTable('payments')) {
            return collect();
        }

        $failedStatuses = [
            'expire',
            'expired',
            'cancel',
            'cancelled',
            'deny',
            'failure',
            'failed',
        ];

        return Payment::with([
                'scheduleBooking.package',
                'scheduleBooking.clientUser',
                'printOrder.client',
            ])
            ->whereIn('transaction_status', $failedStatuses)
            ->latest('updated_at')
            ->limit(120)
            ->get()
            ->map(function (Payment $payment) {
                $booking = $payment->scheduleBooking;
                $client = $booking?->clientUser ?? $payment->printOrder?->client;

                $clientName = $client?->name
                    ?? $booking?->client_name
                    ?? 'Klien';

                $amount = (int) ($payment->base_amount ?: $payment->gross_amount);

                $statusLabel = match ($payment->transaction_status) {
                    'expire', 'expired' => 'kedaluwarsa',
                    'cancel', 'cancelled' => 'dibatalkan',
                    'deny' => 'ditolak',
                    'failure', 'failed' => 'gagal',
                    default => 'tidak berhasil',
                };

                if ($payment->print_order_id) {
                    $activity = 'pembayaran cetak foto ' . $statusLabel . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                } elseif ($payment->payment_stage === 'dp') {
                    $activity = 'pembayaran DP ' . $statusLabel . ' untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                } elseif (in_array($payment->payment_stage, ['full', 'pelunasan', 'remaining'], true)) {
                    $activity = 'pembayaran pelunasan ' . $statusLabel . ' untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                } else {
                    $activity = 'pembayaran ' . $statusLabel . ' untuk ' . $this->bookingScheduleSentence($booking) . ' sebesar Rp ' . number_format($amount, 0, ',', '.');
                }

                return $this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: $activity,
                    occurredAt: $payment->updated_at ?? $payment->created_at,
                    type: 'payment_failed'
                );
            });
    }

    private function photoLinkActivities(): Collection
    {
        if (!Schema::hasTable('photo_links')) {
            return collect();
        }

        return PhotoLink::with(['booking.package', 'booking.clientUser', 'photographer'])
            ->latest('uploaded_at')
            ->latest('created_at')
            ->limit(120)
            ->get()
            ->map(function (PhotoLink $photoLink) {
                $booking = $photoLink->booking;

                $photographerName = $photoLink->photographer?->name
                    ?? $booking?->photographer_name
                    ?? 'Fotografer';

                $clientName = $booking?->clientUser?->name
                    ?? $booking?->client_name
                    ?? 'klien';

                return $this->activityRow(
                    name: $photographerName,
                    role: 'Fotografer',
                    activity: 'mengirim link hasil foto untuk klien ' . $clientName . ' ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $photoLink->uploaded_at ?? $photoLink->created_at,
                    type: 'photo_link'
                );
            });
    }

    private function editRequestActivities(): Collection
    {
        if (!Schema::hasTable('edit_requests')) {
            return collect();
        }

        $editRequests = EditRequest::with([
                'booking.package',
                'booking.clientUser',
                'client',
                'editor',
            ])
            ->latest('updated_at')
            ->limit(160)
            ->get();

        $activities = collect();

        foreach ($editRequests as $editRequest) {
            $booking = $editRequest->booking;

            $clientName = $editRequest->client?->name
                ?? $booking?->clientUser?->name
                ?? $booking?->client_name
                ?? 'Klien';

            $files = is_array($editRequest->selected_files)
                ? $editRequest->selected_files
                : [];

            $fileCount = count($files);

            if ($editRequest->created_at) {
                $activities->push($this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: 'mengupload list foto edit untuk ' . $this->bookingScheduleSentence($booking) . ($fileCount > 0 ? ' sebanyak ' . $fileCount . ' file' : ''),
                    occurredAt: $editRequest->created_at,
                    type: 'edit_request'
                ));
            }

            if ($editRequest->assigned_at && $editRequest->editor) {
                $activities->push($this->activityRow(
                    name: 'Front Office',
                    role: 'Front Office',
                    activity: 'meng-assign editor ' . $editRequest->editor->name . ' untuk permintaan edit klien ' . $clientName . ' ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $editRequest->assigned_at,
                    type: 'assignment'
                ));
            }

            if ($editRequest->completed_at) {
                $editorName = $editRequest->editor?->name ?? 'Editor';

                $activities->push($this->activityRow(
                    name: $editorName,
                    role: 'Editor',
                    activity: 'menyelesaikan edit foto untuk klien ' . $clientName . ' ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $editRequest->completed_at,
                    type: 'edit_completed'
                ));
            }
        }

        return $activities;
    }

    private function printOrderActivities(): Collection
    {
        if (!Schema::hasTable('print_orders')) {
            return collect();
        }

        $printOrders = PrintOrder::with([
                'booking.package',
                'booking.clientUser',
                'client',
            ])
            ->latest('updated_at')
            ->limit(120)
            ->get();

        $activities = collect();

        foreach ($printOrders as $printOrder) {
            $booking = $printOrder->booking;

            $clientName = $printOrder->client?->name
                ?? $booking?->clientUser?->name
                ?? $booking?->client_name
                ?? 'Klien';

            if ($printOrder->created_at) {
                $activities->push($this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: 'mengajukan pesanan cetak foto untuk ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $printOrder->created_at,
                    type: 'print_order'
                ));
            }

            if ($printOrder->processed_at) {
                $activities->push($this->activityRow(
                    name: 'Front Office',
                    role: 'Front Office',
                    activity: 'memproses pesanan cetak foto milik klien ' . $clientName . ' untuk ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $printOrder->processed_at,
                    type: 'print_process'
                ));
            }

            if ($printOrder->completed_at) {
                $activities->push($this->activityRow(
                    name: 'Front Office',
                    role: 'Front Office',
                    activity: 'menyelesaikan pesanan cetak foto milik klien ' . $clientName . ' untuk ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $printOrder->completed_at,
                    type: 'print_completed'
                ));
            }
        }

        return $activities;
    }

    private function reviewActivities(): Collection
    {
        if (!Schema::hasTable('reviews')) {
            return collect();
        }

        return Review::with([
                'booking.package',
                'booking.clientUser',
                'client',
            ])
            ->latest('created_at')
            ->limit(120)
            ->get()
            ->map(function (Review $review) {
                $booking = $review->booking;

                $clientName = $review->client?->name
                    ?? $booking?->clientUser?->name
                    ?? $booking?->client_name
                    ?? 'Klien';

                return $this->activityRow(
                    name: $clientName,
                    role: 'Klien',
                    activity: 'memberikan review rating ' . (int) $review->rating . '/5 untuk ' . $this->bookingScheduleSentence($booking),
                    occurredAt: $review->created_at,
                    type: 'review'
                );
            });
    }

    private function activityRow(
        string $name,
        string $role,
        string $activity,
        mixed $occurredAt,
        string $type = 'default'
    ): array {
        return [
            'name' => $name ?: '-',
            'role' => $role ?: '-',
            'activity' => $activity ?: '-',
            'occurred_at' => $occurredAt ? Carbon::parse($occurredAt) : null,
            'type' => $type,
        ];
    }

    private function bookingScheduleSentence(?ScheduleBooking $booking): string
    {
        if (!$booking) {
            return 'pada data booking yang tidak ditemukan';
        }

        $packageName = $booking->package?->name ?? 'paket foto';

        $date = $booking->booking_date
            ? Carbon::parse($booking->booking_date)->translatedFormat('d F Y')
            : '-';

        $start = $booking->start_time
            ? Carbon::parse($booking->start_time)->format('H:i')
            : null;

        $end = $booking->end_time
            ? Carbon::parse($booking->end_time)->format('H:i')
            : null;

        if ($start && $end) {
            $time = $start . ' - ' . $end;
        } elseif ($start) {
            $time = $start;
        } else {
            $time = '-';
        }

        return 'untuk paket ' . $packageName . ' pada tanggal ' . $date . ' jam ' . $time;
    }

    private function bookingCancelScheduleSentence(BookingCancelLog $cancelLog): string
    {
        $packageName = $cancelLog->package_name ?: 'paket foto';

        try {
            $date = $cancelLog->booking_date
                ? Carbon::parse($cancelLog->booking_date)->translatedFormat('d F Y')
                : '-';
        } catch (\Throwable $exception) {
            $date = $cancelLog->booking_date ?: '-';
        }

        try {
            $start = $cancelLog->start_time
                ? Carbon::parse($cancelLog->start_time)->format('H:i')
                : null;
        } catch (\Throwable $exception) {
            $start = $cancelLog->start_time ?: null;
        }

        try {
            $end = $cancelLog->end_time
                ? Carbon::parse($cancelLog->end_time)->format('H:i')
                : null;
        } catch (\Throwable $exception) {
            $end = $cancelLog->end_time ?: null;
        }

        if ($start && $end) {
            $time = $start . ' - ' . $end;
        } elseif ($start) {
            $time = $start;
        } else {
            $time = '-';
        }

        return 'untuk paket ' . $packageName . ' pada tanggal ' . $date . ' jam ' . $time;
    }

    private function hasBookingPaymentColumns(): bool
    {
        return Schema::hasTable('schedule_bookings')
            && Schema::hasColumn('schedule_bookings', 'payment_status');
    }

    private function resolveExpenseForDate(Carbon $date): int
    {
        if (!Schema::hasTable('expenses')) {
            return 0;
        }

        $amountColumn = $this->resolveExpenseAmountColumn();

        if (!$amountColumn) {
            return 0;
        }

        foreach (['expense_date', 'spent_at', 'created_at'] as $dateColumn) {
            if (Schema::hasColumn('expenses', $dateColumn)) {
                return (int) DB::table('expenses')
                    ->whereDate($dateColumn, $date)
                    ->sum($amountColumn);
            }
        }

        return 0;
    }

    private function resolveTotalExpense(): int
    {
        if (!Schema::hasTable('expenses')) {
            return 0;
        }

        $amountColumn = $this->resolveExpenseAmountColumn();

        if (!$amountColumn) {
            return 0;
        }

        return (int) DB::table('expenses')->sum($amountColumn);
    }

    private function resolveExpenseAmountColumn(): ?string
    {
        foreach (['amount', 'nominal', 'total'] as $column) {
            if (Schema::hasColumn('expenses', $column)) {
                return $column;
            }
        }

        return null;
    }
}
