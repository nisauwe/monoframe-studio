<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'schedule_booking_id',
        'print_order_id',
        'payment_context',
        'payment_stage',
        'payment_gateway_id',
        'provider',
        'order_id',
        'transaction_id',
        'snap_token',
        'snap_redirect_url',
        'payment_type',
        'transaction_status',
        'fraud_status',
        'status_message',
        'payment_code',
        'va_numbers',
        'pdf_url',
        'base_amount',
        'admin_fee',
        'gross_amount',
        'paid_at',
        'settled_at',
        'expired_at',
        'payload',
    ];

    protected $casts = [
        'payload' => 'array',
        'va_numbers' => 'array',
        'base_amount' => 'integer',
        'admin_fee' => 'integer',
        'gross_amount' => 'integer',
        'paid_at' => 'datetime',
        'settled_at' => 'datetime',
        'expired_at' => 'datetime',
    ];

    public function scheduleBooking()
    {
        return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
    }

    public function printOrder()
    {
        return $this->belongsTo(PrintOrder::class, 'print_order_id');
    }

    public function gateway()
    {
        return $this->belongsTo(PaymentGateway::class, 'payment_gateway_id');
    }

    public function isSuccess(): bool
    {
        return in_array($this->transaction_status, [
            'settlement',
            'capture',
        ], true);
    }

    public function isPaid(): bool
    {
        return $this->isSuccess();
    }

    public function isPending(): bool
    {
        return in_array($this->transaction_status, [
            'created',
            'pending',
            'authorize',
        ], true);
    }

    public function isFailed(): bool
    {
        return in_array($this->transaction_status, [
            'deny',
            'cancel',
            'expire',
            'failure',
            'failed',
        ], true);
    }
}
