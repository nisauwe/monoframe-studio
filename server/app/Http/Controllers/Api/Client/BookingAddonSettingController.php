<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\BookingAddonSetting;

class BookingAddonSettingController extends Controller
{
    public function index()
    {
        $data = BookingAddonSetting::query()
            ->where('is_active', true)
            ->orderBy('addon_key')
            ->get();

        return response()->json([
            'message' => 'Daftar add-on booking berhasil diambil',
            'data' => $data,
        ]);
    }
}
