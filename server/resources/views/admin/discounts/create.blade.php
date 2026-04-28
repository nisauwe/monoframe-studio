@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Diskon')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- PAGE HEADER --}}
      <div class="dashboard-heading">
        <div>
          <h4 class="dashboard-title mb-1">Tambah Diskon</h4>
          <p class="dashboard-date mb-0">
            Buat promo diskon baru dengan memilih kategori dan paket yang ingin diberi diskon.
          </p>
        </div>

        <a href="{{ route('admin.packages.index', ['tab' => 'discounts']) }}" class="btn btn-outline-secondary">
          <i class="bx bx-arrow-back me-1"></i>
          Kembali
        </a>
      </div>

      {{-- ALERT ERROR --}}
      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

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

      <form action="{{ route('admin.discounts.store') }}" method="POST" id="discountForm">
        @csrf

        <div class="card section-card discount-form-card">
          <div class="card-header">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
              <div>
                <h5 class="section-title">Form Tambah Diskon</h5>
                <p class="section-subtitle mb-0">
                  Pilih kategori terlebih dahulu, lalu pilih paket yang akan mendapatkan diskon.
                </p>
              </div>

              <div class="mf-badge-total" id="selectedPackageCounter">
                <i class="bx bx-package"></i>
                0 paket dipilih
              </div>
            </div>
          </div>

          <div class="card-body discount-form-body">
            <div class="row g-4">

              {{-- KATEGORI --}}
              <div class="col-md-6">
                <label class="form-label">Kategori</label>
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
                <small class="text-muted d-block mt-2">
                  Setelah kategori dipilih, paket pada kategori tersebut akan muncul di bawah.
                </small>
              </div>

              {{-- NAMA PROMO --}}
              <div class="col-md-6">
                <label class="form-label">Nama Kampanye</label>
                <input
                  type="text"
                  name="promo_name"
                  class="form-control"
                  value="{{ old('promo_name') }}"
                  placeholder="Contoh: Promo Lebaran">
              </div>

              {{-- DISKON --}}
              <div class="col-md-4">
                <label class="form-label">Besar Diskon (%)</label>
                <input
                  type="number"
                  name="discount_percent"
                  class="form-control"
                  min="1"
                  max="100"
                  value="{{ old('discount_percent') }}"
                  placeholder="Contoh: 10"
                  required>
              </div>

              {{-- TANGGAL MULAI --}}
              <div class="col-md-4">
                <label class="form-label">Mulai Tanggal</label>
                <input
                  type="date"
                  name="discount_start_at"
                  class="form-control"
                  value="{{ old('discount_start_at') }}">
              </div>

              {{-- TANGGAL SELESAI --}}
              <div class="col-md-4">
                <label class="form-label">Selesai Tanggal</label>
                <input
                  type="date"
                  name="discount_end_at"
                  class="form-control"
                  value="{{ old('discount_end_at') }}">
              </div>

              {{-- STATUS --}}
              <div class="col-12">
                <div class="discount-status-card">
                  <div>
                    <div class="discount-status-title">Status Diskon</div>
                    <div class="discount-status-subtitle">
                      Jika aktif, diskon akan dihitung pada paket yang dipilih.
                    </div>
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
                    <label class="form-check-label fw-semibold" for="isActive">Aktif</label>
                  </div>
                </div>
              </div>

              {{-- PILIH PAKET --}}
              <div class="col-12">
                <div class="discount-package-section">
                  <div class="discount-package-header">
                    <div>
                      <h6>Pilih Paket</h6>
                      <p>
                        Paket akan tampil sesuai kategori yang dipilih. Centang paket yang ingin diberi diskon.
                      </p>
                    </div>
                  </div>

                  <div id="packageEmptyChooseCategory" class="discount-empty-state">
                    <i class="bx bx-category-alt"></i>
                    <h6>Pilih kategori terlebih dahulu</h6>
                    <p>Setelah kategori dipilih, daftar paket akan muncul di sini.</p>
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
                            {{ in_array($package->id, old('package_ids', [])) ? 'checked' : '' }}>

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
          </div>

          <div class="card-footer discount-form-footer">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i>
              Simpan Diskon
            </button>

            <a href="{{ route('admin.packages.index', ['tab' => 'discounts']) }}" class="btn btn-outline-secondary">
              Batal
            </a>
          </div>
        </div>
      </form>
    </div>
  </div>

  <style>
    .discount-form-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .discount-form-body {
      padding: 28px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .discount-form-footer {
      padding: 22px 34px 28px !important;
      display: flex;
      justify-content: flex-end;
      flex-wrap: wrap;
      gap: 10px;
    }

    .discount-status-card {
      padding: 18px 20px;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
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
    }

    .discount-package-section {
      padding: 22px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
    }

    .discount-package-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 12px;
      margin-bottom: 18px;
    }

    .discount-package-header h6 {
      font-weight: 900;
      margin-bottom: 5px;
    }

    .discount-package-header p {
      color: var(--mf-muted);
      font-weight: 600;
      margin-bottom: 0;
      line-height: 1.6;
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

    .discount-package-checkbox {
      margin-top: 4px;
      flex-shrink: 0;
    }

    .discount-package-icon {
      width: 42px;
      height: 42px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 20px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
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
      font-weight: 900;
      margin-bottom: 6px;
    }

    .discount-empty-state p {
      margin: 0 auto;
      max-width: 420px;
      line-height: 1.7;
    }

    @media (max-width: 768px) {
      .discount-form-card .card-header,
      .discount-form-body,
      .discount-form-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .discount-status-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .discount-form-footer {
        justify-content: flex-start;
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

      function updateCounter() {
        const totalChecked = packageCheckboxes.filter(function (checkbox) {
          return checkbox.checked && checkbox.closest('.discount-package-item').style.display !== 'none';
        }).length;

        if (counter) {
          counter.innerHTML = '<i class="bx bx-package"></i> ' + totalChecked + ' paket dipilih';
        }
      }

      function hideItem(item) {
        item.style.display = 'none';

        const checkbox = item.querySelector('.discount-package-checkbox');

        if (checkbox) {
          checkbox.checked = false;
        }
      }

      function showItem(item) {
        item.style.display = '';
      }

      function filterPackagesByCategory() {
        const selectedCategoryId = categorySelect ? categorySelect.value : '';
        let visibleTotal = 0;

        packageItems.forEach(function (item) {
          const itemCategoryId = item.getAttribute('data-category-id');

          if (selectedCategoryId !== '' && itemCategoryId === selectedCategoryId) {
            showItem(item);
            visibleTotal++;
          } else {
            hideItem(item);
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
        categorySelect.addEventListener('change', filterPackagesByCategory);
      }

      packageCheckboxes.forEach(function (checkbox) {
        checkbox.addEventListener('change', updateCounter);
      });

      filterPackagesByCategory();
    });
  </script>
@endsection