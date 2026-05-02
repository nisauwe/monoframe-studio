@extends('layouts/contentNavbarLayout')

@section('title', 'Edit Paket')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="package-edit-shell">

      {{-- HERO HEADER --}}
      <div class="package-edit-hero mb-4">
        <div class="package-edit-hero-left">
          <div class="package-edit-hero-icon">
            <i class="bx bx-edit-alt"></i>
          </div>

          <div>
            <div class="package-edit-kicker">MANAJEMEN PAKET FOTO</div>
            <h4>Edit Paket Foto</h4>
            <p>
              Perbarui data paket foto, harga, durasi, jumlah foto edit, jenis lokasi,
              status, deskripsi, dan portofolio paket Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="package-edit-hero-actions">
          <a href="{{ route('admin.packages.index', ['tab' => 'photo-packages']) }}" class="btn package-edit-back-btn">
            <i class="bx bx-arrow-back me-1"></i>
            Kembali
          </a>
        </div>
      </div>

      {{-- ERROR ALERT --}}
      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4 package-edit-alert" role="alert">
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

      <form
        action="{{ route('admin.packages.update', $package->id) }}"
        method="POST"
        enctype="multipart/form-data"
        id="editPackageForm">
        @csrf
        @method('PUT')

        <div class="row g-4">
          {{-- LEFT CONTENT --}}
          <div class="col-xl-8 col-lg-7">
            <div class="card package-edit-card">
              <div class="card-header">
                <div>
                  <h5 class="mb-1">Form Edit Paket</h5>
                  <p class="mb-0">
                    Ubah informasi paket foto yang akan digunakan pada sistem dan aplikasi klien.
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
                      <h6>Tambah Portofolio Baru</h6>
                      <p>
                        Tambahkan gambar portofolio baru. Gambar lama bisa dihapus dari preview sebelah kanan.
                      </p>
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

                    <small>Max total 20 gambar • JPG, JPEG, PNG, WEBP</small>
                  </div>

                  <div class="selected-file-info mt-3" id="selectedFileInfo">
                    <i class="bx bx-image"></i>
                    <span id="selectedFileText">
                      Total gambar aktif: {{ is_array($package->portfolio) ? count($package->portfolio) : 0 }} foto.
                    </span>
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
                      <p>Perbarui nama paket, kategori, harga, durasi, jumlah edit, dan lokasi.</p>
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
                        value="{{ old('name', $package->name) }}"
                        placeholder="Contoh: Paket Wisuda Silver"
                        required>
                    </div>

                    <div class="col-md-6">
                      <label for="packageCategory" class="form-label">Kategori</label>
                      <select name="category_id" id="packageCategory" class="form-select" required>
                        <option value="">Pilih Kategori</option>
                        @foreach ($categories as $category)
                          <option
                            value="{{ $category->id }}"
                            {{ old('category_id', $package->category_id) == $category->id ? 'selected' : '' }}>
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
                          value="{{ old('price', $package->price) }}"
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
                          value="{{ old('duration_minutes', $package->duration_minutes) }}"
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
                          value="{{ old('photo_count', $package->photo_count) }}"
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
                        <option value="indoor" {{ old('location_type', $package->location_type) === 'indoor' ? 'selected' : '' }}>
                          Indoor
                        </option>
                        <option value="outdoor" {{ old('location_type', $package->location_type) === 'outdoor' ? 'selected' : '' }}>
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
                        value="{{ old('person_count', $package->person_count) }}"
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
                        placeholder="Tulis deskripsi lengkap paket...">{{ old('description', $package->description) }}</textarea>
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
                        {{ old('is_active', $package->is_active) ? 'checked' : '' }}>
                      <label class="form-check-label" for="isActive">
                        Aktif
                      </label>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-footer package-edit-footer">
                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Perubahan
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
                      Gambar lama dan gambar baru yang akan tersimpan.
                    </p>
                  </div>
                </div>

                <div class="card-body">
                  <div class="preview-image-wrap" id="mainPreviewWrap">
                    <div class="preview-empty {{ !empty($package->portfolio) ? 'd-none' : '' }}" id="previewEmpty">
                      <i class="bx bx-image-add"></i>
                      <span>Belum ada gambar</span>
                    </div>

                    <img
                      id="mainPreviewImage"
                      class="preview-main-image {{ !empty($package->portfolio) ? '' : 'd-none' }}"
                      src="{{ !empty($package->portfolio) ? asset('storage/' . $package->portfolio[0]) : '' }}"
                      alt="Preview Portofolio">

                    <div class="preview-badge {{ !empty($package->portfolio) ? '' : 'd-none' }}" id="previewFileBadge">
                      <i class="bx bx-images"></i>
                      <span id="previewFileCount">
                        {{ is_array($package->portfolio) ? count($package->portfolio) : 0 }} foto
                      </span>
                    </div>
                  </div>

                  <div class="preview-content">
                    <div class="preview-name-row">
                      <h5 id="previewPackageName">{{ $package->name ?: 'Nama Paket' }}</h5>
                      <span
                        class="badge {{ old('is_active', $package->is_active) ? 'bg-label-success' : 'bg-label-secondary' }}"
                        id="previewStatusBadge">
                        {{ old('is_active', $package->is_active) ? 'Aktif' : 'Tidak Aktif' }}
                      </span>
                    </div>

                    <div class="preview-meta">
                      <i class="bx bx-category-alt"></i>
                      <span id="previewCategoryText">
                        {{ optional($package->category)->name ?? 'Kategori belum dipilih' }}
                      </span>
                    </div>

                    <div class="preview-detail-grid">
                      <div>
                        <small>Harga</small>
                        <strong id="previewPriceText">Rp {{ number_format($package->price ?? 0, 0, ',', '.') }}</strong>
                      </div>

                      <div>
                        <small>Durasi</small>
                        <strong id="previewDurationText">{{ $package->duration_minutes ?? 0 }} Menit</strong>
                      </div>

                      <div>
                        <small>Jumlah Edit</small>
                        <strong id="previewPhotoText">{{ $package->photo_count ?? 0 }} Foto</strong>
                      </div>

                      <div>
                        <small>Lokasi</small>
                        <strong id="previewLocationText">
                          {{ $package->location_type ? ucfirst($package->location_type) : '-' }}
                        </strong>
                      </div>
                    </div>

                    <p id="previewDescriptionText">
                      {{ $package->description ?: 'Deskripsi paket akan muncul di sini.' }}
                    </p>
                  </div>

                  <div class="preview-thumbs" id="imagePreview">
                    @if (!empty($package->portfolio))
                      @foreach ($package->portfolio as $index => $image)
                        <div
                          class="preview-thumb-item existing-thumb {{ $index === 0 ? 'active' : '' }}"
                          data-type="existing"
                          data-path="{{ $image }}"
                          data-src="{{ asset('storage/' . $image) }}">
                          <button type="button" class="remove-thumb-btn" title="Hapus gambar">
                            <i class="bx bx-x"></i>
                          </button>
                          <img src="{{ asset('storage/' . $image) }}" alt="Portfolio {{ $index + 1 }}">
                        </div>
                      @endforeach
                    @endif
                  </div>

                  <div id="removedPortfolioInputs"></div>

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

                <h6>Tips Edit Paket</h6>
                <p>
                  Pastikan perubahan harga, durasi, jumlah edit, dan portofolio sudah sesuai
                  sebelum menyimpan paket.
                </p>

                <div class="package-helper-list">
                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Hapus portofolio lama yang sudah tidak relevan.</span>
                  </div>

                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Pastikan kategori dan lokasi sudah benar.</span>
                  </div>

                  <div class="package-helper-item">
                    <i class="bx bx-check-circle"></i>
                    <span>Nonaktifkan paket jika belum siap ditampilkan.</span>
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
    .package-edit-hero {
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

    .package-edit-hero::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .package-edit-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .package-edit-hero-icon {
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

    .package-edit-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .package-edit-hero h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .package-edit-hero p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .package-edit-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .package-edit-back-btn {
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

    .package-edit-back-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .package-edit-alert {
      border: 0;
      border-radius: 20px;
      box-shadow: var(--mf-shadow-soft);
    }

    .package-edit-alert i {
      font-size: 20px;
    }

    .package-edit-card,
    .package-preview-card,
    .package-helper-card {
      border: 0;
      border-radius: 30px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .package-edit-card .card-header,
    .package-preview-card .card-header {
      padding: 30px 34px 22px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-edit-card .card-header h5,
    .package-preview-card .card-header h5 {
      color: var(--mf-ink);
      font-weight: 900;
    }

    .package-edit-card .card-header p,
    .package-preview-card .card-header p {
      color: var(--mf-muted);
      font-size: 14px;
      font-weight: 600;
      line-height: 1.6;
    }

    .package-edit-card .card-body {
      padding: 30px 34px 34px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.10), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-edit-footer {
      padding: 24px 34px 30px !important;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 12px;
      background: #ffffff;
    }

    .package-edit-footer .btn {
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

    .package-edit-card .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.02em;
      margin-bottom: 8px;
    }

    .package-edit-card .form-control,
    .package-edit-card .form-select {
      min-height: 54px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .package-edit-card .form-control:focus,
    .package-edit-card .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .package-edit-card .form-text {
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

      .package-edit-hero {
        align-items: flex-start;
        flex-direction: column;
      }

      .package-edit-hero-actions,
      .package-edit-back-btn {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .package-edit-hero {
        padding: 26px 22px;
      }

      .package-edit-hero-left {
        flex-direction: column;
      }

      .package-edit-hero h4 {
        font-size: 26px;
      }

      .package-edit-card .card-header,
      .package-preview-card .card-header,
      .package-edit-card .card-body,
      .package-edit-footer {
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

      .package-edit-footer {
        flex-direction: column-reverse;
        align-items: stretch;
      }

      .package-edit-footer .btn {
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
      const form = document.getElementById('editPackageForm');
      const dropzone = document.getElementById('portfolioDropzone');
      const portfolioInput = document.getElementById('portfolioImages');
      const previewContainer = document.getElementById('imagePreview');
      const removedPortfolioInputs = document.getElementById('removedPortfolioInputs');
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
      const isActiveInput = document.getElementById('isActive');

      const previewPackageName = document.getElementById('previewPackageName');
      const previewCategoryText = document.getElementById('previewCategoryText');
      const previewPriceText = document.getElementById('previewPriceText');
      const previewDurationText = document.getElementById('previewDurationText');
      const previewPhotoText = document.getElementById('previewPhotoText');
      const previewLocationText = document.getElementById('previewLocationText');
      const previewDescriptionText = document.getElementById('previewDescriptionText');
      const previewStatusBadge = document.getElementById('previewStatusBadge');

      let selectedNewFiles = [];

      function formatRupiah(value) {
        const number = parseInt(value || 0, 10);

        if (Number.isNaN(number)) {
          return 'Rp 0';
        }

        return 'Rp ' + new Intl.NumberFormat('id-ID').format(number);
      }

      function getActiveThumbs() {
        return Array.from(previewContainer.querySelectorAll('.preview-thumb-item'));
      }

      function getExistingActiveCount() {
        return previewContainer.querySelectorAll('.existing-thumb').length;
      }

      function getTotalImageCount() {
        return getExistingActiveCount() + selectedNewFiles.length;
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

      function refreshCounter() {
        const total = getTotalImageCount();

        selectedFileText.textContent = 'Total gambar aktif: ' + total + ' foto.';
        previewFileCount.textContent = total + ' foto';

        if (total > 0) {
          previewFileBadge.classList.remove('d-none');
        } else {
          previewFileBadge.classList.add('d-none');
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

      function syncFileInput() {
        const dataTransfer = new DataTransfer();

        selectedNewFiles.forEach(function (file) {
          dataTransfer.items.add(file);
        });

        portfolioInput.files = dataTransfer.files;
      }

      function addRemovedPortfolioInput(path) {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'remove_portfolio[]';
        input.value = path;
        removedPortfolioInputs.appendChild(input);
      }

      function bindExistingThumbEvents() {
        previewContainer.querySelectorAll('.existing-thumb').forEach(function (item) {
          item.addEventListener('click', function () {
            setActiveThumb(item);
          });

          const removeButton = item.querySelector('.remove-thumb-btn');

          if (removeButton) {
            removeButton.addEventListener('click', function (event) {
              event.stopPropagation();

              const path = item.dataset.path;
              const wasActive = item.classList.contains('active');

              addRemovedPortfolioInput(path);
              item.remove();

              if (wasActive) {
                const firstThumb = previewContainer.querySelector('.preview-thumb-item');

                if (firstThumb) {
                  setActiveThumb(firstThumb);
                } else {
                  setMainImage('');
                }
              }

              chooseFirstImageIfNeeded();
              refreshCounter();
            });
          }
        });
      }

      function createNewThumb(file, index) {
        const imageUrl = URL.createObjectURL(file);

        const item = document.createElement('div');
        item.className = 'preview-thumb-item new-thumb';
        item.dataset.type = 'new';
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

          selectedNewFiles.splice(fileIndex, 1);
          syncFileInput();
          renderNewThumbs();

          if (wasActive) {
            const firstThumb = previewContainer.querySelector('.preview-thumb-item');

            if (firstThumb) {
              setActiveThumb(firstThumb);
            } else {
              setMainImage('');
            }
          }

          chooseFirstImageIfNeeded();
          refreshCounter();
        });

        return item;
      }

      function renderNewThumbs() {
        previewContainer.querySelectorAll('.new-thumb').forEach(function (thumb) {
          thumb.remove();
        });

        selectedNewFiles.forEach(function (file, index) {
          const item = createNewThumb(file, index);
          previewContainer.appendChild(item);
        });

        chooseFirstImageIfNeeded();
        refreshCounter();
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

        const totalAfterAdd = getExistingActiveCount() + selectedNewFiles.length + imageFiles.length;

        if (totalAfterAdd > 20) {
          alert('Maksimal total 20 gambar portofolio. Hapus beberapa gambar dulu jika ingin menambah lagi.');
          portfolioInput.value = '';
          return;
        }

        imageFiles.forEach(function (file) {
          selectedNewFiles.push(file);
        });

        syncFileInput();
        renderNewThumbs();

        const newestThumb = previewContainer.querySelector('.new-thumb:last-child');

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

        const isActive = isActiveInput.checked;

        previewStatusBadge.textContent = isActive ? 'Aktif' : 'Tidak Aktif';
        previewStatusBadge.classList.toggle('bg-label-success', isActive);
        previewStatusBadge.classList.toggle('bg-label-secondary', !isActive);
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
        packageDescription,
        isActiveInput
      ].forEach(function (input) {
        if (!input) return;

        input.addEventListener('input', updatePackagePreview);
        input.addEventListener('change', updatePackagePreview);
      });

      if (form) {
        form.addEventListener('submit', function (event) {
          if (getTotalImageCount() > 20) {
            event.preventDefault();
            alert('Maksimal total 20 gambar portofolio.');
          }
        });
      }

      bindExistingThumbEvents();
      chooseFirstImageIfNeeded();
      refreshCounter();
      updatePackagePreview();
    });
  </script>
@endsection
