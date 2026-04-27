<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PrintOrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'print_order_id',
        'print_price_id',
        'file_name',
        'qty',
        'use_frame',
        'unit_print_price',
        'unit_frame_price',
        'line_total',
    ];

    protected $casts = [
        'qty' => 'integer',
        'use_frame' => 'boolean',
        'unit_print_price' => 'integer',
        'unit_frame_price' => 'integer',
        'line_total' => 'integer',
    ];

    public function printOrder()
    {
        return $this->belongsTo(PrintOrder::class, 'print_order_id');
    }

    public function printPrice()
    {
        return $this->belongsTo(PrintPrice::class, 'print_price_id');
    }
}
