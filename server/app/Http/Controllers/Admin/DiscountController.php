<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Discount;
use App\Models\Package;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DiscountController extends Controller
{
  public function create(Request $request)
  {
    $categoryId = $request->query('category');

    if (!$categoryId) {
      return redirect()
        ->route('admin.packages.index')
        ->with('error', 'Pilih kategori terlebih dahulu sebelum menambah diskon.');
    }

    $selectedCategory = Category::findOrFail($categoryId);

    $packages = Package::where('category_id', $selectedCategory->id)
      ->orderBy('name')
      ->get();

    return view('admin.discounts.create', compact('selectedCategory', 'packages'));
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'category_id' => 'required|exists:categories,id',
      'promo_name' => 'nullable|string|max:255',
      'discount_percent' => 'required|integer|min:1|max:100',
      'discount_start_at' => 'nullable|date',
      'discount_end_at' => 'nullable|date|after_or_equal:discount_start_at',
      'is_active' => 'nullable|boolean',
      'package_ids' => 'required|array|min:1',
      'package_ids.*' => 'exists:packages,id',
    ]);

    $packagesCount = Package::where('category_id', $validated['category_id'])
      ->whereIn('id', $validated['package_ids'])
      ->count();

    if ($packagesCount !== count($validated['package_ids'])) {
      return back()
        ->withInput()
        ->with('error', 'Semua paket yang dipilih harus berasal dari kategori yang sama.');
    }

    DB::transaction(function () use ($request, $validated) {
      $discount = Discount::create([
        'category_id' => $validated['category_id'],
        'promo_name' => $validated['promo_name'] ?? null,
        'discount_percent' => $validated['discount_percent'],
        'discount_start_at' => $validated['discount_start_at'] ?? null,
        'discount_end_at' => $validated['discount_end_at'] ?? null,
        'is_active' => $request->boolean('is_active'),
      ]);

      $discount->packages()->sync($validated['package_ids']);
    });

    return redirect()
      ->route('admin.packages.index', ['category' => $validated['category_id']])
      ->with('success', 'Diskon berhasil ditambahkan.');
  }

  public function edit(Discount $discount)
  {
    $selectedCategory = $discount->category;

    $packages = Package::where('category_id', $selectedCategory->id)
      ->orderBy('name')
      ->get();

    $selectedPackageIds = $discount->packages()->pluck('packages.id')->toArray();

    return view('admin.discounts.edit', compact(
      'discount',
      'selectedCategory',
      'packages',
      'selectedPackageIds'
    ));
  }

  public function update(Request $request, Discount $discount)
  {
    $validated = $request->validate([
      'category_id' => 'required|exists:categories,id',
      'promo_name' => 'nullable|string|max:255',
      'discount_percent' => 'required|integer|min:1|max:100',
      'discount_start_at' => 'nullable|date',
      'discount_end_at' => 'nullable|date|after_or_equal:discount_start_at',
      'is_active' => 'nullable|boolean',
      'package_ids' => 'required|array|min:1',
      'package_ids.*' => 'exists:packages,id',
    ]);

    $packagesCount = Package::where('category_id', $validated['category_id'])
      ->whereIn('id', $validated['package_ids'])
      ->count();

    if ($packagesCount !== count($validated['package_ids'])) {
      return back()
        ->withInput()
        ->with('error', 'Semua paket yang dipilih harus berasal dari kategori yang sama.');
    }

    DB::transaction(function () use ($request, $discount, $validated) {
      $discount->update([
        'category_id' => $validated['category_id'],
        'promo_name' => $validated['promo_name'] ?? null,
        'discount_percent' => $validated['discount_percent'],
        'discount_start_at' => $validated['discount_start_at'] ?? null,
        'discount_end_at' => $validated['discount_end_at'] ?? null,
        'is_active' => $request->boolean('is_active'),
      ]);

      $discount->packages()->sync($validated['package_ids']);
    });

    return redirect()
      ->route('admin.packages.index', ['category' => $validated['category_id']])
      ->with('success', 'Diskon berhasil diperbarui.');
  }

  public function toggleStatus(Request $request, Discount $discount)
  {
    $discount->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', ['category' => $discount->category_id])
      ->with('success', 'Status diskon berhasil diperbarui.');
  }
}
