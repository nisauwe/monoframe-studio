@extends('layouts/contentNavbarLayout')

@section('title', 'Payment Gateway')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    @if (session('success'))
      <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    @if (session('error'))
      <div class="alert alert-danger">{{ session('error') }}</div>
    @endif

    @if ($errors->any())
      <div class="alert alert-danger">
        <ul class="mb-0 ps-3">
          @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
          @endforeach
        </ul>
      </div>
    @endif

    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Payment Gateway</h4>
        <p class="text-muted mb-0">Kelola konfigurasi gateway pembayaran online untuk transaksi booking Monoframe Studio.
        </p>
      </div>

      <div class="d-flex gap-2">
        <form method="POST" action="{{ route('admin.payment-gateway.test') }}">
          @csrf
          <button type="submit" class="btn btn-outline-secondary">
            <i class="bx bx-refresh me-1"></i> Test Koneksi
          </button>
        </form>

        <button type="submit" form="gateway-config-form" class="btn btn-primary">
          <i class="bx bx-save me-1"></i> Simpan Konfigurasi
        </button>
      </div>
    </div>

    <div class="row">
      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Gateway Aktif</span>
                <h3 class="card-title mb-2">{{ ucfirst($gateway->provider) }}</h3>
                <small class="text-primary fw-semibold">Provider utama saat ini</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-primary">
                  <i class="bx bx-credit-card-front"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Mode Gateway</span>
                <h3 class="card-title mb-2">{{ ucfirst($gateway->environment) }}</h3>
                <small class="{{ $gateway->environment === 'sandbox' ? 'text-warning' : 'text-success' }} fw-semibold">
                  {{ $gateway->environment === 'sandbox' ? 'Masih dalam mode pengujian' : 'Siap dipakai transaksi asli' }}
                </small>
              </div>
              <div class="avatar">
                <span
                  class="avatar-initial rounded {{ $gateway->environment === 'sandbox' ? 'bg-label-warning' : 'bg-label-success' }}">
                  <i class="bx {{ $gateway->environment === 'sandbox' ? 'bx-flask' : 'bx-check-circle' }}"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Webhook Status</span>
                <h3 class="card-title mb-2">{{ $gateway->webhook_enabled ? 'Aktif' : 'Nonaktif' }}</h3>
                <small class="{{ $gateway->webhook_enabled ? 'text-success' : 'text-danger' }} fw-semibold">
                  {{ $gateway->webhook_enabled ? 'Callback pembayaran siap digunakan' : 'Webhook sedang dimatikan' }}
                </small>
              </div>
              <div class="avatar">
                <span
                  class="avatar-initial rounded {{ $gateway->webhook_enabled ? 'bg-label-success' : 'bg-label-danger' }}">
                  <i class="bx bx-link-alt"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <form id="gateway-config-form" method="POST" action="{{ route('admin.payment-gateway.update') }}">
      @csrf

      <div class="row">
        <div class="col-lg-8 mb-4">
          <div class="card h-100">
            <div class="card-header">
              <h5 class="mb-0">Konfigurasi Gateway</h5>
              <small class="text-muted">Atur kredensial dan parameter utama payment gateway.</small>
            </div>

            <div class="card-body">
              <div class="row">
                <div class="col-md-6 mb-3">
                  <label class="form-label">Provider Gateway</label>
                  <input type="text" class="form-control" value="Midtrans" disabled>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Mode Environment</label>
                  <select class="form-select" name="environment">
                    <option value="sandbox" {{ $gateway->environment === 'sandbox' ? 'selected' : '' }}>Sandbox</option>
                    <option value="production" {{ $gateway->environment === 'production' ? 'selected' : '' }}>Production
                    </option>
                  </select>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Merchant ID</label>
                  <input type="text" name="merchant_id" class="form-control"
                    value="{{ old('merchant_id', $gateway->merchant_id) }}">
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Client Key</label>
                  <input type="text" name="client_key" class="form-control"
                    value="{{ old('client_key', $gateway->client_key) }}">
                </div>

                <div class="col-12 mb-3">
                  <label class="form-label">Server Key</label>
                  <input type="text" name="server_key" class="form-control"
                    value="{{ old('server_key', $gateway->server_key) }}">
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Snap URL / Endpoint</label>
                  <input type="text" class="form-control" value="{{ $gateway->snap_url }}" readonly>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Expired Payment (Menit)</label>
                  <input type="number" name="expiry_minutes" class="form-control"
                    value="{{ old('expiry_minutes', $gateway->expiry_minutes) }}">
                </div>

                <div class="col-12 mb-3">
                  <label class="form-label">Callback / Notification URL</label>
                  <input type="text" name="notification_url" class="form-control"
                    value="{{ old('notification_url', $gateway->notification_url) }}">
                </div>

                <div class="col-md-4 mb-3">
                  <label class="form-label">Success Redirect URL</label>
                  <input type="text" name="finish_url" class="form-control"
                    value="{{ old('finish_url', $gateway->finish_url) }}">
                </div>

                <div class="col-md-4 mb-3">
                  <label class="form-label">Unfinish Redirect URL</label>
                  <input type="text" name="unfinish_url" class="form-control"
                    value="{{ old('unfinish_url', $gateway->unfinish_url) }}">
                </div>

                <div class="col-md-4 mb-3">
                  <label class="form-label">Error Redirect URL</label>
                  <input type="text" name="error_url" class="form-control"
                    value="{{ old('error_url', $gateway->error_url) }}">
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label">Biaya Admin Default</label>
                  <input type="number" name="admin_fee" class="form-control"
                    value="{{ old('admin_fee', $gateway->admin_fee) }}">
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label d-block">Status Gateway</label>
                  <div class="form-check form-switch mt-2">
                    <input class="form-check-input" type="checkbox" name="is_active" value="1"
                      {{ old('is_active', $gateway->is_active) ? 'checked' : '' }}>
                    <label class="form-check-label">Gateway Aktif</label>
                  </div>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label d-block">Auto Update Status Pembayaran</label>
                  <div class="form-check form-switch mt-2">
                    <input class="form-check-input" type="checkbox" name="auto_update_status" value="1"
                      {{ old('auto_update_status', $gateway->auto_update_status) ? 'checked' : '' }}>
                    <label class="form-check-label">Aktif</label>
                  </div>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label d-block">Tampilkan ke Klien</label>
                  <div class="form-check form-switch mt-2">
                    <input class="form-check-input" type="checkbox" name="is_visible_to_client" value="1"
                      {{ old('is_visible_to_client', $gateway->is_visible_to_client) ? 'checked' : '' }}>
                    <label class="form-check-label">Tampil di aplikasi</label>
                  </div>
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label d-block">Webhook Aktif</label>
                  <div class="form-check form-switch mt-2">
                    <input class="form-check-input" type="checkbox" name="webhook_enabled" value="1"
                      {{ old('webhook_enabled', $gateway->webhook_enabled) ? 'checked' : '' }}>
                    <label class="form-check-label">Listening</label>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-lg-4 mb-4">
          <div class="card mb-4">
            <div class="card-header">
              <h5 class="mb-0">Status Koneksi</h5>
              <small class="text-muted">Pantau status integrasi gateway</small>
            </div>
            <div class="card-body">
              <div class="mb-3">
                @php
                  $badgeClass = 'bg-label-secondary';
                  if ($gateway->last_test_status === 'success') {
                      $badgeClass = 'bg-label-success';
                  }
                  if ($gateway->last_test_status === 'failed') {
                      $badgeClass = 'bg-label-danger';
                  }
                @endphp
                <span class="badge {{ $badgeClass }}">
                  {{ $gateway->last_test_status ? ucfirst($gateway->last_test_status) : 'Belum dites' }}
                </span>
              </div>

              <ul class="list-unstyled mb-0">
                <li class="mb-3">
                  <small class="text-muted d-block">Provider</small>
                  <strong>{{ ucfirst($gateway->provider) }}</strong>
                </li>
                <li class="mb-3">
                  <small class="text-muted d-block">Environment</small>
                  <strong>{{ ucfirst($gateway->environment) }}</strong>
                </li>
                <li class="mb-3">
                  <small class="text-muted d-block">Webhook</small>
                  <strong class="{{ $gateway->webhook_enabled ? 'text-success' : 'text-danger' }}">
                    {{ $gateway->webhook_enabled ? 'Listening' : 'Disabled' }}
                  </strong>
                </li>
                <li class="mb-3">
                  <small class="text-muted d-block">Last Sync</small>
                  <strong>{{ $gateway->last_tested_at ? $gateway->last_tested_at->format('d M Y, H:i') : '-' }}</strong>
                </li>
                <li class="mb-0">
                  <small class="text-muted d-block">Pesan Tes Terakhir</small>
                  <strong>{{ $gateway->last_test_message ?: '-' }}</strong>
                </li>
              </ul>
            </div>
          </div>

          <div class="card">
            <div class="card-header">
              <h5 class="mb-0">Aksi Cepat</h5>
              <small class="text-muted">Shortcut pengujian gateway</small>
            </div>
            <div class="card-body d-grid gap-2">
              <form method="POST" action="{{ route('admin.payment-gateway.test') }}">
                @csrf
                <button type="submit" class="btn btn-outline-primary w-100">Tes API Gateway</button>
              </form>

              <button type="submit" form="gateway-config-form" class="btn btn-outline-success">Simpan
                Perubahan</button>

              <form method="POST" action="{{ route('admin.payment-gateway.reset') }}">
                @csrf
                <button type="submit" class="btn btn-outline-danger w-100">Reset Konfigurasi</button>
              </form>
            </div>
          </div>
        </div>
      </div>

      <div class="card mb-4">
        <div class="card-header">
          <h5 class="mb-0">Channel Pembayaran</h5>
          <small class="text-muted">Aktifkan channel yang diizinkan muncul saat checkout.</small>
        </div>

        <div class="card-body">
          <div class="row">
            @foreach ($availablePaymentTypes as $key => $paymentType)
              <div class="col-md-3 col-sm-6 mb-3">
                <div class="border rounded p-3 h-100">
                  <div class="d-flex justify-content-between align-items-center mb-2">
                    <h6 class="mb-0">{{ $paymentType['label'] }}</h6>
                    <div class="form-check form-switch m-0">
                      <input class="form-check-input" type="checkbox" name="enabled_payment_types[]"
                        value="{{ $key }}"
                        {{ in_array($key, old('enabled_payment_types', $gateway->enabled_payment_types ?? [])) ? 'checked' : '' }}>
                    </div>
                  </div>
                  <small class="text-muted">{{ $paymentType['description'] }}</small>
                </div>
              </div>
            @endforeach
          </div>
        </div>
      </div>
    </form>

    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Riwayat Aktivitas Gateway</h5>
        <small class="text-muted">Monitoring singkat aktivitas konfigurasi dan webhook.</small>
      </div>

      <div class="table-responsive text-nowrap">
        <table class="table">
          <thead>
            <tr>
              <th>Waktu</th>
              <th>Aktivitas</th>
              <th>Status</th>
              <th>Keterangan</th>
            </tr>
          </thead>
          <tbody class="table-border-bottom-0">
            @forelse($logs as $log)
              <tr>
                <td>{{ $log->created_at->format('d M Y H:i') }}</td>
                <td>{{ $log->activity }}</td>
                <td>
                  @php
                    $map = [
                        'success' => 'bg-label-success',
                        'failed' => 'bg-label-danger',
                        'saved' => 'bg-label-primary',
                        'reset' => 'bg-label-warning',
                        'info' => 'bg-label-secondary',
                    ];
                  @endphp
                  <span class="badge {{ $map[$log->status] ?? 'bg-label-secondary' }}">
                    {{ ucfirst($log->status) }}
                  </span>
                </td>
                <td>{{ $log->message }}</td>
              </tr>
            @empty
              <tr>
                <td colspan="4" class="text-center text-muted py-4">Belum ada riwayat aktivitas gateway.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>
    </div>
  </div>
@endsection
