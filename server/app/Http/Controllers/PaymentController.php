<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Models\ScheduleBooking;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;
use Midtrans\Transaction;

class PaymentController extends Controller
{
  public function createSnap(ScheduleBooking $scheduleBooking)
  {
    if (!$scheduleBooking->client_user_id || Auth::id() !== (int) $scheduleBooking->client_user_id) {
      return response()->json([
        'message' => 'Anda tidak berhak membayar booking ini.',
      ], 403);
    }

    $gateway = PaymentGateway::where('provider', 'midtrans')
      ->where('is_active', true)
      ->first();

    if (!$gateway) {
      return response()->json([
        'message' => 'Payment gateway Midtrans belum aktif.',
      ], 422);
    }

    if (!$gateway->server_key || !$gateway->client_key) {
      return response()->json([
        'message' => 'Client Key atau Server Key Midtrans belum diisi.',
      ], 422);
    }

    $existingPaid = Payment::where('schedule_booking_id', $scheduleBooking->id)
      ->whereIn('transaction_status', ['settlement', 'capture'])
      ->latest()
      ->first();

    if ($existingPaid) {
      return response()->json([
        'message' => 'Booking ini sudah dibayar.',
      ], 422);
    }

    $existingPending = Payment::where('schedule_booking_id', $scheduleBooking->id)
      ->whereIn('transaction_status', ['created', 'pending'])
      ->latest()
      ->first();

    if ($existingPending && $existingPending->snap_token) {
      return response()->json([
        'message' => 'Snap token lama masih aktif.',
        'token' => $existingPending->snap_token,
        'redirect_url' => $existingPending->snap_redirect_url,
        'client_key' => $gateway->client_key,
        'snap_js_url' => $this->snapJsUrl($gateway->environment),
        'order_id' => $existingPending->order_id,
      ]);
    }

    $baseAmount = $this->resolveBookingAmount($scheduleBooking);
    $adminFee = (int) $gateway->admin_fee;
    $grossAmount = $baseAmount + $adminFee;

    if ($grossAmount <= 0) {
      return response()->json([
        'message' => 'Nominal pembayaran tidak valid.',
      ], 422);
    }

    $orderId = 'BOOK-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(6));

    Config::$serverKey = $gateway->server_key;
    Config::$clientKey = $gateway->client_key;
    Config::$isProduction = $gateway->environment === 'production';
    Config::$isSanitized = true;
    Config::$is3ds = true;

    $package = $scheduleBooking->package;
    $client = $scheduleBooking->clientUser;

    $itemDetails = [
      [
        'id' => 'BOOKING-' . $scheduleBooking->id,
        'price' => $baseAmount,
        'quantity' => 1,
        'name' => $package?->name ?? 'Booking Foto Monoframe',
      ],
    ];

    if ($adminFee > 0) {
      $itemDetails[] = [
        'id' => 'ADMIN-FEE',
        'price' => $adminFee,
        'quantity' => 1,
        'name' => 'Biaya Admin',
      ];
    }

    $params = [
      'transaction_details' => [
        'order_id' => $orderId,
        'gross_amount' => $grossAmount,
      ],
      'item_details' => $itemDetails,
      'customer_details' => [
        'first_name' => $client?->name ?? $scheduleBooking->client_name ?? 'Klien',
        'email' => $client?->email ?? 'customer@example.com',
        'phone' => $client?->phone ?? $scheduleBooking->client_phone ?? '',
      ],
      'enabled_payments' => $gateway->resolvedEnabledPaymentTypes(),
      'expiry' => [
        'unit' => 'minute',
        'duration' => (int) $gateway->expiry_minutes,
      ],
    ];

    try {
      $transaction = Snap::createTransaction($params);

      $payment = Payment::create([
        'schedule_booking_id' => $scheduleBooking->id,
        'payment_gateway_id' => $gateway->id,
        'provider' => 'midtrans',
        'order_id' => $orderId,
        'base_amount' => $baseAmount,
        'admin_fee' => $adminFee,
        'gross_amount' => $grossAmount,
        'snap_token' => $transaction->token,
        'snap_redirect_url' => $transaction->redirect_url,
        'transaction_status' => 'pending',
        'initiated_at' => now(),
        'expired_at' => now()->addMinutes((int) $gateway->expiry_minutes),
        'payload' => [
          'request' => $params,
          'response' => [
            'token' => $transaction->token,
            'redirect_url' => $transaction->redirect_url,
          ],
        ],
      ]);

      $scheduleBooking->update([
        'payment_status' => 'pending',
        'payment_order_id' => $orderId,
        'payment_due_at' => $payment->expired_at,
      ]);

      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Create Snap Transaction',
        'status' => 'success',
        'message' => 'Snap token berhasil dibuat untuk order ' . $orderId,
        'payload' => [
          'schedule_booking_id' => $scheduleBooking->id,
          'order_id' => $orderId,
          'gross_amount' => $grossAmount,
        ],
      ]);

