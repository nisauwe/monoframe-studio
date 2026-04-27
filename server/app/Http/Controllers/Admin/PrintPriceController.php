<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PrintPrice;
use Illuminate\Http\Request;

class PrintPriceController extends Controller
{
  public function index(Request $request)
  {
    $query = PrintPrice::query()->latest();

    if ($request->filled('search')) {
      $search = $request->search;
      $query->where('size_label', 'like', "%{$search}%");
    }

    if ($request->filled('status') && $request->status !== 'Semua Status') {
      $query->where('is_active', $request->status === 'Aktif');
    }

    $printPrices = $query->paginate(10)->withQueryString();

    $totalPrices = PrintPrice::count();
    $activePrices = PrintPrice::where('is_active', true)->count();
    $inactivePrices = PrintPrice::where('is_active', false)->count();

    return view('admin.packages.index', compact(
      'printPrices',
      'totalPrices',
      'activePrices',
      'inactivePrices'
    ));
  }

  public function create()
  {
    return view('admin.print-prices.create');
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'size_label' => 'required|string|max:50',
      'base_price' => 'required|numeric|min:0',
      'frame_price' => 'required|numeric|min:0',
      'notes' => 'nullable|string',
      'is_active' => 'nullable|boolean',
    ]);

    $validated['is_active'] = $request->boolean('is_active');

    PrintPrice::create($validated);

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Pricelist cetak berhasil ditambahkan.');
  }

  public function edit(PrintPrice $printPrice)
  {
    return view('admin.print-prices.edit', compact('printPrice'));
  }

  public function update(Request $request, PrintPrice $printPrice)
  {
    $validated = $request->validate([
      'size_label' => 'required|string|max:50',
      'base_price' => 'required|numeric|min:0',
      'frame_price' => 'required|numeric|min:0',
      'notes' => 'nullable|string',
      'is_active' => 'nullable|boolean',
    ]);

    $validated['is_active'] = $request->boolean('is_active');

    $printPrice->update($validated);

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Pricelist cetak berhasil diperbarui.');
  }

  public function destroy(PrintPrice $printPrice)
  {
    $printPrice->delete();

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Pricelist cetak berhasil dihapus.');
  }

  public function toggleStatus(Request $request, PrintPrice $printPrice)
  {
    $printPrice->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Status pricelist cetak berhasil diperbarui.');
  }
}
