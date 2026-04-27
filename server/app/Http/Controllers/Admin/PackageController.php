<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Package;
use App\Models\Discount;
use App\Models\PrintPrice;
use Illuminate\Http\Request;

class PackageController extends Controller
{
  public function index(Request $request)
  {
    $activeTab = $request->get('tab', 'categories');
    $selectedCategory = null;
    $packages = collect();
    $discounts = collect();

    $categories = Category::withCount('packages')
      ->orderBy('name')
      ->get();

    $totalCategories = Category::count();

    $activePackages = Package::where('is_active', true)->count();

    $discountPackages = Discount::where('is_active', true)
      ->whereHas('packages')
      ->count();

    if ($request->filled('category')) {
      $selectedCategory = Category::find($request->category);
    }

    if ($activeTab === 'photo-packages') {
      $packagesQuery = Package::with(['category', 'discounts'])->orderBy('name');

      if ($selectedCategory) {
        $packagesQuery->where('category_id', $selectedCategory->id);
      }

      $packages = $packagesQuery->get();
    }

    if ($activeTab === 'discounts') {
      $discountsQuery = Discount::with(['category', 'packages'])->latest();

      if ($selectedCategory) {
        $discountsQuery->where('category_id', $selectedCategory->id);
      }

      $discounts = $discountsQuery->get();
    }

    $printPrices = PrintPrice::query()
      ->latest()
      ->get();

    $totalPrintPrices = PrintPrice::count();
    $activePrintPrices = PrintPrice::where('is_active', true)->count();
    $inactivePrintPrices = PrintPrice::where('is_active', false)->count();

    return view('admin.packages.index', compact(
      'activeTab',
      'categories',
      'selectedCategory',
      'packages',
      'discounts',
      'totalCategories',
      'activePackages',
      'discountPackages',
      'printPrices',
      'totalPrintPrices',
      'activePrintPrices',
      'inactivePrintPrices'
    ));
  }
  public function create()
  {
    $categories = Category::where('is_active', true)->orderBy('name')->get();

    return view('admin.packages.create', compact('categories'));
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'category_id' => 'required|exists:categories,id',
      'name' => 'required|string|max:255',
      'price' => 'required|numeric|min:0',
      'photo_count' => 'required|integer|min:0',
      'duration_minutes' => 'required|integer|min:0',
      'location_type' => 'required|in:indoor,outdoor',
      'person_count' => 'nullable|integer|min:1',
      'portfolio' => 'nullable|array|max:20',
      'portfolio.*' => 'image|mimes:jpg,jpeg,png,webp|max:10240',
      'description' => 'nullable|string',
      'is_active' => 'nullable|boolean',
    ]);

    $validated['is_active'] = $request->boolean('is_active');

    $portfolioPaths = [];

    if ($request->hasFile('portfolio')) {
      foreach ($request->file('portfolio') as $image) {
        $portfolioPaths[] = $image->store('packages/portfolio', 'public');
      }
    }

    $validated['portfolio'] = !empty($portfolioPaths) ? $portfolioPaths : null;

    Package::create($validated);

    return redirect()
      ->route('admin.packages.index', ['category' => $validated['category_id']])
      ->with('success', 'Paket berhasil ditambahkan.');
  }
  public function edit(Package $package)
  {
    $categories = Category::where('is_active', true)
      ->orderBy('name')
      ->get();

    return view('admin.packages.edit', compact('package', 'categories'));
  }

  public function update(Request $request, Package $package)
  {
    $validated = $request->validate([
      'category_id' => 'required|exists:categories,id',
      'name' => 'required|string|max:255',
      'price' => 'required|numeric|min:0',
      'photo_count' => 'required|integer|min:0',
      'duration_minutes' => 'required|integer|min:0',
      'location_type' => 'required|in:indoor,outdoor',
      'person_count' => 'nullable|integer|min:1',
      'portfolio' => 'nullable|array|max:20',
      'portfolio.*' => 'image|mimes:jpg,jpeg,png,webp|max:10240',
      'description' => 'nullable|string',
      'is_active' => 'nullable|boolean',
    ]);

    $validated['is_active'] = $request->boolean('is_active');

    if ($request->hasFile('portfolio')) {
      $portfolioPaths = [];

      foreach ($request->file('portfolio') as $image) {
        $portfolioPaths[] = $image->store('packages/portfolio', 'public');
      }

      $validated['portfolio'] = $portfolioPaths;
    } else {
      unset($validated['portfolio']);
    }

    $package->update($validated);

    return redirect()
      ->route('admin.packages.index', ['category' => $validated['category_id']])
      ->with('success', 'Paket berhasil diperbarui.');
  }

  public function destroy(Package $package)
  {
    $categoryId = $package->category_id;

    $package->delete();

    return redirect()
      ->route('admin.packages.index', ['category' => $categoryId])
      ->with('success', 'Paket berhasil dihapus.');
  }

  public function toggleStatus(Request $request, Package $package)
  {
    $package->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', ['category' => $package->category_id])
      ->with('success', 'Status paket berhasil diperbarui.');
  }

  public function updateDiscount(Request $request)
  {
    $validated = $request->validate([
      'package_id' => 'required|exists:packages,id',
      'promo_name' => 'nullable|string|max:255',
      'discount_percent' => 'nullable|integer|min:0|max:100',
      'discount_start_at' => 'nullable|date',
      'discount_end_at' => 'nullable|date|after_or_equal:discount_start_at',
      'is_discount_active' => 'nullable|boolean',
    ]);

    $package = Package::findOrFail($validated['package_id']);

    $package->update([
      'promo_name' => $validated['promo_name'] ?? null,
      'discount_percent' => $validated['discount_percent'] ?? 0,
      'discount_start_at' => $validated['discount_start_at'] ?? null,
      'discount_end_at' => $validated['discount_end_at'] ?? null,
      'is_discount_active' => $request->boolean('is_discount_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', ['category' => $package->category_id])
      ->with('success', 'Diskon paket berhasil diperbarui.');
  }

  public function toggleDiscount(Request $request, Package $package)
  {
    $package->update([
      'is_discount_active' => $request->boolean('is_discount_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', ['category' => $package->category_id])
      ->with('success', 'Status diskon berhasil diperbarui.');
  }
}
