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
    $categories = Category::where('is_active', true)
      ->orderBy('name')
      ->get();

    $packages = Package::with('category')
      ->where('is_active', true)
      ->orderBy('name')
      ->get();

    $selectedCategory = null;

    if ($request->filled('category')) {
      $selectedCategory = Category::find($request->query('category'));
    }

    return view('admin.discounts.create', compact(
      'categories',
      'packages',
      'selectedCategory'
    ));
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'category_id' => ['required', 'exists:categories,id'],
      'promo_name' => ['nullable', 'string', 'max:255'],
      'discount_percent' => ['required', 'integer', 'min:1', 'max:100'],
      'discount_start_at' => ['nullable', 'date'],
      'discount_end_at' => ['nullable', 'date', 'after_or_equal:discount_start_at'],
      'is_active' => ['nullable', 'boolean'],
      'package_ids' => ['required', 'array', 'min:1'],
      'package_ids.*' => ['exists:packages,id'],
    ], [
      'category_id.required' => 'Kategori wajib dipilih.',
      'category_id.exists' => 'Kategori tidak valid.',
      'discount_percent.required' => 'Besar diskon wajib diisi.',
      'discount_percent.min' => 'Diskon minimal 1%.',
      'discount_percent.max' => 'Diskon maksimal 100%.',
      'discount_end_at.after_or_equal' => 'Tanggal selesai tidak boleh lebih awal dari tanggal mulai.',
      'package_ids.required' => 'Pilih minimal satu paket untuk diberi diskon.',
      'package_ids.min' => 'Pilih minimal satu paket untuk diberi diskon.',
      'package_ids.*.exists' => 'Paket yang dipilih tidak valid.',
    ]);

    $packagesCount = Package::where('category_id', $validated['category_id'])
      ->whereIn('id', $validated['package_ids'])
      ->count();

    if ($packagesCount !== count($validated['package_ids'])) {
      return back()
        ->withInput()
        ->with('error', 'Semua paket yang dipilih harus berasal dari kategori yang dipilih.');
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
      ->route('admin.packages.index', [
        'tab' => 'discounts',
      ])
      ->with('success', 'Diskon berhasil ditambahkan.');
  }

  public function edit(Discount $discount)
  {
      $discount->load(['category', 'packages']);

      $categories = Category::query()
          ->withCount('packages')
          ->orderBy('name')
          ->get();

      $packages = Package::query()
          ->with('category')
          ->where('is_active', true)
          ->orderBy('category_id')
          ->orderBy('name')
          ->get();

      $selectedCategory = $discount->category;
      $selectedPackageIds = $discount->packages->pluck('id')->toArray();

      return view('admin.discounts.edit', compact(
          'discount',
          'categories',
          'packages',
          'selectedCategory',
          'selectedPackageIds'
      ));
  }

  public function update(Request $request, Discount $discount)
  {
      $validated = $request->validate([
          'category_id' => ['required', 'exists:categories,id'],
          'promo_name' => ['nullable', 'string', 'max:255'],
          'discount_percent' => ['required', 'numeric', 'min:1', 'max:100'],
          'discount_start_at' => ['nullable', 'date'],
          'discount_end_at' => ['nullable', 'date', 'after_or_equal:discount_start_at'],
          'is_active' => ['nullable', 'boolean'],
          'package_ids' => ['required', 'array', 'min:1'],
          'package_ids.*' => ['exists:packages,id'],
      ], [
          'category_id.required' => 'Kategori wajib dipilih.',
          'package_ids.required' => 'Minimal pilih satu paket untuk diberi diskon.',
          'package_ids.min' => 'Minimal pilih satu paket untuk diberi diskon.',
          'discount_percent.required' => 'Besar diskon wajib diisi.',
          'discount_percent.min' => 'Diskon minimal 1%.',
          'discount_percent.max' => 'Diskon maksimal 100%.',
          'discount_end_at.after_or_equal' => 'Tanggal selesai tidak boleh lebih awal dari tanggal mulai.',
      ]);

      $validPackageIds = Package::query()
          ->where('category_id', $validated['category_id'])
          ->whereIn('id', $validated['package_ids'])
          ->pluck('id')
          ->toArray();

      if (empty($validPackageIds)) {
          return back()
              ->withInput()
              ->with('error', 'Paket yang dipilih tidak sesuai dengan kategori.');
      }

      $discount->update([
          'category_id' => $validated['category_id'],
          'promo_name' => $validated['promo_name'] ?? null,
          'discount_percent' => $validated['discount_percent'],
          'discount_start_at' => $validated['discount_start_at'] ?? null,
          'discount_end_at' => $validated['discount_end_at'] ?? null,
          'is_active' => $request->boolean('is_active'),
      ]);

      $discount->packages()->sync($validPackageIds);

      return redirect()
          ->route('admin.packages.index', [
              'tab' => 'discounts',
              'category' => $validated['category_id'],
          ])
          ->with('success', 'Diskon berhasil diperbarui.');
  }

  public function toggleStatus(Request $request, Discount $discount)
  {
    $discount->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', [
        'tab' => 'discounts',
      ])
      ->with('success', 'Status diskon berhasil diperbarui.');
  }
}
