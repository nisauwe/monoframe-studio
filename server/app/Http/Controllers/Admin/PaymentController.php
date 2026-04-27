<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
  public function index(Request $request)
  {
    $query = Payment::with([
      'scheduleBooking.package',
      'scheduleBooking.clientUser',
      'gateway',
    ])->latest();

    if ($request->filled('search')) {
      $search = $request->search;

      $query->where(function ($q) use ($search) {
        $q->where('order_id', 'like', "%{$search}%")
          ->orWhere('payment_type', 'like', "%{$search}%")
          ->orWhereHas('scheduleBooking', function ($bookingQuery) use ($search) {
            $bookingQuery->where('client_name', 'like', "%{$search}%")
              ->orWhereHas('clientUser', function ($userQuery) use ($search) {
                $userQuery->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
              });
          });
      });
    }

    if ($request->filled('status') && $request->status !== 'Semua Status') {
      $query->where('transaction_status', $request->status);
    }

    $payments = $query->paginate(10)->withQueryString();

    $totalPayments = Payment::count();
    $pendingPayments = Payment::whereIn('transaction_status', ['created', 'pending'])->count();
    $paidPayments = Payment::whereIn('transaction_status', ['settlement', 'capture'])->count();
    $failedPayments = Payment::whereIn('transaction_status', ['deny', 'expire', 'cancel', 'failure'])->count();

    return view('admin.payments.index', compact(
      'payments',
      'totalPayments',
      'pendingPayments',
      'paidPayments',
      'failedPayments'
    ));
  }

  public function show(Payment $payment)
  {
    $payment->load([
      'scheduleBooking.package',
      'scheduleBooking.clientUser',
      'scheduleBooking.photographerUser',
      'gateway',
    ]);

    return view('admin.payments.show', compact('payment'));
  }
}
