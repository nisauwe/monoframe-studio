<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
  public function create()
  {
    return view('admin.categories.create');
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'name' => ['required', 'string', 'max:255', 'unique:categories,name'],
      'description' => ['nullable', 'string'],
      'is_active' => ['nullable', 'boolean'],
    ], [
      'name.required' => 'Nama kategori wajib diisi.',
      'name.unique' => 'Nama kategori sudah digunakan.',
    ]);

    Category::create([
      'name' => $validated['name'],
      'description' => $validated['description'] ?? null,
      'is_active' => $request->has('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Kategori berhasil ditambahkan.');
  }
  public function toggleStatus(Request $request, Category $category)
  {
    $request->validate([
      'is_active' => 'required|boolean',
    ]);

    $category->update([
      'is_active' => $request->boolean('is_active'),
    ]);

    return redirect()
      ->route('admin.packages.index', ['category' => $category->id])
      ->with('success', 'Status kategori berhasil diperbarui.');
  }
  public function destroy(Category $category)
  {
    if ($category->packages()->exists()) {
      return redirect()
        ->route('admin.packages.index', ['category' => $category->id])
        ->with('error', 'Kategori tidak bisa dihapus karena masih memiliki paket.');
    }

    $category->delete();

    return redirect()
      ->route('admin.packages.index')
      ->with('success', 'Kategori berhasil dihapus.');
  }
}
