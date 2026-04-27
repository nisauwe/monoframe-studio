<?php

namespace App\Console\Commands;

use App\Models\Payment;
use App\Services\BookingPaymentStatusSyncService;
use Illuminate\Console\Command;

class ExpirePendingBookingPayments extends Command
{
    protected $signature = 'payments:expire-booking-pending';
    protected $description = 'Tandai payment booking yang pending dan sudah lewat expired_at sebagai expire';

    public function handle(BookingPaymentStatusSyncService $syncService): int
    {
        $payments = Payment::query()
            ->whereNull('print_order_id')
            ->whereIn('transaction_status', ['created', 'pending'])
            ->whereNotNull('expired_at')
            ->where('expired_at', '<=', now())
            ->get();

        foreach ($payments as $payment) {
            $payment->update([
                'transaction_status' => 'expire',
                'status_message' => 'Payment expired by scheduler',
            ]);

            $syncService->sync($payment);
        }

        $this->info("Expired payments processed: {$payments->count()}");

        return self::SUCCESS;
    }
}
