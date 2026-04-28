@extends('layouts/contentNavbarLayout')

@section('title', 'Payment Gateway')

@section('content')
  @php
    $environmentBadge = $gateway->environment === 'sandbox' ? 'warning' : 'success';
    $webhookBadge = $gateway->webhook_enabled ? 'success' : 'danger';
    $gatewayActiveBadge = $gateway->is_active ? 'success' : 'secondary';

    $lastTestBadge = match ($gateway->last_test_status) {
        'success' => 'success',
        'failed' => 'danger',
        default => 'secondary',
    };

    $logStatusClass = function ($status) {
        return match ($status) {
            'success' => 'success',
            'failed' => 'danger',
            'saved' => 'primary',
            'reset' => 'warning',
            'info' => 'secondary',
            default => 'secondary',
        };
    };

    $logIcon = function ($status) {
        return match ($status) {
            'success' => 'bx-check-circle',
            'failed' => 'bx-error-circle',
            'saved' => 'bx-save',
            'reset' => 'bx-reset',
            'info' => 'bx-info-circle',
            default => 'bx-bell',
        };
    };

    $rupiah = fn ($value) => 'Rp ' . number_format((float) ($value ?? 0), 0, ',', '.');
    $latestLogs = collect($logs ?? [])->take(4);
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell gateway-page">

      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <strong>Data belum valid.</strong>
          <ul class="mb-0 mt-2 ps-3">
            @foreach ($errors->all() as $error)
              <li>{{ $error }}</li>
            @endforeach
          </ul>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      {{-- HERO --}}
      <div class="gateway-hero-card mb-4">
        <div class="gateway-hero-left">
          <div class="gateway-hero-icon">
            <i class="bx bx-credit-card-front"></i>
          </div>

          <div>
            <div class="gateway-hero-kicker">AKSES PEMBAYARAN ONLINE</div>
            <h4>Payment Gateway</h4>
            <p>
              Kelola konfigurasi gateway pembayaran online untuk transaksi booking,
              pembayaran DP, pelunasan, dan callback status pembayaran Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="gateway-hero-actions">
          <form method="POST" action="{{ route('admin.payment-gateway.test') }}">
            @csrf
            <button type="submit" class="btn gateway-hero-btn gateway-hero-btn-outline">
              <i class="bx bx-refresh me-1"></i>
              Test Koneksi
            </button>
          </form>

          <button type="submit" form="gateway-config-form" class="btn gateway-hero-btn">
            <i class="bx bx-save me-1"></i>
            Simpan Konfigurasi
          </button>
        </div>
      </div>

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        <div class="col-xl-3 col-md-6">
          <div class="gateway-stat-card">
            <div>
              <span>Gateway Aktif</span>
              <h3>{{ ucfirst($gateway->provider) }}</h3>
              <p>Provider utama pembayaran</p>
            </div>

            <div class="gateway-stat-icon bg-label-primary">
              <i class="bx bx-credit-card-front"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="gateway-stat-card">
            <div>
              <span>Mode Gateway</span>
              <h3>{{ ucfirst($gateway->environment) }}</h3>
              <p>
                {{ $gateway->environment === 'sandbox' ? 'Mode pengujian aktif' : 'Mode transaksi asli' }}
              </p>
            </div>

            <div class="gateway-stat-icon bg-label-{{ $environmentBadge }}">
              <i class="bx {{ $gateway->environment === 'sandbox' ? 'bx-flask' : 'bx-check-circle' }}"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="gateway-stat-card">
            <div>
              <span>Webhook Status</span>
              <h3>{{ $gateway->webhook_enabled ? 'Aktif' : 'Nonaktif' }}</h3>
              <p>
                {{ $gateway->webhook_enabled ? 'Callback siap digunakan' : 'Webhook sedang mati' }}
              </p>
            </div>

            <div class="gateway-stat-icon bg-label-{{ $webhookBadge }}">
              <i class="bx bx-link-alt"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="gateway-stat-card">
            <div>
              <span>Status Gateway</span>
              <h3>{{ $gateway->is_active ? 'Aktif' : 'Nonaktif' }}</h3>
              <p>
                {{ $gateway->is_visible_to_client ? 'Tampil di aplikasi klien' : 'Tidak tampil ke klien' }}
              </p>
            </div>

            <div class="gateway-stat-icon bg-label-{{ $gatewayActiveBadge }}">
              <i class="bx {{ $gateway->is_active ? 'bx-check-shield' : 'bx-hide' }}"></i>
            </div>
          </div>
        </div>
      </div>

      {{-- INFO --}}
      <div class="gateway-info-card mb-4">
        <div class="gateway-info-icon">
          <i class="bx bx-info-circle"></i>
        </div>

        <div>
          <h6>Pengaturan Integrasi Midtrans</h6>
          <p>
            Pastikan Merchant ID, Client Key, Server Key, Notification URL, dan Redirect URL sudah sesuai.
            Gunakan mode sandbox untuk pengujian, lalu ubah ke production ketika aplikasi sudah siap transaksi asli.
          </p>
        </div>
      </div>

      <form id="gateway-test-form-sidebar" method="POST" action="{{ route('admin.payment-gateway.test') }}" class="d-none">
        @csrf
      </form>

      <form id="gateway-config-form" method="POST" action="{{ route('admin.payment-gateway.update') }}">
        @csrf

        {{-- BARIS 1 --}}
        <div class="row g-4 gateway-top-row">
          <div class="col-xl-8">
            <div class="gateway-config-card">
              <div class="gateway-card-header gateway-card-header-with-action">
                <div>
                  <h5>Konfigurasi Gateway</h5>
                  <p>Atur kredensial dan parameter utama payment gateway.</p>
                </div>

                <div class="gateway-header-action-group">
                  <span class="gateway-header-pill">
                    <i class="bx bx-cog"></i>
                    Konfigurasi
                  </span>

                  <button type="submit" class="btn gateway-inline-save-btn">
                    <i class="bx bx-save me-1"></i>
                    Simpan
                  </button>
                </div>
              </div>

              <div class="gateway-card-body">
                <div class="row g-3">
                  <div class="col-md-6">
                    <label class="form-label">Provider Gateway</label>
                    <input type="text" class="form-control gateway-input" value="Midtrans" disabled>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Mode Environment</label>
                    <select class="form-select gateway-input" name="environment">
                      <option value="sandbox" {{ $gateway->environment === 'sandbox' ? 'selected' : '' }}>Sandbox</option>
                      <option value="production" {{ $gateway->environment === 'production' ? 'selected' : '' }}>Production</option>
                    </select>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Merchant ID</label>
                    <input type="text" name="merchant_id" class="form-control gateway-input"
                      value="{{ old('merchant_id', $gateway->merchant_id) }}" placeholder="Masukkan Merchant ID">
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Client Key</label>
                    <input type="text" name="client_key" class="form-control gateway-input"
                      value="{{ old('client_key', $gateway->client_key) }}" placeholder="Masukkan Client Key">
                  </div>

                  <div class="col-12">
                    <label class="form-label">Server Key</label>
                    <input type="text" name="server_key" class="form-control gateway-input"
                      value="{{ old('server_key', $gateway->server_key) }}" placeholder="Masukkan Server Key">
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Snap URL / Endpoint</label>
                    <input type="text" class="form-control gateway-input" value="{{ $gateway->snap_url }}" readonly>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Expired Payment</label>
                    <div class="input-group gateway-input-group">
                      <input type="number" name="expiry_minutes" class="form-control"
                        value="{{ old('expiry_minutes', $gateway->expiry_minutes) }}" min="1">
                      <span class="input-group-text">Menit</span>
                    </div>
                  </div>

                  <div class="col-12">
                    <label class="form-label">Callback / Notification URL</label>
                    <input type="text" name="notification_url" class="form-control gateway-input"
                      value="{{ old('notification_url', $gateway->notification_url) }}"
                      placeholder="https://domain.com/payment/notification">
                  </div>

                  <div class="col-md-4">
                    <label class="form-label">Success Redirect URL</label>
                    <input type="text" name="finish_url" class="form-control gateway-input"
                      value="{{ old('finish_url', $gateway->finish_url) }}" placeholder="URL setelah sukses">
                  </div>

                  <div class="col-md-4">
                    <label class="form-label">Unfinish Redirect URL</label>
                    <input type="text" name="unfinish_url" class="form-control gateway-input"
                      value="{{ old('unfinish_url', $gateway->unfinish_url) }}" placeholder="URL belum selesai">
                  </div>

                  <div class="col-md-4">
                    <label class="form-label">Error Redirect URL</label>
                    <input type="text" name="error_url" class="form-control gateway-input"
                      value="{{ old('error_url', $gateway->error_url) }}" placeholder="URL error">
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Biaya Admin Default</label>
                    <div class="input-group gateway-input-group">
                      <span class="input-group-text">Rp</span>
                      <input type="number" name="admin_fee" class="form-control"
                        value="{{ old('admin_fee', $gateway->admin_fee) }}" min="0">
                    </div>
                  </div>

                  <div class="col-md-6">
                    <label class="form-label">Ringkasan Biaya Admin</label>
                    <div class="gateway-readonly-box">
                      <span>Biaya Admin Saat Ini</span>
                      <strong>{{ $rupiah($gateway->admin_fee) }}</strong>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="col-xl-4">
            <div class="gateway-side-stack">
              <div class="gateway-side-card">
                <div class="gateway-side-header">
                  <div>
                    <h5>Status Koneksi</h5>
                    <p>Pantau status integrasi gateway.</p>
                  </div>

                  <span class="badge bg-label-{{ $lastTestBadge }}">
                    {{ $gateway->last_test_status ? ucfirst($gateway->last_test_status) : 'Belum dites' }}
                  </span>
                </div>

                <div class="gateway-status-list">
                  <div>
                    <span>Provider</span>
                    <strong>{{ ucfirst($gateway->provider) }}</strong>
                  </div>

                  <div>
                    <span>Environment</span>
                    <strong>{{ ucfirst($gateway->environment) }}</strong>
                  </div>

                  <div>
                    <span>Webhook</span>
                    <strong class="{{ $gateway->webhook_enabled ? 'text-success' : 'text-danger' }}">
                      {{ $gateway->webhook_enabled ? 'Listening' : 'Disabled' }}
                    </strong>
                  </div>

                  <div>
                    <span>Last Sync</span>
                    <strong>
                      {{ $gateway->last_tested_at ? $gateway->last_tested_at->format('d M Y, H:i') : '-' }}
                    </strong>
                  </div>

                  <div class="gateway-status-message">
                    <span>Pesan Tes Terakhir</span>
                    <strong>{{ $gateway->last_test_message ?: '-' }}</strong>
                  </div>

                  <button type="submit" form="gateway-test-form-sidebar" class="btn gateway-status-test-btn w-100">
                    <i class="bx bx-refresh me-1"></i>
                    Test Koneksi Gateway
                  </button>
                </div>
              </div>

              <div class="gateway-help-card gateway-help-card-compact">
                <div class="gateway-help-icon">
                  <i class="bx bx-shield-quarter"></i>
                </div>

                <h5>Catatan Keamanan</h5>
                <p>
                  Server Key bersifat sensitif. Jangan bagikan key production ke pihak luar.
                  Jika transaksi tidak berubah otomatis, cek Notification URL dan webhook Midtrans.
                </p>
              </div>
            </div>
          </div>
        </div>

        {{-- BARIS 2 --}}
        <div class="row g-4 gateway-status-full-row mt-4">
          <div class="col-12">
            <div class="gateway-config-card">
              <div class="gateway-card-header">
                <div>
                  <h5>Status & Visibilitas</h5>
                  <p>Atur status gateway, auto update, visibilitas klien, dan webhook.</p>
                </div>

                <span class="gateway-header-pill">
                  <i class="bx bx-toggle-left"></i>
                  Status
                </span>
              </div>

              <div class="gateway-card-body">
                <div class="gateway-toggle-grid">
                  <label class="gateway-toggle-card">
                    <div>
                      <span>Status Gateway</span>
                      <p>Aktifkan gateway agar bisa digunakan transaksi.</p>
                    </div>

                    <div class="form-check form-switch">
                      <input class="form-check-input" type="checkbox" name="is_active" value="1"
                        {{ old('is_active', $gateway->is_active) ? 'checked' : '' }}>
                    </div>
                  </label>

                  <label class="gateway-toggle-card">
                    <div>
                      <span>Auto Update Status Pembayaran</span>
                      <p>Update otomatis status payment dari callback.</p>
                    </div>

                    <div class="form-check form-switch">
                      <input class="form-check-input" type="checkbox" name="auto_update_status" value="1"
                        {{ old('auto_update_status', $gateway->auto_update_status) ? 'checked' : '' }}>
                    </div>
                  </label>

                  <label class="gateway-toggle-card">
                    <div>
                      <span>Tampilkan ke Klien</span>
                      <p>Gateway ditampilkan di aplikasi client.</p>
                    </div>

                    <div class="form-check form-switch">
                      <input class="form-check-input" type="checkbox" name="is_visible_to_client" value="1"
                        {{ old('is_visible_to_client', $gateway->is_visible_to_client) ? 'checked' : '' }}>
                    </div>
                  </label>

                  <label class="gateway-toggle-card">
                    <div>
                      <span>Webhook Aktif</span>
                      <p>Aktifkan listener callback pembayaran.</p>
                    </div>

                    <div class="form-check form-switch">
                      <input class="form-check-input" type="checkbox" name="webhook_enabled" value="1"
                        {{ old('webhook_enabled', $gateway->webhook_enabled) ? 'checked' : '' }}>
                    </div>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>

        {{-- BARIS 3 --}}
        <div class="row g-4 gateway-channel-full-row mt-4">
          <div class="col-12">
            <div class="gateway-config-card">
              <div class="gateway-card-header gateway-card-header-with-action">
                <div>
                  <h5>Channel Pembayaran</h5>
                  <p>Aktifkan channel yang diizinkan muncul saat checkout.</p>
                </div>

                <div class="gateway-header-action-group">
                  <span class="gateway-header-pill">
                    <i class="bx bx-wallet"></i>
                    Channel
                  </span>

                  <button type="submit" class="btn gateway-inline-save-btn gateway-inline-save-btn-soft">
                    <i class="bx bx-save me-1"></i>
                    Simpan Perubahan
                  </button>
                </div>
              </div>

              <div class="gateway-card-body">
                <div class="gateway-channel-grid">
                  @foreach ($availablePaymentTypes as $key => $paymentType)
                    @php
                      $isChecked = in_array(
                          $key,
                          old('enabled_payment_types', $gateway->enabled_payment_types ?? []),
                          true
                      );
                    @endphp

                    <label class="gateway-channel-card">
                      <div class="gateway-channel-icon">
                        <i class="bx bx-credit-card"></i>
                      </div>

                      <div class="gateway-channel-content">
                        <div class="gateway-channel-title">{{ $paymentType['label'] }}</div>
                        <p>{{ $paymentType['description'] }}</p>
                      </div>

                      <div class="form-check form-switch gateway-channel-switch">
                        <input class="form-check-input" type="checkbox" name="enabled_payment_types[]"
                          value="{{ $key }}" {{ $isChecked ? 'checked' : '' }}>
                      </div>
                    </label>
                  @endforeach
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>

      {{-- RIWAYAT --}}
      <div class="gateway-history-card mt-4">
        <div class="gateway-history-card-head">
          <div class="gateway-history-title-wrap">
            <div class="gateway-history-icon">
              <i class="bx bx-history"></i>
            </div>

            <div>
              <h5>Riwayat Aktivitas Gateway</h5>
              <p>Aktivitas konfigurasi, test koneksi, reset, dan webhook payment gateway.</p>
            </div>
          </div>

          <button type="button" class="btn gateway-history-btn" data-bs-toggle="modal" data-bs-target="#gatewayHistoryModal">
            <i class="bx bx-list-ul me-1"></i>
            Lihat Semua Riwayat
          </button>
        </div>

        <div class="gateway-history-card-body">
          @if ($latestLogs->count())
            <div class="gateway-history-preview-grid">
              @foreach ($latestLogs as $log)
                <div class="gateway-history-preview-item">
                  <span class="gateway-history-chip-icon bg-label-{{ $logStatusClass($log->status) }}">
                    <i class="bx {{ $logIcon($log->status) }}"></i>
                  </span>

                  <div>
                    <div class="gateway-history-preview-top">
                      <strong>{{ $log->activity }}</strong>
                      <span class="badge bg-label-{{ $logStatusClass($log->status) }}">
                        {{ ucfirst($log->status) }}
                      </span>
                    </div>

                    <p>{{ $log->message ?: '-' }}</p>

                    <small>
                      <i class="bx bx-time-five"></i>
                      {{ $log->created_at->format('d M Y, H:i') }} WIB
                    </small>
                  </div>
                </div>
              @endforeach
            </div>
          @else
            <div class="gateway-empty-state gateway-empty-state-card">
              <i class="bx bx-history"></i>
              <h6>Belum ada riwayat aktivitas gateway</h6>
              <p>Aktivitas konfigurasi, reset, test koneksi, dan webhook akan tampil di sini.</p>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- MODAL RIWAYAT --}}
  <div class="modal fade gateway-history-modal" id="gatewayHistoryModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
      <div class="modal-content gateway-history-modal-content">
        <div class="modal-header gateway-history-modal-header">
          <div>
            <h5 class="modal-title">Semua Riwayat Aktivitas Gateway</h5>
            <small>Daftar lengkap aktivitas konfigurasi, test koneksi, reset, dan webhook payment gateway.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body gateway-history-modal-body">
          @forelse ($logs as $log)
            <div class="gateway-history-modal-item">
              <div class="gateway-history-modal-icon bg-label-{{ $logStatusClass($log->status) }}">
                <i class="bx {{ $logIcon($log->status) }}"></i>
              </div>

              <div class="gateway-history-modal-content-text">
                <div class="gateway-history-modal-top">
                  <div>
                    <h6>{{ $log->activity }}</h6>
                    <p>{{ $log->message ?: '-' }}</p>
                  </div>

                  <span class="badge bg-label-{{ $logStatusClass($log->status) }}">
                    {{ ucfirst($log->status) }}
                  </span>
                </div>

                <div class="gateway-history-modal-time">
                  <i class="bx bx-time-five"></i>
                  {{ $log->created_at->format('d M Y, H:i') }} WIB
                </div>
              </div>
            </div>
          @empty
            <div class="gateway-empty-state">
              <i class="bx bx-history"></i>
              <h6>Belum ada riwayat aktivitas gateway</h6>
              <p>Aktivitas konfigurasi, reset, test koneksi, dan webhook akan tampil di sini.</p>
            </div>
          @endforelse
        </div>

        <div class="modal-footer gateway-history-modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            Tutup
          </button>
        </div>
      </div>
    </div>
  </div>

  <style>
    .gateway-page {
      max-width: 1480px;
      margin: 0 auto;
    }

    .gateway-hero-card {
      position: relative;
      overflow: hidden;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 24px;
      padding: 32px 34px;
      border-radius: 32px;
      background:
        radial-gradient(circle at top right, rgba(255, 255, 255, 0.36), transparent 32%),
        linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 24px 54px rgba(52, 79, 165, 0.24);
      color: #ffffff;
    }

    .gateway-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .gateway-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .gateway-hero-icon {
      width: 76px;
      height: 76px;
      border-radius: 26px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: rgba(255, 255, 255, 0.18);
      color: #ffffff;
      font-size: 38px;
      box-shadow: 0 16px 32px rgba(22, 43, 77, 0.16);
    }

    .gateway-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .gateway-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .gateway-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .gateway-hero-actions {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: center;
      gap: 12px;
      flex-shrink: 0;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .gateway-hero-btn {
      min-height: 54px;
      border: 0;
      border-radius: 18px;
      background: rgba(255, 255, 255, 0.92);
      color: var(--mf-primary);
      font-weight: 900;
      padding: 0 22px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      white-space: nowrap;
      box-shadow: 0 16px 30px rgba(22, 43, 77, 0.16);
      transition: 0.2s ease;
    }

    .gateway-hero-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .gateway-hero-btn-outline {
      background: rgba(255, 255, 255, 0.15);
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.35);
    }

    .gateway-hero-btn-outline:hover {
      background: rgba(255, 255, 255, 0.92);
      color: var(--mf-primary);
    }

    .gateway-stat-card {
      min-height: 142px;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 18px;
      padding: 24px;
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
      transition: 0.22s ease;
    }

    .gateway-stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.14);
    }

    .gateway-stat-card span {
      display: block;
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .gateway-stat-card h3 {
      color: var(--mf-ink);
      font-size: 26px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .gateway-stat-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 0;
    }

    .gateway-stat-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 28px;
    }

    .gateway-info-card,
    .gateway-help-card,
    .gateway-config-card,
    .gateway-side-card,
    .gateway-history-card {
      border-radius: 30px;
      background: #ffffff;
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .gateway-info-card {
      display: grid;
      grid-template-columns: 58px 1fr;
      gap: 16px;
      align-items: flex-start;
      padding: 22px 24px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .gateway-info-icon,
    .gateway-help-icon,
    .gateway-history-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 28px;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.22);
    }

    .gateway-info-card h6,
    .gateway-help-card h5 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .gateway-info-card p,
    .gateway-help-card p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .gateway-card-header,
    .gateway-side-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      flex-wrap: wrap;
      padding: 30px 34px 22px;
      border-bottom: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .gateway-card-header h5,
    .gateway-side-header h5,
    .gateway-history-card-head h5 {
      color: var(--mf-ink);
      font-size: 20px;
      font-weight: 900;
      margin-bottom: 7px;
    }

    .gateway-card-header p,
    .gateway-side-header p,
    .gateway-history-card-head p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 700;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .gateway-card-header-with-action {
      align-items: center;
    }

    .gateway-header-action-group {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 10px;
    }

    .gateway-header-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 13px;
      font-weight: 900;
      white-space: nowrap;
    }

    .gateway-inline-save-btn {
      min-height: 42px;
      border: 0;
      border-radius: 15px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-weight: 900;
      padding: 0 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .gateway-inline-save-btn:hover {
      color: #ffffff;
      transform: translateY(-1px);
      box-shadow: 0 16px 30px rgba(88, 115, 220, 0.24);
    }

    .gateway-inline-save-btn-soft {
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      box-shadow: none;
    }

    .gateway-inline-save-btn-soft:hover {
      color: #ffffff;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
    }

    .gateway-card-body {
      padding: 28px 34px 34px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .gateway-card-body .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .gateway-input,
    .gateway-input-group .form-control,
    .gateway-input-group .input-group-text {
      min-height: 52px;
      border-color: var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      box-shadow: none !important;
    }

    .gateway-input {
      border-radius: 18px !important;
    }

    .gateway-input-group {
      border-radius: 18px;
      overflow: hidden;
    }

    .gateway-input-group .form-control {
      border-radius: 0 !important;
    }

    .gateway-input-group .input-group-text {
      border-radius: 0 !important;
      color: var(--mf-muted) !important;
      font-weight: 900 !important;
    }

    .gateway-input:focus,
    .gateway-input-group .form-control:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .gateway-readonly-box {
      min-height: 52px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 13px 16px;
      border-radius: 18px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .gateway-readonly-box span {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 900;
    }

    .gateway-readonly-box strong {
      color: var(--mf-ink);
      font-weight: 900;
      white-space: nowrap;
    }

    .gateway-toggle-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px;
    }

    .gateway-toggle-card {
      cursor: pointer;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      padding: 18px;
      border-radius: 22px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
      transition: 0.2s ease;
    }

    .gateway-toggle-card:hover {
      transform: translateY(-3px);
      box-shadow: 0 16px 34px rgba(52, 79, 165, 0.10);
    }

    .gateway-toggle-card span {
      display: block;
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.35;
      margin-bottom: 5px;
    }

    .gateway-toggle-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .gateway-channel-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 14px;
    }

    .gateway-channel-card {
      cursor: pointer;
      position: relative;
      display: grid;
      grid-template-columns: 48px 1fr auto;
      align-items: flex-start;
      gap: 13px;
      padding: 17px;
      border-radius: 22px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
      transition: 0.2s ease;
    }

    .gateway-channel-card:hover {
      transform: translateY(-3px);
      border-color: rgba(88, 115, 220, 0.35);
      box-shadow: 0 16px 34px rgba(52, 79, 165, 0.10);
    }

    .gateway-channel-icon {
      width: 48px;
      height: 48px;
      border-radius: 17px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 23px;
    }

    .gateway-channel-title {
      color: var(--mf-ink);
      font-size: 15px;
      font-weight: 900;
      line-height: 1.35;
      margin-bottom: 5px;
    }

    .gateway-channel-content p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .gateway-channel-switch {
      margin-top: 3px;
    }

    .gateway-side-header {
      padding: 24px 26px 18px;
    }

    .gateway-status-list {
      flex: 1;
      padding: 20px 26px 22px;
      display: grid;
      gap: 10px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .gateway-status-list > div {
      padding: 12px 14px;
      border-radius: 18px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .gateway-status-list span {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 5px;
    }

    .gateway-status-list strong {
      display: block;
      color: var(--mf-ink);
      font-size: 14px;
      font-weight: 900;
      line-height: 1.5;
      word-break: break-word;
    }

    .gateway-status-message strong {
      color: var(--mf-muted);
      font-weight: 800;
    }

    .gateway-status-test-btn {
      min-height: 48px;
      border: 0;
      border-radius: 16px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-weight: 900;
      margin-top: 4px;
    }

    .gateway-status-test-btn:hover {
      color: #ffffff;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.18);
    }

    .gateway-help-card {
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .gateway-help-card-compact {
      min-height: 188px;
      padding: 22px 26px;
      flex-shrink: 0;
    }

    .gateway-help-card-compact .gateway-help-icon {
      width: 50px;
      height: 50px;
      border-radius: 18px;
      font-size: 24px;
      margin-bottom: 12px;
    }

    .gateway-help-card-compact h5 {
      font-size: 18px;
      margin-bottom: 6px;
    }

    .gateway-help-card-compact p {
      font-size: 13px;
      line-height: 1.6;
    }

    .gateway-history-card-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 18px;
      flex-wrap: wrap;
      padding: 28px 34px 24px;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(88, 115, 220, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .gateway-history-title-wrap {
      display: grid;
      grid-template-columns: 58px 1fr;
      align-items: flex-start;
      gap: 16px;
      min-width: 0;
    }

    .gateway-history-btn {
      min-height: 46px;
      border-radius: 16px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-weight: 900;
      padding: 0 18px;
      white-space: nowrap;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.18);
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .gateway-history-btn:hover {
      color: #ffffff;
      transform: translateY(-2px);
      box-shadow: 0 18px 34px rgba(88, 115, 220, 0.24);
    }

    .gateway-history-card-body {
      padding: 28px 34px 34px;
      background:
        radial-gradient(circle at bottom left, rgba(88, 115, 220, 0.08), transparent 34%),
        linear-gradient(180deg, #f8fbfd 0%, #ffffff 100%);
    }

    .gateway-history-preview-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
    }

    .gateway-history-preview-item {
      display: grid;
      grid-template-columns: 42px 1fr;
      gap: 12px;
      align-items: flex-start;
      padding: 16px;
      border: 1px solid var(--mf-border);
      border-radius: 22px;
      background: #ffffff;
      box-shadow: 0 10px 24px rgba(22, 43, 77, 0.04);
      transition: 0.2s ease;
    }

    .gateway-history-preview-item:hover {
      transform: translateY(-3px);
      box-shadow: 0 18px 34px rgba(52, 79, 165, 0.12);
    }

    .gateway-history-chip-icon {
      width: 42px;
      height: 42px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      flex-shrink: 0;
    }

    .gateway-history-preview-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 8px;
      margin-bottom: 6px;
    }

    .gateway-history-preview-top strong {
      display: block;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      line-height: 1.35;
    }

    .gateway-history-preview-item p {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.55;
      margin-bottom: 8px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .gateway-history-preview-item small {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      color: #526b7f;
      font-size: 11px;
      font-weight: 800;
    }

    .gateway-history-modal-content {
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: 0 24px 60px rgba(22, 43, 77, 0.18);
    }

    .gateway-history-modal-header {
      padding: 24px 28px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      border-bottom: 0;
    }

    .gateway-history-modal-header .modal-title {
      color: #ffffff;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .gateway-history-modal-header small {
      color: rgba(255, 255, 255, 0.78);
      font-weight: 600;
    }

    .gateway-history-modal-body {
      padding: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      display: grid;
      gap: 14px;
    }

    .gateway-history-modal-item {
      display: grid;
      grid-template-columns: 50px 1fr;
      gap: 14px;
      align-items: flex-start;
      padding: 16px;
      border-radius: 22px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
      box-shadow: 0 10px 24px rgba(22, 43, 77, 0.04);
    }

    .gateway-history-modal-icon {
      width: 50px;
      height: 50px;
      border-radius: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
    }

    .gateway-history-modal-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 8px;
    }

    .gateway-history-modal-top h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .gateway-history-modal-top p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.65;
      margin-bottom: 0;
    }

    .gateway-history-modal-time {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: #526b7f;
      font-size: 12px;
      font-weight: 800;
    }

    .gateway-history-modal-time i {
      color: var(--mf-primary);
      font-size: 16px;
    }

    .gateway-history-modal-footer {
      padding: 20px 28px 24px;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
    }

    .gateway-empty-state {
      text-align: center;
      padding: 54px 20px;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .gateway-empty-state i {
      display: block;
      color: var(--mf-primary);
      font-size: 52px;
      margin-bottom: 12px;
    }

    .gateway-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .gateway-empty-state p {
      margin-bottom: 0;
    }

    .gateway-empty-state-card {
      border: 1px dashed var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
    }

    /* FIX UTAMA: KANAN DAN KIRI SAMA TINGGI */
    .gateway-top-row {
      align-items: stretch !important;
    }

    .gateway-top-row > [class*="col-"] {
      display: flex;
      flex-direction: column;
    }

    .gateway-top-row .gateway-config-card {
      height: 100%;
      flex: 1;
      display: flex;
      flex-direction: column;
      margin-bottom: 0;
    }

    .gateway-top-row .gateway-card-body {
      flex: 1;
    }

    .gateway-side-stack {
      height: 100%;
      width: 100%;
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .gateway-side-card {
      flex: 1;
      display: flex;
      flex-direction: column;
      min-height: 0;
      margin-bottom: 0 !important;
    }

    .gateway-side-stack .gateway-help-card {
      margin-bottom: 0 !important;
    }

    .gateway-status-full-row > [class*="col-"],
    .gateway-channel-full-row > [class*="col-"] {
      display: flex;
      flex-direction: column;
    }

    .gateway-status-full-row .gateway-config-card,
    .gateway-channel-full-row .gateway-config-card {
      width: 100%;
      margin-bottom: 0;
    }

    .gateway-status-full-row .gateway-toggle-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .gateway-channel-full-row .gateway-channel-grid {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .gateway-status-full-row .gateway-toggle-card,
    .gateway-channel-full-row .gateway-channel-card {
      min-height: 108px;
    }

    @media (max-width: 1400px) {
      .gateway-history-preview-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (max-width: 1200px) {
      .gateway-side-stack {
        height: auto;
      }

      .gateway-side-card {
        flex: initial;
      }

      .gateway-channel-grid,
      .gateway-status-full-row .gateway-toggle-grid,
      .gateway-channel-full-row .gateway-channel-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 992px) {
      .gateway-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .gateway-hero-actions,
      .gateway-hero-actions form,
      .gateway-hero-btn {
        width: 100%;
      }

      .gateway-hero-actions {
        justify-content: flex-start;
      }

      .gateway-toggle-grid {
        grid-template-columns: 1fr;
      }

      .gateway-header-action-group,
      .gateway-inline-save-btn,
      .gateway-inline-save-btn-soft {
        width: 100%;
      }

      .gateway-history-card-head {
        align-items: flex-start;
        flex-direction: column;
      }

      .gateway-history-btn {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .gateway-hero-card,
      .gateway-card-header,
      .gateway-card-body,
      .gateway-side-header,
      .gateway-status-list,
      .gateway-help-card,
      .gateway-history-card-head,
      .gateway-history-card-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .gateway-hero-card {
        padding-top: 26px;
        padding-bottom: 26px;
      }

      .gateway-hero-left,
      .gateway-info-card,
      .gateway-history-title-wrap {
        grid-template-columns: 1fr;
        flex-direction: column;
      }

      .gateway-hero-btn {
        min-height: 50px;
      }

      .gateway-channel-card {
        grid-template-columns: 44px 1fr;
      }

      .gateway-channel-switch {
        grid-column: 1 / -1;
      }

      .gateway-history-preview-grid {
        grid-template-columns: 1fr;
      }

      .gateway-history-modal-body {
        padding: 22px;
      }

      .gateway-history-modal-item {
        grid-template-columns: 1fr;
      }
    }
  </style>
@endsection