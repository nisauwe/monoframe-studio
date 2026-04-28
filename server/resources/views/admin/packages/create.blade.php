@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Paket')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- PAGE HEADER --}}
      <div class="dashboard-heading">
        <div>
          <h4 class="dashboard-title mb-1">Tambah Paket Baru</h4>
          <p class="dashboard-date mb-0">
            Tambahkan paket layanan foto, harga, durasi, detail edit, dan portofolio studio.
          </p>
        </div>

        <a href="{{ route('admin.packages.index', ['tab' => 'photo-packages']) }}" class="btn btn-outline-secondary">
          <i class="bx bx-arrow-back me-1"></i>
          Kembali
        </a>
      </div>

      {{-- ALERT ERROR --}}
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

      <form action="{{ route('admin.packages.store') }}" method="POST" enctype="multipart/form-data" id="createPackageForm">
        @csrf

        <div class="row g-4">
          {{-- LEFT CONTENT --}}
          <div class="col-xl-8 col-lg-7">
            <div class="card section-card package-create-card">
              <div class="card-header">
                <div>
                  <h5 class="section-title">Informasi Paket</h5>
                  <p class="section-subtitle mb-0">
                    Lengkapi detail paket foto yang akan ditampilkan pada sistem Monoframe.
                  </p>
                </div>
              </div>

              <div class="card-body package-create-body">

                {{-- UPLOAD FILE --}}
                <div class="create-section">
                  <div class="create-section-heading">
                    <div>
                      <h6>Upload Portofolio</h6>
                      <p>Pilih maksimal 20 gambar. Format JPG, JPEG, PNG, atau WEBP.</p>
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
                      <i class="bx bx-upload"></i>
                    </div>

                    <h6>Upload file portofolio</h6>
                    <p>Drag & drop gambar ke sini atau klik tombol di bawah.</p>

                    <label for="portfolioImages" class="btn btn-primary upload-btn">
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
                <div class="create-section">
                  <div class="create-section-heading">
                    <div>
                      <h6>Detail Utama</h6>
                      <p>Masukkan nama paket, kategori, harga, durasi, dan jumlah foto edit.</p>
                    </div>
                  </div>

                  <div class="row g-3">
                    <div class="col-md-6">
                      <label class="form-label">Nama Paket</label>
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
                      <label class="form-label">Kategori</label>
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
                      <label class="form-label">Harga Paket</label>
                      <div class="input-group">
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
                      <label class="form-label">Durasi</label>
                      <div class="input-group">
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
                      <label class="form-label">Jumlah Foto Edit</label>
                      <div class="input-group">
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
                      <label class="form-label">Jenis Lokasi</label>
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
                      <label class="form-label">Jumlah Orang</label>
                      <input
                        type="number"
                        name="person_count"
                        id="packagePersonCount"
                        class="form-control"
                        value="{{ old('person_count') }}"
                        placeholder="Boleh dikosongkan"
                        min="1">
                      <small class="text-muted d-block mt-1">
                        Kosongkan untuk paket seperti prewed atau wedding.
                      </small>
                    </div>

                    <div class="col-12">
                      <label class="form-label">Deskripsi Paket</label>
                      <textarea
                        name="description"
                        id="packageDescription"
                        class="form-control"
                        rows="5"
                        placeholder="Tulis deskripsi lengkap paket...">{{ old('description') }}</textarea>
                    </div>
                  </div>
                </div>

                {{-- STATUS --}}
                <div class="create-section mb-0">
                  <div class="status-card">
                    <div>
                      <h6>Status Paket</h6>
                      <p>Jika aktif, paket akan tampil dan bisa digunakan pada sistem.</p>
                    </div>

                    <input type="hidden" name="is_active" value="0">

                    <div class="form-check form-switch mb-0">
                      <input
                        class="form-check-input"
                        type="checkbox"
                        role="switch"
                        id="isActive"
                        name="is_active"
                        value="1"
                        {{ old('is_active', 1) ? 'checked' : '' }}>
                      <label class="form-check-label fw-semibold" for="isActive">
                        Aktif
                      </label>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card-footer package-create-footer">
                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Paket
                </button>

                <a href="{{ route('admin.packages.index', ['tab' => 'photo-packages']) }}" class="btn btn-outline-secondary">
                  Batal
                </a>
              </div>
            </div>
          </div>

          {{-- RIGHT PREVIEW --}}
          <div class="col-xl-4 col-lg-5">
            <div class="preview-sticky">
              <div class="card section-card preview-card">
                <div class="card-header">
                  <div>
                    <h5 class="section-title">Preview File</h5>
                    <p class="section-subtitle mb-0">
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
                    <h5 id="previewPackageName">Nama Paket</h5>

                    <div class="preview-meta">
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
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>

  <style>
    .package-create-card .card-header,
    .preview-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .package-create-body {
      padding: 28px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.14), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-create-footer {
      padding: 22px 34px 28px !important;
      display: flex;
      justify-content: flex-end;
      flex-wrap: wrap;
      gap: 10px;
    }

    .create-section {
      margin-bottom: 34px;
    }

    .create-section-heading {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 14px;
      margin-bottom: 16px;
    }

    .create-section-heading h6,
    .status-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .create-section-heading p,
    .status-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.6;
      margin-bottom: 0;
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
      margin-bottom: 14px;
    }

    .upload-dropzone h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .upload-dropzone p {
      color: var(--mf-muted);
      font-weight: 600;
      margin-bottom: 16px;
    }

    .upload-dropzone small {
      color: var(--mf-muted);
      font-weight: 600;
      margin-top: 12px;
    }

    .upload-btn {
      min-width: 150px;
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
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .preview-sticky {
      position: sticky;
      top: 105px;
    }

    .preview-card .card-body {
      padding: 24px !important;
    }

    .preview-image-wrap {
      position: relative;
      height: 230px;
      border-radius: 26px;
      overflow: hidden;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.22), transparent 38%),
        linear-gradient(135deg, #eef2ff 0%, #f8fbfd 100%);
      border: 1px solid var(--mf-border);
      margin-bottom: 20px;
    }

    .preview-main-image {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }

    .preview-empty {
      height: 100%;
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

    .preview-content h5 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .preview-meta {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 16px;
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
      font-weight: 800;
      margin-bottom: 5px;
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
      max-height: 220px;
      overflow-y: auto;
      padding-right: 4px;
    }

    .preview-thumb-item {
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
      object-fit: cover;
      display: block;
    }

    @media (max-width: 991px) {
      .preview-sticky {
        position: static;
      }
    }

    @media (max-width: 768px) {
      .package-create-card .card-header,
      .preview-card .card-header,
      .package-create-body,
      .package-create-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .upload-dropzone {
        min-height: 220px;
      }

      .status-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .package-create-footer {
        justify-content: flex-start;
      }

      .preview-detail-grid {
        grid-template-columns: 1fr;
      }

      .preview-thumbs {
        grid-template-columns: repeat(3, 1fr);
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

      function formatRupiah(value) {
        const number = parseInt(value || 0, 10);

        return 'Rp ' + new Intl.NumberFormat('id-ID').format(number);
      }

      function updatePackagePreview() {
        previewPackageName.textContent = packageName.value.trim() || 'Nama Paket';

        previewCategoryText.textContent = packageCategory.options[packageCategory.selectedIndex]?.text || 'Kategori belum dipilih';

        if (!packageCategory.value) {
          previewCategoryText.textContent = 'Kategori belum dipilih';
        }

        previewPriceText.textContent = formatRupiah(packagePrice.value);
        previewDurationText.textContent = (packageDuration.value || 0) + ' Menit';
        previewPhotoText.textContent = (packagePhotoCount.value || 0) + ' Foto';
        previewLocationText.textContent = packageLocation.value ? packageLocation.value.charAt(0).toUpperCase() + packageLocation.value.slice(1) : '-';

        previewDescriptionText.textContent = packageDescription.value.trim() || 'Deskripsi paket akan muncul di sini.';
      }

      function setMainImage(src) {
        mainPreviewImage.src = src;
        mainPreviewImage.classList.remove('d-none');
        previewEmpty.classList.add('d-none');
      }

      function resetImagePreview() {
        previewContainer.innerHTML = '';
        mainPreviewImage.src = '';
        mainPreviewImage.classList.add('d-none');
        previewEmpty.classList.remove('d-none');
        previewFileBadge.classList.add('d-none');
        selectedFileInfo.classList.add('d-none');
        selectedFileText.textContent = 'Belum ada gambar dipilih.';
      }

      function renderImages(files) {
        previewContainer.innerHTML = '';

        if (!files.length) {
          resetImagePreview();
          return;
        }

        if (files.length > 20) {
          alert('Maksimal 20 gambar portofolio.');
          portfolioInput.value = '';
          resetImagePreview();
          return;
        }

        const imageFiles = files.filter(function (file) {
          return file.type.startsWith('image/');
        });

        if (!imageFiles.length) {
          alert('File harus berupa gambar.');
          portfolioInput.value = '';
          resetImagePreview();
          return;
        }

        selectedFileInfo.classList.remove('d-none');
        selectedFileText.textContent = imageFiles.length + ' gambar dipilih';

        previewFileBadge.classList.remove('d-none');
        previewFileCount.textContent = imageFiles.length + ' foto';

        imageFiles.forEach(function (file, index) {
          const imageUrl = URL.createObjectURL(file);

          if (index === 0) {
            setMainImage(imageUrl);
          }

          const item = document.createElement('div');
          item.className = 'preview-thumb-item' + (index === 0 ? ' active' : '');

          item.innerHTML = `
            <img src="${imageUrl}" alt="${file.name}">
          `;

          item.addEventListener('click', function () {
            document.querySelectorAll('.preview-thumb-item').forEach(function (thumb) {
              thumb.classList.remove('active');
            });

            item.classList.add('active');
            setMainImage(imageUrl);
          });

          previewContainer.appendChild(item);
        });
      }

      function setInputFiles(files) {
        const dataTransfer = new DataTransfer();

        files.forEach(function (file) {
          dataTransfer.items.add(file);
        });

        portfolioInput.files = dataTransfer.files;
        renderImages(Array.from(portfolioInput.files));
      }

      if (dropzone && portfolioInput) {
        dropzone.addEventListener('click', function (event) {
          if (event.target.tagName.toLowerCase() !== 'label') {
            portfolioInput.click();
          }
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

          const files = Array.from(event.dataTransfer.files);
          setInputFiles(files);
        });

        portfolioInput.addEventListener('change', function () {
          renderImages(Array.from(this.files));
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
    });
  </script>
@endsection