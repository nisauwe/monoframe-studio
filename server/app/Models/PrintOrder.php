<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PrintOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'schedule_booking_id',
        'client_user_id',

        'selected_files',
        'quantity',

        'size_name',
        'paper_type',
        'use_frame',

        'print_unit_price',
        'frame_unit_price',
        'subtotal_print',
        'subtotal_frame',
        'total_amount',

        'delivery_method',
        'recipient_name',
        'recipient_phone',
        'delivery_address',

        'status',
        'payment_status',

        'paid_at',
        'processed_at',
        'completed_at',

        'delivery_proof_path',
        'delivery_proof_url',

        'completion_photo_path',
        'completion_photo_url',

        'notes',
    ];

    protected $casts = [
        'selected_files' => 'array',
        'quantity' => 'integer',
        'use_frame' => 'boolean',

        'print_unit_price' => 'integer',
        'frame_unit_price' => 'integer',
        'subtotal_print' => 'integer',
        'subtotal_frame' => 'integer',
        'total_amount' => 'integer',

        'paid_at' => 'datetime',
        'processed_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    protected $appends = [
        'status_label',
        'delivery_method_label',
    ];

    public function booking()
    {
        return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
    }

    public function client()
    {
        return $this->belongsTo(User::class, 'client_user_id');
    }

    public function items()
    {
        return $this->hasMany(PrintOrderItem::class, 'print_order_id');
    }

    public function payment()
    {
        return $this->hasOne(Payment::class, 'print_order_id')->latestOfMany();
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'print_order_id');
    }

    public function printPrice()
    {
        return $this->belongsTo(PrintPrice::class, 'print_price_id');
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'pending_payment' => 'Menunggu Pembayaran',
            'paid' => 'Menunggu Diproses',
            'processing' => 'Sedang Diproses',
            'completed' => 'Selesai',
            'cancelled' => 'Dibatalkan',
            default => $this->status ? ucfirst((string) $this->status) : '-',
        };
    }

    public function getDeliveryMethodLabelAttribute(): string
    {
        return $this->delivery_method === 'delivery'
            ? 'Diantar Ekspedisi'
            : 'Jemput di Studio';
    }

    public function isPaid(): bool
    {
        return in_array($this->payment_status, [
            'paid',
            'settlement',
            'capture',
        ], true);
    }
}