      return response()->json([
        'message' => 'Snap token berhasil dibuat.',
        'token' => $payment->snap_token,
        'redirect_url' => $payment->snap_redirect_url,
        'client_key' => $gateway->client_key,
        'snap_js_url' => $this->snapJsUrl($gateway->environment),
        'order_id' => $payment->order_id,
      ]);
    } catch (\Throwable $e) {
      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Create Snap Transaction',
        'status' => 'failed',
        'message' => $e->getMessage(),
        'payload' => [
          'schedule_booking_id' => $scheduleBooking->id,
        ],
      ]);

      return response()->json([
        'message' => 'Gagal membuat transaksi Snap: ' . $e->getMessage(),
      ], 500);
    }
  }

  public function notification(Request $request)
  {
    $gateway = PaymentGateway::where('provider', 'midtrans')->first();

    if (!$gateway || !$gateway->server_key) {
      return response()->json(['message' => 'Gateway tidak tersedia.'], 422);
    }

    $payload = $request->all();

    $orderId = $payload['order_id'] ?? null;
    $statusCode = $payload['status_code'] ?? null;
    $grossAmount = $payload['gross_amount'] ?? null;
    $signatureKey = $payload['signature_key'] ?? null;

    if (!$orderId || !$statusCode || !$grossAmount || !$signatureKey) {
      return response()->json(['message' => 'Payload notifikasi tidak lengkap.'], 422);
    }

    $localSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $gateway->server_key);

    if ($localSignature !== $signatureKey) {
      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Webhook Callback',
        'status' => 'failed',
        'message' => 'Signature key Midtrans tidak valid.',
        'payload' => $payload,
      ]);

      return response()->json(['message' => 'Signature tidak valid.'], 403);
    }

    $payment = Payment::where('order_id', $orderId)->first();

    if (!$payment) {
      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Webhook Callback',
        'status' => 'failed',
        'message' => 'Payment tidak ditemukan untuk order ' . $orderId,
        'payload' => $payload,
      ]);

      return response()->json(['message' => 'Payment tidak ditemukan.'], 404);
    }

    $payment->update($this->mapNotificationToPaymentData($payload));

    if ($payment->payment_context === 'print_order') {
      $this->syncPrintOrderPaymentStatus($payment);
    } else {
      app(\App\Services\BookingPaymentStatusSyncService::class)->sync($payment);
    }

    PaymentGatewayLog::create([
      'payment_gateway_id' => $gateway->id,
      'activity' => 'Webhook Callback',
      'status' => 'success',
      'message' => 'Notifikasi Midtrans diterima untuk order ' . $orderId,
      'payload' => $payload,
    ]);

    return response()->json(['message' => 'OK'], 200);
  }

  public function finish(Request $request)
  {
    $payment = $this->findPaymentFromRequest($request);

    if ($payment) {
      $this->refreshFromMidtrans($payment);
    }

    if ($payment && $payment->isPaid()) {
      return view('payments.success', compact('payment'));
    }

    if ($payment && $payment->isPending()) {
      return view('payments.pending', compact('payment'));
    }

    return view('payments.error', compact('payment'));
  }

  public function unfinish(Request $request)
  {
    $payment = $this->findPaymentFromRequest($request);

    if ($payment) {
      $this->refreshFromMidtrans($payment);
    }

    return view('payments.pending', compact('payment'));
  }

  public function error(Request $request)
  {
    $payment = $this->findPaymentFromRequest($request);

    if ($payment) {
      $this->refreshFromMidtrans($payment);
    }

    return view('payments.error', compact('payment'));
  }

  public function history()
  {
    $payments = Payment::with(['scheduleBooking.package'])
      ->whereHas('scheduleBooking', function ($query) {
        $query->where('client_user_id', Auth::id());
      })
      ->latest()
      ->paginate(10);

    return view('payments.history', compact('payments'));
  }

  public function show(Payment $payment)
  {
    $payment->load(['scheduleBooking.package', 'gateway']);

    if (!$payment->scheduleBooking || (int) $payment->scheduleBooking->client_user_id !== (int) Auth::id()) {
      abort(403);
    }

    return view('payments.show', compact('payment'));
  }

  private function findPaymentFromRequest(Request $request): ?Payment
  {
    $orderId = $request->get('order_id');

    if (!$orderId) {
      return null;
    }

    return Payment::where('order_id', $orderId)->first();
  }

  private function refreshFromMidtrans(Payment $payment): void
  {
    $gateway = PaymentGateway::where('provider', 'midtrans')->first();

    if (!$gateway || !$gateway->server_key) {
      return;
    }

    try {
      Config::$serverKey = $gateway->server_key;
      Config::$clientKey = $gateway->client_key;
      Config::$isProduction = $gateway->environment === 'production';
      Config::$isSanitized = true;
      Config::$is3ds = true;

      $status = Transaction::status($payment->order_id);
      $payload = json_decode(json_encode($status), true);

      $payment->update($this->mapNotificationToPaymentData($payload));

      if ($payment->payment_context === 'print_order') {
        $this->syncPrintOrderPaymentStatus($payment);
      } else {
        app(\App\Services\BookingPaymentStatusSyncService::class)->sync($payment);
      }
    } catch (\Throwable $e) {
      // diamkan agar redirect page tetap bisa dibuka
    }
  }

  private function mapNotificationToPaymentData(array $payload): array
  {
    $transactionStatus = $payload['transaction_status'] ?? 'pending';

    $data = [
      'transaction_id' => $payload['transaction_id'] ?? null,
      'payment_type' => $payload['payment_type'] ?? null,
      'transaction_status' => $transactionStatus,
      'fraud_status' => $payload['fraud_status'] ?? null,
      'status_message' => $payload['status_message'] ?? null,
      'payment_code' => $payload['payment_code']
        ?? $payload['bill_key']
        ?? $payload['permata_va_number']
        ?? null,
      'va_numbers' => $payload['va_numbers'] ?? null,
      'pdf_url' => $payload['pdf_url'] ?? null,
      'payload' => $payload,
    ];

    if (!empty($payload['transaction_time'])) {
      $data['initiated_at'] = Carbon::parse($payload['transaction_time']);
    }

    if (in_array($transactionStatus, ['settlement', 'capture'])) {
      $data['paid_at'] = now();
      $data['settled_at'] = now();
    }

    if ($transactionStatus === 'expire') {
      $data['expired_at'] = now();
    }

    return $data;
  }

  private function syncBookingPaymentStatus(Payment $payment): void
{
    $booking = $payment->scheduleBooking;

    if (!$booking) {
        return;
    }

    $trackingService = app(\App\Services\BookingTrackingService::class);

    $paidAmount = (int) Payment::query()
        ->where('schedule_booking_id', $booking->id)
        ->whereNull('print_order_id')
        ->whereIn('transaction_status', ['settlement', 'capture'])
        ->sum('base_amount');

    $totalAmount = (int) $booking->total_booking_amount;
    $minimumDp = (int) ceil($totalAmount * 0.5);

    if ($payment->isPaid()) {
        if ($paidAmount >= $totalAmount) {
            $booking->update([
                'payment_status' => 'paid',
                'payment_order_id' => $payment->order_id,
                'payment_paid_at' => $payment->paid_at ?? now(),
            ]);

            $trackingService->markDone(
                $booking,
                'dp_payment',
                'Pembayaran DP berhasil diterima.'
            );

            $trackingService->markDone(
                $booking,
                'full_payment',
                'Pelunasan berhasil diterima.'
            );

            $trackingService->markCurrent(
                $booking,
                'shooting',
                'Pembayaran telah lunas. Menunggu jadwal pemotretan.'
            );

            return;
        }

        if ($paidAmount >= $minimumDp) {
            $booking->update([
                'payment_status' => 'partially_paid',
                'payment_order_id' => $payment->order_id,
                'payment_paid_at' => $payment->paid_at ?? now(),
            ]);

            $trackingService->markDone(
                $booking,
                'dp_payment',
                'Pembayaran DP berhasil diterima.'
            );

            $trackingService->markCurrent(
                $booking,
                'full_payment',
                'Bayar pelunasan sebelum tanggal ' . \Carbon\Carbon::parse($booking->booking_date)->translatedFormat('d F Y') . '.'
            );

            return;
        }
    }

    if ($payment->isPending()) {
        $booking->update([
            'payment_status' => $paidAmount >= $minimumDp ? 'partially_paid' : 'pending',
            'payment_order_id' => $payment->order_id,
            'payment_due_at' => $payment->expired_at,
        ]);

        return;
    }

    // gagal / expired / cancel
    if ($paidAmount >= $minimumDp) {
        $booking->update([
            'payment_status' => 'partially_paid',
            'payment_order_id' => $payment->order_id,
        ]);

        $trackingService->markCurrent(
            $booking,
            'full_payment',
            'Tagihan pelunasan gagal atau kedaluwarsa. Silakan buat tagihan ulang sebelum tanggal pemotretan.'
        );

        return;
    }

    $booking->update([
        'status' => 'cancelled',
        'payment_status' => 'failed',
        'payment_order_id' => $payment->order_id,
    ]);

    $trackingService->markPending(
        $booking,
        'dp_payment',
        'Pembayaran DP gagal atau kedaluwarsa. Booking dibatalkan.'
    );
}

  private function resolveBookingAmount(ScheduleBooking $scheduleBooking): int
  {
    $packagePrice = (int) ($scheduleBooking->package->discounted_price
      ?? $scheduleBooking->package->price
      ?? 0);

    $extraDurationFee = (int) ($scheduleBooking->extra_duration_fee ?? 0);

    return $packagePrice + $extraDurationFee;
  }

  private function snapJsUrl(string $environment): string
  {
    return $environment === 'production'
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';
  }
  private function syncPrintOrderPaymentStatus(Payment $payment): void
  {
    $printOrder = $payment->printOrder;

    if (!$printOrder) {
      return;
    }

    if ($payment->isPaid()) {
      $printOrder->update([
        'payment_status' => 'paid',
        'status' => 'processing',
      ]);
      return;
    }

    if ($payment->isPending()) {
      $printOrder->update([
        'payment_status' => 'pending',
      ]);
      return;
    }

    $printOrder->update([
      'payment_status' => 'failed',
    ]);
  }
}
