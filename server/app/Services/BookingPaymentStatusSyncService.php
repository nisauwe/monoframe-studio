<?php

namespace App\Services;

use App\Models\Payment;
use Carbon\Carbon;

class BookingPaymentStatusSyncService
{
    public function sync(Payment $payment): void
    {
        $booking = $payment->scheduleBooking;

        if (!$booking) {
            return;
        }

        $booking->loadMissing(['package', 'successfulBookingPayments']);

        $trackingService = app(BookingTrackingService::class);

        $paidAmount = (int) Payment::query()
            ->where('schedule_booking_id', $booking->id)
            ->whereNull('print_order_id')
            ->whereIn('transaction_status', ['settlement', 'capture'])
            ->sum('base_amount');

        $totalAmount = (int) (
            ($booking->total_booking_amount ?? 0) > 0
                ? $booking->total_booking_amount
                : (
                    (int) ($booking->package?->discounted_price ?? $booking->package?->price ?? 0)
                    + (int) ($booking->extra_duration_fee ?? 0)
                    + (int) ($booking->video_addon_price ?? 0)
                )
        );

        $minimumDp = (int) ceil($totalAmount * 0.5);

        if ($totalAmount <= 0) {
            return;
        }

        if ($paidAmount >= $totalAmount) {
            $booking->update([
                'status' => 'confirmed',
                'payment_status' => 'fully_paid',
                'payment_order_id' => $payment->order_id,
                'payment_paid_at' => $payment->paid_at ?? now(),
                'payment_due_at' => null,
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
                'status' => 'confirmed',
                'payment_status' => 'partially_paid',
                'payment_order_id' => $payment->order_id,
                'payment_paid_at' => $payment->paid_at ?? $booking->payment_paid_at ?? now(),
                'payment_due_at' => $payment->isPending() ? $payment->expired_at : null,
            ]);

            $trackingService->markDone(
                $booking,
                'dp_payment',
                'Pembayaran DP berhasil diterima.'
            );

            if ($payment->isFailed()) {
                $trackingService->markCurrent(
                    $booking,
                    'full_payment',
                    'Tagihan pelunasan gagal atau kedaluwarsa. Silakan buat tagihan ulang sebelum tanggal pemotretan.'
                );

                return;
            }

            $trackingService->markCurrent(
                $booking,
                'full_payment',
                'Bayar pelunasan sebelum tanggal ' .
                    Carbon::parse($booking->booking_date)->translatedFormat('d F Y') .
                    '.'
            );

            return;
        }

        if ($payment->isPending()) {
            $booking->update([
                'payment_status' => 'pending',
                'payment_order_id' => $payment->order_id,
                'payment_due_at' => $payment->expired_at,
            ]);

            return;
        }

        if ($payment->isFailed()) {
            $booking->update([
                'status' => 'cancelled',
                'payment_status' => 'failed',
                'payment_order_id' => $payment->order_id,
                'payment_due_at' => null,
            ]);

            $trackingService->markPending(
                $booking,
                'dp_payment',
                'Pembayaran DP gagal atau kedaluwarsa. Booking dibatalkan.'
            );
        }
    }
}
