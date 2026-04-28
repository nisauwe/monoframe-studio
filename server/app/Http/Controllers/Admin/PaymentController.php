<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Income;
use App\Models\Payment;
use App\Models\ScheduleBooking;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    private array $successStatuses = ['settlement', 'capture'];
    private array $pendingStatuses = ['created', 'pending', 'authorize'];
    private array $failedStatuses = ['deny', 'expire', 'cancel', 'failure', 'failed'];

    public function index(Request $request)
    {
        $dateFrom = $request->filled('date_from')
            ? Carbon::parse($request->date_from)->startOfDay()
            : now()->startOfMonth()->startOfDay();

        $dateTo = $request->filled('date_to')
            ? Carbon::parse($request->date_to)->endOfDay()
            : now()->endOfMonth()->endOfDay();

        $paymentsQuery = Payment::with([
            'scheduleBooking.package',
            'scheduleBooking.clientUser',
            'printOrder.client',
            'gateway',
        ])->latest();

        $paymentsQuery->whereBetween('created_at', [$dateFrom, $dateTo]);

        if ($request->filled('search')) {
            $search = $request->search;

            $paymentsQuery->where(function (Builder $query) use ($search) {
                $query->where('order_id', 'like', "%{$search}%")
                    ->orWhere('payment_type', 'like', "%{$search}%")
                    ->orWhere('provider', 'like', "%{$search}%")
                    ->orWhereHas('scheduleBooking', function (Builder $bookingQuery) use ($search) {
                        $bookingQuery->where('client_name', 'like', "%{$search}%")
                            ->orWhere('client_phone', 'like', "%{$search}%")
                            ->orWhereHas('clientUser', function (Builder $userQuery) use ($search) {
                                $userQuery->where('name', 'like', "%{$search}%")
                                    ->orWhere('email', 'like', "%{$search}%")
                                    ->orWhere('phone', 'like', "%{$search}%");
                            })
                            ->orWhereHas('package', function (Builder $packageQuery) use ($search) {
                                $packageQuery->where('name', 'like', "%{$search}%");
                            });
                    })
                    ->orWhereHas('printOrder', function (Builder $printQuery) use ($search) {
                        $printQuery->where('recipient_name', 'like', "%{$search}%")
                            ->orWhere('recipient_phone', 'like', "%{$search}%")
                            ->orWhereHas('client', function (Builder $clientQuery) use ($search) {
                                $clientQuery->where('name', 'like', "%{$search}%")
                                    ->orWhere('email', 'like', "%{$search}%");
                            });
                    });
            });
        }

        if ($request->filled('status')) {
            $paymentsQuery->where('transaction_status', $request->status);
        }

        if ($request->filled('payment_type')) {
            match ($request->payment_type) {
                'booking' => $paymentsQuery->where(function (Builder $query) {
                    $query->where('payment_context', 'booking')
                        ->orWhere(function (Builder $subQuery) {
                            $subQuery->whereNull('payment_context')
                                ->whereNull('print_order_id');
                        });
                }),
                'dp' => $paymentsQuery->where('payment_stage', 'dp'),
                'full' => $paymentsQuery->where('payment_stage', 'full'),
                'print' => $paymentsQuery->where(function (Builder $query) {
                    $query->where('payment_context', 'print')
                        ->orWhere('payment_context', 'print_order')
                        ->orWhereNotNull('print_order_id');
                }),
                default => null,
            };
        }

        $payments = $paymentsQuery
            ->paginate(10, ['*'], 'payments_page')
            ->withQueryString();

        $paidPaymentsPeriodQuery = $this->paidPaymentsPeriodQuery($dateFrom, $dateTo);

        $bookingPaymentIncome = $this->sumPaymentBaseAmount(
            (clone $paidPaymentsPeriodQuery)->where(function (Builder $query) {
                $query->where('payment_context', 'booking')
                    ->orWhere(function (Builder $subQuery) {
                        $subQuery->whereNull('payment_context')
                            ->whereNull('print_order_id');
                    });
            })
        );

        $printPaymentIncome = $this->sumPaymentBaseAmount(
            (clone $paidPaymentsPeriodQuery)->where(function (Builder $query) {
                $query->where('payment_context', 'print')
                    ->orWhere('payment_context', 'print_order')
                    ->orWhereNotNull('print_order_id');
            })
        );

        $totalPaymentIncome = $this->sumPaymentBaseAmount(clone $paidPaymentsPeriodQuery);

        $manualIncome = (float) Income::query()
            ->whereBetween('income_date', [$dateFrom->toDateString(), $dateTo->toDateString()])
            ->sum('amount');

        $totalExpense = (float) Expense::query()
            ->whereBetween('expense_date', [$dateFrom->toDateString(), $dateTo->toDateString()])
            ->sum('amount');

        $totalIncome = $totalPaymentIncome + $manualIncome;
        $netBalance = $totalIncome - $totalExpense;

        $totalPayments = Payment::count();

        $pendingPayments = Payment::whereIn('transaction_status', $this->pendingStatuses)->count();
        $paidPayments = Payment::whereIn('transaction_status', $this->successStatuses)->count();
        $failedPayments = Payment::whereIn('transaction_status', $this->failedStatuses)->count();

        $bookingMonitor = ScheduleBooking::with([
                'package',
                'clientUser',
                'latestPayment',
                'successfulBookingPayments',
            ])
            ->whereNotIn('status', ['cancelled'])
            ->whereNotNull('booking_date')
            ->orderByDesc('booking_date')
            ->orderByDesc('start_time')
            ->get();

        $unpaidBookings = $bookingMonitor
            ->filter(fn (ScheduleBooking $booking) => !$booking->isDpPaid())
            ->values();

        $dpPaidBookings = $bookingMonitor
            ->filter(fn (ScheduleBooking $booking) => $booking->isDpPaid() && !$booking->isFullyPaid())
            ->values();

        $fullyPaidBookings = $bookingMonitor
            ->filter(fn (ScheduleBooking $booking) => $booking->isFullyPaid())
            ->values();

        $printPaidCount = Payment::query()
            ->where(function (Builder $query) {
                $query->where('payment_context', 'print')
                    ->orWhere('payment_context', 'print_order')
                    ->orWhereNotNull('print_order_id');
            })
            ->whereIn('transaction_status', $this->successStatuses)
            ->count();

        $recentIncomes = Income::with('createdBy')
            ->whereBetween('income_date', [$dateFrom->toDateString(), $dateTo->toDateString()])
            ->latest('income_date')
            ->latest()
            ->take(8)
            ->get();

        $recentExpenses = Expense::with('createdBy')
            ->whereBetween('expense_date', [$dateFrom->toDateString(), $dateTo->toDateString()])
            ->latest('expense_date')
            ->latest()
            ->take(8)
            ->get();

        return view('admin.payments.index', compact(
            'payments',
            'dateFrom',
            'dateTo',
            'totalPayments',
            'pendingPayments',
            'paidPayments',
            'failedPayments',
            'bookingPaymentIncome',
            'printPaymentIncome',
            'totalPaymentIncome',
            'manualIncome',
            'totalExpense',
            'totalIncome',
            'netBalance',
            'unpaidBookings',
            'dpPaidBookings',
            'fullyPaidBookings',
            'printPaidCount',
            'recentIncomes',
            'recentExpenses'
        ));
    }

    public function storeIncome(Request $request)
    {
        $validated = $request->validate([
            'income_date' => ['required', 'date'],
            'category' => ['nullable', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:1'],
            'description' => ['nullable', 'string'],
        ]);

        Income::create([
            'income_date' => $validated['income_date'],
            'category' => $validated['category'] ?? 'Pemasukan Manual',
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
            'created_by_user_id' => auth()->id(),
        ]);

        return back()->with('success', 'Pemasukan berhasil ditambahkan.');
    }

    public function storeExpense(Request $request)
    {
        $validated = $request->validate([
            'expense_date' => ['required', 'date'],
            'category' => ['nullable', 'string', 'max:255'],
            'amount' => ['required', 'numeric', 'min:1'],
            'description' => ['nullable', 'string'],
        ]);

        Expense::create([
            'expense_date' => $validated['expense_date'],
            'category' => $validated['category'] ?? 'Pengeluaran Studio',
            'amount' => $validated['amount'],
            'description' => $validated['description'] ?? null,
            'created_by_user_id' => auth()->id(),
        ]);

        return back()->with('success', 'Pengeluaran berhasil ditambahkan.');
    }

    public function destroyIncome(Income $income)
    {
        $income->delete();

        return back()->with('success', 'Pemasukan berhasil dihapus.');
    }

    public function destroyExpense(Expense $expense)
    {
        $expense->delete();

        return back()->with('success', 'Pengeluaran berhasil dihapus.');
    }

    public function show(Payment $payment)
    {
        $payment->load([
            'scheduleBooking.package',
            'scheduleBooking.clientUser',
            'scheduleBooking.photographerUser',
            'printOrder.client',
            'gateway',
        ]);

        return view('admin.payments.show', compact('payment'));
    }

    private function paidPaymentsPeriodQuery(Carbon $dateFrom, Carbon $dateTo)
    {
        return Payment::query()
            ->whereIn('transaction_status', $this->successStatuses)
            ->whereBetween(DB::raw('COALESCE(settled_at, paid_at, created_at)'), [$dateFrom, $dateTo]);
    }

    private function sumPaymentBaseAmount(Builder $query): float
    {
        return (float) $query
            ->selectRaw('COALESCE(SUM(COALESCE(base_amount, gross_amount, 0)), 0) as total')
            ->value('total');
    }
}