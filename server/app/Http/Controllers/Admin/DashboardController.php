<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Review;
use App\Models\ScheduleBooking;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
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

    private array $unpaidBookingStatuses = [
        'unpaid',
        'pending',
        'failed',
        null,
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

        /*
        |--------------------------------------------------------------------------
        | Booking Aktif
        |--------------------------------------------------------------------------
        | Booking aktif = booking yang sudah membayar DP atau sudah lunas.
        | Jadi yang dihitung:
        | - schedule_bookings.payment_status = dp_paid / partially_paid / paid / fully_paid
        | ATAU
        | - punya payment settlement/capture di tabel payments
        */
        $bookingAktif = (clone $baseBookingQuery)
            ->where(function (Builder $query) {
                $this->applyPaidBookingFilter($query);
            })
            ->count();

        /*
        |--------------------------------------------------------------------------
        | Belum Bayar
        |--------------------------------------------------------------------------
        | Belum bayar = booking aktif yang belum punya pembayaran sukses.
        | Jadi kalau sudah DP/lunas, tidak boleh masuk Belum Bayar.
        */
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

        /*
        |--------------------------------------------------------------------------
        | Jadwal Hari Ini
        |--------------------------------------------------------------------------
        | Jadwal hari ini hanya dihitung kalau booking sudah aktif
        | yaitu sudah DP atau sudah lunas.
        */
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

        $aktivitasBooking = ScheduleBooking::with([
                'package',
                'latestPayment',
                'payments',
                'trackings',
                'review',
            ])
            ->latest('booking_date')
            ->latest('start_time')
            ->limit(10)
            ->get()
            ->map(function ($booking) {
                $activity = $this->resolveActivityStatus($booking);

                $booking->dashboard_status_label = $activity['label'];
                $booking->dashboard_status_badge = $activity['badge'];
                $booking->dashboard_date_label = $booking->booking_date
                    ? Carbon::parse($booking->booking_date)->translatedFormat('d M Y')
                    : '-';

                return $booking;
            });

        return view('admin.dashboard', compact(
            'bookingAktif',
            'belumBayar',
            'jadwalHariIni',
            'reviewCount',
            'pemasukanHariIni',
            'pengeluaranHariIni',
            'saldoKeseluruhan',
            'aktivitasBooking'
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

    private function resolveActivityStatus(ScheduleBooking $booking): array
    {
        $paymentStatus = strtolower((string) $booking->payment_status);

        if ($this->hasBookingPaymentColumns()) {
            if ($paymentStatus === 'failed') {
                return [
                    'label' => 'Pembayaran Gagal',
                    'badge' => 'danger',
                ];
            }

            if (in_array($paymentStatus, ['unpaid', 'pending', ''], true)) {
                return [
                    'label' => 'Belum Bayar DP',
                    'badge' => 'warning',
                ];
            }

            if (in_array($paymentStatus, ['dp_paid', 'partially_paid'], true)) {
                return [
                    'label' => 'Booking Aktif (DP)',
                    'badge' => 'info',
                ];
            }

            if (in_array($paymentStatus, ['paid', 'fully_paid'], true)) {
                return [
                    'label' => 'Booking Aktif (Lunas)',
                    'badge' => 'success',
                ];
            }
        }

        $latestPayment = $booking->latestPayment;

        if ($latestPayment && in_array($latestPayment->transaction_status, $this->successfulPaymentStatuses, true)) {
            if ($latestPayment->payment_stage === 'dp') {
                return [
                    'label' => 'Booking Aktif (DP)',
                    'badge' => 'info',
                ];
            }

            if ($latestPayment->payment_stage === 'full') {
                return [
                    'label' => 'Booking Aktif (Lunas)',
                    'badge' => 'success',
                ];
            }

            return [
                'label' => 'Pembayaran Berhasil',
                'badge' => 'success',
            ];
        }

        $currentTracking = $booking->trackings->firstWhere('status', 'current');

        if ($currentTracking) {
            return match ($currentTracking->stage_key) {
                'dp_payment' => ['label' => 'Menunggu DP', 'badge' => 'warning'],
                'photographer_assignment' => ['label' => 'Menunggu Assign Fotografer', 'badge' => 'info'],
                'full_payment' => ['label' => 'Menunggu Pelunasan', 'badge' => 'warning'],
                'shooting' => ['label' => 'Jadwal Pemotretan', 'badge' => 'info'],
                'photo_upload' => ['label' => 'Upload Foto', 'badge' => 'primary'],
                'edit_upload' => ['label' => 'Edit Proses', 'badge' => 'primary'],
                'print' => ['label' => 'Proses Cetak', 'badge' => 'info'],
                'review' => ['label' => 'Menunggu Review', 'badge' => 'success'],
                default => ['label' => $currentTracking->stage_name, 'badge' => 'secondary'],
            };
        }

        if ($booking->status === 'completed') {
            return [
                'label' => 'Selesai',
                'badge' => 'success',
            ];
        }

        if ($booking->status === 'cancelled') {
            return [
                'label' => 'Dibatalkan',
                'badge' => 'danger',
            ];
        }

        return [
            'label' => ucfirst($booking->status ?? 'Booking'),
            'badge' => 'secondary',
        ];
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
