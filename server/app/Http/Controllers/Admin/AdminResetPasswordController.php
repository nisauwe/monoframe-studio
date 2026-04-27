<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

class AdminResetPasswordController extends Controller
{
  public function showResetForm(Request $request, string $token)
  {
    return view('admin.auth.reset-password', [
      'token' => $token,
      'email' => $request->email,
    ]);
  }

  public function reset(Request $request)
  {
    $request->validate([
      'token' => ['required'],
      'email' => ['required', 'email'],
      'password' => ['required', 'confirmed', 'min:8'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'password.required' => 'Password wajib diisi.',
      'password.confirmed' => 'Konfirmasi password tidak cocok.',
      'password.min' => 'Password minimal 8 karakter.',
    ]);

    $user = User::where('email', $request->email)
      ->where('role', 'Admin')
      ->first();

    if (!$user) {
      return back()->withErrors([
        'email' => 'Email admin tidak ditemukan.',
      ]);
    }

    $status = Password::reset(
      $request->only('email', 'password', 'password_confirmation', 'token'),
      function (User $user, string $password) {
        $user->forceFill([
          'password' => Hash::make($password),
          'remember_token' => Str::random(60),
        ])->save();

        event(new PasswordReset($user));
      }
    );

    return $status === Password::PASSWORD_RESET
      ? redirect()->route('admin.login')->with('status', __($status))
      : back()->withErrors(['email' => [__($status)]]);
  }
}
