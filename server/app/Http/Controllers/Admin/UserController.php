<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
  public function index(Request $request)
  {
    $search = trim($request->input('search', ''));
    $role = trim($request->input('role', ''));

    $query = User::query();

    if ($search !== '') {
      $query->where(function ($q) use ($search) {
        $q->where('name', 'like', "%{$search}%")
          ->orWhere('email', 'like', "%{$search}%");
      });
    }

    if ($role !== '') {
      $query->where('role', $role);
    }

    $users = $query->latest()->paginate(10)->withQueryString();

    $totalUsers = User::count();

    $newUsers = User::whereMonth('created_at', now()->month)
      ->whereYear('created_at', now()->year)
      ->count();

    $activeUsers = User::where('is_active', true)->count();

    return view('admin.users.index', compact(
      'users',
      'totalUsers',
      'newUsers',
      'activeUsers',
      'search',
      'role'
    ));
  }

  public function create()
  {
    return view('admin.users.create');
  }

  public function store(Request $request)
  {
    $validated = $request->validate([
      'username' => ['required', 'string', 'max:255', 'unique:users,username'],
      'name' => ['required', 'string', 'max:255'],
      'email' => ['required', 'email', 'max:255', 'unique:users,email'],
      'phone' => ['required', 'string', 'max:20'],
      'address' => ['required', 'string'],
      'role' => ['required', 'string'],
      'password' => ['required', 'confirmed', 'min:8'],
    ], [
      'username.required' => 'Username wajib diisi.',
      'username.unique' => 'Username sudah digunakan.',
      'name.required' => 'Nama wajib diisi.',
      'email.required' => 'Email wajib diisi.',
      'email.unique' => 'Email sudah digunakan.',
      'phone.required' => 'Nomor HP wajib diisi.',
      'address.required' => 'Alamat wajib diisi.',
      'role.required' => 'Role wajib dipilih.',
      'password.required' => 'Password wajib diisi.',
      'password.confirmed' => 'Konfirmasi password tidak cocok.',
      'password.min' => 'Password minimal 8 karakter.',
    ]);

    User::create([
      'username' => $validated['username'],
      'name' => $validated['name'],
      'email' => $validated['email'],
      'phone' => $validated['phone'],
      'address' => $validated['address'],
      'role' => $validated['role'],
      'is_active' => true,
      'password' => Hash::make($validated['password']),
    ]);

    return redirect()
      ->route('admin.users.index')
      ->with('success', 'User berhasil ditambahkan.');
  }

  public function edit(User $user)
  {
    return view('admin.users.edit', compact('user'));
  }

  public function update(Request $request, User $user)
  {
    $validated = $request->validate([
      'username' => ['required', 'string', 'max:255', 'unique:users,username,' . $user->id],
      'name' => ['required', 'string', 'max:255'],
      'email' => ['required', 'email', 'max:255', 'unique:users,email,' . $user->id],
      'phone' => ['required', 'string', 'max:20'],
      'address' => ['required', 'string'],
      'role' => ['required', 'string'],
      'is_active' => ['nullable', 'boolean'],
    ], [
      'username.required' => 'Username wajib diisi.',
      'username.unique' => 'Username sudah digunakan.',
      'name.required' => 'Nama wajib diisi.',
      'email.required' => 'Email wajib diisi.',
      'email.unique' => 'Email sudah digunakan.',
      'phone.required' => 'Nomor HP wajib diisi.',
      'address.required' => 'Alamat wajib diisi.',
      'role.required' => 'Role wajib dipilih.',
    ]);

    $user->update([
      'username' => $validated['username'],
      'name' => $validated['name'],
      'email' => $validated['email'],
      'phone' => $validated['phone'],
      'address' => $validated['address'],
      'role' => $validated['role'],
      'is_active' => $request->has('is_active'),
    ]);

    return redirect()
      ->route('admin.users.index')
      ->with('success', 'Data user berhasil diperbarui.');
  }

  public function destroy(User $user)
  {
    if (strtolower($user->role) === 'admin') {
      return redirect()
        ->route('admin.users.index')
        ->with('success', 'User dengan role Admin tidak boleh dihapus.');
    }

    $user->delete();

    return redirect()
      ->route('admin.users.index')
      ->with('success', 'User berhasil dihapus.');
  }

  public function resetAll()
  {
    $deletedCount = User::whereRaw('LOWER(role) != ?', ['admin'])->delete();

    return redirect()
      ->route('admin.users.index')
      ->with('success', "{$deletedCount} data user non-admin berhasil dihapus. Data Admin tetap aman.");
  }

  public function exportExcel(Request $request)
  {
    $users = $this->getExportUsers($request);

    $fileName = 'data-user-monoframe-' . now()->format('Y-m-d-H-i-s') . '.xls';

    return response()
      ->view('admin.users.exports.excel', compact('users'))
      ->header('Content-Type', 'application/vnd.ms-excel; charset=UTF-8')
      ->header('Content-Disposition', 'attachment; filename="' . $fileName . '"')
      ->header('Cache-Control', 'max-age=0');
  }

  public function exportPdf(Request $request)
  {
    $users = $this->getExportUsers($request);

    $fileName = 'data-user-monoframe-' . now()->format('Y-m-d-H-i-s') . '.pdf';

    $pdf = Pdf::loadView('admin.users.exports.pdf', compact('users'))
      ->setPaper('a4', 'landscape');

    return $pdf->download($fileName);
  }

  private function getExportUsers(Request $request)
  {
    $search = trim($request->input('search', ''));
    $role = trim($request->input('role', ''));

    $query = User::query();

    if ($search !== '') {
      $query->where(function ($q) use ($search) {
        $q->where('name', 'like', "%{$search}%")
          ->orWhere('email', 'like', "%{$search}%");
      });
    }

    if ($role !== '') {
      $query->where('role', $role);
    }

    return $query
      ->select('name', 'email', 'role', 'phone', 'created_at')
      ->orderBy('created_at', 'desc')
      ->get();
  }
}