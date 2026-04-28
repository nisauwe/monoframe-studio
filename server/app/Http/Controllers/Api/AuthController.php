<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
  public function register(Request $request)
  {
    $setting = AppSetting::current();

    if (!$setting->allow_client_registration) {
      return response()->json([
        'message' => 'Registrasi klien sedang dinonaktifkan oleh admin.',
      ], 403);
    }

    $validated = $request->validate([
      'name' => ['required', 'string', 'max:255'],
      'username' => ['required', 'string', 'max:100', 'unique:users,username'],
      'email' => ['required', 'email', 'max:255', 'unique:users,email'],
      'phone' => ['required', 'string', 'max:20'],
      'address' => ['required', 'string'],
      'password' => ['required', 'string', 'min:8', 'confirmed'],
    ]);

    $user = User::create([
      'name' => $validated['name'],
      'username' => $validated['username'],
      'email' => $validated['email'],
      'phone' => $validated['phone'],
      'address' => $validated['address'],
      'role' => $setting->default_client_role ?: 'Klien',
      'is_active' => true,
      'password' => $validated['password'],
    ]);

    $token = $user->createToken('flutter-client')->plainTextToken;

    return response()->json([
      'message' => 'Registrasi berhasil',
      'token' => $token,
      'user' => $user,
    ], 201);
  }

  public function login(Request $request)
  {
    $request->validate([
      'email' => ['required', 'email'],
      'password' => ['required'],
    ]);

    $user = User::where('email', $request->email)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
      throw ValidationException::withMessages([
        'email' => ['Email atau password salah.'],
      ]);
    }

    if (!$user->is_active) {
      return response()->json([
        'message' => 'Akun dinonaktifkan'
      ], 403);
    }

    $token = $user->createToken('flutter-client')->plainTextToken;

    return response()->json([
      'message' => 'Login berhasil',
      'token' => $token,
      'user' => $user,
    ]);
  }

  public function me(Request $request)
  {
    return response()->json([
      'user' => $request->user(),
    ]);
  }

  public function logout(Request $request)
  {
    $request->user()->currentAccessToken()?->delete();

    return response()->json([
      'message' => 'Logout berhasil'
    ]);
  }
}
