<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Package;

class PackageController extends Controller
{
  public function index()
  {
    $packages = Package::with(['category', 'discounts'])
      ->where('is_active', true)
      ->orderBy('name')
      ->get();

    return response()->json([
      'message' => 'Daftar paket berhasil diambil',
      'data' => $packages
    ]);
  }

  public function show(Package $package)
  {
    if (!$package->is_active) {
      return response()->json([
        'message' => 'Paket tidak tersedia'
      ], 404);
    }

    return response()->json([
      'message' => 'Detail paket berhasil diambil',
      'data' => $package->load(['category', 'discounts'])
    ]);
  }
}
