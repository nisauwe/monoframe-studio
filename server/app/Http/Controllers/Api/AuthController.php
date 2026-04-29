<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\AuthOtpMail;
use App\Models\AppSetting;
use App\Models\EmailOtp;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
  private int $otpMinutes = 10;
  private int $resendSeconds = 60;
  private int $maxAttempts = 5;

  public function requestRegisterOtp(Request $request)
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
    ], [
      'name.required' => 'Nama wajib diisi.',
      'username.required' => 'Username wajib diisi.',
      'username.unique' => 'Username sudah digunakan.',
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'email.unique' => 'Email sudah terdaftar.',
      'phone.required' => 'Nomor WhatsApp wajib diisi.',
      'address.required' => 'Alamat wajib diisi.',
      'password.required' => 'Password wajib diisi.',
      'password.min' => 'Password minimal 8 karakter.',
      'password.confirmed' => 'Konfirmasi password tidak sama.',
    ]);

    $latest = EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'register')
      ->latest()
      ->first();

    if ($latest && !$latest->canResend()) {
      $seconds = now()->diffInSeconds($latest->resend_available_at, false);

      return response()->json([
        'message' => 'Kode OTP baru bisa dikirim ulang dalam ' . max($seconds, 1) . ' detik.',
      ], 429);
    }

    $code = $this->generateOtp();

    EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'register')
      ->delete();

    EmailOtp::create([
      'email' => $validated['email'],
      'purpose' => 'register',
      'code_hash' => Hash::make($code),
      'payload' => [
        'name' => $validated['name'],
        'username' => $validated['username'],
        'email' => $validated['email'],
        'phone' => $validated['phone'],
        'address' => $validated['address'],
        'password_hash' => Hash::make($validated['password']),
        'role' => $setting->default_client_role ?: 'Klien',
      ],
      'attempts' => 0,
      'expires_at' => now()->addMinutes($this->otpMinutes),
      'resend_available_at' => now()->addSeconds($this->resendSeconds),
      'ip_address' => $request->ip(),
    ]);

    Mail::to($validated['email'])->send(new AuthOtpMail(
      code: $code,
      title: 'Kode OTP Registrasi Monoframe',
      messageText: 'Gunakan kode OTP berikut untuk menyelesaikan pendaftaran akun klien Monoframe Studio.',
      minutes: $this->otpMinutes
    ));

    return response()->json([
      'message' => 'Kode OTP sudah dikirim ke email. Silakan cek inbox atau spam.',
      'email' => $validated['email'],
      'expires_in_minutes' => $this->otpMinutes,
    ]);
  }

  public function verifyRegisterOtp(Request $request)
  {
    $validated = $request->validate([
      'email' => ['required', 'email'],
      'otp' => ['required', 'digits:6'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'otp.required' => 'Kode OTP wajib diisi.',
      'otp.digits' => 'Kode OTP harus 6 digit.',
    ]);

    $otp = EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'register')
      ->latest()
      ->first();

    if (!$otp) {
      return response()->json([
        'message' => 'Kode OTP tidak ditemukan. Silakan kirim ulang OTP.',
      ], 404);
    }

    if ($otp->isExpired()) {
      $otp->delete();

      return response()->json([
        'message' => 'Kode OTP sudah kedaluwarsa. Silakan kirim ulang OTP.',
      ], 422);
    }

    if ($otp->attempts >= $this->maxAttempts) {
      $otp->delete();

      return response()->json([
        'message' => 'Percobaan OTP terlalu banyak. Silakan kirim ulang OTP.',
      ], 429);
    }

    if (!Hash::check($validated['otp'], $otp->code_hash)) {
      $otp->increment('attempts');

      return response()->json([
        'message' => 'Kode OTP salah.',
      ], 422);
    }

    $payload = $otp->payload ?? [];

    if (empty($payload['email']) || empty($payload['password_hash'])) {
      $otp->delete();

      return response()->json([
        'message' => 'Data registrasi tidak valid. Silakan daftar ulang.',
      ], 422);
    }

    $user = DB::transaction(function () use ($payload, $otp) {
      if (User::where('email', $payload['email'])->exists()) {
        throw ValidationException::withMessages([
          'email' => ['Email sudah terdaftar.'],
        ]);
      }

      if (User::where('username', $payload['username'])->exists()) {
        throw ValidationException::withMessages([
          'username' => ['Username sudah digunakan.'],
        ]);
      }

      $user = User::create([
        'name' => $payload['name'],
        'username' => $payload['username'],
        'email' => $payload['email'],
        'phone' => $payload['phone'],
        'address' => $payload['address'],
        'role' => $payload['role'] ?? 'Klien',
        'is_active' => true,
        'email_verified_at' => now(),
        'password' => $payload['password_hash'],
      ]);

      EmailOtp::where('email', $payload['email'])
        ->where('purpose', 'register')
        ->delete();

      return $user;
    });

    $token = $user->createToken('flutter-client')->plainTextToken;

    return response()->json([
      'message' => 'Registrasi berhasil dan email sudah diverifikasi.',
      'token' => $token,
      'user' => $user,
    ], 201);
  }

  public function requestPasswordResetOtp(Request $request)
  {
    $validated = $request->validate([
      'email' => ['required', 'email'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
    ]);

    $user = User::where('email', $validated['email'])->first();

    if (!$user) {
      return response()->json([
        'message' => 'Email tidak ditemukan.',
      ], 404);
    }

    if (!$user->is_active) {
      return response()->json([
        'message' => 'Akun sedang dinonaktifkan.',
      ], 403);
    }

    $latest = EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'reset_password')
      ->latest()
      ->first();

    if ($latest && !$latest->canResend()) {
      $seconds = now()->diffInSeconds($latest->resend_available_at, false);

      return response()->json([
        'message' => 'Kode OTP baru bisa dikirim ulang dalam ' . max($seconds, 1) . ' detik.',
      ], 429);
    }

    $code = $this->generateOtp();

    EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'reset_password')
      ->delete();

    EmailOtp::create([
      'email' => $validated['email'],
      'purpose' => 'reset_password',
      'code_hash' => Hash::make($code),
      'payload' => null,
      'attempts' => 0,
      'expires_at' => now()->addMinutes($this->otpMinutes),
      'resend_available_at' => now()->addSeconds($this->resendSeconds),
      'ip_address' => $request->ip(),
    ]);

    Mail::to($validated['email'])->send(new AuthOtpMail(
      code: $code,
      title: 'Kode OTP Reset Password Monoframe',
      messageText: 'Gunakan kode OTP berikut untuk mengganti password akun Monoframe Studio Anda.',
      minutes: $this->otpMinutes
    ));

    return response()->json([
      'message' => 'Kode OTP reset password sudah dikirim ke email.',
      'email' => $validated['email'],
      'expires_in_minutes' => $this->otpMinutes,
    ]);
  }

  public function resetPasswordWithOtp(Request $request)
  {
    $validated = $request->validate([
      'email' => ['required', 'email'],
      'otp' => ['required', 'digits:6'],
      'password' => ['required', 'string', 'min:8', 'confirmed'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'otp.required' => 'Kode OTP wajib diisi.',
      'otp.digits' => 'Kode OTP harus 6 digit.',
      'password.required' => 'Password baru wajib diisi.',
      'password.min' => 'Password baru minimal 8 karakter.',
      'password.confirmed' => 'Konfirmasi password tidak sama.',
    ]);

    $user = User::where('email', $validated['email'])->first();

    if (!$user) {
      return response()->json([
        'message' => 'Email tidak ditemukan.',
      ], 404);
    }

    $otp = EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'reset_password')
      ->latest()
      ->first();

    if (!$otp) {
      return response()->json([
        'message' => 'Kode OTP tidak ditemukan. Silakan kirim ulang OTP.',
      ], 404);
    }

    if ($otp->isExpired()) {
      $otp->delete();

      return response()->json([
        'message' => 'Kode OTP sudah kedaluwarsa. Silakan kirim ulang OTP.',
      ], 422);
    }

    if ($otp->attempts >= $this->maxAttempts) {
      $otp->delete();

      return response()->json([
        'message' => 'Percobaan OTP terlalu banyak. Silakan kirim ulang OTP.',
      ], 429);
    }

    if (!Hash::check($validated['otp'], $otp->code_hash)) {
      $otp->increment('attempts');

      return response()->json([
        'message' => 'Kode OTP salah.',
      ], 422);
    }

    $user->forceFill([
      'password' => $validated['password'],
    ])->save();

    EmailOtp::where('email', $validated['email'])
      ->where('purpose', 'reset_password')
      ->delete();

    $user->tokens()->delete();

    return response()->json([
      'message' => 'Password berhasil diganti. Silakan login menggunakan password baru.',
    ]);
  }

  public function register(Request $request)
  {
    return $this->requestRegisterOtp($request);
  }

  public function login(Request $request)
  {
    $request->validate([
      'email' => ['required', 'email'],
      'password' => ['required'],
    ], [
      'email.required' => 'Email wajib diisi.',
      'email.email' => 'Format email tidak valid.',
      'password.required' => 'Password wajib diisi.',
    ]);

    $user = User::where('email', $request->email)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
      return response()->json([
        'message' => 'Email atau password salah.',
      ], 401);
    }

    if (!$user->is_active) {
      return response()->json([
        'message' => 'Akun dinonaktifkan.',
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

  private function generateOtp(): string
  {
    return (string) random_int(100000, 999999);
  }
}
