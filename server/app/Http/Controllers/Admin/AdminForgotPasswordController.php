<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;

class AdminForgotPasswordController extends Controller
{
  public function showLinkRequestForm()
  {
    return view('admin.auth.forgot-password');
  }

  public function sendResetLinkEmail(Request $request)
  {
    $request->validate([
      'email' => ['required', 'email'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
    ]);

    $user = User::where('email', $request->email)
      ->where('role', 'Admin')
      ->first();

    if (!$user) {
      return back()->withErrors([
        'email' => 'Email admin tidak ditemukan.',
      ])->withInput();
    }

    if (isset($user->is_active) && !$user->is_active) {
      return back()->withErrors([
        'email' => 'Akun admin sedang dinonaktifkan.',
      ])->withInput();
    }

    $status = Password::sendResetLink([
      'email' => $request->email,
    ]);

    return $status === Password::RESET_LINK_SENT
      ? back()->with('status', __($status))
      : back()->withErrors(['email' => __($status)]);
  }
}
