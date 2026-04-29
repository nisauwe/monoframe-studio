<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentGateway;
use App\Models\PaymentGatewayLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class PaymentGatewayController extends Controller
{
  public function index()
  {
    $gateway = PaymentGateway::firstOrCreate(
      ['provider' => 'midtrans'],
      $this->defaultGatewayData()
    );

    $logs = $gateway->logs()
      ->latest()
      ->take(10)
      ->get();

    $availablePaymentTypes = $this->availablePaymentTypes();

    return view('admin.payment-gateway.index', compact(
      'gateway',
      'logs',
      'availablePaymentTypes'
    ));
  }

  public function update(Request $request)
  {
    $gateway = PaymentGateway::firstOrCreate(
      ['provider' => 'midtrans'],
      $this->defaultGatewayData()
    );

    /*
    |--------------------------------------------------------------------------
    | Normalisasi URL sebelum validasi
    |--------------------------------------------------------------------------
    | Tujuannya:
    | - Jika kosong, simpan null.
    | - Jika user isi 127.0.0.1:8000/api/midtrans/notification,
    |   otomatis menjadi http://127.0.0.1:8000/api/midtrans/notification.
    | - Jika user isi domain tanpa protocol, otomatis menjadi https://domain.
    */
    $request->merge([
      'notification_url' => $this->normalizeNullableUrl($request->input('notification_url')),
      'finish_url' => $this->normalizeNullableUrl($request->input('finish_url')),
      'unfinish_url' => $this->normalizeNullableUrl($request->input('unfinish_url')),
      'error_url' => $this->normalizeNullableUrl($request->input('error_url')),
    ]);

    $validated = $request->validate([
      'environment' => ['required', 'in:sandbox,production'],
      'merchant_id' => ['nullable', 'string', 'max:255'],
      'client_key' => ['nullable', 'string'],
      'server_key' => ['nullable', 'string'],

      /*
      |--------------------------------------------------------------------------
      | Jangan pakai rule bawaan "url"
      |--------------------------------------------------------------------------
      | Rule bawaan Laravel sering membuat URL development seperti localhost /
      | 127.0.0.1 merepotkan. Kita pakai validasi custom agar lebih jelas.
      */
      'notification_url' => ['nullable', 'string', 'max:2048', $this->validHttpUrlRule('Notification URL')],
      'finish_url' => ['nullable', 'string', 'max:2048', $this->validHttpUrlRule('Success Redirect URL')],
      'unfinish_url' => ['nullable', 'string', 'max:2048', $this->validHttpUrlRule('Unfinish Redirect URL')],
      'error_url' => ['nullable', 'string', 'max:2048', $this->validHttpUrlRule('Error Redirect URL')],

      'expiry_minutes' => ['required', 'integer', 'min:1', 'max:1440'],
      'admin_fee' => ['required', 'integer', 'min:0'],
      'enabled_payment_types' => ['nullable', 'array'],
      'enabled_payment_types.*' => [
        'string',
        'in:' . implode(',', array_keys($this->availablePaymentTypes())),
      ],
      'is_active' => ['nullable', 'boolean'],
      'auto_update_status' => ['nullable', 'boolean'],
      'is_visible_to_client' => ['nullable', 'boolean'],
      'webhook_enabled' => ['nullable', 'boolean'],
    ], [
      'environment.required' => 'Mode environment wajib dipilih.',
      'environment.in' => 'Mode environment harus sandbox atau production.',
      'expiry_minutes.required' => 'Expired payment wajib diisi.',
      'expiry_minutes.integer' => 'Expired payment harus berupa angka.',
      'expiry_minutes.min' => 'Expired payment minimal 1 menit.',
      'expiry_minutes.max' => 'Expired payment maksimal 1440 menit.',
      'admin_fee.required' => 'Biaya admin wajib diisi.',
      'admin_fee.integer' => 'Biaya admin harus berupa angka.',
      'admin_fee.min' => 'Biaya admin tidak boleh kurang dari 0.',
      'enabled_payment_types.array' => 'Channel pembayaran tidak valid.',
      'enabled_payment_types.*.in' => 'Ada channel pembayaran yang tidak dikenali.',
    ]);

    $environment = $validated['environment'];

    $gateway->update([
      'environment' => $environment,
      'merchant_id' => $validated['merchant_id'] ?? null,
      'client_key' => $validated['client_key'] ?? null,
      'server_key' => $validated['server_key'] ?? null,
      'notification_url' => $validated['notification_url'] ?? null,
      'finish_url' => $validated['finish_url'] ?? null,
      'unfinish_url' => $validated['unfinish_url'] ?? null,
      'error_url' => $validated['error_url'] ?? null,
      'expiry_minutes' => $validated['expiry_minutes'],
      'admin_fee' => $validated['admin_fee'],
      'enabled_payment_types' => $validated['enabled_payment_types'] ?? [],
      'is_active' => $request->boolean('is_active'),
      'auto_update_status' => $request->boolean('auto_update_status'),
      'is_visible_to_client' => $request->boolean('is_visible_to_client'),
      'webhook_enabled' => $request->boolean('webhook_enabled'),
      'snap_url' => $this->snapUrl($environment),
      'api_base_url' => $this->apiBaseUrl($environment),
    ]);

    PaymentGatewayLog::create([
      'payment_gateway_id' => $gateway->id,
      'activity' => 'Update Konfigurasi',
      'status' => 'saved',
      'message' => 'Konfigurasi payment gateway berhasil diperbarui.',
      'payload' => [
        'environment' => $gateway->environment,
        'merchant_id' => $gateway->merchant_id,
        'notification_url' => $gateway->notification_url,
        'enabled_payment_types' => $gateway->enabled_payment_types,
      ],
    ]);

    $message = 'Konfigurasi payment gateway berhasil disimpan.';

    if ($gateway->notification_url && $this->isLocalUrl($gateway->notification_url)) {
      $message .= ' Catatan: Notification URL masih memakai localhost / IP lokal. URL ini boleh untuk disimpan saat development, tetapi Midtrans tidak bisa mengirim callback ke localhost. Untuk testing callback pembayaran, gunakan URL publik dari ngrok atau cloudflared.';
    }

    return back()->with('success', $message);
  }

  public function testConnection()
  {
    $gateway = PaymentGateway::where('provider', 'midtrans')->first();

    if (!$gateway) {
      return back()->with('error', 'Konfigurasi gateway belum tersedia.');
    }

    if (!$gateway->server_key) {
      return back()->with('error', 'Server Key belum diisi.');
    }

    try {
      $dummyOrderId = 'PG-CONNECTION-TEST-' . Str::upper(Str::random(8));

      $response = Http::acceptJson()
        ->withBasicAuth($gateway->server_key, '')
        ->get($this->apiBaseUrl($gateway->environment) . "/v2/{$dummyOrderId}/status");

      /*
      |--------------------------------------------------------------------------
      | 404 tetap dianggap koneksi berhasil
      |--------------------------------------------------------------------------
      | Karena order dummy memang tidak ada di Midtrans.
      | Yang penting server key bisa menjangkau endpoint Midtrans.
      */
      if (in_array($response->status(), [200, 404], true)) {
        $gateway->update([
          'last_tested_at' => now(),
          'last_test_status' => 'success',
          'last_test_message' => 'Koneksi berhasil. Kredensial dapat menjangkau API Midtrans.',
        ]);

        PaymentGatewayLog::create([
          'payment_gateway_id' => $gateway->id,
          'activity' => 'Test API Gateway',
          'status' => 'success',
          'message' => 'Koneksi Midtrans berhasil diuji.',
          'payload' => [
            'http_status' => $response->status(),
            'response' => $response->json(),
          ],
        ]);

        return back()->with('success', 'Test koneksi berhasil. Kredensial Midtrans valid.');
      }

      $gateway->update([
        'last_tested_at' => now(),
        'last_test_status' => 'failed',
        'last_test_message' => 'Koneksi gagal. Periksa Server Key atau environment.',
      ]);

      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Test API Gateway',
        'status' => 'failed',
        'message' => 'Koneksi Midtrans gagal diuji.',
        'payload' => [
          'http_status' => $response->status(),
          'response' => $response->json(),
        ],
      ]);

      return back()->with('error', 'Test koneksi gagal. Periksa Server Key, Merchant ID, dan mode environment.');
    } catch (\Throwable $e) {
      $gateway->update([
        'last_tested_at' => now(),
        'last_test_status' => 'failed',
        'last_test_message' => $e->getMessage(),
      ]);

      PaymentGatewayLog::create([
        'payment_gateway_id' => $gateway->id,
        'activity' => 'Test API Gateway',
        'status' => 'failed',
        'message' => $e->getMessage(),
      ]);

      return back()->with('error', 'Terjadi error saat test koneksi: ' . $e->getMessage());
    }
  }

  public function resetConfig()
  {
    $gateway = PaymentGateway::where('provider', 'midtrans')->first();

    if (!$gateway) {
      return back()->with('error', 'Konfigurasi belum tersedia.');
    }

    $gateway->update($this->defaultGatewayData());

    PaymentGatewayLog::create([
      'payment_gateway_id' => $gateway->id,
      'activity' => 'Reset Konfigurasi',
      'status' => 'reset',
      'message' => 'Konfigurasi gateway dikembalikan ke default.',
    ]);

    return back()->with('success', 'Konfigurasi berhasil direset ke default.');
  }

  private function defaultGatewayData(): array
  {
    return [
      'environment' => 'sandbox',
      'merchant_id' => null,
      'client_key' => null,
      'server_key' => null,
      'snap_url' => $this->snapUrl('sandbox'),
      'api_base_url' => $this->apiBaseUrl('sandbox'),

      /*
      |--------------------------------------------------------------------------
      | Kosongkan default URL
      |--------------------------------------------------------------------------
      | URL callback harus disesuaikan dengan domain server yang sedang dipakai.
      | Untuk lokal gunakan ngrok/cloudflared.
      */
      'notification_url' => null,
      'finish_url' => null,
      'unfinish_url' => null,
      'error_url' => null,

      'expiry_minutes' => 60,
      'admin_fee' => 0,
      'enabled_payment_types' => ['qris', 'bank_transfer', 'gopay', 'bni_va', 'bca_va'],
      'is_active' => true,
      'auto_update_status' => true,
      'is_visible_to_client' => true,
      'webhook_enabled' => true,
    ];
  }

  private function snapUrl(string $environment): string
  {
    return $environment === 'production'
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';
  }

  private function apiBaseUrl(string $environment): string
  {
    return $environment === 'production'
      ? 'https://api.midtrans.com'
      : 'https://api.sandbox.midtrans.com';
  }

  private function availablePaymentTypes(): array
  {
    return [
      'qris' => [
        'label' => 'QRIS',
        'description' => 'Pembayaran via QRIS',
      ],
      'bank_transfer' => [
        'label' => 'Bank Transfer',
        'description' => 'VA / transfer bank',
      ],
      'gopay' => [
        'label' => 'GoPay',
        'description' => 'Pembayaran via GoPay',
      ],
      'shopeepay' => [
        'label' => 'ShopeePay',
        'description' => 'Pembayaran via ShopeePay',
      ],
      'credit_card' => [
        'label' => 'Credit Card',
        'description' => 'Kartu kredit/debit',
      ],
      'bni_va' => [
        'label' => 'BNI VA',
        'description' => 'Virtual account BNI',
      ],
      'bca_va' => [
        'label' => 'BCA VA',
        'description' => 'Virtual account BCA',
      ],
      'permata_va' => [
        'label' => 'Permata VA',
        'description' => 'Virtual account Permata',
      ],
    ];
  }

  private function normalizeNullableUrl($value): ?string
  {
    $value = trim((string) ($value ?? ''));

    if ($value === '') {
      return null;
    }

    // Hilangkan spasi yang tidak sengaja ikut tercopy.
    $value = preg_replace('/\s+/', '', $value);

    if (Str::startsWith($value, '//')) {
      return 'https:' . $value;
    }

    // Jika user tidak menulis http:// atau https://, tambahkan otomatis.
    if (!preg_match('/^https?:\/\//i', $value)) {
      $probeHost = parse_url('http://' . $value, PHP_URL_HOST);

      $scheme = $this->isLocalHostValue($probeHost)
        ? 'http://'
        : 'https://';

      return $scheme . $value;
    }

    return $value;
  }

  private function validHttpUrlRule(string $label): \Closure
  {
    return function (string $attribute, $value, \Closure $fail) use ($label): void {
      if ($value === null || $value === '') {
        return;
      }

      if (!is_string($value)) {
        $fail($label . ' harus berupa teks URL.');
        return;
      }

      if (preg_match('/\s/', $value)) {
        $fail($label . ' tidak boleh mengandung spasi.');
        return;
      }

      $parts = parse_url($value);

      if ($parts === false) {
        $fail($label . ' tidak valid.');
        return;
      }

      $scheme = strtolower($parts['scheme'] ?? '');
      $host = $parts['host'] ?? '';

      if (!in_array($scheme, ['http', 'https'], true)) {
        $fail($label . ' harus diawali http:// atau https://.');
        return;
      }

      if ($host === '') {
        $fail($label . ' harus memiliki host/domain yang jelas.');
        return;
      }

      if (Str::contains($host, '_')) {
        $fail($label . ' tidak boleh memakai underscore pada domain/host.');
        return;
      }
    };
  }

  private function isLocalUrl(?string $url): bool
  {
    if (!$url) {
      return false;
    }

    $host = parse_url($url, PHP_URL_HOST);

    return $this->isLocalHostValue($host);
  }

  private function isLocalHostValue(?string $host): bool
  {
    if (!$host) {
      return false;
    }

    $host = strtolower($host);

    return $host === 'localhost'
      || $host === '127.0.0.1'
      || $host === '::1'
      || Str::startsWith($host, '192.168.')
      || Str::startsWith($host, '10.')
      || preg_match('/^172\.(1[6-9]|2[0-9]|3[0-1])\./', $host);
  }
}
