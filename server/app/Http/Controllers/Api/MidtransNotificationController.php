<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Services\BookingPaymentStatusSyncService;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class MidtransNotificationController extends Controller
{
    public function handle(Request $request)
    {
        $payload = $request->all();

        Log::info('Midtrans notification received', $payload);

        $orderId = $payload['order_id'] ?? null;
        $statusCode = $payload['status_code'] ?? null;
        $grossAmount = $payload['gross_amount'] ?? null;
        $signatureKey = $payload['signature_key'] ?? null;

        if (!$orderId) {
            return response()->json([
                'message' => 'Order ID tidak ditemukan.',
            ], 422);
        }

        $payment = Payment::where('order_id', $orderId)->first();

        if (!$payment) {
            Log::warning('Midtrans payment not found', [
                'order_id' => $orderId,
                'payload' => $payload,
            ]);

            return response()->json([
                'message' => 'Payment tidak ditemukan.',
            ], 404);
        }

        $gateway = PaymentGateway::where('provider', 'midtrans')->first();

        if (!$gateway || !$gateway->server_key) {
            $this->writeGatewayLog($gateway, 'failed', 'Gateway Midtrans tidak tersedia atau Server Key kosong.', $payload);

            return response()->json([
                'message' => 'Gateway Midtrans tidak tersedia atau Server Key kosong.',
            ], 422);
        }

        if ($statusCode && $grossAmount && $signatureKey) {
            $localSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $gateway->server_key);

            if (!hash_equals($localSignature, $signatureKey)) {
                $this->writeGatewayLog($gateway, 'failed', 'Signature key Midtrans tidak valid untuk order ' . $orderId, $payload);

                return response()->json([
                    'message' => 'Signature key Midtrans tidak valid.',
                ], 403);
            }
        }

        $this->applyMidtransPayload($payment, $payload);

        $payment->refresh();

        if ($payment->print_order_id) {
            $this->syncPrintPayment($payment);
        } else {
            app(BookingPaymentStatusSyncService::class)->sync($payment);
        }

        $this->writeGatewayLog($gateway, 'success', 'Notification processed for order ' . $orderId, $payload);

        return response()->json([
            'message' => 'Notification processed.',
        ]);
    }

    private function applyMidtransPayload(Payment $payment, array $payload): void
    {
        $transactionStatus = $payload['transaction_status'] ?? $payment->transaction_status;
        $fraudStatus = $payload['fraud_status'] ?? $payment->fraud_status;
        $normalizedStatus = $this->normalizeStatus($transactionStatus, $fraudStatus);

        $payment->update([
            'transaction_id' => $payload['transaction_id'] ?? $payment->transaction_id,
            'payment_type' => $payload['payment_type'] ?? $payment->payment_type,
            'transaction_status' => $normalizedStatus,
            'fraud_status' => $fraudStatus,
            'status_message' => $payload['status_message'] ?? $payment->status_message,
            'gross_amount' => isset($payload['gross_amount'])
                ? (int) $payload['gross_amount']
                : $payment->gross_amount,
            'va_numbers' => $payload['va_numbers'] ?? $payment->va_numbers,
            'payment_code' => $payload['payment_code']
                ?? $payload['bill_key']
                ?? $payload['permata_va_number']
                ?? $payment->payment_code,
            'pdf_url' => $payload['pdf_url'] ?? $payment->pdf_url,
            'paid_at' => in_array($normalizedStatus, ['settlement', 'capture'], true)
                ? ($payment->paid_at ?? now())
                : $payment->paid_at,
            'settled_at' => in_array($normalizedStatus, ['settlement', 'capture'], true)
                ? ($payment->settled_at ?? now())
                : $payment->settled_at,
            'expired_at' => $normalizedStatus === 'expire'
                ? ($payment->expired_at ?? now())
                : $payment->expired_at,
            'payload' => array_merge($payment->payload ?? [], [
                'notification' => $payload,
            ]),
        ]);
    }

    private function syncPrintPayment(Payment $payment): void
    {
        $printOrder = $payment->printOrder;

        if (!$printOrder) {
            return;
        }

        if ($payment->isPaid()) {
            $printOrder->update([
                'payment_status' => 'paid',
                'status' => 'paid',
                'paid_at' => now(),
            ]);

            if ($printOrder->booking) {
                app(BookingTrackingService::class)->markCurrent(
                    $printOrder->booking,
                    'print',
                    'Pembayaran cetak berhasil. Pesanan cetak menunggu diproses Front Office.'
                );
            }

            return;
        }

        if ($payment->isPending()) {
            $printOrder->update([
                'payment_status' => 'pending',
            ]);

            return;
        }

        if ($payment->isFailed()) {
            $printOrder->update([
                'payment_status' => 'failed',
            ]);
        }
    }

    private function normalizeStatus(?string $transactionStatus, ?string $fraudStatus): string
    {
        if ($transactionStatus === 'capture') {
            if ($fraudStatus === 'challenge') {
                return 'pending';
            }

            return 'capture';
        }

        return $transactionStatus ?: 'pending';
    }

    private function writeGatewayLog(?PaymentGateway $gateway, string $status, string $message, array $payload): void
    {
        if (!$gateway) {
            Log::warning($message, $payload);
            return;
        }

        PaymentGatewayLog::create([
            'payment_gateway_id' => $gateway->id,
            'activity' => 'Midtrans Notification',
            'status' => $status,
            'message' => $message,
            'payload' => $payload,
        ]);
    }
}
