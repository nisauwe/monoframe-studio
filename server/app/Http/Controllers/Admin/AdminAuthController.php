<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminAuthController extends Controller
{
  public function showLoginForm()
  {
    if (Auth::check() && Auth::user()->role === 'Admin') {
      return redirect()->route('admin.dashboard');
    }

    return view('admin.auth.login');
  }

  public function login(Request $request)
  {
    $credentials = $request->validate([
      'email' => ['required', 'email'],
      'password' => ['required'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'password.required' => 'Password wajib diisi.',
    ]);

    if (!Auth::attempt($credentials, $request->boolean('remember'))) {
      return back()->withErrors([
        'email' => 'Email atau password salah.',
      ])->withInput();
    }

    $request->session()->regenerate();

    $user = Auth::user();

    if (($user->role ?? null) !== 'Admin') {
      Auth::logout();

      return back()->withErrors([
        'email' => 'Akun ini tidak memiliki akses ke panel admin.',
      ])->withInput();
    }

    if (isset($user->is_active) && !$user->is_active) {
      Auth::logout();

      return back()->withErrors([
        'email' => 'Akun admin sedang dinonaktifkan.',
      ])->withInput();
    }

    return redirect()->route('admin.dashboard');
  }

  public function logout(Request $request)
  {
    Auth::logout();

    $request->session()->invalidate();
    $request->session()->regenerateToken();

    return redirect()->route('admin.login');
  }
}
