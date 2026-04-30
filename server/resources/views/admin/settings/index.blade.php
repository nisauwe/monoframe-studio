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
    <div class="alert alert-success alert-dismissible fade show mb-4 settings-alert" role="alert">
      <i class="bx bx-check-circle me-1"></i>
      {{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if (session('error'))
    <div class="alert alert-danger alert-dismissible fade show mb-4 settings-alert" role="alert">
      <i class="bx bx-error-circle me-1"></i>
      {{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if ($errors->any())
    <div class="alert alert-danger alert-dismissible fade show mb-4 settings-alert" role="alert">
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
        <div class="settings-stat-icon"><i class="bx bx-calendar-check"></i></div>
        <span>Booking</span>
        <h4>{{ $setting->booking_is_active ? 'Aktif' : 'Nonaktif' }}</h4>
        <p>Kontrol booking dari aplikasi klien.</p>
      </div>
    </div>

    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <div class="settings-stat-icon"><i class="bx bx-star"></i></div>
        <span>Review Publik</span>
        <h4>{{ $setting->show_reviews_on_client ? 'Tampil' : 'Tersembunyi' }}</h4>
        <p>{{ $reviewSummary['displayable'] }} review lolos filter.</p>
      </div>
    </div>

    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <div class="settings-stat-icon"><i class="bx bx-support"></i></div>
        <span>Kontak Klien</span>
        <h4>{{ $contactSummary['visible_to_client'] }}</h4>
        <p>Dari {{ $contactSummary['total'] }} kontak call center.</p>
      </div>
    </div>

    <div class="col-xl-3 col-md-6">
      <div class="settings-stat-card">
        <div class="settings-stat-icon"><i class="bx bx-wallet"></i></div>
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
      <div class="settings-dirty-badge" id="settingsDirtyBadge">
        <i class="bx bx-info-circle"></i>
        <span>Ada perubahan yang belum disimpan.</span>
      </div>

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
                <div class="preview-box" id="studioLogoPreview">
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
                <div class="preview-box preview-banner" id="clientBannerPreview">
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
                  <option value="{{ $rating }}" {{ (int) $value('minimum_rating_display', $setting->minimum_rating_display) === $rating ? 'selected' : '' }}>
                    {{ $rating }} Bintang ke atas
                  </option>
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
    --mf-primary: #344fa5;
    --mf-primary-dark: #233b93;
    --mf-primary-light: #6b7fd7;
    --mf-primary-soft: #eef4ff;
    --mf-text: #10223f;
    --mf-muted: #697a8d;
    --mf-border: #e5edf5;

    max-width: 1480px;
    margin: 0 auto;
  }

  .settings-page *,
  .settings-page *::before,
  .settings-page *::after {
    transition:
      transform .24s ease,
      box-shadow .24s ease,
      border-color .24s ease,
      background-color .24s ease,
      color .24s ease,
      opacity .24s ease;
  }

  .settings-alert {
    border: 0;
    border-radius: 20px;
    box-shadow: 0 16px 38px rgba(67, 89, 113, .12);
  }

  .settings-hero {
    position: relative;
    isolation: isolate;
    overflow: hidden;
    display: flex;
    justify-content: space-between;
    gap: 24px;
    align-items: center;
    padding: 30px;
    border-radius: 30px;
    color: #fff;
    background:
      radial-gradient(circle at 86% 16%, rgba(255, 255, 255, .24), transparent 28%),
      linear-gradient(135deg, #344fa5 0%, #4f6dd1 58%, #6b7fd7 100%);
    box-shadow: 0 24px 50px rgba(52, 79, 165, .24);
  }

  .settings-hero::before,
  .settings-hero::after {
    content: '';
    position: absolute;
    border-radius: 999px;
    background: rgba(255, 255, 255, .12);
    z-index: -1;
  }

  .settings-hero::before {
    width: 220px;
    height: 220px;
    top: -115px;
    right: -85px;
  }

  .settings-hero::after {
    width: 150px;
    height: 150px;
    left: 52%;
    bottom: -92px;
  }

  .settings-hero:hover {
    transform: translateY(-5px);
    box-shadow: 0 32px 68px rgba(52, 79, 165, .32);
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
    background: rgba(255, 255, 255, .18);
    border: 1px solid rgba(255, 255, 255, .20);
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 34px;
    flex-shrink: 0;
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, .20);
  }

  .settings-hero:hover .settings-hero-icon {
    transform: rotate(-6deg) scale(1.06);
    background: rgba(255, 255, 255, .24);
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
    color: rgba(255, 255, 255, .88);
    line-height: 1.7;
    font-weight: 600;
  }

  .settings-hero-btn {
    position: relative;
    z-index: 2;
    background: #fff;
    color: #344fa5;
    border: 0;
    border-radius: 16px;
    min-height: 50px;
    padding: 0 22px;
    font-weight: 900;
    white-space: nowrap;
    box-shadow: 0 14px 28px rgba(0, 0, 0, .12);
  }

  .settings-hero-btn:hover {
    color: #233b93;
    background: #f8fbff;
    transform: translateY(-3px);
    box-shadow: 0 20px 38px rgba(0, 0, 0, .18);
  }

  .settings-stat-card,
  .settings-card,
  .upload-card,
  .toggle-card,
  .integration-card {
    background: #fff;
    border: 1px solid rgba(226, 234, 240, .95);
    border-radius: 24px;
    box-shadow: 0 14px 38px rgba(67, 89, 113, .10);
  }

  .settings-card {
    overflow: hidden;
    position: relative;
  }

  .settings-card:hover {
    box-shadow: 0 24px 65px rgba(67, 89, 113, .14);
  }

  .settings-stat-card,
  .integration-card {
    position: relative;
    overflow: hidden;
    cursor: pointer;
    transform: translateY(0);
    will-change: transform, box-shadow;
    perspective: 900px;
  }

  .settings-stat-card {
    min-height: 148px;
    padding: 22px;
  }

  .integration-card {
    padding: 24px;
    height: 100%;
    min-height: 246px;
    border-color: rgba(226, 234, 240, .95);
  }

  .settings-stat-card::before,
  .integration-card::before {
    content: '';
    position: absolute;
    inset: 0;
    background:
      radial-gradient(circle at 90% 10%, rgba(52, 79, 165, .16), transparent 35%),
      linear-gradient(135deg, rgba(52, 79, 165, .04), rgba(168, 203, 224, .10));
    opacity: 0;
    pointer-events: none;
    z-index: 0;
  }

  .settings-stat-card::after,
  .integration-card::after {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background:
      linear-gradient(
        135deg,
        rgba(255, 255, 255, .55),
        rgba(255, 255, 255, 0) 45%,
        rgba(52, 79, 165, .10)
      );
    opacity: 0;
    pointer-events: none;
    z-index: 1;
  }

  .settings-stat-card > *,
  .integration-card > * {
    position: relative;
    z-index: 2;
  }

  .settings-stat-card:hover,
  .settings-reveal.is-visible.settings-stat-card:hover,
  .integration-card:hover,
  .settings-reveal.is-visible.integration-card:hover {
    transform: translateY(-10px) scale(1.018);
    border-color: rgba(52, 79, 165, .32);
    box-shadow:
      0 30px 65px rgba(52, 79, 165, .20),
      0 12px 26px rgba(15, 23, 42, .08);
  }

  .settings-stat-card:hover::before,
  .settings-reveal.is-visible.settings-stat-card:hover::before,
  .integration-card:hover::before,
  .settings-reveal.is-visible.integration-card:hover::before,
  .settings-stat-card:hover::after,
  .settings-reveal.is-visible.settings-stat-card:hover::after,
  .integration-card:hover::after,
  .settings-reveal.is-visible.integration-card:hover::after {
    opacity: 1;
  }

  .settings-stat-card:active,
  .settings-reveal.is-visible.settings-stat-card:active,
  .integration-card:active,
  .settings-reveal.is-visible.integration-card:active {
    transform: translateY(-4px) scale(.99);
    box-shadow:
      0 18px 38px rgba(52, 79, 165, .16),
      0 8px 18px rgba(15, 23, 42, .06);
  }

  .settings-stat-icon {
    position: absolute;
    top: 18px;
    right: 18px;
    width: 42px;
    height: 42px;
    display: grid;
    place-items: center;
    border-radius: 16px;
    color: #344fa5;
    background: rgba(52, 79, 165, .10);
    font-size: 22px;
    opacity: .92;
    z-index: 3;
  }

  .settings-stat-card:hover .settings-stat-icon,
  .settings-reveal.is-visible.settings-stat-card:hover .settings-stat-icon {
    transform: rotate(-8deg) scale(1.12);
    background: linear-gradient(135deg, #344fa5, #233b93);
    color: #fff;
    box-shadow: 0 14px 28px rgba(52, 79, 165, .26);
  }

  .settings-stat-card span {
    display: block;
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

  .settings-stat-card:hover span,
  .settings-reveal.is-visible.settings-stat-card:hover span {
    color: #344fa5;
  }

  .settings-stat-card:hover h4,
  .settings-reveal.is-visible.settings-stat-card:hover h4 {
    color: #17384d;
  }

  .settings-stat-card:hover p,
  .settings-reveal.is-visible.settings-stat-card:hover p {
    color: #4f6075;
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
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, .40);
  }

  .integration-card:hover .integration-icon,
  .settings-reveal.is-visible.integration-card:hover .integration-icon {
    transform: rotate(-7deg) scale(1.12);
    background: linear-gradient(135deg, #344fa5, #233b93);
    color: #fff;
    box-shadow: 0 14px 28px rgba(52, 79, 165, .25);
  }

  .integration-card h6 {
    font-weight: 900;
    color: #2b354f;
    margin-bottom: 16px;
  }

  .integration-card p {
    margin-bottom: 7px;
    color: #697a8d;
    font-weight: 700;
  }

  .integration-card:hover h6,
  .settings-reveal.is-visible.integration-card:hover h6 {
    color: #17384d;
  }

  .integration-card:hover p,
  .settings-reveal.is-visible.integration-card:hover p {
    color: #4f6075;
  }

  .integration-card a {
    position: relative;
    z-index: 3;
    border-radius: 14px;
    font-weight: 900;
    padding: 7px 13px;
    background: rgba(255, 255, 255, .82);
  }

  .integration-card a:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 22px rgba(52, 79, 165, .16);
  }

  .settings-dirty-badge {
    display: none;
    align-items: center;
    gap: 8px;
    margin: 18px 22px 0;
    padding: 12px 15px;
    border-radius: 16px;
    color: #8a4b00;
    background: #fff6df;
    border: 1px solid #ffe2a3;
    font-weight: 800;
  }

  .settings-dirty-badge.show {
    display: flex;
    animation: settingsFadeIn .22s ease;
  }

  .settings-tabs-wrap {
    padding: 20px 22px 0;
    border-bottom: 1px solid rgba(67, 89, 113, .12);
    background: linear-gradient(180deg, #fff 0%, #fbfdff 100%);
    overflow-x: auto;
  }

  .settings-tabs {
    gap: 8px;
    flex-wrap: nowrap;
    min-width: max-content;
    padding-bottom: 14px;
  }

  .settings-tabs .nav-link {
    border-radius: 14px;
    font-weight: 800;
    color: #566a7f;
    white-space: nowrap;
    padding: 10px 15px;
  }

  .settings-tabs .nav-link:hover {
    color: #344fa5;
    background: #eef4ff;
    transform: translateY(-2px);
  }

  .settings-tabs .nav-link.active {
    background: linear-gradient(135deg, #344fa5, #233b93);
    color: #fff;
    box-shadow: 0 10px 24px rgba(52, 79, 165, .25);
  }

  .settings-tab-content {
    padding: 26px;
  }

  .tab-pane {
    animation: settingsFadeIn .26s ease;
  }

  @keyframes settingsFadeIn {
    from {
      opacity: 0;
      transform: translateY(8px);
    }

    to {
      opacity: 1;
      transform: translateY(0);
    }
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

  .settings-page .form-label {
    color: #2b354f;
    font-size: 13px;
    font-weight: 800;
    margin-bottom: 8px;
  }

  .settings-page .form-control,
  .settings-page .form-select {
    min-height: 46px;
    border-radius: 14px;
    border-color: #dbe6ef;
    color: #10223f;
    font-weight: 650;
    box-shadow: none;
  }

  .settings-page textarea.form-control {
    min-height: 98px;
  }

  .settings-page .form-control:hover,
  .settings-page .form-select:hover {
    border-color: rgba(52, 79, 165, .36);
    box-shadow: 0 10px 24px rgba(52, 79, 165, .06);
  }

  .settings-page .form-control:focus,
  .settings-page .form-select:focus {
    border-color: #344fa5;
    box-shadow: 0 0 0 .22rem rgba(52, 79, 165, .12);
  }

  .upload-card {
    position: relative;
    overflow: hidden;
    padding: 20px;
    height: 100%;
    background:
      radial-gradient(circle at 85% 12%, rgba(52, 79, 165, .06), transparent 28%),
      linear-gradient(180deg, #fff 0%, #f8fbff 100%);
  }

  .upload-card:hover {
    transform: translateY(-7px);
    border-color: rgba(52, 79, 165, .25);
    box-shadow: 0 24px 52px rgba(52, 79, 165, .14);
  }

  .preview-box {
    min-height: 230px;
    border: 2px dashed rgba(52, 79, 165, .20);
    border-radius: 22px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
    gap: 10px;
    background:
      radial-gradient(circle at 80% 20%, rgba(255,255,255,.45), transparent 32%),
      linear-gradient(135deg, #d9edf7, #a8cbe0);
    overflow: hidden;
  }

  .preview-box:hover {
    transform: scale(1.015);
    border-color: #344fa5;
    box-shadow: inset 0 0 0 1px rgba(52, 79, 165, .10);
  }

  .preview-box img {
    width: 100%;
    height: 100%;
    min-height: 230px;
    object-fit: contain;
    padding: 14px;
    filter: drop-shadow(0 14px 18px rgba(0,0,0,.14));
  }

  .preview-banner img {
    object-fit: cover;
    padding: 0;
  }

  .preview-box i {
    font-size: 42px;
    color: #344fa5;
  }

  .preview-box span {
    color: #344fa5;
    font-weight: 900;
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

  .toggle-card:hover {
    transform: translateY(-7px);
    border-color: rgba(52, 79, 165, .22);
    box-shadow: 0 24px 52px rgba(52, 79, 165, .13);
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

  .settings-page .form-check-input {
    cursor: pointer;
    border-color: #b8c7d5;
  }

  .settings-page .form-check-input:checked {
    background-color: #344fa5;
    border-color: #344fa5;
  }

  .settings-page .form-check-input:focus {
    box-shadow: 0 0 0 .22rem rgba(52, 79, 165, .12);
  }

  .settings-page .form-check-label {
    cursor: pointer;
    color: #2b354f;
    font-weight: 650;
  }

  .settings-footer-actions {
    display: flex;
    justify-content: flex-end;
    padding: 20px 26px 26px;
    border-top: 1px solid rgba(67, 89, 113, .12);
  }

  .settings-footer-actions .btn {
    border-radius: 16px;
    padding: 12px 20px;
    font-weight: 900;
    background: linear-gradient(135deg, #344fa5, #233b93);
    border: 0;
    box-shadow: 0 14px 28px rgba(52, 79, 165, .24);
  }

  .settings-footer-actions .btn:hover {
    transform: translateY(-3px);
    box-shadow: 0 20px 38px rgba(52, 79, 165, .32);
  }

  .settings-floating-save {
    position: sticky;
    bottom: 18px;
    z-index: 20;
    display: flex;
    justify-content: flex-end;
    pointer-events: none;
    margin-top: 22px;
  }

  .settings-floating-save .btn {
    pointer-events: auto;
    border-radius: 18px;
    padding: 13px 20px;
    font-weight: 900;
    background: linear-gradient(135deg, #344fa5, #233b93);
    border: 0;
    color: #fff;
    box-shadow: 0 18px 40px rgba(52, 79, 165, .28);
  }

  .settings-floating-save .btn:hover {
    transform: translateY(-4px);
    box-shadow: 0 24px 52px rgba(52, 79, 165, .36);
  }

  .settings-reveal {
    opacity: 0;
    transform: translateY(18px);
  }

  .settings-reveal.is-visible {
    opacity: 1;
    transform: translateY(0);
  }

  .settings-reveal.is-visible.settings-stat-card:hover,
  .settings-reveal.is-visible.integration-card:hover {
    opacity: 1;
    transform: translateY(-10px) scale(1.018);
  }

  .settings-reveal.is-visible.settings-stat-card.is-tilting,
  .settings-reveal.is-visible.integration-card.is-tilting {
    opacity: 1;
  }

  @media (max-width: 991.98px) {
    .settings-hero {
      align-items: flex-start;
      flex-direction: column;
    }

    .settings-hero-content {
      flex-direction: column;
    }

    .settings-hero-btn {
      width: 100%;
    }

    .toggle-grid {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 575.98px) {
    .settings-tab-content {
      padding: 22px 16px 24px;
    }

    .settings-hero {
      padding: 24px;
    }

    .settings-hero h4 {
      font-size: 21px;
    }

    .settings-hero p {
      font-size: 13px;
    }

    .settings-tabs-wrap {
      padding-left: 16px;
      padding-right: 16px;
    }

    .settings-footer-actions {
      padding-left: 16px;
      padding-right: 16px;
    }

    .settings-footer-actions .btn,
    .settings-floating-save .btn {
      width: 100%;
    }
  }
</style>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    const settingsPage = document.querySelector('.settings-page');
    const settingsForm = document.getElementById('settings-form');
    const dirtyBadge = document.getElementById('settingsDirtyBadge');

    if (!settingsPage || !settingsForm) return;

    const revealTargets = [
      ...settingsPage.querySelectorAll('.settings-alert'),
      ...settingsPage.querySelectorAll('.settings-hero'),
      ...settingsPage.querySelectorAll('.settings-stat-card'),
      ...settingsPage.querySelectorAll('.settings-card'),
      ...settingsPage.querySelectorAll('.upload-card'),
      ...settingsPage.querySelectorAll('.toggle-card'),
      ...settingsPage.querySelectorAll('.integration-card')
    ];

    revealTargets.forEach(function (element) {
      element.classList.add('settings-reveal');
    });

    const revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry, index) {
        if (entry.isIntersecting) {
          setTimeout(function () {
            entry.target.classList.add('is-visible');
          }, index * 55);

          revealObserver.unobserve(entry.target);
        }
      });
    }, {
      threshold: 0.12
    });

    revealTargets.forEach(function (element) {
      revealObserver.observe(element);
    });

    const addTiltEffect = function (selector) {
      const cards = settingsPage.querySelectorAll(selector);

      cards.forEach(function (card) {
        card.addEventListener('mousemove', function (event) {
          const rect = card.getBoundingClientRect();
          const x = event.clientX - rect.left;
          const y = event.clientY - rect.top;

          const centerX = rect.width / 2;
          const centerY = rect.height / 2;

          const rotateX = ((y - centerY) / centerY) * -3;
          const rotateY = ((x - centerX) / centerX) * 3;

          card.classList.add('is-tilting');
          card.style.transform =
            'translateY(-10px) scale(1.018) rotateX(' +
            rotateX +
            'deg) rotateY(' +
            rotateY +
            'deg)';
        });

        card.addEventListener('mouseleave', function () {
          card.classList.remove('is-tilting');
          card.style.transform = '';
        });
      });
    };

    addTiltEffect('.settings-stat-card');
    addTiltEffect('.integration-card');

    const markDirty = function () {
      if (dirtyBadge) {
        dirtyBadge.classList.add('show');
      }
    };

    settingsForm.querySelectorAll('input, textarea, select').forEach(function (field) {
      field.addEventListener('change', markDirty);
      field.addEventListener('input', markDirty);
    });

    const previewImage = function (input, previewSelector, fallbackIconClass, fallbackText) {
      const preview = document.querySelector(previewSelector);

      if (!input || !preview) return;

      input.addEventListener('change', function () {
        const file = this.files && this.files[0];

        if (!file) return;

        const allowedTypes = [
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/jpg'
        ];

        if (!allowedTypes.includes(file.type)) {
          alert('Format gambar harus JPG, PNG, atau WEBP.');
          this.value = '';
          preview.innerHTML =
            '<i class="' +
            fallbackIconClass +
            '"></i><span>' +
            fallbackText +
            '</span>';
          return;
        }

        const reader = new FileReader();

        reader.onload = function (event) {
          preview.innerHTML =
            '<img src="' + event.target.result + '" alt="Preview">';
        };

        reader.readAsDataURL(file);
      });
    };

    previewImage(
      settingsForm.querySelector('input[name="studio_logo"]'),
      '#studioLogoPreview',
      'bx bx-image',
      'Belum ada logo'
    );

    previewImage(
      settingsForm.querySelector('input[name="client_home_banner"]'),
      '#clientBannerPreview',
      'bx bx-photo-album',
      'Belum ada banner'
    );

    const removeLogoCheckbox = settingsForm.querySelector('input[name="remove_studio_logo"]');
    const removeBannerCheckbox = settingsForm.querySelector('input[name="remove_client_home_banner"]');

    if (removeLogoCheckbox) {
      removeLogoCheckbox.addEventListener('change', function () {
        const preview = document.getElementById('studioLogoPreview');

        if (this.checked && preview) {
          preview.innerHTML =
            '<i class="bx bx-trash"></i><span>Logo akan dihapus saat disimpan</span>';
        }
      });
    }

    if (removeBannerCheckbox) {
      removeBannerCheckbox.addEventListener('change', function () {
        const preview = document.getElementById('clientBannerPreview');

        if (this.checked && preview) {
          preview.innerHTML =
            '<i class="bx bx-trash"></i><span>Banner akan dihapus saat disimpan</span>';
        }
      });
    }

    settingsForm.addEventListener('submit', function () {
      const submitButtons = settingsPage.querySelectorAll(
        'button[type="submit"][form="settings-form"], #settings-form button[type="submit"]'
      );

      submitButtons.forEach(function (button) {
        button.disabled = true;
        button.innerHTML =
          '<span class="spinner-border spinner-border-sm me-1"></span> Menyimpan...';
      });
    });
  });
</script>
@endsection
