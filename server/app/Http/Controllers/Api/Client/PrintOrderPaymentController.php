<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Models\PrintOrder;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;

class PrintOrderPaymentController extends Controller
{
  public function createSnap(Request $request, PrintOrder $printOrder)
  {
    $printOrder->load(['booking', 'client', 'items.printPrice']);

    if ((int) $printOrder->client_user_id !== (int) $request->user()->id) {
      return response()->json(['message' => 'Akses ditolak'], 403);
    }

    if ($printOrder->status !== 'awaiting_payment') {
      return response()->json([
        'message' => 'Permintaan cetak belum siap untuk dibayar.'
      ], 422);
    }

    $gateway = PaymentGateway::where('provider', 'midtrans')
      ->where('is_active', true)
      ->first();

    if (!$gateway) {
      return response()->json(['message' => 'Payment gateway Midtrans belum aktif.'], 422);
    }

    if (!$gateway->server_key || !$gateway->client_key) {
      return response()->json(['message' => 'Client Key atau Server Key Midtrans belum diisi.'], 422);
    }

    $existingPaid = Payment::query()
      ->where('payment_context', 'print_order')
      ->where('print_order_id', $printOrder->id)
      ->whereIn('transaction_status', ['settlement', 'capture'])
      ->latest()
      ->first();

    if ($existingPaid) {
      return response()->json(['message' => 'Pesanan cetak ini sudah dibayar.'], 422);
    }

    $existingPending = Payment::query()
      ->where('payment_context', 'print_order')
      ->where('print_order_id', $printOrder->id)
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

    $baseAmount = (int) $printOrder->total_amount;
    $adminFee = (int) $gateway->admin_fee;
    $grossAmount = $baseAmount + $adminFee;

    if ($grossAmount <= 0) {
      return response()->json(['message' => 'Nominal pembayaran cetak tidak valid.'], 422);
    }

    $orderId = 'PRINT-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(6));

    Config::$serverKey = $gateway->server_key;
    Config::$clientKey = $gateway->client_key;
    Config::$isProduction = $gateway->environment === 'production';
    Config::$isSanitized = true;
    Config::$is3ds = true;

    $itemDetails = [];
    foreach ($printOrder->items as $item) {
      $itemDetails[] = [
        'id' => 'PRINT-ITEM-' . $item->id,
        'price' => (int) $item->line_total,
        'quantity' => 1,
        'name' => $item->file_name . ' - ' . ($item->printPrice->size_label ?? 'Cetak'),
      ];
    }

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
        'first_name' => $printOrder->client?->name ?? 'Klien',
        'email' => $printOrder->client?->email ?? 'customer@example.com',
        'phone' => $printOrder->client?->phone ?? $printOrder->recipient_phone ?? '',
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
        'schedule_booking_id' => $printOrder->schedule_booking_id,
        'payment_context' => 'print_order',
        'print_order_id' => $printOrder->id,
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

      $printOrder->update([
        'payment_status' => 'pending',
      ]);

      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Create Snap Transaction Print Order',
        'status' => 'success',
        'message' => 'Snap token print order berhasil dibuat untuk order ' . $orderId,
        'payload' => [
          'print_order_id' => $printOrder->id,
          'schedule_booking_id' => $printOrder->schedule_booking_id,
          'order_id' => $orderId,
          'gross_amount' => $grossAmount,
        ],
      ]);

      return response()->json([
        'message' => 'Snap token pembayaran cetak berhasil dibuat.',
        'token' => $payment->snap_token,
        'redirect_url' => $payment->snap_redirect_url,
        'client_key' => $gateway->client_key,
        'snap_js_url' => $this->snapJsUrl($gateway->environment),
        'order_id' => $payment->order_id,
      ]);
    } catch (\Throwable $e) {
      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Create Snap Transaction Print Order',
        'status' => 'failed',
        'message' => $e->getMessage(),
        'payload' => [
          'print_order_id' => $printOrder->id,
        ],
      ]);

      return response()->json([
        'message' => 'Gagal membuat transaksi cetak: ' . $e->getMessage(),
      ], 500);
    }
  }

  private function snapJsUrl(string $environment): string
  {
    return $environment === 'production'
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';
  }
}
