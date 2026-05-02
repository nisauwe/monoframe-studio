@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Kategori')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="category-create-shell">

      {{-- HERO HEADER --}}
      <div class="category-create-hero mb-4">
        <div class="category-create-hero-left">
          <div class="category-create-hero-icon">
            <i class="bx bx-category-alt"></i>
          </div>

          <div>
            <div class="category-create-kicker">MANAJEMEN KATEGORI</div>
            <h4>Tambah Kategori</h4>
            <p>
              Tambahkan kategori layanan foto baru agar paket foto Monoframe Studio
              lebih mudah dikelompokkan dan dikelola oleh admin.
            </p>
          </div>
        </div>

        <div class="category-create-hero-actions">
          <a href="{{ route('admin.packages.index', ['tab' => 'categories']) }}" class="btn category-create-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      {{-- ERROR ALERT --}}
      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 category-alert" role="alert">
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

      <div class="row g-4">
        <div class="col-lg-8">
          <div class="card category-create-card">
            <div class="card-header">
              <div>
                <h5 class="mb-1">Form Tambah Kategori</h5>
                <p class="mb-0">
                  Lengkapi nama kategori, deskripsi, dan status kategori.
                </p>
              </div>
            </div>

            <div class="card-body">
              <form action="{{ route('admin.categories.store') }}" method="POST">
                @csrf

                <div class="mb-4">
                  <label for="category_name" class="form-label">Nama Kategori</label>
                  <input
                    type="text"
                    name="name"
                    id="category_name"
                    class="form-control"
                    value="{{ old('name') }}"
                    placeholder="Contoh: Prewedding"
                    required
                    autofocus>
                  <div class="form-text">
                    Gunakan nama singkat dan jelas, misalnya Prewedding, Wisuda, Family, atau Product.
                  </div>
                </div>

                <div class="mb-4">
                  <label for="category_description" class="form-label">Deskripsi</label>
                  <textarea
                    name="description"
                    id="category_description"
                    class="form-control category-textarea"
                    rows="5"
                    placeholder="Masukkan deskripsi kategori...">{{ old('description') }}</textarea>
                  <div class="form-text">
                    Deskripsi membantu admin memahami jenis layanan pada kategori ini.
                  </div>
                </div>

                <div class="category-status-card mb-4">
                  <div class="category-status-info">
                    <div class="category-status-icon">
                      <i class="bx bx-check-shield"></i>
                    </div>

                    <div>
                      <div class="category-status-title">Status Kategori</div>
                      <div class="category-status-subtitle">
                        Jika aktif, kategori dapat digunakan pada sistem dan paket foto.
                      </div>
                    </div>
                  </div>

                  <input type="hidden" name="is_active" value="0">

                  <div class="form-check form-switch category-switch mb-0">
                    <input
                      class="form-check-input"
                      type="checkbox"
                      name="is_active"
                      value="1"
                      id="category_is_active"
                      {{ old('is_active', true) ? 'checked' : '' }}>
                    <label class="form-check-label" for="category_is_active">
                      Aktif
                    </label>
                  </div>
                </div>

                <div class="category-form-actions">
                  <a href="{{ route('admin.packages.index', ['tab' => 'categories']) }}" class="btn btn-outline-secondary">
                    Batal
                  </a>

                  <button type="submit" class="btn btn-primary">
                    <i class="bx bx-save me-1"></i>
                    Simpan Kategori
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>

        <div class="col-lg-4">
          <div class="category-helper-card">
            <div class="category-helper-icon">
              <i class="bx bx-bulb"></i>
            </div>

            <h5>Tips Kategori</h5>
            <p>
              Buat kategori berdasarkan jenis layanan utama agar paket lebih rapi
              dan mudah dicari.
            </p>

            <div class="category-helper-list">
              <div class="category-helper-item">
                <i class="bx bx-check-circle"></i>
                <span>Gunakan nama kategori yang pendek.</span>
              </div>

              <div class="category-helper-item">
                <i class="bx bx-check-circle"></i>
                <span>Aktifkan kategori jika sudah siap digunakan.</span>
              </div>

              <div class="category-helper-item">
                <i class="bx bx-check-circle"></i>
                <span>Tambahkan deskripsi agar data lebih jelas.</span>
              </div>
            </div>
          </div>

          <div class="category-preview-card mt-4">
            <div class="category-preview-head">
              <div>
                <div class="category-preview-label">Preview</div>
                <h6>Kategori Baru</h6>
              </div>

              <span class="badge bg-label-success">Aktif</span>
            </div>

            <div class="category-preview-body">
              <div class="category-preview-icon">
                <i class="bx bx-folder"></i>
              </div>

              <div>
                <div class="category-preview-title">Nama kategori</div>
                <div class="category-preview-subtitle">
                  Kategori akan tampil di daftar kategori paket.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <style>
      .category-create-hero {
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

      .category-create-hero::after {
        content: "";
        position: absolute;
        width: 260px;
        height: 260px;
        right: -90px;
        bottom: -130px;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.14);
      }

      .category-create-hero-left {
        position: relative;
        z-index: 2;
        display: flex;
        align-items: flex-start;
        gap: 18px;
        min-width: 0;
        max-width: 880px;
      }

      .category-create-hero-icon {
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

      .category-create-kicker {
        color: rgba(255, 255, 255, 0.78);
        font-size: 12px;
        font-weight: 900;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        margin-bottom: 8px;
      }

      .category-create-hero h4 {
        color: #ffffff;
        font-size: 30px;
        font-weight: 900;
        line-height: 1.2;
        margin-bottom: 10px;
      }

      .category-create-hero p {
        color: rgba(255, 255, 255, 0.86);
        font-size: 15px;
        font-weight: 600;
        line-height: 1.75;
        margin-bottom: 0;
      }

      .category-create-hero-actions {
        position: relative;
        z-index: 2;
        flex-shrink: 0;
      }

      .category-create-back-btn {
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

      .category-create-back-btn:hover {
        background: #ffffff;
        color: var(--mf-primary);
        transform: translateY(-2px);
        box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
      }

      .category-alert {
        border-radius: 20px;
        border: 0;
        box-shadow: var(--mf-shadow-soft);
      }

      .category-alert i {
        font-size: 20px;
      }

      .category-create-card,
      .category-helper-card,
      .category-preview-card {
        border: 0;
        border-radius: 30px;
        background: rgba(255, 255, 255, 0.98);
        box-shadow: var(--mf-shadow-soft);
        overflow: hidden;
      }

      .category-create-card .card-header {
        padding: 30px 34px 22px !important;
        border-bottom: 1px solid var(--mf-border);
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
          linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      }

      .category-create-card .card-header h5 {
        color: var(--mf-ink);
        font-weight: 900;
      }

      .category-create-card .card-header p {
        color: var(--mf-muted);
        font-size: 14px;
        font-weight: 600;
      }

      .category-create-card .card-body {
        padding: 30px 34px 34px !important;
      }

      .category-create-card .form-label {
        color: var(--mf-ink);
        font-size: 12px;
        font-weight: 900;
        letter-spacing: 0.02em;
        margin-bottom: 8px;
      }

      .category-create-card .form-control {
        min-height: 54px;
        border-radius: 18px !important;
        border: 1px solid var(--mf-border) !important;
        background: #ffffff !important;
        color: var(--mf-ink) !important;
        font-size: 14px !important;
        font-weight: 700 !important;
        box-shadow: none !important;
      }

      .category-textarea {
        min-height: 135px !important;
        resize: vertical;
        padding-top: 14px !important;
      }

      .category-create-card .form-control:focus {
        border-color: rgba(88, 115, 220, 0.48) !important;
        box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
      }

      .category-create-card .form-text {
        color: var(--mf-muted);
        font-size: 12px;
        font-weight: 600;
        margin-top: 8px;
      }

      .category-status-card {
        padding: 18px 20px;
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

      .category-status-info {
        display: flex;
        align-items: center;
        gap: 14px;
      }

      .category-status-icon {
        width: 46px;
        height: 46px;
        border-radius: 16px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
        color: #ffffff;
        font-size: 22px;
        box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
      }

      .category-status-title {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 4px;
      }

      .category-status-subtitle {
        color: var(--mf-muted);
        font-size: 13px;
        font-weight: 600;
        line-height: 1.55;
      }

      .category-switch {
        flex-shrink: 0;
      }

      .category-switch .form-check-input {
        width: 46px;
        height: 24px;
        cursor: pointer;
      }

      .category-switch .form-check-label {
        color: var(--mf-ink);
        font-weight: 900;
        margin-left: 6px;
        cursor: pointer;
      }

      .category-form-actions {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        flex-wrap: wrap;
        gap: 12px;
        padding-top: 4px;
      }

      .category-form-actions .btn {
        min-height: 48px;
        border-radius: 16px;
        font-weight: 900;
        padding-left: 24px;
        padding-right: 24px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
      }

      .category-helper-card {
        padding: 28px;
      }

      .category-helper-icon {
        width: 58px;
        height: 58px;
        border-radius: 20px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 18px;
        background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
        color: #ffffff;
        font-size: 30px;
        box-shadow: 0 14px 28px rgba(88, 115, 220, 0.20);
      }

      .category-helper-card h5 {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 10px;
      }

      .category-helper-card p {
        color: var(--mf-muted);
        font-size: 14px;
        font-weight: 600;
        line-height: 1.7;
        margin-bottom: 18px;
      }

      .category-helper-list {
        display: flex;
        flex-direction: column;
        gap: 12px;
      }

      .category-helper-item {
        display: flex;
        align-items: flex-start;
        gap: 10px;
        color: var(--mf-ink);
        font-size: 13px;
        font-weight: 700;
        line-height: 1.55;
      }

      .category-helper-item i {
        color: var(--mf-primary);
        font-size: 18px;
        margin-top: 1px;
      }

      .category-preview-card {
        padding: 24px;
      }

      .category-preview-head {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 14px;
        margin-bottom: 18px;
      }

      .category-preview-label {
        color: var(--mf-muted);
        font-size: 11px;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin-bottom: 4px;
      }

      .category-preview-head h6 {
        color: var(--mf-ink);
        font-weight: 900;
        margin: 0;
      }

      .category-preview-body {
        display: flex;
        align-items: center;
        gap: 14px;
        padding: 16px;
        border: 1px solid var(--mf-border);
        border-radius: 22px;
        background:
          radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 38%),
          #ffffff;
      }

      .category-preview-icon {
        width: 44px;
        height: 44px;
        border-radius: 16px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
        color: #ffffff;
        font-size: 20px;
      }

      .category-preview-title {
        color: var(--mf-ink);
        font-weight: 900;
        margin-bottom: 3px;
      }

      .category-preview-subtitle {
        color: var(--mf-muted);
        font-size: 12px;
        font-weight: 600;
        line-height: 1.5;
      }

      @media (max-width: 992px) {
        .category-create-hero {
          align-items: flex-start;
          flex-direction: column;
        }

        .category-create-hero-actions,
        .category-create-back-btn {
          width: 100%;
        }
      }

      @media (max-width: 768px) {
        .category-create-hero {
          padding: 26px 22px;
        }

        .category-create-hero-left {
          flex-direction: column;
        }

        .category-create-hero h4 {
          font-size: 26px;
        }

        .category-create-card .card-header,
        .category-create-card .card-body {
          padding-left: 22px !important;
          padding-right: 22px !important;
        }

        .category-status-card,
        .category-status-info {
          align-items: flex-start;
          flex-direction: column;
        }

        .category-form-actions {
          flex-direction: column-reverse;
        }

        .category-form-actions .btn {
          width: 100%;
        }

        .category-helper-card,
        .category-preview-card {
          padding: 22px;
        }
      }
    </style>
  </div>
@endsection
