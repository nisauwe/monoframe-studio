<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PrintPrice extends Model
{
    use HasFactory;

    protected $fillable = [
        'size_label',
        'base_price',
        'frame_price',
        'is_active',
        'notes',

        'size_name',
        'paper_type',
        'print_price',
        'is_available',
    ];

    protected $casts = [
        'base_price' => 'integer',
        'print_price' => 'integer',
        'frame_price' => 'integer',
        'is_active' => 'boolean',
        'is_available' => 'boolean',
    ];

    public function printOrders()
    {
        return $this->hasMany(PrintOrder::class);
    }

    public function printOrderItems()
    {
        return $this->hasMany(PrintOrderItem::class);
    }

    public function getApiSizeNameAttribute(): string
    {
        return (string) ($this->size_name ?: $this->size_label ?: '');
    }

    public function getApiPaperTypeAttribute(): string
    {
        return (string) ($this->paper_type ?: $this->notes ?: '');
    }

    public function getApiPrintPriceAttribute(): int
    {
        $printPrice = (int) ($this->print_price ?? 0);
        $basePrice = (int) ($this->base_price ?? 0);

        return $printPrice > 0 ? $printPrice : $basePrice;
    }

    public function getApiFramePriceAttribute(): int
    {
        return (int) ($this->frame_price ?? 0);
    }

    public function getApiIsAvailableAttribute(): bool
    {
        $isAvailable = true;

        if ($this->is_available !== null) {
            $isAvailable = (bool) $this->is_available;
        }

        if ($this->is_active !== null) {
            $isAvailable = $isAvailable && (bool) $this->is_active;
        }

        return $isAvailable;
    }
}
