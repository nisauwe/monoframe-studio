@extends('layouts/contentNavbarLayout')

@section('title', 'Call Center Kontak')

@section('content')
  @php
    $platformOptions = [
        'whatsapp' => 'WhatsApp',
        'instagram' => 'Instagram',
        'tiktok' => 'TikTok',
        'email' => 'Email',
        'phone' => 'Telepon',
        'website' => 'Website',
    ];

    $statusBadgeClass = function ($status) {
        return match ($status) {
            'active' => 'success',
            'standby' => 'warning',
            'inactive' => 'secondary',
            default => 'secondary',
        };
    };

    $priorityBadgeClass = function ($priority) {
        return match ($priority) {
            'urgent' => 'danger',
            'high' => 'warning',
            'normal' => 'primary',
            'low' => 'secondary',
            default => 'secondary',
        };
    };

    $platformIcon = function ($platform) {
        return match ($platform) {
            'whatsapp' => 'bxl-whatsapp',
            'instagram' => 'bxl-instagram',
            'tiktok' => 'bxl-tiktok',
            'email' => 'bx-envelope',
            'phone' => 'bx-phone',
            'website' => 'bx-globe',
            default => 'bx-link',
        };
    };

    $platformColor = function ($platform) {
        return match ($platform) {
            'whatsapp' => 'success',
            'instagram' => 'danger',
            'tiktok' => 'dark',
            'email' => 'primary',
            'phone' => 'info',
            'website' => 'secondary',
            default => 'secondary',
        };
    };

    $hasActiveFilter = request('q') || request('division') || request('platform');
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell call-center-page">

      {{-- ALERT --}}
      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
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
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      {{-- HERO HEADER --}}
      <div class="call-hero-card mb-4">
        <div class="call-hero-left">
          <div class="call-hero-icon">
            <i class="bx bx-headphone"></i>
          </div>

          <div>
            <div class="call-hero-kicker">PUSAT BANTUAN KLIEN</div>
            <h4>Call Center Kontak</h4>
            <p>
              Kelola daftar kontak bantuan yang bisa dihubungi klien untuk pertanyaan paket,
              request custom, pembayaran, kendala aplikasi, dan kebutuhan operasional studio.
            </p>
          </div>
        </div>

        <div class="call-hero-actions">
          <button type="button" class="btn call-hero-btn" data-bs-toggle="modal" data-bs-target="#createContactModal">
            <i class="bx bx-plus me-1"></i>
            Tambah Kontak
          </button>
        </div>
      </div>

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        <div class="col-xl-4 col-md-6">
          <div class="call-stat-card">
            <div>
              <span>Total Kontak</span>
              <h3>{{ $summary['total'] ?? 0 }}</h3>
              <p>Kontak bantuan terdaftar</p>
            </div>

            <div class="call-stat-icon bg-label-primary">
              <i class="bx bx-phone-call"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-4 col-md-6">
          <div class="call-stat-card">
            <div>
              <span>Kontak Aktif</span>
              <h3>{{ $summary['active'] ?? 0 }}</h3>
              <p>Siap dihubungi klien</p>
            </div>

            <div class="call-stat-icon bg-label-success">
              <i class="bx bx-check-circle"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-4 col-md-6">
          <div class="call-stat-card">
            <div>
              <span>Kontak Darurat</span>
              <h3>{{ $summary['emergency'] ?? 0 }}</h3>
              <p>Prioritas bantuan cepat</p>
            </div>

            <div class="call-stat-icon bg-label-danger">
              <i class="bx bx-error-circle"></i>
            </div>
          </div>
        </div>
      </div>

      {{-- INFO --}}
      <div class="call-info-card mb-4">
        <div class="call-info-icon">
          <i class="bx bx-info-circle"></i>
        </div>

        <div>
          <h6>Pengaturan Call Center</h6>
          <p>
            Kontak yang aktif dan ditandai tampil ke klien dapat digunakan sebagai jalur bantuan di aplikasi.
            Admin dapat mengatur divisi, platform, jam layanan, prioritas, status, dan kontak darurat.
          </p>
        </div>
      </div>

      {{-- MAIN CONTACT CARD --}}
      <div class="call-main-card mb-4">
        <div class="call-main-header">
          <div>
            <h5>Daftar Kontak Call Center</h5>
            <p>Kelola kontak bantuan berdasarkan divisi, platform, status, dan prioritas.</p>
          </div>

          <div class="call-count-pill">
            <i class="bx bx-headphone"></i>
            {{ $contacts->count() }} kontak
          </div>
        </div>

        {{-- FILTER --}}
        <div class="call-filter-area">
          <form method="GET" action="{{ route('admin.call-center.index') }}" class="call-filter-box">
            <div class="call-filter-head">
              <div>
                <h6>Filter Kontak</h6>
                <p>Cari kontak berdasarkan nama, divisi, platform, atau nomor kontak.</p>
              </div>

              @if ($hasActiveFilter)
                <span class="call-filter-active">
                  <i class="bx bx-filter-alt"></i>
                  Filter aktif
                </span>
              @endif
            </div>

            <div class="call-filter-grid">
              <div class="call-filter-field call-search-field">
                <label class="form-label">Pencarian Kontak</label>
                <div class="call-input-with-icon">
                  <span>
                    <i class="bx bx-search"></i>
                  </span>

                  <input
                    type="text"
                    name="q"
                    class="form-control"
                    value="{{ request('q') }}"
                    placeholder="Cari nama, divisi, kontak..."
                  >
                </div>
              </div>

              <div class="call-filter-field">
                <label class="form-label">Divisi</label>
                <select name="division" class="form-select">
                  <option value="">Semua Divisi</option>

                  @foreach ($divisions as $division)
                    <option value="{{ $division }}" @selected(request('division') === $division)>
                      {{ $division }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="call-filter-field">
                <label class="form-label">Platform</label>
                <select name="platform" class="form-select">
                  <option value="">Semua Platform</option>

                  @foreach ($platformOptions as $value => $label)
                    <option value="{{ $value }}" @selected(request('platform') === $value)>
                      {{ $label }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="call-filter-buttons">
                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-filter-alt me-1"></i>
                  Filter
                </button>

                <a href="{{ route('admin.call-center.index') }}" class="btn btn-outline-secondary">
                  Reset
                </a>
              </div>
            </div>
          </form>
        </div>

        {{-- CONTACT LIST --}}
        <div class="call-contact-area">
          @if ($contacts->isEmpty())
            <div class="call-empty-state">
              <div class="call-empty-icon">
                <i class="bx bx-phone-off"></i>
              </div>

              <h6>Belum ada kontak</h6>
              <p>Tambahkan kontak WhatsApp, Instagram, TikTok, Email, Telepon, atau Website.</p>

              <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#createContactModal">
                <i class="bx bx-plus me-1"></i>
                Tambah Kontak
              </button>
            </div>
          @else
            <div class="call-contact-grid">
              @foreach ($contacts as $contact)
                @php
                  $statusClass = $statusBadgeClass($contact->status);
                  $priorityClass = $priorityBadgeClass($contact->priority);
                  $icon = $platformIcon($contact->platform);
                  $color = $platformColor($contact->platform);
                @endphp

                <div class="call-contact-card">
                  <div class="call-contact-top">
                    <div class="call-platform-avatar bg-label-{{ $color }}">
                      <i class="bx {{ $icon }}"></i>
                    </div>

                    <div class="call-contact-badges">
                      <span class="badge bg-label-{{ $statusClass }}">
                        {{ $contact->status_label }}
                      </span>

                      @if ($contact->is_emergency)
                        <span class="badge bg-label-danger">
                          Darurat
                        </span>
                      @endif
                    </div>
                  </div>

                  <div class="call-contact-title">
                    <h6>{{ $contact->title }}</h6>
                    <p>{{ $contact->description ?: 'Tidak ada deskripsi.' }}</p>
                  </div>

                  <div class="call-contact-main">
                    <div>
                      <span>
                        <i class="bx {{ $icon }}"></i>
                        {{ $contact->platform_label }}
                      </span>

                      <strong>{{ $contact->contact_value }}</strong>
                    </div>

                    @if ($contact->contact_url)
                      <a href="{{ $contact->contact_url }}" target="_blank" class="btn btn-primary btn-sm">
                        <i class="bx bx-link-external me-1"></i>
                        Buka
                      </a>
                    @endif
                  </div>

                  <div class="call-contact-info">
                    <div>
                      <span>Divisi</span>
                      <strong>{{ $contact->division ?: '-' }}</strong>
                    </div>

                    <div>
                      <span>PIC</span>
                      <strong>{{ $contact->contact_person ?: '-' }}</strong>
                    </div>

                    <div>
                      <span>Jam Layanan</span>
                      <strong>{{ $contact->service_hours ?: '-' }}</strong>
                    </div>

                    <div>
                      <span>Prioritas</span>
                      <strong>
                        <span class="badge bg-label-{{ $priorityClass }}">
                          {{ $contact->priority_label }}
                        </span>
                      </strong>
                    </div>
                  </div>

                  <div class="call-visible-box">
                    <div>
                      <span>Tampil di aplikasi klien</span>
                      <p>{{ $contact->is_visible_to_client ? 'Ditampilkan untuk klien.' : 'Disembunyikan dari klien.' }}</p>
                    </div>

                    @if ($contact->is_visible_to_client)
                      <span class="badge bg-label-success">Ya</span>
                    @else
                      <span class="badge bg-label-secondary">Tidak</span>
                    @endif
                  </div>

                  <div class="call-contact-actions">
                    <button
                      type="button"
                      class="btn btn-outline-warning btn-sm btn-edit-contact"
                      data-bs-toggle="modal"
                      data-bs-target="#editContactModal"
                      data-id="{{ $contact->id }}"
                      data-title="{{ $contact->title }}"
                      data-division="{{ $contact->division }}"
                      data-description="{{ $contact->description }}"
                      data-contact-person="{{ $contact->contact_person }}"
                      data-platform="{{ $contact->platform }}"
                      data-contact-value="{{ $contact->contact_value }}"
                      data-whatsapp-number="{{ $contact->whatsapp_number }}"
                      data-url="{{ $contact->url }}"
                      data-service-hours="{{ $contact->service_hours }}"
                      data-priority="{{ $contact->priority }}"
                      data-status="{{ $contact->status }}"
                      data-is-emergency="{{ $contact->is_emergency ? 1 : 0 }}"
                      data-is-visible-to-client="{{ $contact->is_visible_to_client ? 1 : 0 }}"
                      data-sort-order="{{ $contact->sort_order }}"
                    >
                      <i class="bx bx-edit-alt me-1"></i>
                      Edit
                    </button>

                    <form action="{{ route('admin.call-center.toggle-status', $contact) }}" method="POST">
                      @csrf
                      @method('PATCH')

                      <button type="submit" class="btn btn-outline-secondary btn-sm">
                        @if ($contact->status === 'active')
                          <i class="bx bx-hide me-1"></i>
                          Nonaktif
                        @else
                          <i class="bx bx-check-circle me-1"></i>
                          Aktif
                        @endif
                      </button>
                    </form>

                    <form action="{{ route('admin.call-center.destroy', $contact) }}" method="POST" class="form-delete-contact">
                      @csrf
                      @method('DELETE')

                      <button type="submit" class="btn btn-outline-danger btn-sm">
                        <i class="bx bx-trash me-1"></i>
                        Hapus
                      </button>
                    </form>
                  </div>
                </div>
              @endforeach
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- CREATE MODAL --}}
  <div class="modal fade call-contact-modal" id="createContactModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered call-modal-dialog">
      <form method="POST" action="{{ route('admin.call-center.store') }}" class="modal-content call-modal-content">
        @csrf

        <div class="modal-header call-modal-header">
          <div>
            <h5 class="modal-title">Tambah Kontak</h5>
            <small>Tambahkan kontak bantuan baru untuk klien Monoframe Studio.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body call-modal-body">
          @include('admin.call-center.partials.form', [
              'prefix' => 'create',
              'contact' => null,
          ])
        </div>

        <div class="modal-footer call-modal-footer">
          <button type="button" class="btn btn-outline-secondary call-modal-cancel-btn" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-primary call-modal-submit-btn">
            <i class="bx bx-save me-1"></i>
            Simpan Kontak
          </button>
        </div>
      </form>
    </div>
  </div>

  {{-- EDIT MODAL --}}
  <div class="modal fade call-contact-modal" id="editContactModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered call-modal-dialog">
      <form method="POST" action="#" class="modal-content call-modal-content" id="editContactForm">
        @csrf
        @method('PUT')

        <div class="modal-header call-modal-header">
          <div>
            <h5 class="modal-title">Edit Kontak</h5>
            <small>Ubah detail kontak bantuan yang sudah terdaftar.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body call-modal-body">
          @include('admin.call-center.partials.form', [
              'prefix' => 'edit',
              'contact' => null,
          ])
        </div>

        <div class="modal-footer call-modal-footer">
          <button type="button" class="btn btn-outline-secondary call-modal-cancel-btn" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-warning call-modal-submit-btn">
            <i class="bx bx-save me-1"></i>
            Update Kontak
          </button>
        </div>
      </form>
    </div>
  </div>

  <style>
    .call-center-page {
      max-width: 1480px;
      margin: 0 auto;
    }

    .call-hero-card {
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

    .call-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .call-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .call-hero-icon {
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

    .call-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .call-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .call-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .call-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .call-hero-btn {
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

    .call-hero-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .call-stat-card {
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

    .call-stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.14);
    }

    .call-stat-card span {
      display: block;
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .call-stat-card h3 {
      color: var(--mf-ink);
      font-size: 34px;
      font-weight: 900;
      line-height: 1;
      margin-bottom: 10px;
    }

    .call-stat-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 0;
    }

    .call-stat-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 28px;
    }

    .call-info-card {
      display: grid;
      grid-template-columns: 58px 1fr;
      gap: 16px;
      align-items: flex-start;
      padding: 22px 24px;
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
    }

    .call-info-icon {
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

    .call-info-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .call-info-card p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .call-main-card {
      border-radius: 32px;
      background: #ffffff;
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .call-main-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      flex-wrap: wrap;
      padding: 30px 34px 22px;
      border-bottom: 1px solid var(--mf-border);
    }

    .call-main-header h5 {
      color: var(--mf-ink);
      font-size: 20px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .call-main-header p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .call-count-pill {
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

    .call-filter-area {
      padding: 26px 34px 30px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .call-filter-box {
      padding: 20px;
      border: 1px solid var(--mf-border);
      border-radius: 26px;
      background: #ffffff;
      box-shadow: 0 10px 24px rgba(22, 43, 77, 0.04);
    }

    .call-filter-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      flex-wrap: wrap;
      padding-bottom: 16px;
      margin-bottom: 16px;
      border-bottom: 1px solid rgba(224, 231, 241, 0.85);
    }

    .call-filter-head h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .call-filter-head p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.55;
      margin-bottom: 0;
    }

    .call-filter-active {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 11px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 12px;
      font-weight: 900;
      white-space: nowrap;
    }

    .call-filter-grid {
      display: grid;
      grid-template-columns: minmax(260px, 1.5fr) minmax(170px, 0.7fr) minmax(170px, 0.7fr) auto;
      gap: 14px;
      align-items: end;
    }

    .call-filter-field {
      min-width: 0;
    }

    .call-filter-field .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .call-filter-field .form-select {
      width: 100%;
      height: 52px !important;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      box-shadow: none !important;
    }

    .call-filter-field .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .call-input-with-icon {
      display: flex;
      align-items: stretch;
      width: 100%;
      height: 52px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
      overflow: hidden;
      transition: 0.18s ease;
    }

    .call-input-with-icon:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .call-input-with-icon span {
      width: 58px;
      min-width: 58px;
      height: 100%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: #ffffff;
      color: var(--mf-ink);
      border-right: 1px solid var(--mf-border);
      font-size: 20px;
    }

    .call-input-with-icon input {
      height: 100% !important;
      flex: 1;
      min-width: 0;
      border: 0 !important;
      border-radius: 0 !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      padding: 0 18px !important;
      box-shadow: none !important;
      outline: none !important;
    }

    .call-input-with-icon input::placeholder {
      color: rgba(107, 124, 147, 0.62) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
    }

    .call-filter-buttons {
      display: flex;
      align-items: end;
      justify-content: flex-end;
      gap: 10px;
      min-width: 220px;
      width: 100%;
    }

    .call-filter-buttons .btn {
      height: 52px;
      border-radius: 18px;
      font-weight: 900;
      padding-left: 18px;
      padding-right: 18px;
      white-space: nowrap;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .call-filter-buttons .btn-primary {
      min-width: 112px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.20);
    }

    .call-filter-buttons .btn-outline-secondary {
      min-width: 90px;
      background: #ffffff;
    }

    .call-contact-area {
      padding: 0 34px 34px;
      background:
        radial-gradient(circle at bottom left, rgba(88, 115, 220, 0.08), transparent 34%),
        linear-gradient(180deg, #f8fbfd 0%, #ffffff 100%);
    }

    .call-contact-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }

    .call-contact-card {
      display: flex;
      flex-direction: column;
      min-height: 100%;
      padding: 20px;
      border: 1px solid var(--mf-border);
      border-radius: 28px;
      background: #ffffff;
      box-shadow: 0 14px 34px rgba(22, 43, 77, 0.06);
      transition: 0.22s ease;
    }

    .call-contact-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 50px rgba(52, 79, 165, 0.14);
    }

    .call-contact-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 16px;
    }

    .call-platform-avatar {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      flex-shrink: 0;
    }

    .call-contact-badges {
      display: flex;
      justify-content: flex-end;
      flex-wrap: wrap;
      gap: 7px;
    }

    .call-contact-title {
      margin-bottom: 14px;
    }

    .call-contact-title h6 {
      color: var(--mf-ink);
      font-size: 18px;
      font-weight: 900;
      line-height: 1.35;
      margin-bottom: 6px;
    }

    .call-contact-title p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .call-contact-main {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 14px;
      border-radius: 20px;
      border: 1px solid rgba(224, 231, 241, 0.9);
      background:
        radial-gradient(circle at top right, rgba(88, 115, 220, 0.10), transparent 34%),
        linear-gradient(180deg, #fbfdff 0%, #f4f7fb 100%);
      margin-bottom: 14px;
    }

    .call-contact-main span {
      display: flex;
      align-items: center;
      gap: 7px;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 5px;
    }

    .call-contact-main span i {
      color: var(--mf-primary);
      font-size: 16px;
    }

    .call-contact-main strong {
      display: block;
      color: var(--mf-ink);
      font-size: 15px;
      font-weight: 900;
      word-break: break-word;
    }

    .call-contact-main .btn {
      border-radius: 13px;
      font-weight: 900;
      white-space: nowrap;
    }

    .call-contact-info {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 14px;
    }

    .call-contact-info > div {
      padding: 12px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .call-contact-info span {
      display: block;
      color: var(--mf-muted);
      font-size: 10px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 5px;
    }

    .call-contact-info strong {
      display: block;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      line-height: 1.45;
      word-break: break-word;
    }

    .call-visible-box {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 13px 14px;
      border-radius: 20px;
      background: rgba(47, 177, 140, 0.08);
      margin-bottom: 14px;
    }

    .call-visible-box span:first-child {
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
    }

    .call-visible-box p {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.5;
      margin: 2px 0 0;
    }

    .call-contact-actions {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: auto;
    }

    .call-contact-actions form {
      display: inline-block;
      margin-bottom: 0;
    }

    .call-contact-actions .btn {
      border-radius: 13px;
      font-size: 12px;
      font-weight: 900;
      padding: 8px 11px;
      position: relative;
      z-index: 3;
    }

    .call-empty-state {
      text-align: center;
      padding: 60px 20px;
      border: 1px dashed var(--mf-border);
      border-radius: 28px;
      background: #ffffff;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .call-empty-icon {
      width: 74px;
      height: 74px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 14px;
      border-radius: 26px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 40px;
    }

    .call-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .call-empty-state p {
      margin-bottom: 18px;
    }

    .call-empty-state .btn {
      border-radius: 16px;
      font-weight: 900;
    }

    .call-modal-dialog {
      max-width: 760px;
    }

    .call-modal-content {
      min-height: 86vh;
      max-height: 92vh;
      display: flex;
      flex-direction: column;
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: 0 24px 60px rgba(22, 43, 77, 0.18);
    }

    .call-modal-header {
      flex-shrink: 0;
      padding: 24px 28px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      border-bottom: 0;
    }

    .call-modal-header .modal-title {
      color: #ffffff;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .call-modal-header small {
      color: rgba(255, 255, 255, 0.78);
      font-weight: 600;
    }

    .call-modal-body {
      flex: 1 1 auto;
      overflow-y: auto;
      padding: 28px 28px 18px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .call-modal-footer {
      flex-shrink: 0;
      margin-top: auto;
      padding: 28px 30px 32px;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      gap: 14px;
    }

    .call-modal-footer .btn {
      height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 24px;
      padding-right: 24px;
    }

    .call-modal-cancel-btn {
      min-width: 104px;
      background: #ffffff;
    }

    .call-modal-submit-btn {
      min-width: 220px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.20);
    }

    @media (max-width: 1400px) {
      .call-contact-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .call-filter-grid {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }

      .call-search-field {
        grid-column: span 3;
      }

      .call-filter-buttons {
        grid-column: span 3;
        justify-content: flex-end;
      }
    }

    @media (max-width: 992px) {
      .call-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .call-hero-actions,
      .call-hero-btn {
        width: 100%;
      }

      .call-filter-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .call-search-field,
      .call-filter-buttons {
        grid-column: span 2;
      }

      .call-filter-buttons {
        justify-content: flex-start;
      }

      .call-contact-grid {
        grid-template-columns: 1fr;
      }
    }

    @media (max-width: 768px) {
      .call-hero-card,
      .call-main-header,
      .call-filter-area,
      .call-contact-area {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .call-hero-card {
        padding-top: 26px;
        padding-bottom: 26px;
      }

      .call-hero-left {
        flex-direction: column;
      }

      .call-hero-btn {
        min-height: 50px;
      }

      .call-info-card {
        grid-template-columns: 1fr;
      }

      .call-filter-box {
        padding: 16px;
      }

      .call-filter-grid {
        grid-template-columns: 1fr;
      }

      .call-search-field,
      .call-filter-buttons {
        grid-column: span 1;
      }

      .call-filter-buttons {
        flex-direction: column;
        min-width: 0;
      }

      .call-filter-buttons .btn,
      .call-filter-buttons .btn-outline-secondary {
        width: 100%;
      }

      .call-contact-main,
      .call-visible-box {
        align-items: flex-start;
        flex-direction: column;
      }

      .call-contact-main .btn {
        width: 100%;
      }

      .call-contact-info {
        grid-template-columns: 1fr;
      }

      .call-contact-actions .btn,
      .call-contact-actions form {
        width: 100%;
      }

      .call-modal-dialog {
        max-width: calc(100% - 24px);
        margin-left: auto;
        margin-right: auto;
      }

      .call-modal-content {
        min-height: 88vh;
        max-height: 94vh;
      }

      .call-modal-footer {
        flex-direction: column;
        padding: 22px;
      }

      .call-modal-footer .btn,
      .call-modal-cancel-btn,
      .call-modal-submit-btn {
        width: 100%;
        min-width: 0;
      }
    }
  </style>
@endsection

@push('scripts')
  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const editButtons = document.querySelectorAll('.btn-edit-contact');
      const editForm = document.getElementById('editContactForm');

      const updateRouteTemplate = "{{ route('admin.call-center.update', '__ID__') }}";

      editButtons.forEach(function (button) {
        button.addEventListener('click', function () {
          if (!editForm) {
            return;
          }

          const id = button.dataset.id;

          editForm.action = updateRouteTemplate.replace('__ID__', id);

          setField('edit_title', button.dataset.title);
          setField('edit_division', button.dataset.division);
          setField('edit_description', button.dataset.description);
          setField('edit_contact_person', button.dataset.contactPerson);
          setField('edit_platform', button.dataset.platform);
          setField('edit_contact_value', button.dataset.contactValue);
          setField('edit_whatsapp_number', button.dataset.whatsappNumber);
          setField('edit_url', button.dataset.url);
          setField('edit_service_hours', button.dataset.serviceHours);
          setField('edit_priority', button.dataset.priority);
          setField('edit_status', button.dataset.status);
          setField('edit_sort_order', button.dataset.sortOrder);

          setCheckbox('edit_is_emergency', button.dataset.isEmergency === '1');
          setCheckbox('edit_is_visible_to_client', button.dataset.isVisibleToClient === '1');
        });
      });

      const deleteForms = document.querySelectorAll('.form-delete-contact');

      deleteForms.forEach(function (form) {
        form.addEventListener('submit', function (event) {
          const confirmed = confirm('Yakin ingin menghapus kontak ini?');

          if (!confirmed) {
            event.preventDefault();
          }
        });
      });

      function setField(id, value) {
        const field = document.getElementById(id);

        if (field) {
          field.value = value || '';
        }
      }

      function setCheckbox(id, checked) {
        const field = document.getElementById(id);

        if (field) {
          field.checked = checked;
        }
      }
    });
  </script>
@endpush