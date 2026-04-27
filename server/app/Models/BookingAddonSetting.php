<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BookingAddonSetting extends Model
{
    protected $fillable = [
        'addon_key',
        'addon_name',
        'price',
        'is_active',
    ];
}
