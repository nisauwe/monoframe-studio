<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\StoreExpenseRequest;
use App\Http\Requests\FrontOffice\StoreIncomeRequest;
use App\Models\Expense;
use App\Models\Income;
use App\Models\Payment;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
  private array $successStatuses = ['settlement', 'capture'];

  public function summary(Request $request)
  {
    $request->validate([
      'start_date' => ['nullable', 'date'],
      'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
    ]);

    [$startDate, $endDate] = $this->resolvePeriod($request);

    $paidPaymentsPeriodQuery = $this->paidPaymentsPeriodQuery($startDate, $endDate);

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

    $paymentIncome = $this->sumPaymentBaseAmount(clone $paidPaymentsPeriodQuery);

    $manualIncome = (float) Income::query()
      ->whereBetween('income_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->sum('amount');

    $totalExpense = (float) Expense::query()
      ->whereBetween('expense_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->sum('amount');

    $totalIncome = $paymentIncome + $manualIncome;
    $netBalance = $totalIncome - $totalExpense;

    $recentPayments = Payment::with([
        'scheduleBooking.package',
        'scheduleBooking.clientUser',
        'printOrder.client',
      ])
      ->whereIn('transaction_status', $this->successStatuses)
      ->whereBetween(DB::raw('COALESCE(settled_at, paid_at, created_at)'), [$startDate, $endDate])
      ->latest()
      ->take(10)
      ->get();

    $recentIncomes = Income::with('createdBy')
      ->whereBetween('income_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->latest('income_date')
      ->latest()
      ->take(10)
      ->get();

    $recentExpenses = Expense::with('createdBy')
      ->whereBetween('expense_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->latest('expense_date')
      ->latest()
      ->take(10)
      ->get();

    return response()->json([
      'message' => 'Ringkasan keuangan front office berhasil diambil',
      'filters' => [
        'start_date' => $startDate->toDateString(),
        'end_date' => $endDate->toDateString(),
      ],
      'summary' => [
        'booking_payment_income' => $bookingPaymentIncome,
        'print_payment_income' => $printPaymentIncome,
        'payment_income' => $paymentIncome,
        'manual_income' => $manualIncome,
        'total_income' => $totalIncome,

        // Backward compatibility untuk model Flutter lama.
        'income' => $totalIncome,

        'total_expense' => $totalExpense,
        'expenses' => $totalExpense,

        'net_balance' => $netBalance,
        'balance' => $netBalance,
      ],
      'recent_payments' => $recentPayments,
      'recent_incomes' => $recentIncomes,
      'recent_expenses' => $recentExpenses,
    ]);
  }

  public function incomes(Request $request)
  {
    $request->validate([
      'start_date' => ['nullable', 'date'],
      'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
    ]);

    [$startDate, $endDate] = $this->resolvePeriod($request);

    $incomes = Income::with('createdBy')
      ->whereBetween('income_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->latest('income_date')
      ->latest()
      ->paginate(15);

    return response()->json([
      'message' => 'Daftar pemasukan berhasil diambil',
      'filters' => [
        'start_date' => $startDate->toDateString(),
        'end_date' => $endDate->toDateString(),
      ],
      'data' => $incomes,
    ]);
  }

  public function storeIncome(StoreIncomeRequest $request)
  {
    $income = Income::create([
      'income_date' => $request->income_date,
      'category' => $request->category ?: 'Pemasukan Manual',
      'amount' => $request->amount,
      'description' => $request->description,
      'created_by_user_id' => $request->user()->id,
    ]);

    return response()->json([
      'message' => 'Pemasukan berhasil disimpan',
      'data' => $income->load('createdBy'),
    ], 201);
  }

  public function expenses(Request $request)
  {
    $request->validate([
      'start_date' => ['nullable', 'date'],
      'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
    ]);

    [$startDate, $endDate] = $this->resolvePeriod($request);

    $expenses = Expense::with('createdBy')
      ->whereBetween('expense_date', [$startDate->toDateString(), $endDate->toDateString()])
      ->latest('expense_date')
      ->latest()
      ->paginate(15);

    return response()->json([
      'message' => 'Daftar pengeluaran berhasil diambil',
      'filters' => [
        'start_date' => $startDate->toDateString(),
        'end_date' => $endDate->toDateString(),
      ],
      'data' => $expenses,
    ]);
  }

  public function storeExpense(StoreExpenseRequest $request)
  {
    $expense = Expense::create([
      'expense_date' => $request->expense_date,
      'category' => $request->category ?: 'Pengeluaran Studio',
      'amount' => $request->amount,
      'description' => $request->description,
      'created_by_user_id' => $request->user()->id,
    ]);

    return response()->json([
      'message' => 'Pengeluaran berhasil disimpan',
      'data' => $expense->load('createdBy'),
    ], 201);
  }

  private function resolvePeriod(Request $request): array
  {
    $startDate = $request->start_date
      ? Carbon::parse($request->start_date)->startOfDay()
      : now()->startOfMonth()->startOfDay();

    $endDate = $request->end_date
      ? Carbon::parse($request->end_date)->endOfDay()
      : now()->endOfMonth()->endOfDay();

    return [$startDate, $endDate];
  }

  private function paidPaymentsPeriodQuery(Carbon $startDate, Carbon $endDate): Builder
  {
    return Payment::query()
      ->whereIn('transaction_status', $this->successStatuses)
      ->whereBetween(DB::raw('COALESCE(settled_at, paid_at, created_at)'), [$startDate, $endDate]);
  }

  private function sumPaymentBaseAmount(Builder $query): float
  {
    return (float) $query
      ->selectRaw('COALESCE(SUM(COALESCE(base_amount, gross_amount, 0)), 0) as total')
      ->value('total');
  }
}
