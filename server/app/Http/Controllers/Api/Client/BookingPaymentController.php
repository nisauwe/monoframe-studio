<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Models\ScheduleBooking;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Midtrans\Config;
use Midtrans\Snap;

class BookingPaymentController extends Controller
{
    public function createSnap(Request $request, ScheduleBooking $booking)
    {
        $request->validate([
            'mode' => ['required', 'in:dp,full'],
        ]);

        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load(['package', 'clientUser', 'successfulBookingPayments']);

        if ($booking->status === 'cancelled') {
            return response()->json([
                'message' => 'Booking sudah dibatalkan.',
            ], 422);
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

        $mode = $request->mode;

        if ($mode === 'dp' && $booking->isDpPaid()) {
            return response()->json([
                'message' => 'DP booking ini sudah dibayar.',
            ], 422);
        }

        if ($mode === 'full' && $booking->isFullyPaid()) {
            return response()->json([
                'message' => 'Booking ini sudah lunas.',
            ], 422);
        }

        $existingPending = Payment::query()
            ->where('schedule_booking_id', $booking->id)
            ->whereNull('print_order_id')
            ->where('payment_stage', $mode)
            ->whereIn('transaction_status', ['created', 'pending'])
            ->latest()
            ->first();

        if ($existingPending && $existingPending->snap_token) {
            return response()->json([
                'message' => 'Tagihan pembayaran lama masih aktif.',
                'token' => $existingPending->snap_token,
                'redirect_url' => $existingPending->snap_redirect_url,
                'client_key' => $gateway->client_key,
                'snap_js_url' => $this->snapJsUrl($gateway->environment),
                'order_id' => $existingPending->order_id,
                'payment_stage' => $mode,
            ]);
        }

        [$baseAmount, $invoiceLabel] = $this->resolveInvoiceAmount($booking, $mode);

        $adminFee = (int) $gateway->admin_fee;
        $grossAmount = $baseAmount + $adminFee;

        if ($grossAmount <= 0) {
            return response()->json([
                'message' => 'Nominal pembayaran tidak valid.',
            ], 422);
        }

        $orderId = 'BOOK-' . strtoupper($mode) . '-' . now()->format('YmdHis') . '-' . strtoupper(Str::random(6));

        Config::$serverKey = $gateway->server_key;
        Config::$clientKey = $gateway->client_key;
        Config::$isProduction = $gateway->environment === 'production';
        Config::$isSanitized = true;
        Config::$is3ds = true;

        $itemDetails = [
            [
                'id' => 'BOOKING-' . $booking->id . '-' . strtoupper($mode),
                'price' => $baseAmount,
                'quantity' => 1,
                'name' => $invoiceLabel,
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
                'first_name' => $booking->clientUser?->name ?? $booking->client_name ?? 'Klien',
                'email' => $booking->clientUser?->email ?? 'customer@example.com',
                'phone' => $booking->clientUser?->phone ?? $booking->client_phone ?? '',
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
                'schedule_booking_id' => $booking->id,
                'payment_context' => 'booking',
                'payment_stage' => $mode,
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

            $booking->update([
                'payment_status' => 'unpaid',
                'payment_order_id' => $orderId,
                'payment_due_at' => $payment->expired_at,
            ]);

            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Create Snap Transaction API',
                'status' => 'success',
                'message' => 'Snap token booking berhasil dibuat untuk order ' . $orderId,
                'payload' => [
                    'schedule_booking_id' => $booking->id,
                    'order_id' => $orderId,
                    'gross_amount' => $grossAmount,
                    'payment_stage' => $mode,
                ],
            ]);

            return response()->json([
                'message' => 'Snap token berhasil dibuat.',
                'token' => $payment->snap_token,
                'redirect_url' => $payment->snap_redirect_url,
                'client_key' => $gateway->client_key,
                'snap_js_url' => $this->snapJsUrl($gateway->environment),
                'order_id' => $payment->order_id,
                'payment_stage' => $mode,
                'base_amount' => $baseAmount,
                'gross_amount' => $grossAmount,
            ]);
        } catch (\Throwable $e) {
            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Create Snap Transaction API',
                'status' => 'failed',
                'message' => $e->getMessage(),
                'payload' => [
                    'schedule_booking_id' => $booking->id,
                    'payment_stage' => $mode,
                ],
            ]);

            return response()->json([
                'message' => 'Gagal membuat transaksi Snap: ' . $e->getMessage(),
            ], 500);
        }
    }

    private function resolveInvoiceAmount(ScheduleBooking $booking, string $mode): array
    {
        $total = (int) $booking->total_booking_amount;

        if ($mode === 'dp') {
            return [
                (int) ceil($total * 0.5),
                'DP Booking ' . ($booking->package?->name ?? 'Monoframe'),
            ];
        }

        if ($booking->isDpPaid()) {
            return [
                (int) $booking->remaining_booking_amount,
                'Pelunasan Booking ' . ($booking->package?->name ?? 'Monoframe'),
            ];
        }

        return [
            $total,
            'Pelunasan Penuh Booking ' . ($booking->package?->name ?? 'Monoframe'),
        ];
    }

    private function snapJsUrl(string $environment): string
    {
        return $environment === 'production'
            ? 'https://app.midtrans.com/snap/snap.js'
            : 'https://app.sandbox.midtrans.com/snap/snap.js';
    }
}
