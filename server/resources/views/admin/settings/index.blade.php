@extends('layouts/contentNavbarLayout')

@section('title', 'Pengaturan Sistem')

@section('content')
@php
  $booleanChecked = function (string $name, $default) {
      return old($name, $default) ? 'checked' : '';
  };

  $value = function (string $name, $default = null) {
      return old($name, $default);
  };
@endphp

<div class="container-xxl flex-grow-1 container-p-y settings-page">
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

  <div class="settings-hero mb-4">
    <div class="settings-hero-content">
      <div class="settings-hero-icon">
        <i class="bx bx-cog"></i>
      </div>
      <div>
        <div class="settings-kicker">PUSAT KONTROL SISTEM</div>
        <h4>Pengaturan Monoframe Studio</h4>
        <p>
          Kelola identitas studio, tampilan aplikasi klien Flutter, aturan booking,
          review, notifikasi, sistem, dan ringkasan integrasi dari satu halaman.
        </p>
      </div>
    </div>

    <button type="submit" form="settings-form" class="btn settings-hero-btn">
      <i class="bx bx-save me-1"></i>
      Simpan Pengaturan
    </button>
  </div>

  <div class="row g-4 mb-4">
    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <span>Booking</span>
        <h4>{{ $setting->booking_is_active ? 'Aktif' : 'Nonaktif' }}</h4>
        <p>Kontrol booking dari aplikasi klien.</p>
      </div>
    </div>
    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <span>Review Publik</span>
        <h4>{{ $setting->show_reviews_on_client ? 'Tampil' : 'Tersembunyi' }}</h4>
        <p>{{ $reviewSummary['displayable'] }} review lolos filter.</p>
      </div>
    </div>
    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <span>Kontak Klien</span>
        <h4>{{ $contactSummary['visible_to_client'] }}</h4>
        <p>Dari {{ $contactSummary['total'] }} kontak call center.</p>
      </div>
    </div>
    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <span>Gateway</span>
        <h4>{{ $gateway?->is_active ? 'Aktif' : 'Nonaktif' }}</h4>
        <p>{{ $gateway ? ucfirst($gateway->environment) : 'Belum dikonfigurasi' }}</p>
      </div>
    </div>
  </div>

  <form id="settings-form" method="POST" action="{{ route('admin.settings.update') }}" enctype="multipart/form-data">
    @csrf
    @method('PUT')

    <div class="settings-card">
      <div class="settings-tabs-wrap">
        <ul class="nav nav-pills settings-tabs" id="settingsTab" role="tablist">
          <li class="nav-item" role="presentation">
            <button class="nav-link active" data-bs-toggle="tab" data-bs-target="#tab-general" type="button">
              <i class="bx bx-building-house me-1"></i> Umum
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-client" type="button">
              <i class="bx bx-mobile-alt me-1"></i> Aplikasi Client
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-booking" type="button">
              <i class="bx bx-calendar-check me-1"></i> Booking
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-review" type="button">
              <i class="bx bx-star me-1"></i> Review
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-notification" type="button">
              <i class="bx bx-bell me-1"></i> Notifikasi
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-system" type="button">
              <i class="bx bx-shield-quarter me-1"></i> Sistem
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" data-bs-toggle="tab" data-bs-target="#tab-integration" type="button">
              <i class="bx bx-link-alt me-1"></i> Integrasi
            </button>
          </li>
        </ul>
      </div>

      <div class="tab-content settings-tab-content">
        <div class="tab-pane fade show active" id="tab-general">
          <div class="settings-section-head">
            <h5>Identitas Studio</h5>
            <p>Data ini dipakai untuk aplikasi klien, invoice, kontak, dan tampilan publik.</p>
          </div>

          <div class="row g-4">
            <div class="col-lg-8">
              <div class="row g-3">
                <div class="col-md-6">
                  <label class="form-label">Nama Studio</label>
                  <input type="text" name="studio_name" class="form-control" value="{{ $value('studio_name', $setting->studio_name) }}" required>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Tagline Studio</label>
                  <input type="text" name="studio_tagline" class="form-control" value="{{ $value('studio_tagline', $setting->studio_tagline) }}">
                </div>
                <div class="col-12">
                  <label class="form-label">Alamat Studio</label>
                  <textarea name="studio_address" class="form-control" rows="3">{{ $value('studio_address', $setting->studio_address) }}</textarea>
                </div>
                <div class="col-12">
                  <label class="form-label">Google Maps Link</label>
                  <input type="url" name="studio_maps_url" class="form-control" value="{{ $value('studio_maps_url', $setting->studio_maps_url) }}">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Email Studio</label>
                  <input type="email" name="studio_email" class="form-control" value="{{ $value('studio_email', $setting->studio_email) }}">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Nomor WhatsApp Utama</label>
                  <input type="text" name="studio_whatsapp" class="form-control" value="{{ $value('studio_whatsapp', $setting->studio_whatsapp) }}" placeholder="628xxxxxxxxxx">
                </div>
                <div class="col-md-4">
                  <label class="form-label">Instagram URL</label>
                  <input type="url" name="instagram_url" class="form-control" value="{{ $value('instagram_url', $setting->instagram_url) }}">
                </div>
                <div class="col-md-4">
                  <label class="form-label">TikTok URL</label>
                  <input type="url" name="tiktok_url" class="form-control" value="{{ $value('tiktok_url', $setting->tiktok_url) }}">
                </div>
                <div class="col-md-4">
                  <label class="form-label">Website URL</label>
                  <input type="url" name="website_url" class="form-control" value="{{ $value('website_url', $setting->website_url) }}">
                </div>
              </div>
            </div>

            <div class="col-lg-4">
              <div class="upload-card">
                <label class="form-label">Logo Studio</label>
                <div class="preview-box">
                  @if ($setting->studio_logo_url)
                    <img src="{{ $setting->studio_logo_url }}" alt="Logo Studio">
                  @else
                    <i class="bx bx-image"></i>
                    <span>Belum ada logo</span>
                  @endif
                </div>
                <input type="file" name="studio_logo" class="form-control mt-3" accept="image/*">
                @if ($setting->studio_logo)
                  <div class="form-check mt-3">
                    <input class="form-check-input" type="checkbox" name="remove_studio_logo" value="1" id="remove_studio_logo">
                    <label class="form-check-label" for="remove_studio_logo">Hapus logo saat disimpan</label>
                  </div>
                @endif
                <small class="text-muted d-block mt-2">Format jpg, png, webp. Maksimal 2MB.</small>
              </div>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-client">
          <div class="settings-section-head">
            <h5>Tampilan Aplikasi Client Flutter</h5>
            <p>Konten ini bisa dibaca Flutter lewat endpoint <code>/api/app-settings</code>.</p>
          </div>

          <div class="row g-4">
            <div class="col-lg-8">
              <div class="row g-3">
                <div class="col-12">
                  <label class="form-label">Judul Home Client</label>
                  <input type="text" name="client_home_title" class="form-control" value="{{ $value('client_home_title', $setting->client_home_title) }}" required>
                </div>
                <div class="col-12">
                  <label class="form-label">Deskripsi Home Client</label>
                  <textarea name="client_home_subtitle" class="form-control" rows="4">{{ $value('client_home_subtitle', $setting->client_home_subtitle) }}</textarea>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Teks Tombol CTA</label>
                  <input type="text" name="client_cta_text" class="form-control" value="{{ $value('client_cta_text', $setting->client_cta_text) }}" required>
                </div>
                <div class="col-md-6">
                  <label class="form-label">Banner Home</label>
                  <input type="file" name="client_home_banner" class="form-control" accept="image/*">
                </div>
              </div>

              <div class="toggle-grid mt-4">
                <label class="toggle-card">
                  <span>Tampilkan Paket Populer</span>
                  <p>Flutter bisa memakai toggle ini untuk menampilkan section paket.</p>
                  <input type="hidden" name="show_popular_packages" value="0">
                  <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="show_popular_packages" value="1" {{ $booleanChecked('show_popular_packages', $setting->show_popular_packages) }}>
                  </div>
                </label>
                <label class="toggle-card">
                  <span>Tampilkan Review Client</span>
                  <p>Section review publik di aplikasi client.</p>
                  <input type="hidden" name="show_client_reviews" value="0">
                  <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="show_client_reviews" value="1" {{ $booleanChecked('show_client_reviews', $setting->show_client_reviews) }}>
                  </div>
                </label>
                <label class="toggle-card">
                  <span>Tampilkan Kontak Bantuan</span>
                  <p>Shortcut call center di aplikasi client.</p>
                  <input type="hidden" name="show_support_contact" value="0">
                  <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" name="show_support_contact" value="1" {{ $booleanChecked('show_support_contact', $setting->show_support_contact) }}>
                  </div>
                </label>
              </div>
            </div>

            <div class="col-lg-4">
              <div class="upload-card">
                <label class="form-label">Preview Banner</label>
                <div class="preview-box preview-banner">
                  @if ($setting->client_home_banner_url)
                    <img src="{{ $setting->client_home_banner_url }}" alt="Banner Home">
                  @else
                    <i class="bx bx-photo-album"></i>
                    <span>Belum ada banner</span>
                  @endif
                </div>
                @if ($setting->client_home_banner)
                  <div class="form-check mt-3">
                    <input class="form-check-input" type="checkbox" name="remove_client_home_banner" value="1" id="remove_client_home_banner">
                    <label class="form-check-label" for="remove_client_home_banner">Hapus banner saat disimpan</label>
                  </div>
                @endif
                <small class="text-muted d-block mt-2">Disarankan rasio 16:9. Maksimal 4MB.</small>
              </div>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-booking">
          <div class="settings-section-head">
            <h5>Aturan Booking Global</h5>
            <p>Aturan ini membatasi booking dari aplikasi client tanpa mengganggu halaman Jadwal & Slot.</p>
          </div>

          <div class="row g-4">
            <div class="col-lg-5">
              <div class="toggle-card big">
                <span>Status Booking Client</span>
                <p>Jika dinonaktifkan, client tidak bisa membuat booking baru dari Flutter.</p>
                <input type="hidden" name="booking_is_active" value="0">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" name="booking_is_active" value="1" {{ $booleanChecked('booking_is_active', $setting->booking_is_active) }}>
                </div>
              </div>
            </div>
            <div class="col-lg-7">
              <label class="form-label">Pesan Saat Booking Ditutup</label>
              <textarea name="booking_closed_message" class="form-control" rows="4">{{ $value('booking_closed_message', $setting->booking_closed_message) }}</textarea>
            </div>

            <div class="col-md-4">
              <label class="form-label">Maksimal Moodboard Upload</label>
              <input type="number" name="max_moodboard_upload" class="form-control" min="0" max="20" value="{{ $value('max_moodboard_upload', $setting->max_moodboard_upload) }}" required>
            </div>
            <div class="col-md-4">
              <label class="form-label">Maksimal Extra Duration Unit</label>
              <input type="number" name="max_extra_duration_units" class="form-control" min="0" max="20" value="{{ $value('max_extra_duration_units', $setting->max_extra_duration_units) }}" required>
            </div>
            <div class="col-md-4">
              <label class="form-label">Minimal Hari Reschedule</label>
              <input type="number" name="min_reschedule_days" class="form-control" min="0" max="30" value="{{ $value('min_reschedule_days', $setting->min_reschedule_days) }}" required>
            </div>
            <div class="col-12">
              <label class="form-label">Catatan Kebijakan Booking</label>
              <textarea name="booking_policy" class="form-control" rows="4">{{ $value('booking_policy', $setting->booking_policy) }}</textarea>
            </div>
            <div class="col-12">
              <label class="form-label">Syarat & Ketentuan Booking</label>
              <textarea name="booking_terms" class="form-control" rows="6">{{ $value('booking_terms', $setting->booking_terms) }}</textarea>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-review">
          <div class="settings-section-head">
            <h5>Kebijakan Review Client</h5>
            <p>Admin tetap hanya bisa melihat dan menghapus review. Pengaturan ini hanya mengatur status dan visibilitas.</p>
          </div>

          <div class="toggle-grid mb-4">
            <label class="toggle-card">
              <span>Aktifkan Review</span>
              <p>Jika mati, client tidak bisa mengirim review baru.</p>
              <input type="hidden" name="review_is_active" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="review_is_active" value="1" {{ $booleanChecked('review_is_active', $setting->review_is_active) }}>
              </div>
            </label>
            <label class="toggle-card">
              <span>Tampilkan Review ke Client</span>
              <p>Dipakai endpoint /api/public-reviews.</p>
              <input type="hidden" name="show_reviews_on_client" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="show_reviews_on_client" value="1" {{ $booleanChecked('show_reviews_on_client', $setting->show_reviews_on_client) }}>
              </div>
            </label>
            <label class="toggle-card">
              <span>Auto-hide Rating Rendah</span>
              <p>Review publik difilter berdasarkan rating minimal.</p>
              <input type="hidden" name="auto_hide_low_rating" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="auto_hide_low_rating" value="1" {{ $booleanChecked('auto_hide_low_rating', $setting->auto_hide_low_rating) }}>
              </div>
            </label>
          </div>

          <div class="row g-3">
            <div class="col-md-4">
              <label class="form-label">Minimal Rating yang Ditampilkan</label>
              <select name="minimum_rating_display" class="form-select" required>
                @for ($rating = 1; $rating <= 5; $rating++)
                  <option value="{{ $rating }}" {{ (int) $value('minimum_rating_display', $setting->minimum_rating_display) === $rating ? 'selected' : '' }}>{{ $rating }} Bintang ke atas</option>
                @endfor
              </select>
            </div>
            <div class="col-md-8">
              <label class="form-label">Pesan Ajakan Review</label>
              <textarea name="review_invitation_message" class="form-control" rows="3">{{ $value('review_invitation_message', $setting->review_invitation_message) }}</textarea>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-notification">
          <div class="settings-section-head">
            <h5>Template Notifikasi</h5>
            <p>Siapkan template pesan agar nanti mudah dipakai email, WhatsApp, atau in-app notification.</p>
          </div>

          <div class="toggle-grid mb-4">
            <label class="toggle-card">
              <span>Email</span>
              <p>Aktifkan template untuk email.</p>
              <input type="hidden" name="email_notifications_enabled" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="email_notifications_enabled" value="1" {{ $booleanChecked('email_notifications_enabled', $setting->email_notifications_enabled) }}>
              </div>
            </label>
            <label class="toggle-card">
              <span>WhatsApp</span>
              <p>Aktifkan template untuk WhatsApp.</p>
              <input type="hidden" name="whatsapp_notifications_enabled" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="whatsapp_notifications_enabled" value="1" {{ $booleanChecked('whatsapp_notifications_enabled', $setting->whatsapp_notifications_enabled) }}>
              </div>
            </label>
            <label class="toggle-card">
              <span>In-App</span>
              <p>Aktifkan template untuk notifikasi aplikasi.</p>
              <input type="hidden" name="in_app_notifications_enabled" value="0">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="in_app_notifications_enabled" value="1" {{ $booleanChecked('in_app_notifications_enabled', $setting->in_app_notifications_enabled) }}>
              </div>
            </label>
          </div>

          <div class="row g-3">
            <div class="col-md-6">
              <label class="form-label">Nama Pengirim</label>
              <input type="text" name="notification_sender_name" class="form-control" value="{{ $value('notification_sender_name', $setting->notification_sender_name) }}" required>
            </div>
            <div class="col-12">
              <label class="form-label">Template Booking Dibuat</label>
              <textarea name="booking_created_template" class="form-control" rows="3">{{ $value('booking_created_template', $setting->booking_created_template) }}</textarea>
            </div>
            <div class="col-12">
              <label class="form-label">Template Pembayaran Berhasil</label>
              <textarea name="payment_success_template" class="form-control" rows="3">{{ $value('payment_success_template', $setting->payment_success_template) }}</textarea>
            </div>
            <div class="col-12">
              <label class="form-label">Template Edit Selesai</label>
              <textarea name="edit_completed_template" class="form-control" rows="3">{{ $value('edit_completed_template', $setting->edit_completed_template) }}</textarea>
            </div>
            <div class="col-12">
              <label class="form-label">Template Permintaan Review</label>
              <textarea name="review_request_template" class="form-control" rows="3">{{ $value('review_request_template', $setting->review_request_template) }}</textarea>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-system">
          <div class="settings-section-head">
            <h5>Pengaturan Sistem</h5>
            <p>Kontrol status aplikasi, registrasi klien, role default, dan keamanan dasar.</p>
          </div>

          <div class="row g-4">
            <div class="col-lg-6">
              <label class="toggle-card big h-100">
                <span>Maintenance Mode</span>
                <p>Flutter dapat membaca status ini dan menampilkan halaman maintenance.</p>
                <input type="hidden" name="maintenance_mode" value="0">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" name="maintenance_mode" value="1" {{ $booleanChecked('maintenance_mode', $setting->maintenance_mode) }}>
                </div>
              </label>
            </div>
            <div class="col-lg-6">
              <label class="toggle-card big h-100">
                <span>Izinkan Registrasi Client</span>
                <p>Jika mati, endpoint register akan menolak user baru dari Flutter.</p>
                <input type="hidden" name="allow_client_registration" value="0">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" name="allow_client_registration" value="1" {{ $booleanChecked('allow_client_registration', $setting->allow_client_registration) }}>
                </div>
              </label>
            </div>

            <div class="col-12">
              <label class="form-label">Pesan Maintenance</label>
              <textarea name="maintenance_message" class="form-control" rows="3">{{ $value('maintenance_message', $setting->maintenance_message) }}</textarea>
            </div>
            <div class="col-md-6">
              <label class="form-label">Default Role User Baru</label>
              <input type="text" name="default_client_role" class="form-control" value="{{ $value('default_client_role', $setting->default_client_role) }}" required>
              <small class="text-muted">Biarkan Klien agar sesuai middleware role.api:Klien.</small>
            </div>
            <div class="col-md-6">
              <label class="form-label">Batas Percobaan Login</label>
              <input type="number" name="login_attempt_limit" class="form-control" min="1" max="20" value="{{ $value('login_attempt_limit', $setting->login_attempt_limit) }}" required>
              <small class="text-muted">Disimpan untuk kebutuhan keamanan lanjutan.</small>
            </div>
          </div>
        </div>

        <div class="tab-pane fade" id="tab-integration">
          <div class="settings-section-head">
            <h5>Ringkasan Integrasi</h5>
            <p>Bagian ini hanya ringkasan. Detail tetap di halaman Payment Gateway, Call Center, dan Review.</p>
          </div>

          <div class="row g-4">
            <div class="col-lg-4">
              <div class="integration-card">
                <div class="integration-icon"><i class="bx bx-wallet"></i></div>
                <h6>Payment Gateway</h6>
                <p>Provider: <strong>{{ $gateway?->provider ? ucfirst($gateway->provider) : '-' }}</strong></p>
                <p>Mode: <strong>{{ $gateway?->environment ? ucfirst($gateway->environment) : '-' }}</strong></p>
                <p>Status: <strong>{{ $gateway?->is_active ? 'Aktif' : 'Nonaktif' }}</strong></p>
                <a href="{{ route('admin.payment-gateway.index') }}" class="btn btn-sm btn-outline-primary mt-2">Kelola Gateway</a>
              </div>
            </div>
            <div class="col-lg-4">
              <div class="integration-card">
                <div class="integration-icon"><i class="bx bx-support"></i></div>
                <h6>Call Center</h6>
                <p>Total kontak: <strong>{{ $contactSummary['total'] }}</strong></p>
                <p>Aktif: <strong>{{ $contactSummary['active'] }}</strong></p>
                <p>Tampil ke client: <strong>{{ $contactSummary['visible_to_client'] }}</strong></p>
                <a href="{{ route('admin.call-center.index') }}" class="btn btn-sm btn-outline-primary mt-2">Kelola Kontak</a>
              </div>
            </div>
            <div class="col-lg-4">
              <div class="integration-card">
                <div class="integration-icon"><i class="bx bx-star"></i></div>
                <h6>Review</h6>
                <p>Total review: <strong>{{ $reviewSummary['total'] }}</strong></p>
                <p>Rata-rata rating: <strong>{{ $reviewSummary['average_rating'] ?: '-' }}</strong></p>
                <p>Lolos filter publik: <strong>{{ $reviewSummary['displayable'] }}</strong></p>
                <a href="{{ route('admin.reviews.index') }}" class="btn btn-sm btn-outline-primary mt-2">Lihat Review</a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="settings-footer-actions">
        <button type="submit" class="btn btn-primary">
          <i class="bx bx-save me-1"></i>
          Simpan Semua Pengaturan
        </button>
      </div>
    </div>
  </form>
