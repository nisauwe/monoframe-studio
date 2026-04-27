<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Http\Requests\FrontOffice\StoreExpenseRequest;
use App\Models\Expense;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
  public function summary(Request $request)
  {
    $request->validate([
      'start_date' => ['nullable', 'date'],
      'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
    ]);

    $startDate = $request->start_date
      ? Carbon::parse($request->start_date)->startOfDay()
      : now()->startOfMonth()->startOfDay();

    $endDate = $request->end_date
      ? Carbon::parse($request->end_date)->endOfDay()
      : now()->endOfMonth()->endOfDay();

    $incomeQuery = Payment::query()
      ->whereIn('transaction_status', ['settlement', 'capture'])
      ->whereBetween(DB::raw('COALESCE(settled_at, paid_at, created_at)'), [$startDate, $endDate]);

    $expenseQuery = Expense::query()
      ->whereBetween('expense_date', [$startDate->toDateString(), $endDate->toDateString()]);

    $income = (float) $incomeQuery->sum('gross_amount');
    $expenses = (float) $expenseQuery->sum('amount');
    $balance = $income - $expenses;

    $recentPayments = Payment::with(['scheduleBooking.package', 'scheduleBooking.clientUser'])
      ->whereIn('transaction_status', ['settlement', 'capture'])
      ->latest()
      ->take(10)
      ->get();

    $recentExpenses = Expense::with('createdBy')
      ->latest('expense_date')
      ->take(10)
      ->get();

    return response()->json([
      'message' => 'Ringkasan keuangan front office berhasil diambil',
      'filters' => [
        'start_date' => $startDate->toDateString(),
        'end_date' => $endDate->toDateString(),
      ],
      'summary' => [
        'income' => $income,
        'expenses' => $expenses,
        'balance' => $balance,
      ],
      'recent_payments' => $recentPayments,
      'recent_expenses' => $recentExpenses,
    ]);
  }

  public function expenses()
  {
    $expenses = Expense::with('createdBy')
      ->latest('expense_date')
      ->paginate(15);

    return response()->json([
      'message' => 'Daftar pengeluaran berhasil diambil',
      'data' => $expenses,
    ]);
  }

  public function storeExpense(StoreExpenseRequest $request)
  {
    $expense = Expense::create([
      'expense_date' => $request->expense_date,
      'category' => $request->category,
      'amount' => $request->amount,
      'description' => $request->description,
      'created_by_user_id' => $request->user()->id,
    ]);

    return response()->json([
      'message' => 'Pengeluaran berhasil disimpan',
      'data' => $expense->load('createdBy'),
    ], 201);
  }
}
