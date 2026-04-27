<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\PrintPrice;

class PrintPriceController extends Controller
{
  public function index()
  {
    $prices = PrintPrice::query()
      ->where('is_active', true)
      ->orderBy('size_label')
      ->get(['id', 'size_label', 'base_price', 'frame_price', 'notes']);

    return response()->json([
      'message' => 'Pricelist cetak berhasil diambil',
      'data' => $prices,
    ]);
  }
}
