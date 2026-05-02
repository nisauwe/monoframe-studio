@extends('layouts/contentNavbarLayout')

@section('title', 'Edit Diskon')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="discount-edit-shell">

      {{-- HERO HEADER --}}
      <div class="discount-edit-hero mb-4">
        <div class="discount-edit-hero-left">
          <div class="discount-edit-hero-icon">
            <i class="bx bx-edit-alt"></i>
          </div>

          <div>
            <div class="discount-edit-kicker">MANAJEMEN DISKON</div>
            <h4>Edit Diskon</h4>
            <p>
              Perbarui promo diskon, kategori, paket foto yang terhubung, persentase diskon,
              periode promo, dan status diskon Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="discount-edit-hero-actions">
          <a href="{{ route('admin.packages.index', ['tab' => 'discounts', 'category' => old('category_id', optional($selectedCategory)->id)]) }}"
            class="btn discount-edit-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      {{-- ALERT ERROR --}}
      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4 discount-edit-alert" role="alert">
          <div class="d-flex gap-2">
            <i class="bx bx-error-circle mt-1"></i>
            <div>{{ session('error') }}</div>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 discount-edit-alert" role="alert">
          <div class="d-flex gap-2">
            <i class="bx bx-error-circle mt-1"></i>
            <div>
              <strong>Terjadi kesalahan.</strong>
              <ul class="mb-0 mt-2 ps-3">
                @foreach ($errors->all() as $error)
                  <li>{{ $error }}</li>
                @endforeach
              </ul>
            </div>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      <form action="{{ route('admin.discounts.update', $discount->id) }}" method="POST" id="discountForm">
        @csrf
        @method('PUT')

        <div class="row g-4">
          {{-- LEFT FORM --}}
          <div class="col-xl-8 col-lg-7">
            <div class="card discount-edit-card">
              <div class="card-header">
                <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                  <div>
                    <h5 class="mb-1">Form Edit Diskon</h5>
                    <p class="mb-0">
                      Ubah kategori, data promo, dan paket yang akan mendapatkan diskon.
                    </p>
                  </div>

                  <div class="discount-counter-badge" id="selectedPackageCounter">
                    <i class="bx bx-package"></i>
                    0 paket dipilih
                  </div>
                </div>
              </div>

              <div class="card-body">

                {{-- DETAIL PROMO --}}
                <div class="discount-form-section">
                  <div class="discount-section-heading">
                    <div class="discount-section-icon">
                      <i class="bx bx-detail"></i>
                    </div>

                    <div>
                      <h6>Detail Promo</h6>
                      <p>Ubah kategori, nama promo, persentase diskon, tanggal promo, dan status diskon.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    {{-- KATEGORI --}}
                    <div class="col-md-6">
                      <label for="discountCategorySelect" class="form-label">Kategori</label>
                      <select name="category_id" id="discountCategorySelect" class="form-select" required>
                        <option value="">Pilih Kategori</option>
                        @foreach ($categories as $category)
                          <option
                            value="{{ $category->id }}"
                            {{ (string) old('category_id', optional($selectedCategory)->id) === (string) $category->id ? 'selected' : '' }}>
                            {{ $category->name }}
                          </option>
                        @endforeach
                      </select>
                      <div class="form-text">
                        Jika kategori diganti, daftar paket akan ikut berubah.
                      </div>
                    </div>

                    {{-- NAMA PROMO --}}
                    <div class="col-md-6">
                      <label for="promoName" class="form-label">Nama Kampanye</label>
                      <input
                        type="text"
                        name="promo_name"
                        id="promoName"
                        class="form-control"
                        value="{{ old('promo_name', $discount->promo_name) }}"
                        placeholder="Contoh: Promo Lebaran">
                      <div class="form-text">
                        Kosongkan jika tidak ingin memberi nama promo khusus.
                      </div>
                    </div>

                    {{-- DISKON --}}
                    <div class="col-md-4">
                      <label for="discountPercent" class="form-label">Besar Diskon</label>
                      <div class="input-group discount-input-group">
                        <input
                          type="number"
                          name="discount_percent"
                          id="discountPercent"
                          class="form-control"
                          min="1"
                          max="100"
                          value="{{ old('discount_percent', $discount->discount_percent) }}"
                          placeholder="Contoh: 10"
                          required>
                        <span class="input-group-text">%</span>
                      </div>
                    </div>

                    {{-- TANGGAL MULAI --}}
                    <div class="col-md-4">
                      <label for="discountStartAt" class="form-label">Mulai Tanggal</label>
                      <input
                        type="date"
                        name="discount_start_at"
                        id="discountStartAt"
                        class="form-control"
                        value="{{ old('discount_start_at', optional($discount->discount_start_at)->format('Y-m-d')) }}">
                    </div>

                    {{-- TANGGAL SELESAI --}}
                    <div class="col-md-4">
                      <label for="discountEndAt" class="form-label">Selesai Tanggal</label>
                      <input
                        type="date"
                        name="discount_end_at"
                        id="discountEndAt"
                        class="form-control"
                        value="{{ old('discount_end_at', optional($discount->discount_end_at)->format('Y-m-d')) }}">
                    </div>

                    {{-- STATUS --}}
                    <div class="col-12">
                      <div class="discount-status-card">
                        <div class="discount-status-info">
                          <div class="discount-status-icon">
                            <i class="bx bx-check-shield"></i>
                          </div>

                          <div>
                            <div class="discount-status-title">Status Diskon</div>
                            <div class="discount-status-subtitle">
                              Jika aktif, diskon akan dihitung pada paket yang dipilih.
                            </div>
                          </div>
                        </div>

                        <input type="hidden" name="is_active" value="0">

                        <div class="form-check form-switch discount-switch mb-0">
                          <input
                            class="form-check-input"
                            type="checkbox"
                            role="switch"
                            id="isActive"
                            name="is_active"
                            value="1"
                            {{ old('is_active', $discount->is_active) ? 'checked' : '' }}>
                          <label class="form-check-label" for="isActive">Aktif</label>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {{-- PILIH PAKET --}}
                <div class="discount-form-section mb-0">
                  <div class="discount-section-heading">
                    <div class="discount-section-icon">
                      <i class="bx bx-camera"></i>
                    </div>

                    <div>
                      <h6>Pilih Paket</h6>
                      <p>
                        Paket akan tampil sesuai kategori yang dipilih. Centang paket yang ingin diberi diskon.
                      </p>
                    </div>
                  </div>

                  <div class="discount-package-section">
                    <div id="packageEmptyChooseCategory" class="discount-empty-state">
                      <i class="bx bx-category-alt"></i>
                      <h6>Pilih kategori terlebih dahulu</h6>
                      <p>Setelah kategori dipilih, daftar paket foto akan muncul di area ini.</p>
                    </div>

                    <div id="packageEmptyNoData" class="discount-empty-state d-none">
                      <i class="bx bx-package"></i>
                      <h6>Belum ada paket</h6>
                      <p>Kategori ini belum memiliki paket aktif yang bisa diberi diskon.</p>
                    </div>

                    <div class="row g-3" id="discountPackageList">
                      @foreach ($packages as $package)
                        <div
                          class="col-xl-4 col-md-6 discount-package-item"
                          data-category-id="{{ $package->category_id }}"
                          style="display: none;">
                          <label class="discount-package-card" for="package{{ $package->id }}">
                            <input
                              class="form-check-input discount-package-checkbox"
                              type="checkbox"
                              name="package_ids[]"
                              value="{{ $package->id }}"
                              id="package{{ $package->id }}"
                              data-category-id="{{ $package->category_id }}"
                              data-package-name="{{ $package->name }}"
                              data-package-price="{{ $package->price }}"
                              {{ in_array($package->id, old('package_ids', $selectedPackageIds)) ? 'checked' : '' }}>

                            <div class="discount-package-icon">
                              <i class="bx bx-camera"></i>
                            </div>

                            <div class="discount-package-content">
                              <div class="discount-package-name">{{ $package->name }}</div>
                              <div class="discount-package-meta">
                                {{ $package->category->name ?? '-' }}
                              </div>
                              <div class="discount-package-price">
                                Rp {{ number_format($package->price, 0, ',', '.') }}
                              </div>
                              <div class="discount-package-detail">
                                {{ $package->duration_minutes }} menit • {{ $package->photo_count }} foto
                              </div>
                            </div>
                          </label>
                        </div>
                      @endforeach
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-footer discount-form-footer">
                <a href="{{ route('admin.packages.index', ['tab' => 'discounts', 'category' => old('category_id', optional($selectedCategory)->id)]) }}"
                  class="btn btn-outline-secondary">
                  Batal
                </a>

                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Perubahan
                </button>
              </div>
            </div>
          </div>

          {{-- RIGHT PREVIEW --}}
          <div class="col-xl-4 col-lg-5">
            <div class="discount-side-sticky">
              <div class="discount-preview-card">
                <div class="discount-preview-head">
                  <div>
                    <div class="discount-preview-label">Preview</div>
                    <h6 id="previewPromoName">
                      {{ old('promo_name', $discount->promo_name) ?: 'Promo Diskon' }}
                    </h6>
                  </div>

                  <span
                    class="badge {{ old('is_active', $discount->is_active) ? 'bg-label-success' : 'bg-label-secondary' }}"
                    id="previewStatusBadge">
                    {{ old('is_active', $discount->is_active) ? 'Aktif' : 'Tidak Aktif' }}
                  </span>
                </div>

                <div class="discount-preview-hero">
                  <div class="discount-preview-icon">
                    <i class="bx bx-purchase-tag-alt"></i>
                  </div>

                  <div>
                    <div class="discount-preview-percent" id="previewPercent">
                      {{ old('discount_percent', $discount->discount_percent) ?: 0 }}%
                    </div>
                    <div class="discount-preview-subtitle" id="previewCategoryText">
                      {{ optional($selectedCategory)->name ?: 'Kategori belum dipilih' }}
                    </div>
                  </div>
                </div>

                <div class="discount-preview-grid">
                  <div>
                    <small>Paket Dipilih</small>
                    <strong id="previewPackageCount">0 paket</strong>
                  </div>

                  <div>
                    <small>Periode</small>
                    <strong id="previewPeriod">Tanpa batas</strong>
                  </div>
                </div>

                <div class="discount-preview-selected">
                  <div class="discount-preview-selected-title">
                    <i class="bx bx-package"></i>
                    Paket yang dipilih
                  </div>

                  <div class="discount-preview-selected-list" id="previewSelectedPackages">
                    <span class="text-muted">Belum ada paket dipilih.</span>
                  </div>
                </div>
              </div>

              <div class="discount-helper-card mt-4">
                <div class="discount-helper-icon">
                  <i class="bx bx-bulb"></i>
                </div>

                <h6>Tips Edit Diskon</h6>
                <p>
                  Jika kategori diganti, pastikan paket yang dipilih juga sesuai dengan kategori baru.
                </p>

                <div class="discount-helper-list">
                  <div class="discount-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Pilih ulang paket setelah mengganti kategori.</span>
                  </div>

                  <div class="discount-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Pastikan persentase diskon masih sesuai.</span>
                  </div>

                  <div class="discount-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Nonaktifkan promo jika tidak ingin dihitung ke paket.</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>

  <style>
    .discount-edit-hero {
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

    .discount-edit-hero::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .discount-edit-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .discount-edit-hero-icon {
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

    .discount-edit-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .discount-edit-hero h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .discount-edit-hero p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .discount-edit-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .discount-edit-back-btn {
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

    .discount-edit-back-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .discount-edit-alert {
      border: 0;
      border-radius: 20px;
      box-shadow: var(--mf-shadow-soft);
    }

    .discount-edit-alert i {
      font-size: 20px;
    }

    .discount-edit-card,
    .discount-preview-card,
    .discount-helper-card {
      border: 0;
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .discount-edit-card .card-header {
      padding: 30px 34px 22px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .discount-edit-card .card-header h5 {
      color: var(--mf-ink);
      font-weight: 900;
    }

    .discount-edit-card .card-header p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 600;
      line-height: 1.6;
    }

    .discount-counter-badge {
      min-height: 42px;
      padding: 0 16px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 13px;
      font-weight: 900;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      white-space: nowrap;
    }

    .discount-edit-card .card-body {
      padding: 30px 34px 34px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.10), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .discount-form-section {
      margin-bottom: 34px;
      padding-bottom: 34px;
      border-bottom: 1px solid var(--mf-border);
    }

    .discount-form-section.mb-0 {
      margin-bottom: 0 !important;
      padding-bottom: 0 !important;
      border-bottom: 0;
    }

    .discount-section-heading {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 18px;
    }

    .discount-section-icon,
    .discount-status-icon,
    .discount-package-icon,
    .discount-preview-icon,
    .discount-helper-icon {
      width: 48px;
      height: 48px;
      border-radius: 17px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 23px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .discount-section-heading h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .discount-section-heading p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .discount-edit-card .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.02em;
      margin-bottom: 8px;
    }

    .discount-edit-card .form-control,
    .discount-edit-card .form-select {
      min-height: 54px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .discount-edit-card .form-control:focus,
    .discount-edit-card .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .discount-edit-card .form-text {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      margin-top: 8px;
    }

    .discount-input-group {
      min-height: 54px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      overflow: hidden;
      background: #ffffff;
      transition: 0.18s ease;
    }

    .discount-input-group:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .discount-input-group .input-group-text {
      border: 0 !important;
      background: #ffffff !important;
      color: var(--mf-muted) !important;
      font-size: 13px !important;
      font-weight: 900 !important;
      padding-left: 16px;
      padding-right: 16px;
    }

    .discount-input-group .form-control {
      border: 0 !important;
      border-radius: 0 !important;
      min-height: 52px !important;
    }

    .discount-status-card {
      padding: 20px;
      border: 1px solid var(--mf-border);
      border-radius: 22px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 36%),
        #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 18px;
    }

    .discount-status-info {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .discount-status-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .discount-status-subtitle {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.55;
    }

    .discount-switch {
      flex-shrink: 0;
    }

    .discount-switch .form-check-input {
      width: 46px;
      height: 24px;
      cursor: pointer;
    }

    .discount-switch .form-check-label {
      color: var(--mf-ink);
      font-weight: 900;
      margin-left: 6px;
      cursor: pointer;
    }

    .discount-package-section {
      padding: 22px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
    }

    .discount-package-card {
      height: 100%;
      padding: 18px;
      border: 1px solid var(--mf-border);
      border-radius: 22px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 38%),
        #ffffff;
      display: flex;
      align-items: flex-start;
      gap: 14px;
      cursor: pointer;
      transition: 0.18s ease;
    }

    .discount-package-card:hover {
      transform: translateY(-3px);
      border-color: rgba(88, 115, 220, 0.35);
      box-shadow: 0 18px 38px rgba(52, 79, 165, 0.12);
    }

    .discount-package-card:has(.discount-package-checkbox:checked) {
      border-color: rgba(88, 115, 220, 0.55);
      background:
        radial-gradient(circle at top right, rgba(88, 115, 220, 0.16), transparent 38%),
        #ffffff;
      box-shadow: 0 18px 38px rgba(52, 79, 165, 0.12);
    }

    .discount-package-checkbox {
      margin-top: 4px;
      flex-shrink: 0;
      accent-color: var(--mf-primary);
    }

    .discount-package-icon {
      width: 42px;
      height: 42px;
      border-radius: 16px;
      font-size: 20px;
    }

    .discount-package-content {
      min-width: 0;
    }

    .discount-package-name {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.35;
      margin-bottom: 3px;
    }

    .discount-package-meta,
    .discount-package-detail {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      line-height: 1.5;
    }

    .discount-package-price {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 8px 0 2px;
    }

    .discount-empty-state {
      padding: 44px 20px;
      text-align: center;
      color: var(--mf-muted);
      border: 1px dashed var(--mf-sky);
      border-radius: 22px;
      background: #f8fbfd;
    }

    .discount-empty-state i {
      display: block;
      font-size: 48px;
      color: var(--mf-primary);
      margin-bottom: 12px;
    }

    .discount-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .discount-empty-state p {
      margin: 0 auto;
      max-width: 420px;
      line-height: 1.7;
      font-weight: 600;
    }

    .discount-form-footer {
      padding: 24px 34px 30px !important;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      background: #ffffff;
    }

    .discount-form-footer .btn {
      min-height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 24px;
      padding-right: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .discount-side-sticky {
      position: sticky;
      top: 105px;
    }

    .discount-preview-card,
    .discount-helper-card {
      padding: 26px;
    }

    .discount-preview-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 18px;
    }

    .discount-preview-label {
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      margin-bottom: 4px;
    }

    .discount-preview-head h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 0;
      line-height: 1.35;
    }

    .discount-preview-hero {
      display: flex;
      align-items: center;
      gap: 14px;
      padding: 18px;
      border-radius: 24px;
      margin-bottom: 14px;
      background:
        radial-gradient(circle at top right, rgba(255, 255, 255, 0.28), transparent 34%),
        linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
    }

    .discount-preview-icon {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      background: rgba(255, 255, 255, 0.18);
      color: #ffffff;
      box-shadow: none;
      font-size: 27px;
    }

    .discount-preview-percent {
      color: #ffffff;
      font-size: 28px;
      font-weight: 900;
      line-height: 1;
      margin-bottom: 5px;
    }

    .discount-preview-subtitle {
      color: rgba(255, 255, 255, 0.82);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.45;
    }

    .discount-preview-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
      margin-bottom: 16px;
    }

    .discount-preview-grid div {
      padding: 14px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .discount-preview-grid small {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      margin-bottom: 5px;
    }

    .discount-preview-grid strong {
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      line-height: 1.45;
    }

    .discount-preview-selected {
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background: #ffffff;
      padding: 15px;
    }

    .discount-preview-selected-title {
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 12px;
    }

    .discount-preview-selected-title i {
      color: var(--mf-primary);
      font-size: 18px;
    }

    .discount-preview-selected-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.55;
    }

    .discount-preview-selected-list .badge {
      white-space: normal;
      text-align: left;
      line-height: 1.4;
    }

    .discount-helper-icon {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      font-size: 27px;
      margin-bottom: 16px;
    }

    .discount-helper-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 8px;
    }

    .discount-helper-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.7;
      margin-bottom: 16px;
    }

    .discount-helper-list {
      display: flex;
      flex-direction: column;
      gap: 11px;
    }

    .discount-helper-item {
      display: flex;
      align-items: flex-start;
      gap: 9px;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.55;
    }

    .discount-helper-item i {
      color: var(--mf-primary);
      font-size: 18px;
      margin-top: 1px;
    }

    @media (max-width: 991px) {
      .discount-side-sticky {
        position: static;
      }

      .discount-edit-hero {
        align-items: flex-start;
        flex-direction: column;
      }

      .discount-edit-hero-actions,
      .discount-edit-back-btn {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .discount-edit-hero {
        padding: 26px 22px;
      }

      .discount-edit-hero-left {
        flex-direction: column;
      }

      .discount-edit-hero h4 {
        font-size: 26px;
      }

      .discount-edit-card .card-header,
      .discount-edit-card .card-body,
      .discount-form-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .discount-status-card,
      .discount-status-info,
      .discount-section-heading {
        align-items: flex-start;
        flex-direction: column;
      }

      .discount-form-footer {
        flex-direction: column-reverse;
        align-items: stretch;
      }

      .discount-form-footer .btn {
        width: 100%;
      }

      .discount-preview-card,
      .discount-helper-card {
        padding: 22px;
      }

      .discount-preview-grid {
        grid-template-columns: 1fr;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const categorySelect = document.getElementById('discountCategorySelect');
      const packageItems = Array.from(document.querySelectorAll('.discount-package-item'));
      const packageCheckboxes = Array.from(document.querySelectorAll('.discount-package-checkbox'));
      const chooseCategoryEmpty = document.getElementById('packageEmptyChooseCategory');
      const noDataEmpty = document.getElementById('packageEmptyNoData');
      const counter = document.getElementById('selectedPackageCounter');

      const promoNameInput = document.getElementById('promoName');
      const discountPercentInput = document.getElementById('discountPercent');
      const discountStartAtInput = document.getElementById('discountStartAt');
      const discountEndAtInput = document.getElementById('discountEndAt');
      const isActiveInput = document.getElementById('isActive');

      const previewPromoName = document.getElementById('previewPromoName');
      const previewStatusBadge = document.getElementById('previewStatusBadge');
      const previewPercent = document.getElementById('previewPercent');
      const previewCategoryText = document.getElementById('previewCategoryText');
      const previewPackageCount = document.getElementById('previewPackageCount');
      const previewPeriod = document.getElementById('previewPeriod');
      const previewSelectedPackages = document.getElementById('previewSelectedPackages');

      const oldSelectedPackageIds = @json(array_map('strval', old('package_ids', $selectedPackageIds)));

      function selectedVisibleCheckboxes() {
        return packageCheckboxes.filter(function (checkbox) {
          const item = checkbox.closest('.discount-package-item');

          return checkbox.checked && item && item.style.display !== 'none';
        });
      }

      function formatDate(value) {
        if (!value) {
          return '';
        }

        const parts = value.split('-');

        if (parts.length !== 3) {
          return value;
        }

        return parts[2] + '/' + parts[1] + '/' + parts[0];
      }

      function selectedCategoryName() {
        if (!categorySelect || !categorySelect.value) {
          return 'Kategori belum dipilih';
        }

        return categorySelect.options[categorySelect.selectedIndex]?.text || 'Kategori belum dipilih';
      }

      function updatePreview() {
        const selectedPackages = selectedVisibleCheckboxes();
        const promoName = promoNameInput.value.trim();
        const percent = discountPercentInput.value || 0;
        const startDate = discountStartAtInput.value;
        const endDate = discountEndAtInput.value;
        const isActive = isActiveInput.checked;

        previewPromoName.textContent = promoName || 'Promo Diskon';
        previewPercent.textContent = percent + '%';
        previewCategoryText.textContent = selectedCategoryName();
        previewPackageCount.textContent = selectedPackages.length + ' paket';

        if (startDate && endDate) {
          previewPeriod.textContent = formatDate(startDate) + ' - ' + formatDate(endDate);
        } else if (startDate) {
          previewPeriod.textContent = 'Mulai ' + formatDate(startDate);
        } else if (endDate) {
          previewPeriod.textContent = 'Sampai ' + formatDate(endDate);
        } else {
          previewPeriod.textContent = 'Tanpa batas';
        }

        previewStatusBadge.textContent = isActive ? 'Aktif' : 'Tidak Aktif';
        previewStatusBadge.classList.toggle('bg-label-success', isActive);
        previewStatusBadge.classList.toggle('bg-label-secondary', !isActive);

        if (selectedPackages.length === 0) {
          previewSelectedPackages.innerHTML = '<span class="text-muted">Belum ada paket dipilih.</span>';
        } else {
          previewSelectedPackages.innerHTML = selectedPackages.map(function (checkbox) {
            const name = checkbox.dataset.packageName || 'Paket';
            return '<span class="badge bg-label-primary">' + name + '</span>';
          }).join('');
        }
      }

      function updateCounter() {
        const totalChecked = selectedVisibleCheckboxes().length;

        if (counter) {
          counter.innerHTML = '<i class="bx bx-package"></i> ' + totalChecked + ' paket dipilih';
        }

        updatePreview();
      }

      function hideItem(item, shouldClear = true) {
        item.style.display = 'none';

        const checkbox = item.querySelector('.discount-package-checkbox');

        if (checkbox && shouldClear) {
          checkbox.checked = false;
        }
      }

      function showItem(item) {
        item.style.display = '';
      }

      function filterPackagesByCategory(shouldResetHidden = true) {
        const selectedCategoryId = categorySelect ? categorySelect.value : '';
        let visibleTotal = 0;

        packageItems.forEach(function (item) {
          const itemCategoryId = item.getAttribute('data-category-id');
          const checkbox = item.querySelector('.discount-package-checkbox');

          if (selectedCategoryId !== '' && itemCategoryId === selectedCategoryId) {
            showItem(item);
            visibleTotal++;

            if (checkbox && oldSelectedPackageIds.includes(String(checkbox.value))) {
              checkbox.checked = true;
            }
          } else {
            hideItem(item, shouldResetHidden);
          }
        });

        if (chooseCategoryEmpty) {
          chooseCategoryEmpty.classList.toggle('d-none', selectedCategoryId !== '');
        }

        if (noDataEmpty) {
          noDataEmpty.classList.toggle('d-none', selectedCategoryId === '' || visibleTotal > 0);
        }

        updateCounter();
      }

      if (categorySelect) {
        categorySelect.addEventListener('change', function () {
          packageCheckboxes.forEach(function (checkbox) {
            checkbox.checked = false;
          });

          filterPackagesByCategory(true);
        });
      }

      packageCheckboxes.forEach(function (checkbox) {
        checkbox.addEventListener('change', updateCounter);
      });

      [
        promoNameInput,
        discountPercentInput,
        discountStartAtInput,
        discountEndAtInput,
        isActiveInput
      ].forEach(function (input) {
        if (!input) {
          return;
        }

        input.addEventListener('input', updatePreview);
        input.addEventListener('change', updatePreview);
      });

      filterPackagesByCategory(false);
      updatePreview();
    });
  </script>
@endsection
