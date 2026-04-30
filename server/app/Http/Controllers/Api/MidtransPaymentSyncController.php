<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use App\Models\PrintOrder;
use App\Models\ScheduleBooking;
use App\Services\BookingPaymentStatusSyncService;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MidtransPaymentSyncController extends Controller
{
    public function checkBookingPayment(Request $request, ScheduleBooking $booking)
    {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak.',
            ], 403);
        }

        $payment = Payment::query()
            ->where('schedule_booking_id', $booking->id)
            ->whereNull('print_order_id')
            ->latest()
            ->first();

        if (!$payment) {
            return response()->json([
                'message' => 'Data pembayaran booking tidak ditemukan.',
            ], 404);
        }

        $syncResult = $this->syncPaymentFromMidtrans($payment);

        if (!$syncResult['success']) {
            return response()->json([
                'message' => $syncResult['message'],
            ], 422);
        }

        $payment->refresh();

        app(BookingPaymentStatusSyncService::class)->sync($payment);

        $booking = $booking->fresh([
            'package',
            'clientUser',
            'photographerUser',
            'latestPayment',
            'successfulBookingPayments',
            'trackings',
        ]);

        $payment->refresh();

        return response()->json([
            'message' => $this->bookingSyncMessage($payment, $booking),
            'data' => [
                'payment' => $payment,
                'booking' => $booking,
            ],
        ]);
    }

    public function checkPrintPayment(
        Request $request,
        PrintOrder $printOrder,
        BookingTrackingService $trackingService
    ) {
        if ((int) $printOrder->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak.',
            ], 403);
        }

        $payment = Payment::query()
            ->where('print_order_id', $printOrder->id)
            ->latest()
            ->first();

        if (!$payment) {
            return response()->json([
                'message' => 'Data pembayaran cetak tidak ditemukan.',
            ], 404);
        }

        $syncResult = $this->syncPaymentFromMidtrans($payment);

        if (!$syncResult['success']) {
            return response()->json([
                'message' => $syncResult['message'],
            ], 422);
        }

        $payment->refresh();

        $this->processPrintPayment($payment, $trackingService);

        $printOrder = $printOrder->fresh([
            'items.printPrice',
            'payment',
        ]);

        return response()->json([
            'message' => $payment->isPaid()
                ? 'Pembayaran cetak berhasil diperbarui.'
                : 'Status pembayaran cetak masih ' . $payment->transaction_status . '.',
            'data' => [
                'payment' => $payment,
                'print_order' => $printOrder,
            ],
        ]);
    }

    private function syncPaymentFromMidtrans(Payment $payment): array
    {
        $gateway = null;

        if ($payment->payment_gateway_id) {
            $gateway = PaymentGateway::find($payment->payment_gateway_id);
        }

        if (!$gateway) {
            $gateway = PaymentGateway::query()
                ->where('provider', 'midtrans')
                ->where('is_active', true)
                ->first();
        }

        if (!$gateway) {
            return [
                'success' => false,
                'message' => 'Payment gateway Midtrans belum aktif.',
            ];
        }

        if (empty($gateway->server_key)) {
            return [
                'success' => false,
                'message' => 'Server key Midtrans belum diisi.',
            ];
        }

        if (empty($payment->order_id)) {
            return [
                'success' => false,
                'message' => 'Order ID pembayaran kosong.',
            ];
        }

        $statusUrl = $this->apiBaseUrl($gateway) . '/v2/' . rawurlencode($payment->order_id) . '/status';

        $response = Http::withBasicAuth($gateway->server_key, '')
            ->acceptJson()
            ->get($statusUrl);

        if (!$response->successful()) {
            Log::warning('Midtrans status sync failed', [
                'payment_id' => $payment->id,
                'order_id' => $payment->order_id,
                'response' => $response->json(),
            ]);

            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Midtrans Manual Sync',
                'status' => 'failed',
                'message' => 'Gagal mengecek status pembayaran ke Midtrans untuk order ' . $payment->order_id,
                'payload' => [
                    'payment_id' => $payment->id,
                    'order_id' => $payment->order_id,
                    'midtrans_response' => $response->json(),
                ],
            ]);

            return [
                'success' => false,
                'message' => 'Gagal mengecek status pembayaran ke Midtrans.',
            ];
        }

        $payload = $response->json();

        $transactionStatus = $payload['transaction_status'] ?? null;
        $fraudStatus = $payload['fraud_status'] ?? null;

        if (!$transactionStatus) {
            PaymentGatewayLog::create([
                'payment_gateway_id' => $gateway->id,
                'activity' => 'Midtrans Manual Sync',
                'status' => 'failed',
                'message' => 'Response Midtrans tidak memiliki transaction_status untuk order ' . $payment->order_id,
                'payload' => [
                    'payment_id' => $payment->id,
                    'order_id' => $payment->order_id,
                    'midtrans_response' => $payload,
                ],
            ]);

            return [
                'success' => false,
                'message' => 'Response Midtrans tidak memiliki transaction_status.',
            ];
        }

        $normalizedStatus = $this->normalizeStatus($transactionStatus, $fraudStatus);
        $grossAmount = $payload['gross_amount'] ?? null;

        $payment->update([
            'payment_gateway_id' => $payment->payment_gateway_id ?: $gateway->id,
            'provider' => $payment->provider ?: 'midtrans',
            'transaction_id' => $payload['transaction_id'] ?? $payment->transaction_id,
            'payment_type' => $payload['payment_type'] ?? $payment->payment_type,
            'transaction_status' => $normalizedStatus,
            'fraud_status' => $fraudStatus,
            'status_message' => $payload['status_message'] ?? $payment->status_message,
            'gross_amount' => $grossAmount
                ? (int) round((float) $grossAmount)
                : $payment->gross_amount,
            'va_numbers' => $payload['va_numbers'] ?? $payment->va_numbers,
            'payment_code' => $payload['payment_code']
                ?? $payload['bill_key']
                ?? $payload['permata_va_number']
                ?? $payment->payment_code,
            'pdf_url' => $payload['pdf_url'] ?? $payment->pdf_url,
            'paid_at' => in_array($normalizedStatus, ['settlement', 'capture'], true)
                ? ($payment->paid_at ?: now())
                : $payment->paid_at,
            'settled_at' => $normalizedStatus === 'settlement'
                ? ($payment->settled_at ?: now())
                : $payment->settled_at,
            'expired_at' => $normalizedStatus === 'expire'
                ? ($payment->expired_at ?: now())
                : $payment->expired_at,
            'payload' => array_merge($payment->payload ?? [], [
                'manual_sync' => $payload,
            ]),
        ]);

        PaymentGatewayLog::create([
            'payment_gateway_id' => $gateway->id,
            'activity' => 'Midtrans Manual Sync',
            'status' => 'success',
            'message' => 'Manual sync processed for order ' . $payment->order_id,
            'payload' => [
                'payment_id' => $payment->id,
                'order_id' => $payment->order_id,
                'payment_context' => $payment->payment_context,
                'payment_stage' => $payment->payment_stage,
                'print_order_id' => $payment->print_order_id,
                'midtrans_response' => $payload,
            ],
        ]);

        return [
            'success' => true,
            'message' => 'Status pembayaran berhasil disinkronkan.',
        ];
    }

    private function processPrintPayment(Payment $payment, BookingTrackingService $trackingService): void
    {
        $printOrder = $payment->printOrder;

        if (!$printOrder) {
            return;
        }

        if ($payment->isPaid()) {
            $printOrder->update([
                'payment_status' => 'paid',
                'status' => 'paid',
                'paid_at' => $printOrder->paid_at ?: ($payment->paid_at ?: now()),
            ]);

            if ($printOrder->booking) {
                $trackingService->markCurrent(
                    $printOrder->booking,
                    'print',
                    'Pembayaran cetak sudah diterima. Pesanan menunggu diproses Front Office.'
                );
            }

            return;
        }

        if ($payment->isFailed()) {
            $printOrder->update([
                'payment_status' => 'failed',
                'status' => 'pending_payment',
            ]);

            return;
        }

        $printOrder->update([
            'payment_status' => 'pending',
            'status' => 'pending_payment',
        ]);
    }

    private function normalizeStatus(string $transactionStatus, ?string $fraudStatus): string
    {
        if ($transactionStatus === 'capture') {
            if ($fraudStatus === 'challenge') {
                return 'pending';
            }

            return 'capture';
        }

        return $transactionStatus;
    }

    private function apiBaseUrl(PaymentGateway $gateway): string
    {
        $isProduction = $gateway->environment === 'production'
            || (bool) ($gateway->is_production ?? false);

        return $isProduction
            ? 'https://api.midtrans.com'
            : 'https://api.sandbox.midtrans.com';
    }

    private function bookingSyncMessage(Payment $payment, ScheduleBooking $booking): string
    {
        if ($booking->isFullyPaid()) {
            return 'Pelunasan berhasil diperbarui. Booking sudah lunas.';
        }

        if ($booking->isDpPaid()) {
            if ($payment->isPending()) {
                return 'Status pembayaran masih pending di Midtrans. DP sudah tercatat, pelunasan belum lunas.';
            }

            return 'Status pembayaran berhasil diperbarui. DP sudah tercatat, pelunasan belum lunas.';
        }

        if ($payment->isFailed()) {
            return 'Pembayaran gagal atau kedaluwarsa.';
        }

        return 'Status pembayaran masih pending di Midtrans.';
    }
}
