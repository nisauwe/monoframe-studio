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

    $logs = PaymentGatewayLog::latest()->take(10)->get();

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

    $validated = $request->validate([
      'environment' => ['required', 'in:sandbox,production'],
      'merchant_id' => ['nullable', 'string', 'max:255'],
      'client_key' => ['nullable', 'string'],
      'server_key' => ['nullable', 'string'],
      'notification_url' => ['nullable', 'url'],
      'finish_url' => ['nullable', 'url'],
      'unfinish_url' => ['nullable', 'url'],
      'error_url' => ['nullable', 'url'],
      'expiry_minutes' => ['required', 'integer', 'min:1', 'max:1440'],
      'admin_fee' => ['required', 'integer', 'min:0'],
      'enabled_payment_types' => ['nullable', 'array'],
      'enabled_payment_types.*' => ['string', 'in:' . implode(',', array_keys($this->availablePaymentTypes()))],
      'is_active' => ['nullable', 'boolean'],
      'auto_update_status' => ['nullable', 'boolean'],
      'is_visible_to_client' => ['nullable', 'boolean'],
      'webhook_enabled' => ['nullable', 'boolean'],
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
        'enabled_payment_types' => $gateway->enabled_payment_types,
      ],
    ]);

    return back()->with('success', 'Konfigurasi payment gateway berhasil disimpan.');
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

      if (in_array($response->status(), [200, 404])) {
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
      'qris' => ['label' => 'QRIS', 'description' => 'Pembayaran via QRIS'],
      'bank_transfer' => ['label' => 'Bank Transfer', 'description' => 'VA / transfer bank'],
      'gopay' => ['label' => 'GoPay', 'description' => 'Pembayaran via GoPay'],
      'shopeepay' => ['label' => 'ShopeePay', 'description' => 'Pembayaran via ShopeePay'],
      'credit_card' => ['label' => 'Credit Card', 'description' => 'Kartu kredit/debit'],
      'bni_va' => ['label' => 'BNI VA', 'description' => 'Virtual account BNI'],
      'bca_va' => ['label' => 'BCA VA', 'description' => 'Virtual account BCA'],
      'permata_va' => ['label' => 'Permata VA', 'description' => 'Virtual account Permata'],
    ];
  }
}