</div>

<style>
  .settings-page {
    max-width: 1480px;
    margin: 0 auto;
  }

  .settings-hero {
    display: flex;
    justify-content: space-between;
    gap: 24px;
    align-items: center;
    padding: 30px;
    border-radius: 30px;
    color: #fff;
    background: linear-gradient(135deg, #344fa5, #6b7fd7);
    box-shadow: 0 24px 50px rgba(52, 79, 165, .24);
  }

  .settings-hero-content {
    display: flex;
    align-items: flex-start;
    gap: 18px;
  }

  .settings-hero-icon {
    width: 68px;
    height: 68px;
    border-radius: 22px;
    background: rgba(255,255,255,.18);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 34px;
    flex-shrink: 0;
  }

  .settings-kicker {
    font-size: 12px;
    font-weight: 900;
    letter-spacing: .12em;
    opacity: .78;
    margin-bottom: 8px;
  }

  .settings-hero h4 {
    color: #fff;
    margin-bottom: 8px;
    font-weight: 900;
  }

  .settings-hero p {
    max-width: 860px;
    margin-bottom: 0;
    color: rgba(255,255,255,.88);
    line-height: 1.7;
    font-weight: 600;
  }

  .settings-hero-btn {
    background: #fff;
    color: #344fa5;
    border: 0;
    border-radius: 16px;
    min-height: 50px;
    padding: 0 22px;
    font-weight: 900;
    white-space: nowrap;
  }

  .settings-stat-card,
  .settings-card,
  .upload-card,
  .toggle-card,
  .integration-card {
    background: #fff;
    border-radius: 24px;
    box-shadow: 0 14px 38px rgba(67, 89, 113, .10);
  }

  .settings-stat-card {
    min-height: 134px;
    padding: 22px;
  }

  .settings-stat-card span {
    color: #697a8d;
    font-size: 13px;
    font-weight: 800;
  }

  .settings-stat-card h4 {
    margin: 10px 0 8px;
    font-weight: 900;
    color: #2b354f;
  }

  .settings-stat-card p {
    margin-bottom: 0;
    color: #697a8d;
    font-weight: 600;
  }

  .settings-card {
    overflow: hidden;
  }

  .settings-tabs-wrap {
    padding: 20px 22px 0;
    border-bottom: 1px solid rgba(67, 89, 113, .12);
  }

  .settings-tabs {
    gap: 8px;
    flex-wrap: wrap;
  }

  .settings-tabs .nav-link {
    border-radius: 14px;
    font-weight: 800;
    color: #566a7f;
  }

  .settings-tabs .nav-link.active {
    background: #344fa5;
    color: #fff;
  }

  .settings-tab-content {
    padding: 26px;
  }

  .settings-section-head {
    margin-bottom: 24px;
  }

  .settings-section-head h5 {
    margin-bottom: 6px;
    font-weight: 900;
    color: #2b354f;
  }

  .settings-section-head p {
    margin-bottom: 0;
    color: #697a8d;
    font-weight: 600;
  }

  .upload-card {
    padding: 20px;
    height: 100%;
  }

  .preview-box {
    min-height: 210px;
    border: 1px dashed rgba(67, 89, 113, .25);
    border-radius: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    gap: 10px;
    background: #f8fbfd;
    overflow: hidden;
  }

  .preview-box img {
    width: 100%;
    height: 100%;
    min-height: 210px;
    object-fit: contain;
  }

  .preview-banner img {
    object-fit: cover;
  }

  .preview-box i {
    font-size: 42px;
    color: #a1acb8;
  }

  .toggle-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 16px;
  }

  .toggle-card {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 16px;
    align-items: start;
    padding: 20px;
    cursor: pointer;
  }

  .toggle-card.big {
    min-height: 150px;
  }

  .toggle-card span {
    display: block;
    color: #2b354f;
    font-weight: 900;
    margin-bottom: 6px;
  }

  .toggle-card p {
    color: #697a8d;
    font-weight: 600;
    line-height: 1.6;
    margin-bottom: 0;
  }

  .integration-card {
    padding: 24px;
    height: 100%;
  }

  .integration-icon {
    width: 56px;
    height: 56px;
    border-radius: 18px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    background: rgba(52, 79, 165, .10);
    color: #344fa5;
    font-size: 28px;
    margin-bottom: 16px;
  }

  .integration-card h6 {
    font-weight: 900;
    color: #2b354f;
  }

  .integration-card p {
    margin-bottom: 6px;
    color: #697a8d;
    font-weight: 600;
  }

  .settings-footer-actions {
    display: flex;
    justify-content: flex-end;
    padding: 20px 26px 26px;
    border-top: 1px solid rgba(67, 89, 113, .12);
  }

  @media (max-width: 991.98px) {
    .settings-hero {
      align-items: flex-start;
      flex-direction: column;
    }

    .settings-hero-content {
      flex-direction: column;
    }

    .toggle-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
@endsection
