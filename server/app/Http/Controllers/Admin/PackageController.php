<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Package;
use App\Models\Discount;
use App\Models\PrintPrice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

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
    $totalPhotoPackages = Package::count();
    $totalPrintPrices = PrintPrice::count();

    $activeCategories = Category::where('is_active', true)->count();

    $activePackages = Package::where('is_active', true)->count();

    $discountPackages = Discount::where('is_active', true)
      ->whereHas('packages')
      ->count();

    if ($request->filled('category')) {
      $selectedCategory = Category::find($request->category);
    }

    /*
    |--------------------------------------------------------------------------
    | Paket Foto
    |--------------------------------------------------------------------------
    | Di tab paket foto, semua paket di-load dulu.
    | Filter kategori dilakukan realtime di frontend dengan JavaScript,
    | jadi klik kategori tidak refresh halaman.
    */
    if ($activeTab === 'photo-packages') {
      $packages = Package::with(['category', 'discounts'])
        ->orderBy('name')
        ->get();
    }

    /*
    |--------------------------------------------------------------------------
    | Diskon
    |--------------------------------------------------------------------------
    | Diskon tetap boleh pakai filter kategori dari URL.
    */
    if ($activeTab === 'discounts') {
      $discountsQuery = Discount::with(['category', 'packages'])
        ->latest();

      if ($selectedCategory) {
        $discountsQuery->where('category_id', $selectedCategory->id);
      }

      $discounts = $discountsQuery->get();
    }

    $printPrices = PrintPrice::query()
      ->latest()
      ->get();

    $activePrintPrices = PrintPrice::where('is_active', true)->count();
    $inactivePrintPrices = PrintPrice::where('is_active', false)->count();

    return view('admin.packages.index', compact(
      'activeTab',
      'activeCategories',
      'categories',
      'selectedCategory',
      'packages',
      'discounts',
      'totalCategories',
      'totalPhotoPackages',
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
    $categories = Category::where('is_active', true)
      ->orderBy('name')
      ->get();

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
      ->route('admin.packages.index', [
        'tab' => 'photo-packages',
      ])
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
          'remove_portfolio' => 'nullable|array',
          'remove_portfolio.*' => 'nullable|string',
          'description' => 'nullable|string',
          'is_active' => 'nullable|boolean',
      ]);

      $validated['is_active'] = $request->boolean('is_active');

      $currentPortfolio = is_array($package->portfolio)
          ? $package->portfolio
          : [];

      $removedPortfolio = $request->input('remove_portfolio', []);

      if (!empty($removedPortfolio)) {
          foreach ($removedPortfolio as $removedImage) {
              if (in_array($removedImage, $currentPortfolio, true)) {
                  Storage::disk('public')->delete($removedImage);
              }
          }

          $currentPortfolio = array_values(array_filter($currentPortfolio, function ($image) use ($removedPortfolio) {
              return !in_array($image, $removedPortfolio, true);
          }));
      }

      $newPortfolioPaths = [];

      if ($request->hasFile('portfolio')) {
          foreach ($request->file('portfolio') as $image) {
              $newPortfolioPaths[] = $image->store('packages/portfolio', 'public');
          }
      }

      $finalPortfolio = array_values(array_merge($currentPortfolio, $newPortfolioPaths));

      if (count($finalPortfolio) > 20) {
          return back()
              ->withErrors([
                  'portfolio' => 'Maksimal total 20 gambar portofolio.',
              ])
              ->withInput();
      }

      $validated['portfolio'] = !empty($finalPortfolio) ? $finalPortfolio : null;

      unset($validated['remove_portfolio']);

      $package->update($validated);

      return redirect()
          ->route('admin.packages.index', [
              'tab' => 'photo-packages',
          ])
          ->with('success', 'Paket berhasil diperbarui.');
  }

  public function destroy(Package $package)
  {
    $package->delete();

    return redirect()
      ->route('admin.packages.index', [
        'tab' => 'photo-packages',
      ])
      ->with('success', 'Paket berhasil dihapus.');
  }

  public function toggleStatus(Request $request, Package $package)
  {
    $package->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', [
        'tab' => 'photo-packages',
      ])
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
      ->route('admin.packages.index', [
        'tab' => 'photo-packages',
      ])
      ->with('success', 'Diskon paket berhasil diperbarui.');
  }

  public function toggleDiscount(Request $request, Package $package)
  {
    $package->update([
      'is_discount_active' => $request->boolean('is_discount_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', [
        'tab' => 'photo-packages',
      ])
      ->with('success', 'Status diskon berhasil diperbarui.');
  }
}
