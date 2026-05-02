@extends('layouts/contentNavbarLayout')

@section('title', 'Edit Kategori')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="category-edit-shell">

      <div class="category-edit-hero mb-4">
        <div class="category-edit-hero-left">
          <div class="category-edit-hero-icon">
            <i class="bx bx-edit-alt"></i>
          </div>

          <div>
            <div class="category-edit-kicker">MANAJEMEN KATEGORI</div>
            <h4>Edit Kategori</h4>
            <p>
              Perbarui nama kategori, deskripsi, dan status aktif kategori layanan foto
              Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="category-edit-hero-actions">
          <a
            href="{{ route('admin.packages.index', ['tab' => 'categories', 'category' => $category->id]) }}"
            class="btn category-edit-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <strong>Terjadi kesalahan.</strong>
          <ul class="mb-0 mt-2 ps-3">
            @foreach ($errors->all() as $error)
              <li>{{ $error }}</li>
            @endforeach
          </ul>
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      <div class="card category-edit-card">
        <div class="card-header">
          <div>
            <h5 class="mb-1">Form Edit Kategori</h5>
            <p class="mb-0 text-muted">
              Data yang diubah akan langsung digunakan pada paket foto dan tampilan klien.
            </p>
          </div>
        </div>

        <div class="card-body">
          <form action="{{ route('admin.categories.update', $category->id) }}" method="POST">
            @csrf
            @method('PUT')

            <div class="mb-3">
              <label for="category_name" class="form-label">Nama Kategori</label>
              <input
                type="text"
                name="name"
                id="category_name"
                class="form-control"
                value="{{ old('name', $category->name) }}"
                placeholder="Contoh: Prewedding"
                required>
            </div>

            <div class="mb-3">
              <label for="category_description" class="form-label">Deskripsi</label>
              <textarea
                name="description"
                id="category_description"
                class="form-control"
                rows="5"
                placeholder="Masukkan deskripsi kategori...">{{ old('description', $category->description) }}</textarea>
            </div>

            <div class="category-status-card mb-4">
              <div>
                <div class="category-status-title">Status Kategori</div>
                <div class="category-status-subtitle">
                  Jika aktif, kategori dapat digunakan dan ditampilkan pada sistem.
                </div>
              </div>

              <input type="hidden" name="is_active" value="0">

              <div class="form-check form-switch mb-0">
                <input
                  class="form-check-input"
                  type="checkbox"
                  role="switch"
                  id="category_is_active"
                  name="is_active"
                  value="1"
                  {{ old('is_active', $category->is_active) ? 'checked' : '' }}>
                <label class="form-check-label fw-semibold" for="category_is_active">
                  Aktif
                </label>
              </div>
            </div>

            <div class="d-flex justify-content-end flex-wrap gap-2">
              <button type="submit" class="btn btn-primary">
                <i class="bx bx-save me-1"></i>
                Simpan Perubahan
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>

  <style>
    .category-edit-hero {
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

    .category-edit-hero::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .category-edit-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .category-edit-hero-icon {
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

    .category-edit-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .category-edit-hero h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .category-edit-hero p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .category-edit-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .category-edit-back-btn {
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

    .category-edit-back-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .category-edit-card {
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: var(--mf-shadow-soft);
    }

    .category-edit-card .card-header {
      padding: 28px 32px 20px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      border-bottom: 1px solid var(--mf-border);
    }

    .category-edit-card .card-header h5 {
      color: var(--mf-ink);
      font-weight: 900;
    }

    .category-edit-card .card-body {
      padding: 30px 32px 34px !important;
      background: #ffffff;
    }

    .category-edit-card .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .category-edit-card .form-control {
      min-height: 52px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .category-edit-card textarea.form-control {
      min-height: 130px;
      resize: vertical;
    }

    .category-edit-card .form-control:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .category-status-card {
      padding: 18px 20px;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 36%),
        #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
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

    .category-edit-card .btn {
      min-height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 22px;
      padding-right: 22px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    @media (max-width: 768px) {
      .category-edit-hero {
        align-items: flex-start;
        flex-direction: column;
        padding: 26px 22px;
      }

      .category-edit-hero-left {
        flex-direction: column;
      }

      .category-edit-hero-actions,
      .category-edit-back-btn {
        width: 100%;
      }

      .category-edit-card .card-header,
      .category-edit-card .card-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .category-status-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .category-edit-card .btn {
        width: 100%;
      }
    }
  </style>
@endsection
