@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Paket')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="package-create-shell">

      {{-- HERO HEADER --}}
      <div class="package-create-hero mb-4">
        <div class="package-create-hero-left">
          <div class="package-create-hero-icon">
            <i class="bx bx-camera"></i>
          </div>

          <div>
            <div class="package-create-kicker">MANAJEMEN PAKET FOTO</div>
            <h4>Tambah Paket Baru</h4>
            <p>
              Tambahkan paket layanan foto, harga, durasi, jumlah foto edit,
              jenis lokasi, deskripsi, status, dan portofolio paket Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="package-create-hero-actions">
          <a href="{{ route('admin.packages.index', ['tab' => 'photo-packages']) }}" class="btn package-create-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      {{-- ALERT ERROR --}}
      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 package-create-alert" role="alert">
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

      <form action="{{ route('admin.packages.store') }}" method="POST" enctype="multipart/form-data" id="createPackageForm">
        @csrf

        <div class="row g-4">
          {{-- LEFT CONTENT --}}
          <div class="col-xl-8 col-lg-7">
            <div class="card package-create-card">
              <div class="card-header">
                <div>
                  <h5 class="mb-1">Form Tambah Paket</h5>
                  <p class="mb-0">
                    Lengkapi data paket foto yang akan ditampilkan pada sistem dan aplikasi klien.
                  </p>
                </div>
              </div>

              <div class="card-body">

                {{-- UPLOAD PORTFOLIO --}}
                <div class="package-form-section">
                  <div class="package-section-heading">
                    <div class="package-section-icon">
                      <i class="bx bx-images"></i>
                    </div>

                    <div>
                      <h6>Upload Portofolio</h6>
                      <p>Pilih gambar portofolio untuk paket ini. Maksimal 20 gambar.</p>
                    </div>
                  </div>

                  <div class="upload-dropzone" id="portfolioDropzone">
                    <input
                      type="file"
                      name="portfolio[]"
                      id="portfolioImages"
                      class="d-none"
                      accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
                      multiple>

                    <div class="upload-icon">
                      <i class="bx bx-cloud-upload"></i>
                    </div>

                    <h6>Upload gambar portofolio</h6>
                    <p>Drag & drop gambar ke area ini, atau klik tombol di bawah.</p>

                    <label for="portfolioImages" class="btn btn-primary upload-btn" id="browsePortfolioBtn">
                      <i class="bx bx-folder-open me-1"></i>
                      Browse File
                    </label>

                    <small>Max 20 gambar • JPG, JPEG, PNG, WEBP</small>
                  </div>

                  <div class="selected-file-info d-none" id="selectedFileInfo">
                    <i class="bx bx-image"></i>
                    <span id="selectedFileText">Belum ada gambar dipilih.</span>
                  </div>
                </div>

                {{-- MAIN DETAILS --}}
                <div class="package-form-section">
                  <div class="package-section-heading">
                    <div class="package-section-icon">
                      <i class="bx bx-detail"></i>
                    </div>

                    <div>
                      <h6>Detail Utama</h6>
                      <p>Masukkan nama paket, kategori, harga, durasi, jumlah edit, dan lokasi.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label for="packageName" class="form-label">Nama Paket</label>
                      <input
                        type="text"
                        name="name"
                        id="packageName"
                        class="form-control"
                        value="{{ old('name') }}"
                        placeholder="Contoh: Paket Wisuda Silver"
                        required>
                    </div>

                    <div class="col-md-6">
                      <label for="packageCategory" class="form-label">Kategori</label>
                      <select name="category_id" id="packageCategory" class="form-select" required>
                        <option value="">Pilih Kategori</option>
                        @foreach ($categories as $category)
                          <option value="{{ $category->id }}" {{ old('category_id') == $category->id ? 'selected' : '' }}>
                            {{ $category->name }}
                          </option>
                        @endforeach
                      </select>
                    </div>

                    <div class="col-md-4">
                      <label for="packagePrice" class="form-label">Harga Paket</label>
                      <div class="input-group package-input-group">
                        <span class="input-group-text">Rp</span>
                        <input
                          type="number"
                          name="price"
                          id="packagePrice"
                          class="form-control"
                          value="{{ old('price', 0) }}"
                          min="0"
                          required>
                      </div>
                    </div>

                    <div class="col-md-4">
                      <label for="packageDuration" class="form-label">Durasi</label>
                      <div class="input-group package-input-group">
                        <input
                          type="number"
                          name="duration_minutes"
                          id="packageDuration"
                          class="form-control"
                          value="{{ old('duration_minutes') }}"
                          placeholder="Contoh: 60"
                          min="0"
                          required>
                        <span class="input-group-text">Menit</span>
                      </div>
                    </div>

                    <div class="col-md-4">
                      <label for="packagePhotoCount" class="form-label">Jumlah Foto Edit</label>
                      <div class="input-group package-input-group">
                        <input
                          type="number"
                          name="photo_count"
                          id="packagePhotoCount"
                          class="form-control"
                          value="{{ old('photo_count') }}"
                          placeholder="Contoh: 10"
                          min="0"
                          required>
                        <span class="input-group-text">Foto</span>
                      </div>
                    </div>

                    <div class="col-md-6">
                      <label for="packageLocation" class="form-label">Jenis Lokasi</label>
                      <select name="location_type" id="packageLocation" class="form-select" required>
                        <option value="">Pilih jenis lokasi</option>
                        <option value="indoor" {{ old('location_type') === 'indoor' ? 'selected' : '' }}>
                          Indoor
                        </option>
                        <option value="outdoor" {{ old('location_type') === 'outdoor' ? 'selected' : '' }}>
                          Outdoor
                        </option>
                      </select>
                    </div>

                    <div class="col-md-6">
                      <label for="packagePersonCount" class="form-label">Jumlah Orang</label>
                      <input
                        type="number"
                        name="person_count"
                        id="packagePersonCount"
                        class="form-control"
                        value="{{ old('person_count') }}"
                        placeholder="Boleh dikosongkan"
                        min="1">
                      <div class="form-text">
                        Kosongkan untuk paket seperti prewed, wedding, atau paket fleksibel.
                      </div>
                    </div>

                    <div class="col-12">
                      <label for="packageDescription" class="form-label">Deskripsi Paket</label>
                      <textarea
                        name="description"
                        id="packageDescription"
                        class="form-control package-textarea"
                        rows="5"
                        placeholder="Tulis deskripsi lengkap paket...">{{ old('description') }}</textarea>
                    </div>
                  </div>
                </div>

                {{-- STATUS --}}
                <div class="package-form-section mb-0">
                  <div class="status-card">
                    <div class="status-card-left">
                      <div class="status-card-icon">
                        <i class="bx bx-check-shield"></i>
                      </div>

                      <div>
                        <h6>Status Paket</h6>
                        <p>Jika aktif, paket akan tampil dan bisa digunakan pada sistem.</p>
                      </div>
                    </div>

                    <input type="hidden" name="is_active" value="0">

                    <div class="form-check form-switch status-switch mb-0">
                      <input
                        class="form-check-input"
                        type="checkbox"
                        role="switch"
                        id="isActive"
                        name="is_active"
                        value="1"
                        {{ old('is_active', 1) ? 'checked' : '' }}>
                      <label class="form-check-label" for="isActive">
                        Aktif
                      </label>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-footer package-create-footer">
                <a href="{{ route('admin.packages.index', ['tab' => 'photo-packages']) }}" class="btn btn-outline-secondary">
                  Batal
                </a>

                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Paket
                </button>
              </div>
            </div>
          </div>

          {{-- RIGHT PREVIEW --}}
          <div class="col-xl-4 col-lg-5">
            <div class="preview-sticky">
              <div class="card package-preview-card">
                <div class="card-header">
                  <div>
                    <h5 class="mb-1">Preview Paket</h5>
                    <p class="mb-0">
                      Tampilan singkat paket yang sedang dibuat.
                    </p>
                  </div>
                </div>

                <div class="card-body">
                  <div class="preview-image-wrap" id="mainPreviewWrap">
                    <div class="preview-empty" id="previewEmpty">
                      <i class="bx bx-image-add"></i>
                      <span>Belum ada gambar</span>
                    </div>

                    <img id="mainPreviewImage" class="preview-main-image d-none" src="" alt="Preview Portofolio">

                    <div class="preview-badge d-none" id="previewFileBadge">
                      <i class="bx bx-images"></i>
                      <span id="previewFileCount">0 foto</span>
                    </div>
                  </div>

                  <div class="preview-content">
                    <div class="preview-name-row">
                      <h5 id="previewPackageName">Nama Paket</h5>
                      <span class="badge bg-label-success">Aktif</span>
                    </div>

                    <div class="preview-meta">
                      <i class="bx bx-category-alt"></i>
                      <span id="previewCategoryText">Kategori belum dipilih</span>
                    </div>

                    <div class="preview-detail-grid">
                      <div>
                        <small>Harga</small>
                        <strong id="previewPriceText">Rp 0</strong>
                      </div>

                      <div>
                        <small>Durasi</small>
                        <strong id="previewDurationText">0 Menit</strong>
                      </div>

                      <div>
                        <small>Jumlah Edit</small>
                        <strong id="previewPhotoText">0 Foto</strong>
                      </div>

                      <div>
                        <small>Lokasi</small>
                        <strong id="previewLocationText">-</strong>
                      </div>
                    </div>

                    <p id="previewDescriptionText">
                      Deskripsi paket akan muncul di sini.
                    </p>
                  </div>

                  <div class="preview-thumbs" id="imagePreview"></div>

                  <div class="preview-note">
                    <i class="bx bx-info-circle"></i>
                    <span>Klik gambar untuk preview utama. Klik tombol X untuk menghapus gambar.</span>
                  </div>
                </div>
              </div>

              <div class="package-helper-card mt-4">
                <div class="package-helper-icon">
                  <i class="bx bx-bulb"></i>
                </div>

                <h6>Tips Paket</h6>
                <p>
                  Gunakan nama paket yang jelas, harga sesuai layanan, dan foto portofolio
                  yang merepresentasikan hasil studio.
                </p>

                <div class="package-helper-list">
                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Upload foto portofolio terbaik.</span>
                  </div>

                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Pastikan durasi dan jumlah edit sudah sesuai.</span>
                  </div>

                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Aktifkan paket jika sudah siap dipakai klien.</span>
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
    .package-create-hero {
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

    .package-create-hero::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .package-create-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .package-create-hero-icon {
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

    .package-create-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .package-create-hero h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .package-create-hero p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .package-create-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .package-create-back-btn {
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

    .package-create-back-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .package-create-alert {
      border: 0;
      border-radius: 20px;
      box-shadow: var(--mf-shadow-soft);
    }

    .package-create-alert i {
      font-size: 20px;
    }

    .package-create-card,
    .package-preview-card,
    .package-helper-card {
      border: 0;
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .package-create-card .card-header,
    .package-preview-card .card-header {
      padding: 30px 34px 22px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-create-card .card-header h5,
    .package-preview-card .card-header h5 {
      color: var(--mf-ink);
      font-weight: 900;
    }

    .package-create-card .card-header p,
    .package-preview-card .card-header p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 600;
      line-height: 1.6;
    }

    .package-create-card .card-body {
      padding: 30px 34px 34px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.10), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-create-footer {
      padding: 24px 34px 30px !important;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      background: #ffffff;
    }

    .package-create-footer .btn {
      min-height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 24px;
      padding-right: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .package-form-section {
      margin-bottom: 34px;
      padding-bottom: 34px;
      border-bottom: 1px solid var(--mf-border);
    }

    .package-form-section.mb-0 {
      margin-bottom: 0 !important;
      padding-bottom: 0 !important;
      border-bottom: 0;
    }

    .package-section-heading {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 18px;
    }

    .package-section-icon,
    .status-card-icon,
    .package-helper-icon {
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

    .package-section-heading h6,
    .status-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .package-section-heading p,
    .status-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.6;
      margin-bottom: 0;
    }

    .package-create-card .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.02em;
      margin-bottom: 8px;
    }

    .package-create-card .form-control,
    .package-create-card .form-select {
      min-height: 54px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .package-create-card .form-control:focus,
    .package-create-card .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .package-create-card .form-text {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      margin-top: 8px;
    }

    .package-textarea {
      min-height: 138px !important;
      padding-top: 14px !important;
      resize: vertical;
    }

    .package-input-group {
      min-height: 54px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      overflow: hidden;
      background: #ffffff;
      transition: 0.18s ease;
    }

    .package-input-group:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .package-input-group .input-group-text {
      border: 0 !important;
      background: #ffffff !important;
      color: var(--mf-muted) !important;
      font-size: 13px !important;
      font-weight: 900 !important;
      padding-left: 16px;
      padding-right: 16px;
    }

    .package-input-group .form-control {
      border: 0 !important;
      border-radius: 0 !important;
      min-height: 52px !important;
    }

    .upload-dropzone {
      min-height: 250px;
      border: 1.8px dashed rgba(88, 115, 220, 0.35);
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        #ffffff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 28px;
      cursor: pointer;
      transition: 0.2s ease;
    }

    .upload-dropzone:hover,
    .upload-dropzone.drag-over {
      border-color: var(--mf-primary);
      background: var(--mf-primary-soft);
      transform: translateY(-2px);
    }

    .upload-icon {
      width: 62px;
      height: 62px;
      border-radius: 22px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 31px;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.22);
      margin-bottom: 14px;
    }

    .upload-dropzone h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .upload-dropzone p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 600;
      line-height: 1.65;
      margin-bottom: 16px;
    }

    .upload-dropzone small {
      color: var(--mf-muted);
      font-weight: 600;
      margin-top: 12px;
    }

    .upload-btn {
      min-width: 160px;
      min-height: 46px;
      border-radius: 15px;
      font-weight: 900;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .selected-file-info {
      margin-top: 14px;
      padding: 13px 16px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
      color: var(--mf-ink);
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .selected-file-info i {
      color: var(--mf-primary);
      font-size: 20px;
    }

    .status-card {
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

    .status-card-left {
      display: flex;
      align-items: center;
      gap: 14px;
    }

    .status-switch {
      flex-shrink: 0;
    }

    .status-switch .form-check-input {
      width: 46px;
      height: 24px;
      cursor: pointer;
    }

    .status-switch .form-check-label {
      color: var(--mf-ink);
      font-weight: 900;
      margin-left: 6px;
      cursor: pointer;
    }

    .preview-sticky {
      position: sticky;
      top: 105px;
    }

    .package-preview-card .card-body {
      padding: 24px !important;
    }

    .preview-image-wrap {
      position: relative;
      width: 100%;
      min-height: 230px;
      border-radius: 26px;
      overflow: hidden;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.22), transparent 38%),
        linear-gradient(135deg, #eef2ff 0%, #f8fbfd 100%);
      border: 1px solid var(--mf-border);
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: 0.2s ease;
    }

    .preview-image-wrap.is-landscape {
      aspect-ratio: 16 / 10;
      width: 100%;
      min-height: unset;
    }

    .preview-image-wrap.is-portrait {
      aspect-ratio: 3 / 4;
      width: min(78%, 310px);
      min-height: unset;
      margin-left: auto;
      margin-right: auto;
    }

    .preview-image-wrap.is-square {
      aspect-ratio: 1 / 1;
      width: min(88%, 330px);
      min-height: unset;
      margin-left: auto;
      margin-right: auto;
    }

    .preview-main-image {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
      background: #f8fbfd;
    }

    .preview-empty {
      height: 100%;
      min-height: 230px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: var(--mf-muted);
      font-weight: 800;
      gap: 8px;
    }

    .preview-empty i {
      font-size: 46px;
      color: var(--mf-primary);
    }

    .preview-badge {
      position: absolute;
      left: 14px;
      bottom: 14px;
      padding: 9px 12px;
      border-radius: 999px;
      background: rgba(22, 43, 77, 0.78);
      color: #ffffff;
      font-size: 12px;
      font-weight: 800;
      display: inline-flex;
      align-items: center;
      gap: 7px;
      backdrop-filter: blur(10px);
    }

    .preview-name-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 8px;
    }

    .preview-name-row h5 {
      color: var(--mf-ink);
      font-weight: 900;
      margin: 0;
      line-height: 1.35;
    }

    .preview-meta {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 16px;
    }

    .preview-meta i {
      color: var(--mf-primary);
      font-size: 17px;
    }

    .preview-detail-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 12px;
      margin-bottom: 16px;
    }

    .preview-detail-grid div {
      padding: 14px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .preview-detail-grid small {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      margin-bottom: 5px;
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }

    .preview-detail-grid strong {
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
    }

    #previewDescriptionText {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.7;
      margin-bottom: 18px;
    }

    .preview-thumbs {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 10px;
      max-height: 260px;
      overflow-y: auto;
      padding-right: 4px;
    }

    .preview-thumb-item {
      position: relative;
      border: 1px solid var(--mf-border);
      border-radius: 14px;
      overflow: hidden;
      background: #ffffff;
      cursor: pointer;
      transition: 0.18s ease;
    }

    .preview-thumb-item:hover,
    .preview-thumb-item.active {
      transform: translateY(-2px);
      border-color: var(--mf-primary);
      box-shadow: 0 12px 22px rgba(88, 115, 220, 0.16);
    }

    .preview-thumb-item img {
      width: 100%;
      height: 68px;
      object-fit: contain;
      display: block;
      background: #f8fbfd;
    }

    .remove-thumb-btn {
      position: absolute;
      top: 6px;
      right: 6px;
      width: 24px;
      height: 24px;
      border: 0;
      border-radius: 999px;
      background: rgba(220, 53, 69, 0.92);
      color: #ffffff;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      z-index: 2;
      padding: 0;
      line-height: 1;
    }

    .remove-thumb-btn i {
      font-size: 17px;
    }

    .preview-note {
      display: flex;
      align-items: flex-start;
      gap: 8px;
      margin-top: 14px;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      line-height: 1.6;
    }

    .preview-note i {
      color: var(--mf-primary);
      font-size: 17px;
      margin-top: 1px;
    }

    .package-helper-card {
      padding: 24px;
    }

    .package-helper-icon {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      font-size: 27px;
      margin-bottom: 16px;
    }

    .package-helper-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 8px;
    }

    .package-helper-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.7;
      margin-bottom: 16px;
    }

    .package-helper-list {
      display: flex;
      flex-direction: column;
      gap: 11px;
    }

    .package-helper-item {
      display: flex;
      align-items: flex-start;
      gap: 9px;
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.55;
    }

    .package-helper-item i {
      color: var(--mf-primary);
      font-size: 18px;
      margin-top: 1px;
    }

    @media (max-width: 991px) {
      .preview-sticky {
        position: static;
      }

      .package-create-hero {
        align-items: flex-start;
        flex-direction: column;
      }

      .package-create-hero-actions,
      .package-create-back-btn {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .package-create-hero {
        padding: 26px 22px;
      }

      .package-create-hero-left {
        flex-direction: column;
      }

      .package-create-hero h4 {
        font-size: 26px;
      }

      .package-create-card .card-header,
      .package-preview-card .card-header,
      .package-create-card .card-body,
      .package-create-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .upload-dropzone {
        min-height: 220px;
      }

      .status-card,
      .status-card-left,
      .package-section-heading {
        align-items: flex-start;
        flex-direction: column;
      }

      .package-create-footer {
        flex-direction: column-reverse;
        align-items: stretch;
      }

      .package-create-footer .btn {
        width: 100%;
      }

      .preview-detail-grid {
        grid-template-columns: 1fr;
      }

      .preview-thumbs {
        grid-template-columns: repeat(3, 1fr);
      }

      .preview-image-wrap.is-portrait {
        width: min(86%, 300px);
      }

      .preview-image-wrap.is-square {
        width: min(90%, 310px);
      }

      .package-helper-card {
        padding: 22px;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const form = document.getElementById('createPackageForm');
      const dropzone = document.getElementById('portfolioDropzone');
      const portfolioInput = document.getElementById('portfolioImages');
      const previewContainer = document.getElementById('imagePreview');
      const selectedFileInfo = document.getElementById('selectedFileInfo');
      const selectedFileText = document.getElementById('selectedFileText');
      const browsePortfolioBtn = document.getElementById('browsePortfolioBtn');

      const mainPreviewWrap = document.getElementById('mainPreviewWrap');
      const mainPreviewImage = document.getElementById('mainPreviewImage');
      const previewEmpty = document.getElementById('previewEmpty');
      const previewFileBadge = document.getElementById('previewFileBadge');
      const previewFileCount = document.getElementById('previewFileCount');

      const packageName = document.getElementById('packageName');
      const packageCategory = document.getElementById('packageCategory');
      const packagePrice = document.getElementById('packagePrice');
      const packageDuration = document.getElementById('packageDuration');
      const packagePhotoCount = document.getElementById('packagePhotoCount');
      const packageLocation = document.getElementById('packageLocation');
      const packageDescription = document.getElementById('packageDescription');

      const previewPackageName = document.getElementById('previewPackageName');
      const previewCategoryText = document.getElementById('previewCategoryText');
      const previewPriceText = document.getElementById('previewPriceText');
      const previewDurationText = document.getElementById('previewDurationText');
      const previewPhotoText = document.getElementById('previewPhotoText');
      const previewLocationText = document.getElementById('previewLocationText');
      const previewDescriptionText = document.getElementById('previewDescriptionText');

      let selectedFiles = [];

      function formatRupiah(value) {
        const number = parseInt(value || 0, 10);
        return 'Rp ' + new Intl.NumberFormat('id-ID').format(number);
      }

      function clearPreviewOrientation() {
        if (!mainPreviewWrap) return;

        mainPreviewWrap.classList.remove('is-landscape', 'is-portrait', 'is-square');
      }

      function applyPreviewOrientation(src) {
        if (!mainPreviewWrap || !src) return;

        const tempImage = new Image();

        tempImage.onload = function () {
          clearPreviewOrientation();

          const width = tempImage.naturalWidth;
          const height = tempImage.naturalHeight;

          if (width > height) {
            mainPreviewWrap.classList.add('is-landscape');
          } else if (height > width) {
            mainPreviewWrap.classList.add('is-portrait');
          } else {
            mainPreviewWrap.classList.add('is-square');
          }
        };

        tempImage.src = src;
      }

      function setMainImage(src) {
        if (!src) {
          mainPreviewImage.src = '';
          mainPreviewImage.classList.add('d-none');
          previewEmpty.classList.remove('d-none');
          clearPreviewOrientation();
          return;
        }

        mainPreviewImage.src = src;
        mainPreviewImage.classList.remove('d-none');
        previewEmpty.classList.add('d-none');

        applyPreviewOrientation(src);
      }

      function syncInputFiles() {
        const dataTransfer = new DataTransfer();

        selectedFiles.forEach(function (file) {
          dataTransfer.items.add(file);
        });

        portfolioInput.files = dataTransfer.files;
      }

      function refreshFileInfo() {
        const total = selectedFiles.length;

        if (total > 0) {
          selectedFileInfo.classList.remove('d-none');
          selectedFileText.textContent = total + ' gambar dipilih';

          previewFileBadge.classList.remove('d-none');
          previewFileCount.textContent = total + ' foto';
        } else {
          selectedFileInfo.classList.add('d-none');
          selectedFileText.textContent = 'Belum ada gambar dipilih.';

          previewFileBadge.classList.add('d-none');
          previewFileCount.textContent = '0 foto';
        }
      }

      function setActiveThumb(item) {
        previewContainer.querySelectorAll('.preview-thumb-item').forEach(function (thumb) {
          thumb.classList.remove('active');
        });

        item.classList.add('active');
        setMainImage(item.dataset.src);
      }

      function chooseFirstImageIfNeeded() {
        const activeThumb = previewContainer.querySelector('.preview-thumb-item.active');

        if (activeThumb) {
          setMainImage(activeThumb.dataset.src);
          return;
        }

        const firstThumb = previewContainer.querySelector('.preview-thumb-item');

        if (firstThumb) {
          setActiveThumb(firstThumb);
        } else {
          setMainImage('');
        }
      }

      function renderImages() {
        previewContainer.innerHTML = '';

        selectedFiles.forEach(function (file, index) {
          const imageUrl = URL.createObjectURL(file);

          const item = document.createElement('div');
          item.className = 'preview-thumb-item' + (index === 0 ? ' active' : '');
          item.dataset.index = index;
          item.dataset.src = imageUrl;

          item.innerHTML = `
            <button type="button" class="remove-thumb-btn" title="Hapus gambar">
              <i class="bx bx-x"></i>
            </button>
            <img src="${imageUrl}" alt="${file.name}">
          `;

          item.addEventListener('click', function () {
            setActiveThumb(item);
          });

          item.querySelector('.remove-thumb-btn').addEventListener('click', function (event) {
            event.stopPropagation();

            const wasActive = item.classList.contains('active');
            const fileIndex = parseInt(item.dataset.index, 10);

            selectedFiles.splice(fileIndex, 1);
            syncInputFiles();
            renderImages();

            if (wasActive) {
              chooseFirstImageIfNeeded();
            }
          });

          previewContainer.appendChild(item);
        });

        refreshFileInfo();
        chooseFirstImageIfNeeded();
      }

      function addFiles(files) {
        const imageFiles = files.filter(function (file) {
          return file.type.startsWith('image/');
        });

        if (!imageFiles.length) {
          alert('File harus berupa gambar.');
          portfolioInput.value = '';
          return;
        }

        if ((selectedFiles.length + imageFiles.length) > 20) {
          alert('Maksimal 20 gambar portofolio.');
          portfolioInput.value = '';
          return;
        }

        imageFiles.forEach(function (file) {
          selectedFiles.push(file);
        });

        syncInputFiles();
        renderImages();

        const newestThumb = previewContainer.querySelector('.preview-thumb-item:last-child');

        if (newestThumb) {
          setActiveThumb(newestThumb);
        }
      }

      function updatePackagePreview() {
        previewPackageName.textContent = packageName.value.trim() || 'Nama Paket';

        if (packageCategory.value) {
          previewCategoryText.textContent = packageCategory.options[packageCategory.selectedIndex]?.text || 'Kategori belum dipilih';
        } else {
          previewCategoryText.textContent = 'Kategori belum dipilih';
        }

        previewPriceText.textContent = formatRupiah(packagePrice.value);
        previewDurationText.textContent = (packageDuration.value || 0) + ' Menit';
        previewPhotoText.textContent = (packagePhotoCount.value || 0) + ' Foto';

        previewLocationText.textContent = packageLocation.value
          ? packageLocation.value.charAt(0).toUpperCase() + packageLocation.value.slice(1)
          : '-';

        previewDescriptionText.textContent = packageDescription.value.trim() || 'Deskripsi paket akan muncul di sini.';
      }

      if (dropzone && portfolioInput) {
        dropzone.addEventListener('click', function (event) {
          if (
            event.target === portfolioInput ||
            event.target === browsePortfolioBtn ||
            browsePortfolioBtn?.contains(event.target)
          ) {
            return;
          }

          portfolioInput.click();
        });

        dropzone.addEventListener('dragover', function (event) {
          event.preventDefault();
          dropzone.classList.add('drag-over');
        });

        dropzone.addEventListener('dragleave', function () {
          dropzone.classList.remove('drag-over');
        });

        dropzone.addEventListener('drop', function (event) {
          event.preventDefault();
          dropzone.classList.remove('drag-over');

          addFiles(Array.from(event.dataTransfer.files));
        });

        portfolioInput.addEventListener('change', function () {
          addFiles(Array.from(this.files));
        });
      }

      [
        packageName,
        packageCategory,
        packagePrice,
        packageDuration,
        packagePhotoCount,
        packageLocation,
        packageDescription
      ].forEach(function (input) {
        if (!input) return;

        input.addEventListener('input', updatePackagePreview);
        input.addEventListener('change', updatePackagePreview);
      });

      if (form) {
        form.addEventListener('submit', function (event) {
          if (portfolioInput.files.length > 20) {
            event.preventDefault();
            alert('Maksimal 20 gambar portofolio.');
          }
        });
      }

      updatePackagePreview();
      refreshFileInfo();
      chooseFirstImageIfNeeded();
    });
  </script>
@endsection
