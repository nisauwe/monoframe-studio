<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Models\PrintOrder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class PrintPaymentController extends Controller
{
    public function create(Request $request, PrintOrder $printOrder)
    {
        $printOrder->load([
            'booking',
            'items.printPrice',
            'payment',
        ]);

        if ((int) $printOrder->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak.',
            ], 403);
        }

        if ($printOrder->payment_status === 'paid' || $printOrder->isPaid()) {
            return response()->json([
                'message' => 'Pesanan cetak sudah dibayar.',
            ], 422);
        }

        if ($printOrder->status === 'completed') {
            return response()->json([
                'message' => 'Pesanan cetak sudah selesai.',
            ], 422);
        }

        $grossAmount = (int) $printOrder->total_amount;

        if ($grossAmount <= 0) {
            return response()->json([
                'message' => 'Total pembayaran cetak tidak valid.',
            ], 422);
        }

        $gateway = PaymentGateway::query()
            ->where('provider', 'midtrans')
            ->where('is_active', true)
            ->first();

        if (!$gateway) {
            return response()->json([
                'message' => 'Payment gateway Midtrans belum aktif.',
            ], 422);
        }

        if (empty($gateway->server_key)) {
            return response()->json([
                'message' => 'Server key Midtrans belum diisi.',
            ], 422);
        }

        $existingPaidPayment = Payment::query()
            ->where('print_order_id', $printOrder->id)
            ->whereIn('transaction_status', ['settlement', 'capture'])
            ->latest()
            ->first();

        if ($existingPaidPayment) {
            $printOrder->update([
                'payment_status' => 'paid',
                'status' => 'paid',
                'paid_at' => $printOrder->paid_at ?: ($existingPaidPayment->paid_at ?: now()),
            ]);

            return response()->json([
                'message' => 'Pesanan cetak sudah dibayar.',
            ], 422);
        }

        $existingPendingPayment = Payment::query()
            ->where('print_order_id', $printOrder->id)
            ->whereIn('transaction_status', ['created', 'pending', 'authorize'])
            ->latest()
            ->first();

        if ($existingPendingPayment && $existingPendingPayment->snap_redirect_url) {
            return response()->json([
                'message' => 'Tagihan pembayaran cetak masih aktif.',
                'payment_id' => $existingPendingPayment->id,
                'print_order_id' => $printOrder->id,
                'order_id' => $existingPendingPayment->order_id,
                'snap_token' => $existingPendingPayment->snap_token,
                'redirect_url' => $existingPendingPayment->snap_redirect_url,
                'snap_redirect_url' => $existingPendingPayment->snap_redirect_url,
                'gross_amount' => (int) $existingPendingPayment->gross_amount,
                'data' => [
                    'payment_id' => $existingPendingPayment->id,
                    'print_order_id' => $printOrder->id,
                    'order_id' => $existingPendingPayment->order_id,
                    'snap_token' => $existingPendingPayment->snap_token,
                    'redirect_url' => $existingPendingPayment->snap_redirect_url,
                    'snap_redirect_url' => $existingPendingPayment->snap_redirect_url,
                    'gross_amount' => (int) $existingPendingPayment->gross_amount,
                ],
            ]);
        }

        $orderId = 'PRINT-' .
            $printOrder->id .
            '-' .
            now()->format('YmdHis') .
            '-' .
            Str::upper(Str::random(5));

        $payment = Payment::create([
            'schedule_booking_id' => $printOrder->schedule_booking_id,
            'print_order_id' => $printOrder->id,
            'payment_context' => 'print',
            'payment_stage' => 'print',
            'payment_gateway_id' => $gateway->id,
            'provider' => 'midtrans',
            'order_id' => $orderId,
            'base_amount' => $grossAmount,
            'admin_fee' => 0,
            'gross_amount' => $grossAmount,
            'transaction_status' => 'pending',
            'expired_at' => now()->addMinutes((int) ($gateway->expiry_minutes ?: 60)),
            'payload' => [
                'source' => 'client_print_order',
                'print_order_id' => $printOrder->id,
            ],
        ]);

        $printOrder->update([
            'payment_status' => 'pending',
            'status' => 'pending_payment',
        ]);

        $client = $request->user();

        $itemDetails = [];

        foreach ($printOrder->items as $item) {
            $sizeName = $item->printPrice?->size_name
                ?: $item->printPrice?->size_label
                ?: 'Cetak Foto';

            $frameText = $item->use_frame ? ' + Bingkai' : '';

            $itemDetails[] = [
                'id' => 'PRINT-ITEM-' . $item->id,
                'price' => (int) $item->line_total,
                'quantity' => 1,
                'name' => $item->file_name . ' - ' . $sizeName . $frameText,
            ];
        }

        if (empty($itemDetails)) {
            $itemDetails[] = [
                'id' => 'PRINT-' . $printOrder->id,
                'price' => $grossAmount,
                'quantity' => 1,
                'name' => 'Pembayaran Cetak Foto',
            ];
        }

        $snapPayload = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => $grossAmount,
            ],
            'customer_details' => [
                'first_name' => $client->name ?: 'Klien',
                'email' => $client->email,
                'phone' => $client->phone ?? $printOrder->recipient_phone,
            ],
            'item_details' => $itemDetails,
            'enabled_payments' => $gateway->resolvedEnabledPaymentTypes(),
            'expiry' => [
                'unit' => 'minute',
                'duration' => (int) ($gateway->expiry_minutes ?: 60),
            ],
        ];

        $response = Http::withBasicAuth($gateway->server_key, '')
            ->acceptJson()
            ->post($this->snapUrl($gateway), $snapPayload);

        if (!$response->successful()) {
            $payment->update([
                'transaction_status' => 'failed',
                'status_message' => 'Gagal membuat Snap pembayaran cetak',
                'payload' => array_merge($payment->payload ?? [], [
                    'snap_request' => $snapPayload,
                    'snap_error' => $response->json(),
                ]),
            ]);

            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Create Print Snap',
                'status' => 'failed',
                'message' => 'Gagal membuat Snap pembayaran cetak untuk order ' . $orderId,
                'payload' => [
                    'payment_id' => $payment->id,
                    'print_order_id' => $printOrder->id,
                    'order_id' => $orderId,
                    'midtrans_response' => $response->json(),
                ],
            ]);

            return response()->json([
                'message' => 'Gagal membuat pembayaran cetak.',
                'error' => $response->json(),
            ], 422);
        }

        $snap = $response->json();

        $snapToken = $snap['token'] ?? null;
        $redirectUrl = $snap['redirect_url'] ?? null;

        if (!$redirectUrl) {
            $payment->update([
                'transaction_status' => 'failed',
                'status_message' => 'Midtrans tidak mengembalikan redirect URL.',
                'payload' => array_merge($payment->payload ?? [], [
                    'snap_request' => $snapPayload,
                    'snap_response' => $snap,
                ]),
            ]);

            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Create Print Snap',
                'status' => 'failed',
                'message' => 'Midtrans tidak mengembalikan redirect URL untuk order ' . $orderId,
                'payload' => [
                    'payment_id' => $payment->id,
                    'print_order_id' => $printOrder->id,
                    'order_id' => $orderId,
                    'midtrans_response' => $snap,
                ],
            ]);

            return response()->json([
                'message' => 'Midtrans tidak mengembalikan URL pembayaran.',
            ], 422);
        }

        $payment->update([
            'snap_token' => $snapToken,
            'snap_redirect_url' => $redirectUrl,
            'payload' => array_merge($payment->payload ?? [], [
                'snap_request' => $snapPayload,
                'snap_response' => $snap,
            ]),
        ]);

        PaymentGatewayLog::create([
            'payment_gateway_id' => $gateway->id,
            'activity' => 'Create Print Snap',
            'status' => 'success',
            'message' => 'Snap pembayaran cetak berhasil dibuat untuk order ' . $orderId,
            'payload' => [
                'payment_id' => $payment->id,
                'print_order_id' => $printOrder->id,
                'order_id' => $orderId,
                'gross_amount' => $grossAmount,
                'snap_token' => $snapToken,
                'snap_redirect_url' => $redirectUrl,
            ],
        ]);

        return response()->json([
            'message' => 'Pembayaran cetak berhasil dibuat.',
            'payment_id' => $payment->id,
            'print_order_id' => $printOrder->id,
            'order_id' => $orderId,
            'snap_token' => $snapToken,
            'redirect_url' => $redirectUrl,
            'snap_redirect_url' => $redirectUrl,
            'gross_amount' => (int) $payment->gross_amount,
            'data' => [
                'payment_id' => $payment->id,
                'print_order_id' => $printOrder->id,
                'order_id' => $orderId,
                'snap_token' => $snapToken,
                'redirect_url' => $redirectUrl,
                'snap_redirect_url' => $redirectUrl,
                'gross_amount' => (int) $payment->gross_amount,
            ],
        ]);
    }

    private function snapUrl(PaymentGateway $gateway): string
    {
        $isProduction = $gateway->environment === 'production'
            || (bool) ($gateway->is_production ?? false);

        return $isProduction
            ? 'https://app.midtrans.com/snap/v1/transactions'
            : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
    }
}
