@extends('layouts/contentNavbarLayout')

@section('title', 'Paket & Kategori')

@section('content')
  @php
    $currentTab = $activeTab ?? 'categories';
    $categoryListCount = isset($categories) ? $categories->count() : 0;
    $packageListCount = isset($packages) ? $packages->count() : 0;
    $printPriceItems = $printPrices ?? collect();
    $printPriceListCount = $printPriceItems->count();
    $discountListCount = isset($discounts) ? $discounts->count() : 0;

    $tabs = [
        [
            'key' => 'categories',
            'label' => 'Kategori',
            'icon' => 'bx bx-category-alt',
            'url' => route('admin.packages.index', ['tab' => 'categories', 'category' => request('category')]),
        ],
        [
            'key' => 'photo-packages',
            'label' => 'Paket Foto',
            'icon' => 'bx bx-camera',
            'url' => route('admin.packages.index', ['tab' => 'photo-packages']),
        ],
        [
            'key' => 'print-prices',
            'label' => 'Paket Cetak',
            'icon' => 'bx bx-printer',
            'url' => route('admin.packages.index', ['tab' => 'print-prices']),
        ],
        [
            'key' => 'discounts',
            'label' => 'Diskon',
            'icon' => 'bx bx-purchase-tag-alt',
            'url' => route('admin.packages.index', ['tab' => 'discounts', 'category' => request('category')]),
        ],
    ];

    $statCards = [
        [
            'label' => 'Kategori Aktif',
            'value' => $activeCategories ?? 0,
            'helper' => 'Kategori yang tampil ke sistem',
            'icon' => 'bx bx-category',
            'class' => '',
        ],
        [
            'label' => 'Paket Foto Aktif',
            'value' => $activePackages ?? 0,
            'helper' => 'Paket foto yang bisa dibooking',
            'icon' => 'bx bx-camera',
            'class' => 'success',
        ],
        [
            'label' => 'Paket Cetak Aktif',
            'value' => $activePrintPrices ?? 0,
            'helper' => 'Paket cetak yang bisa dipilih klien',
            'icon' => 'bx bx-printer',
            'class' => 'info',
        ],
        [
            'label' => 'Diskon Aktif',
            'value' => $discountPackages ?? 0,
            'helper' => 'Promo diskon aktif pada paket',
            'icon' => 'bx bx-purchase-tag',
            'class' => 'warning',
        ],
    ];

    $modalName = old('_package_modal');
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- HERO HEADER --}}
      <div class="package-hero-card mb-4">
        <div class="package-hero-left">
          <div class="package-hero-icon">
            <i class="bx bx-package"></i>
          </div>

          <div>
            <div class="package-hero-kicker">MANAJEMEN STUDIO</div>
            <h4>Paket & Kategori</h4>
            <p>
              Kelola kategori layanan, paket foto, paket cetak, dan diskon Monoframe Studio
              agar data layanan tetap rapi dan mudah digunakan oleh klien.
            </p>
          </div>
        </div>

        <div class="package-hero-actions">
          @if ($currentTab === 'categories')
            <a href="{{ route('admin.categories.create') }}" class="btn package-hero-btn">
              <i class="bx bx-plus me-1"></i>
              Tambah Kategori
            </a>
          @elseif ($currentTab === 'photo-packages')
            <a href="{{ route('admin.packages.create') }}" class="btn package-hero-btn">
              <i class="bx bx-plus me-1"></i>
              Tambah Paket
            </a>
          @elseif ($currentTab === 'print-prices')
            <a href="{{ route('admin.print-prices.create') }}" class="btn package-hero-btn">
              <i class="bx bx-plus me-1"></i>
              Tambah Paket Cetak
            </a>
          @elseif ($currentTab === 'discounts')
            <a href="{{ route('admin.discounts.create') }}" class="btn package-hero-btn">
              <i class="bx bx-plus me-1"></i>
              Tambah Diskon
            </a>
          @endif
        </div>
      </div>

      {{-- ALERT --}}
      @foreach (['success' => 'alert-success bx-check-circle', 'error' => 'alert-danger bx-error-circle'] as $type => $style)
        @if (session($type))
          @php [$alertClass, $iconClass] = explode(' ', $style); @endphp
          <div class="alert {{ $alertClass }} alert-dismissible fade show mb-4" role="alert">
            <i class="bx {{ $iconClass }} me-1"></i>
            {{ session($type) }}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
          </div>
        @endif
      @endforeach

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

      {{-- TAB MENU --}}
      <div class="package-tabs-card mb-4">
        <ul class="nav package-tabs">
          @foreach ($tabs as $tab)
            <li class="nav-item">
              <a class="nav-link {{ $currentTab === $tab['key'] ? 'active' : '' }}" href="{{ $tab['url'] }}">
                <i class="{{ $tab['icon'] }} me-1"></i>
                {{ $tab['label'] }}
              </a>
            </li>
          @endforeach
        </ul>
      </div>

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        @foreach ($statCards as $card)
          <div class="col-xl-3 col-md-6">
            <div class="card stat-card h-100">
              <div class="card-body">
                <div class="d-flex justify-content-between align-items-start gap-3">
                  <div>
                    <div class="stat-label">{{ $card['label'] }}</div>
                    <div class="stat-number">{{ $card['value'] }}</div>
                    <div class="stat-helper">{{ $card['helper'] }}</div>
                  </div>

                  <div class="stat-icon {{ $card['class'] }}">
                    <i class="{{ $card['icon'] }}"></i>
                  </div>
                </div>
              </div>
            </div>
          </div>
        @endforeach
      </div>

      {{-- TAB KATEGORI --}}
      @if ($currentTab === 'categories')
        <div class="row g-4">
          <div class="col-lg-5 col-md-12">
            <div class="card section-card package-index-card h-100">
              <div class="card-header">
                <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                  <div>
                    <h5 class="section-title">Kategori Paket</h5>
                    <p class="section-subtitle mb-0">Daftar kategori layanan foto Monoframe.</p>
                  </div>

                  <div class="mf-badge-total">
                    <i class="bx bx-category"></i>
                    {{ $categoryListCount }} kategori
                  </div>
                </div>
              </div>

              <div class="card-body package-category-body">
                <div class="package-category-list">
                  @forelse ($categories as $category)
                    <a
                      href="{{ route('admin.packages.index', ['tab' => 'categories', 'category' => $category->id]) }}"
                      class="package-category-item {{ $selectedCategory && $selectedCategory->id === $category->id ? 'active' : '' }}">
                      <div class="package-category-icon">
                        <i class="bx bx-folder"></i>
                      </div>

                      <div class="package-category-content">
                        <div class="package-category-title">{{ $category->name }}</div>
                        <div class="package-category-subtitle">
                          {{ $category->packages_count }} paket tersedia
                        </div>
                      </div>

                      <span class="badge {{ $category->is_active ? 'bg-label-success' : 'bg-label-secondary' }}">
                        {{ $category->is_active ? 'Aktif' : 'Tidak Aktif' }}
                      </span>
                    </a>
                  @empty
                    <div class="package-empty-state">
                      <i class="bx bx-category-alt"></i>
                      <h6>Belum ada kategori</h6>
                      <p>Tambahkan kategori agar paket foto bisa dikelompokkan.</p>
                      <a href="{{ route('admin.categories.create') }}" class="btn btn-primary">
                        <i class="bx bx-plus me-1"></i>
                        Tambah Kategori
                      </a>
                    </div>
                  @endforelse
                </div>
              </div>
            </div>
          </div>

          <div class="col-lg-7 col-md-12">
            <div class="card section-card package-index-card h-100">
              <div class="card-header">
                <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                  <div>
                    <h5 class="section-title">Detail Kategori</h5>
                    <p class="section-subtitle mb-0">
                      Lihat status, deskripsi, dan kelola kategori yang dipilih.
                    </p>
                  </div>

                  @if ($selectedCategory)
                    <div class="mf-badge-total">
                      <i class="bx bx-folder-open"></i>
                      Dipilih
                    </div>
                  @endif
                </div>
              </div>

              <div class="card-body package-detail-body">
                @if ($selectedCategory)
                  <div class="package-detail-hero">
                    <div class="package-detail-icon">
                      <i class="bx bx-category"></i>
                    </div>

                    <div>
                      <h5 class="mb-1">{{ $selectedCategory->name }}</h5>
                      <p class="mb-0">
                        {{ $selectedCategory->description ?: 'Kategori ini belum memiliki deskripsi.' }}
                      </p>
                    </div>
                  </div>

                  <div class="row g-3 mt-2">
                    <div class="col-md-6">
                      <div class="package-readonly-card">
                        <div class="package-readonly-label">Nama Kategori</div>
                        <div class="package-readonly-value">{{ $selectedCategory->name }}</div>
                      </div>
                    </div>

                    <div class="col-md-6">
                      <div class="package-readonly-card">
                        <div class="package-readonly-label">Status</div>
                        <div class="package-readonly-value">
                          {{ $selectedCategory->is_active ? 'Aktif' : 'Tidak Aktif' }}
                        </div>
                      </div>
                    </div>

                    <div class="col-12">
                      <div class="package-readonly-card">
                        <div class="package-readonly-label">Deskripsi</div>
                        <div class="package-readonly-value">
                          {{ $selectedCategory->description ?: '-' }}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="package-action-panel mt-4">
                    <form action="{{ route('admin.categories.toggle-status', $selectedCategory->id) }}" method="POST">
                      @csrf
                      @method('PATCH')

                      <input type="hidden" name="is_active" value="0">

                      <div class="form-check form-switch d-flex align-items-center gap-2 mb-0">
                        <input
                          class="form-check-input"
                          type="checkbox"
                          role="switch"
                          id="statusSwitchCategory"
                          name="is_active"
                          value="1"
                          {{ $selectedCategory->is_active ? 'checked' : '' }}
                          onchange="
                            document.getElementById('statusTextCategory').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                            this.form.submit();
                          ">

                        <label class="form-check-label fw-semibold" for="statusSwitchCategory" id="statusTextCategory">
                          {{ $selectedCategory->is_active ? 'Aktif' : 'Tidak Aktif' }}
                        </label>
                      </div>
                    </form>

                    <div class="d-flex flex-wrap gap-2 justify-content-end">
                      <a
                        href="{{ route('admin.categories.edit', $selectedCategory->id) }}"
                        class="btn btn-outline-primary">
                        <i class="bx bx-edit-alt me-1"></i>
                        Edit Kategori
                      </a>

                      <form
                        action="{{ route('admin.categories.destroy', $selectedCategory->id) }}"
                        method="POST"
                        onsubmit="return confirm('Yakin ingin menghapus kategori ini?')"
                        class="m-0">
                        @csrf
                        @method('DELETE')

                        <button type="submit" class="btn btn-outline-danger">
                          <i class="bx bx-trash me-1"></i>
                          Hapus Kategori
                        </button>
                      </form>
                    </div>
                  </div>
                @else
                  <div class="package-empty-state">
                    <i class="bx bx-folder-open"></i>
                    <h6>Pilih kategori</h6>
                    <p>Pilih salah satu kategori di sisi kiri untuk melihat detailnya.</p>
                  </div>
                @endif
              </div>
            </div>
          </div>
        </div>
      @endif

      {{-- TAB PAKET FOTO --}}
      @if ($currentTab === 'photo-packages')
        <div class="card section-card package-index-card">
          <div class="card-header">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
              <div>
                <h5 class="section-title">Daftar Paket Foto</h5>
                <p class="section-subtitle mb-0" id="photoPackageSubtitle">
                  Menampilkan semua paket foto. Pilih kategori di bawah untuk memfilter paket.
                </p>
              </div>

              <div class="mf-badge-total">
                <i class="bx bx-camera"></i>
                <span id="photoPackageVisibleCount">{{ $packages->count() }}</span> paket tampil
              </div>
            </div>
          </div>

          <div class="card-body package-filter-body">
            <div class="package-filter-label">
              <i class="bx bx-filter-alt"></i>
              Filter Kategori
            </div>

            <div class="package-category-scroll" id="photoPackageCategoryFilter">
              <button type="button" class="package-filter-chip active" data-category-id="all" data-category-name="Semua Paket">
                <i class="bx bx-grid-alt"></i>
                Semua Paket
                <span>{{ $packages->count() }}</span>
              </button>

              @foreach ($categories as $category)
                <button
                  type="button"
                  class="package-filter-chip"
                  data-category-id="{{ $category->id }}"
                  data-category-name="{{ $category->name }}">
                  <i class="bx bx-folder"></i>
                  {{ $category->name }}
                  <span>{{ $category->packages_count }}</span>
                </button>
              @endforeach
            </div>
          </div>

          <div class="package-table-wrap">
            <div class="table-responsive">
              <table class="table package-table align-middle">
                <thead>
                  <tr>
                    <th>Nama Paket</th>
                    <th>Kategori</th>
                    <th>Harga</th>
                    <th>Jumlah Edit</th>
                    <th>Durasi</th>
                    <th>Lokasi</th>
                    <th>Diskon</th>
                    <th>Status</th>
                    <th>Aksi</th>
                  </tr>
                </thead>

                <tbody class="table-border-bottom-0">
                  @forelse ($packages as $package)
                    @php
                      $activeDiscount = $package->discounts->where('is_active', true)->first();
                      $discountedPrice = $activeDiscount
                          ? $package->price - ($package->price * $activeDiscount->discount_percent) / 100
                          : null;
                    @endphp

                    <tr
                      class="js-photo-package-row"
                      data-category-id="{{ $package->category_id }}"
                      data-category-name="{{ $package->category->name ?? '-' }}">
                      <td>
                        <div class="package-info-cell">
                          <div class="package-avatar-initial">
                            <i class="bx bx-camera"></i>
                          </div>

                          <div>
                            <div class="package-name">{{ $package->name }}</div>
                          </div>
                        </div>
                      </td>

                      <td>
                        <span class="badge bg-label-primary">
                          {{ $package->category->name ?? '-' }}
                        </span>
                      </td>

                      <td>
                        @if ($activeDiscount)
                          <div class="package-price-stack">
                            <span class="package-price-old">
                              Rp {{ number_format($package->price, 0, ',', '.') }}
                            </span>
                            <span class="package-price-new">
                              Rp {{ number_format($discountedPrice, 0, ',', '.') }}
                            </span>
                          </div>
                        @else
                          <span class="package-price-normal">
                            Rp {{ number_format($package->price, 0, ',', '.') }}
                          </span>
                        @endif
                      </td>

                      <td>{{ $package->photo_count }} Foto</td>
                      <td>{{ $package->duration_minutes }} Menit</td>

                      <td>
                        <span class="badge bg-label-info text-capitalize">
                          {{ $package->location_type ?? '-' }}
                        </span>
                      </td>

                      <td>
                        @if ($activeDiscount)
                          <div class="package-price-stack">
                            <span class="badge bg-label-warning">{{ $activeDiscount->discount_percent }}%</span>
                            <span class="package-subtext">
                              {{ $activeDiscount->promo_name ?: 'Promo Diskon' }}
                            </span>
                          </div>
                        @else
                          <span class="text-muted">-</span>
                        @endif
                      </td>

                      <td>
                        <form action="{{ route('admin.packages.toggle-status', $package->id) }}" method="POST" class="m-0">
                          @csrf
                          @method('PATCH')

                          <input type="hidden" name="is_active" value="0">

                          <div class="form-check form-switch d-flex align-items-center gap-2 mb-0">
                            <input
                              class="form-check-input"
                              type="checkbox"
                              role="switch"
                              id="packageStatusSwitch{{ $package->id }}"
                              name="is_active"
                              value="1"
                              {{ $package->is_active ? 'checked' : '' }}
                              onchange="
                                document.getElementById('packageStatusText{{ $package->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                                this.form.submit();
                              ">

                            <label class="form-check-label fw-semibold text-nowrap" for="packageStatusSwitch{{ $package->id }}" id="packageStatusText{{ $package->id }}">
                              {{ $package->is_active ? 'Aktif' : 'Tidak Aktif' }}
                            </label>
                          </div>
                        </form>
                      </td>

                      <td>
                        <div class="d-flex flex-wrap gap-2">
                          <a href="{{ route('admin.packages.edit', $package->id) }}" class="btn btn-outline-primary btn-sm">
                            <i class="bx bx-edit-alt me-1"></i>
                            Edit
                          </a>

                          <form
                            action="{{ route('admin.packages.destroy', $package->id) }}"
                            method="POST"
                            onsubmit="return confirm('Yakin ingin menghapus paket ini?')"
                            class="m-0">
                            @csrf
                            @method('DELETE')

                            <button type="submit" class="btn btn-outline-danger btn-sm">
                              <i class="bx bx-trash me-1"></i>
                              Hapus
                            </button>
                          </form>
                        </div>
                      </td>
                    </tr>
                  @empty
                    <tr>
                      <td colspan="9">
                        <div class="package-empty-state">
                          <i class="bx bx-camera-off"></i>
                          <h6>Belum ada paket foto</h6>
                          <p>Belum ada paket foto yang tersimpan.</p>
                        </div>
                      </td>
                    </tr>
                  @endforelse

                  <tr id="photoPackageNoResult" style="display: none;">
                    <td colspan="9">
                      <div class="package-empty-state">
                        <i class="bx bx-search-alt"></i>
                        <h6>Paket tidak ditemukan</h6>
                        <p>Tidak ada paket foto pada kategori yang dipilih.</p>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      @endif

      {{-- TAB PAKET CETAK --}}
      @if ($currentTab === 'print-prices')
        <div class="card section-card package-index-card">
          <div class="card-header">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
              <div>
                <h5 class="section-title">Daftar Paket Cetak</h5>
                <p class="section-subtitle mb-0">
                  Kelola ukuran cetak, harga cetak, harga bingkai, catatan, dan status.
                </p>
              </div>

              <div class="mf-badge-total">
                <i class="bx bx-printer"></i>
                {{ $printPriceListCount }} paket cetak
              </div>
            </div>
          </div>

          <div class="package-table-wrap">
            <div class="table-responsive">
              <table class="table package-table align-middle">
                <thead>
                  <tr>
                    <th>Ukuran</th>
                    <th>Harga Cetak</th>
                    <th>Harga Bingkai</th>
                    <th>Status</th>
                    <th>Catatan</th>
                    <th>Aksi</th>
                  </tr>
                </thead>

                <tbody>
                  @forelse ($printPriceItems as $item)
                    <tr>
                      <td>
                        <div class="package-info-cell">
                          <div class="package-avatar-initial">
                            <i class="bx bx-printer"></i>
                          </div>

                          <div>
                            <div class="package-name">{{ $item->size_label }}</div>
                          </div>
                        </div>
                      </td>

                      <td>
                        <span class="package-price-normal">
                          Rp {{ number_format($item->base_price, 0, ',', '.') }}
                        </span>
                      </td>

                      <td>
                        <span class="package-price-normal">
                          Rp {{ number_format($item->frame_price, 0, ',', '.') }}
                        </span>
                      </td>

                      <td>
                        <form action="{{ route('admin.print-prices.toggle-status', $item->id) }}" method="POST" class="m-0">
                          @csrf
                          @method('PATCH')

                          <input type="hidden" name="is_active" value="0">

                          <div class="form-check form-switch d-flex align-items-center gap-2 mb-0">
                            <input
                              class="form-check-input"
                              type="checkbox"
                              role="switch"
                              id="printPriceStatusSwitch{{ $item->id }}"
                              name="is_active"
                              value="1"
                              {{ $item->is_active ? 'checked' : '' }}
                              onchange="
                                document.getElementById('printPriceStatusText{{ $item->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                                this.form.submit();
                              ">

                            <label class="form-check-label fw-semibold text-nowrap" for="printPriceStatusSwitch{{ $item->id }}" id="printPriceStatusText{{ $item->id }}">
                              {{ $item->is_active ? 'Aktif' : 'Tidak Aktif' }}
                            </label>
                          </div>
                        </form>
                      </td>

                      <td>
                        <div class="package-note">{{ $item->notes ?? '-' }}</div>
                      </td>

                      <td>
                        <div class="d-flex flex-wrap gap-2">
                          <a href="{{ route('admin.print-prices.edit', $item->id) }}" class="btn btn-outline-primary btn-sm">
                            <i class="bx bx-edit-alt me-1"></i>
                            Edit
                          </a>

                          <form
                            action="{{ route('admin.print-prices.destroy', $item->id) }}"
                            method="POST"
                            onsubmit="return confirm('Yakin ingin menghapus paket cetak ini?')"
                            class="m-0">
                            @csrf
                            @method('DELETE')

                            <button type="submit" class="btn btn-outline-danger btn-sm">
                              <i class="bx bx-trash me-1"></i>
                              Hapus
                            </button>
                          </form>
                        </div>
                      </td>
                    </tr>
                  @empty
                    <tr>
                      <td colspan="6">
                        <div class="package-empty-state">
                          <i class="bx bx-printer"></i>
                          <h6>Belum ada paket cetak</h6>
                          <p>Tambahkan paket cetak agar klien bisa memilih ukuran cetak foto.</p>
                          <a href="{{ route('admin.print-prices.create') }}" class="btn btn-primary">
                            <i class="bx bx-plus me-1"></i>
                            Tambah Paket Cetak
                          </a>
                        </div>
                      </td>
                    </tr>
                  @endforelse
                </tbody>
              </table>
            </div>
          </div>
        </div>
      @endif

      {{-- TAB DISKON --}}
      @if ($currentTab === 'discounts')
        <div class="card section-card package-index-card">
          <div class="card-header">
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
              <div>
                <h5 class="section-title">Daftar Diskon</h5>
                <p class="section-subtitle mb-0">
                  {{ $selectedCategory ? 'Kelola diskon yang sudah dibuat untuk kategori ini.' : 'Menampilkan seluruh diskon dari semua kategori.' }}
                </p>
              </div>

              <div class="mf-badge-total">
                <i class="bx bx-purchase-tag-alt"></i>
                {{ $discountListCount }} diskon tampil
              </div>
            </div>
          </div>

          <div class="card-body package-discount-body">
            <div class="discount-list">
              @forelse ($discounts as $discount)
                <div class="discount-item">
                  <div class="discount-main">
                    <div class="discount-icon">
                      <i class="bx bx-purchase-tag"></i>
                    </div>

                    <div class="discount-content">
                      <h6>{{ $discount->promo_name ?: 'Tanpa Nama Promo' }}</h6>

                      <div class="discount-meta">
                        <span class="badge bg-label-warning">{{ $discount->discount_percent }}%</span>
                        <span class="badge bg-label-secondary">{{ $discount->category->name ?? 'Tanpa Kategori' }}</span>

                        @if ($discount->discount_start_at || $discount->discount_end_at)
                          <span class="discount-date">
                            {{ $discount->discount_start_at ? \Illuminate\Support\Carbon::parse($discount->discount_start_at)->format('d M Y') : '-' }}
                            -
                            {{ $discount->discount_end_at ? \Illuminate\Support\Carbon::parse($discount->discount_end_at)->format('d M Y') : '-' }}
                          </span>
                        @endif
                      </div>

                      <div class="discount-packages">
                        @forelse ($discount->packages as $package)
                          <span class="badge bg-label-primary">{{ $package->name }}</span>
                        @empty
                          <span class="text-muted">Belum ada paket dipilih</span>
                        @endforelse
                      </div>
                    </div>
                  </div>

                  <div class="discount-actions">
                    <form action="{{ route('admin.discounts.toggle-status', $discount->id) }}" method="POST">
                      @csrf
                      @method('PATCH')

                      <input type="hidden" name="is_active" value="0">

                      <div class="form-check form-switch d-flex align-items-center gap-2 justify-content-end mb-0">
                        <input
                          class="form-check-input"
                          type="checkbox"
                          role="switch"
                          id="discountSwitch{{ $discount->id }}"
                          name="is_active"
                          value="1"
                          {{ $discount->is_active ? 'checked' : '' }}
                          onchange="
                            document.getElementById('discountText{{ $discount->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                            this.form.submit();
                          ">

                        <label class="form-check-label fw-semibold text-nowrap" for="discountSwitch{{ $discount->id }}" id="discountText{{ $discount->id }}">
                          {{ $discount->is_active ? 'Aktif' : 'Tidak Aktif' }}
                        </label>
                      </div>
                    </form>

                    <a href="{{ route('admin.discounts.edit', $discount->id) }}" class="btn btn-outline-primary btn-sm">
                      <i class="bx bx-edit-alt me-1"></i>
                      Edit Diskon
                    </a>
                  </div>
                </div>
              @empty
                <div class="package-empty-state">
                  <i class="bx bx-purchase-tag-alt"></i>
                  <h6>Belum ada diskon</h6>
                  <p>
                    {{ $selectedCategory ? 'Belum ada diskon untuk kategori ini.' : 'Belum ada diskon yang tersimpan.' }}
                  </p>
                </div>
              @endforelse
            </div>
          </div>
        </div>
      @endif
    </div>
  </div>

  {{-- CREATE CATEGORY MODAL --}}
  <div class="modal fade package-create-modal" id="createCategoryModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered package-modal-dialog">
      <form action="{{ route('admin.categories.store') }}" method="POST" class="modal-content package-modal-content">
        @csrf

        <input type="hidden" name="_package_modal" value="create-category">

        <div class="modal-header package-modal-header">
          <div>
            <h5 class="modal-title">Tambah Kategori</h5>
            <small>Tambahkan kategori layanan foto baru.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body package-modal-body">
          <div class="row g-3">
            <div class="col-12">
              <label for="create_category_name" class="form-label">Nama Kategori</label>
              <input
                type="text"
                name="name"
                id="create_category_name"
                class="form-control"
                value="{{ $modalName === 'create-category' ? old('name') : '' }}"
                placeholder="Contoh: Prewedding"
                required>
            </div>

            <div class="col-12">
              <label for="create_category_description" class="form-label">Deskripsi</label>
              <textarea
                name="description"
                id="create_category_description"
                class="form-control"
                rows="4"
                placeholder="Masukkan deskripsi kategori...">{{ $modalName === 'create-category' ? old('description') : '' }}</textarea>
            </div>

            <div class="col-12">
              <div class="package-modal-status-card">
                <div>
                  <div class="package-modal-status-title">Status Kategori</div>
                  <div class="package-modal-status-subtitle">
                    Jika aktif, kategori dapat digunakan pada sistem.
                  </div>
                </div>

                <input type="hidden" name="is_active" value="0">

                <div class="form-check form-switch mb-0">
                  <input
                    class="form-check-input"
                    type="checkbox"
                    role="switch"
                    id="create_category_is_active"
                    name="is_active"
                    value="1"
                    {{ $modalName === 'create-category' ? (old('is_active', 1) ? 'checked' : '') : 'checked' }}>
                  <label class="form-check-label fw-semibold" for="create_category_is_active">
                    Aktif
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer package-modal-footer">
          <button type="button" class="btn btn-outline-secondary package-modal-cancel-btn" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-primary package-modal-submit-btn">
            <i class="bx bx-save me-1"></i>
            Simpan Kategori
          </button>
        </div>
      </form>
    </div>
  </div>

  {{-- CREATE PRINT PRICE MODAL --}}
  <div class="modal fade package-create-modal" id="createPrintPriceModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered package-modal-dialog">
      <form action="{{ route('admin.print-prices.store') }}" method="POST" class="modal-content package-modal-content">
        @csrf

        <input type="hidden" name="_package_modal" value="create-print-price">

        <div class="modal-header package-modal-header">
          <div>
            <h5 class="modal-title">Tambah Paket Cetak</h5>
            <small>Tambahkan ukuran cetak, harga cetak, dan harga bingkai.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body package-modal-body">
          <div class="row g-3">
            <div class="col-md-6">
              <label for="create_size_label" class="form-label">Ukuran Cetak</label>
              <input
                type="text"
                name="size_label"
                id="create_size_label"
                class="form-control"
                value="{{ $modalName === 'create-print-price' ? old('size_label') : '' }}"
                placeholder="Contoh: 4R"
                required>
            </div>

            <div class="col-md-6">
              <label for="create_base_price" class="form-label">Harga Cetak</label>
              <input
                type="number"
                name="base_price"
                id="create_base_price"
                class="form-control"
                value="{{ $modalName === 'create-print-price' ? old('base_price') : '' }}"
                min="0"
                placeholder="Contoh: 15000"
                required>
            </div>

            <div class="col-md-6">
              <label for="create_frame_price" class="form-label">Harga Bingkai</label>
              <input
                type="number"
                name="frame_price"
                id="create_frame_price"
                class="form-control"
                value="{{ $modalName === 'create-print-price' ? old('frame_price') : '' }}"
                min="0"
                placeholder="Contoh: 25000"
                required>
            </div>

            <div class="col-md-6">
              <div class="package-modal-status-card h-100">
                <div>
                  <div class="package-modal-status-title">Status Paket Cetak</div>
                  <div class="package-modal-status-subtitle">
                    Jika aktif, paket cetak akan tampil ke klien.
                  </div>
                </div>

                <input type="hidden" name="is_active" value="0">

                <div class="form-check form-switch mb-0">
                  <input
                    class="form-check-input"
                    type="checkbox"
                    role="switch"
                    id="create_print_is_active"
                    name="is_active"
                    value="1"
                    {{ $modalName === 'create-print-price' ? (old('is_active', 1) ? 'checked' : '') : 'checked' }}>
                  <label class="form-check-label fw-semibold" for="create_print_is_active">
                    Aktif
                  </label>
                </div>
              </div>
            </div>

            <div class="col-12">
              <label for="create_notes" class="form-label">Catatan</label>
              <textarea
                name="notes"
                id="create_notes"
                rows="4"
                class="form-control"
                placeholder="Catatan tambahan (opsional)">{{ $modalName === 'create-print-price' ? old('notes') : '' }}</textarea>
            </div>
          </div>
        </div>

        <div class="modal-footer package-modal-footer">
          <button type="button" class="btn btn-outline-secondary package-modal-cancel-btn" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-primary package-modal-submit-btn">
            <i class="bx bx-save me-1"></i>
            Simpan Paket Cetak
          </button>
        </div>
      </form>
    </div>
  </div>

  <style>
    .package-hero-card {
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

    .package-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .package-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .package-hero-icon {
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

    .package-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .package-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .package-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .package-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .package-hero-btn {
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

    .package-hero-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .package-tabs-card {
      padding: 10px;
      border-radius: 26px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow-x: auto;
    }

    .package-tabs,
    .package-category-list,
    .discount-list {
      display: flex;
    }

    .package-tabs {
      flex-wrap: nowrap;
      gap: 10px;
      min-width: max-content;
      border: 0;
    }

    .package-category-list,
    .discount-list {
      flex-direction: column;
      gap: 12px;
    }

    .discount-list {
      gap: 14px;
    }

    .package-tabs .nav-link {
      border: 0 !important;
      border-radius: 18px !important;
      padding: 12px 18px;
      color: var(--mf-muted);
      font-weight: 800;
      display: inline-flex;
      align-items: center;
      white-space: nowrap;
      transition: 0.18s ease;
    }

    .package-tabs .nav-link:hover {
      background: var(--mf-primary-soft);
      color: var(--mf-primary);
    }

    .package-tabs .nav-link.active,
    .package-filter-chip.active {
      color: #ffffff !important;
      border-color: transparent;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue)) !important;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.24);
    }

    .package-index-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .package-category-body,
    .package-detail-body,
    .package-discount-body,
    .package-toolbar-body {
      padding: 24px 34px 30px !important;
    }

    .package-filter-body {
      padding: 22px 34px 20px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-action-row {
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
    }

    .package-category-item,
    .discount-item {
      display: flex;
      gap: 14px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 38%),
        #ffffff;
      transition: 0.2s ease;
    }

    .package-category-item {
      align-items: center;
      padding: 16px;
      color: var(--mf-ink);
      text-decoration: none;
    }

    .discount-item {
      justify-content: space-between;
      align-items: flex-start;
      gap: 18px;
      padding: 20px;
    }

    .package-category-item:hover,
    .package-category-item.active,
    .discount-item:hover {
      transform: translateY(-3px);
      border-color: rgba(88, 115, 220, 0.35);
      box-shadow: 0 18px 38px rgba(52, 79, 165, 0.12);
      color: var(--mf-ink);
    }

    .package-category-item.active {
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.22), transparent 38%),
        linear-gradient(180deg, #ffffff 0%, #f7fbfd 100%);
    }

    .package-category-icon,
    .package-avatar-initial,
    .package-detail-icon,
    .discount-icon {
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
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .package-category-content,
    .discount-main {
      flex: 1;
      min-width: 0;
    }

    .discount-main {
      display: flex;
      align-items: flex-start;
      gap: 14px;
    }

    .package-category-title,
    .package-name,
    .discount-content h6 {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.35;
    }

    .discount-content h6 {
      margin-bottom: 8px;
    }

    .package-category-subtitle,
    .package-subtext {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      margin-top: 3px;
    }

    .package-detail-hero {
      display: flex;
      align-items: flex-start;
      gap: 16px;
      padding: 22px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.22), transparent 38%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-detail-hero h5 {
      font-weight: 900;
      margin-bottom: 4px;
    }

    .package-detail-hero p {
      color: var(--mf-muted);
      line-height: 1.7;
    }

    .package-readonly-card {
      padding: 16px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .package-readonly-label {
      font-size: 12px;
      color: var(--mf-muted);
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 6px;
    }

    .package-readonly-value {
      color: var(--mf-ink);
      font-weight: 800;
      line-height: 1.6;
    }

    .package-action-panel {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 14px;
      padding: 18px;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background: #ffffff;
    }

    .package-table-wrap {
      margin: 28px 34px 30px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      overflow: hidden;
      background: #ffffff;
    }

    .package-table thead th,
    .package-table tbody td {
      padding: 20px 22px !important;
    }

    .package-table tbody td {
      padding-top: 22px !important;
      padding-bottom: 22px !important;
    }

    .package-info-cell {
      display: flex;
      align-items: center;
      gap: 14px;
      min-width: 220px;
    }

    .package-price-stack {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .package-price-old {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      text-decoration: line-through;
    }

    .package-price-new {
      color: var(--mf-danger);
    }

    .package-price-new,
    .package-price-normal {
      font-weight: 900;
      white-space: nowrap;
    }

    .package-price-normal {
      color: var(--mf-ink);
    }

    .package-note {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.6;
      min-width: 180px;
      white-space: normal;
    }

    .package-empty-state {
      padding: 46px 20px;
      text-align: center;
      color: var(--mf-muted);
    }

    .package-empty-state i {
      display: block;
      font-size: 48px;
      color: var(--mf-primary);
      margin-bottom: 12px;
    }

    .package-empty-state h6 {
      font-weight: 900;
      margin-bottom: 6px;
    }

    .package-empty-state p {
      margin: 0 auto 18px;
      max-width: 420px;
      line-height: 1.7;
    }

    .discount-meta,
    .discount-packages {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 8px;
    }

    .discount-packages {
      margin-bottom: 0;
    }

    .discount-date {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
    }

    .discount-actions {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 10px;
      flex-shrink: 0;
    }

    .package-filter-label {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: var(--mf-ink);
      font-weight: 900;
      font-size: 13px;
      margin-bottom: 14px;
    }

    .package-category-scroll {
      display: flex;
      gap: 12px;
      overflow-x: auto;
      overflow-y: hidden;
      padding: 2px 2px 12px;
      scroll-snap-type: x proximity;
      -webkit-overflow-scrolling: touch;
    }

    .package-category-scroll::-webkit-scrollbar {
      height: 6px;
    }

    .package-category-scroll::-webkit-scrollbar-track {
      background: #eef2ff;
      border-radius: 999px;
    }

    .package-category-scroll::-webkit-scrollbar-thumb {
      background: rgba(88, 115, 220, 0.35);
      border-radius: 999px;
    }

    .package-filter-chip {
      flex: 0 0 auto;
      min-height: 46px;
      padding: 0 16px;
      border: 1px solid var(--mf-border);
      border-radius: 999px;
      background: #ffffff;
      color: var(--mf-muted);
      font-weight: 900;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      white-space: nowrap;
      cursor: pointer;
      transition: 0.18s ease;
      scroll-snap-align: start;
    }

    .package-filter-chip:hover {
      color: var(--mf-primary);
      border-color: rgba(88, 115, 220, 0.35);
      background: var(--mf-primary-soft);
      transform: translateY(-2px);
    }

    .package-filter-chip span {
      min-width: 24px;
      height: 24px;
      padding: 0 7px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.12);
      color: var(--mf-primary);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 900;
    }

    .package-filter-chip.active span {
      background: rgba(255, 255, 255, 0.22);
      color: #ffffff;
    }

    .package-modal-dialog {
      max-width: 760px;
    }

    .package-modal-content {
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: 0 24px 60px rgba(22, 43, 77, 0.18);
    }

    .package-modal-header {
      padding: 24px 28px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      border-bottom: 0;
    }

    .package-modal-header .modal-title {
      color: #ffffff;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .package-modal-header small {
      color: rgba(255, 255, 255, 0.78);
      font-weight: 600;
    }

    .package-modal-body {
      padding: 28px 28px 18px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .package-modal-body .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .package-modal-body .form-control,
    .package-modal-body .form-select {
      min-height: 50px;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
      box-shadow: none !important;
    }

    .package-modal-body textarea.form-control {
      min-height: 120px;
      resize: vertical;
    }

    .package-modal-body .form-control:focus,
    .package-modal-body .form-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .package-modal-status-card {
      padding: 18px 20px;
      border: 1px solid var(--mf-border);
      border-radius: 20px;
      background: #ffffff;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .package-modal-status-title {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .package-modal-status-subtitle {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 600;
      line-height: 1.55;
    }

    .package-modal-footer {
      padding: 24px 30px 28px;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
      display: flex;
      justify-content: flex-end;
      align-items: center;
      gap: 14px;
    }

    .package-modal-footer .btn {
      height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding-left: 24px;
      padding-right: 24px;
    }

    .package-modal-cancel-btn {
      min-width: 104px;
      background: #ffffff;
    }

    .package-modal-submit-btn {
      min-width: 210px;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.20);
    }

    @media (max-width: 768px) {
      .package-hero-card {
        align-items: flex-start;
        flex-direction: column;
        padding: 26px 22px;
      }

      .package-hero-left {
        flex-direction: column;
      }

      .package-hero-actions,
      .package-hero-btn {
        width: 100%;
      }

      .package-hero-btn {
        min-height: 50px;
      }

      .package-index-card .card-header,
      .package-category-body,
      .package-detail-body,
      .package-discount-body,
      .package-toolbar-body,
      .package-filter-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .package-table-wrap {
        margin: 22px;
      }

      .package-action-row {
        justify-content: flex-start;
      }

      .package-info-cell {
        min-width: 180px;
      }

      .discount-item,
      .discount-main,
      .package-detail-hero {
        flex-direction: column;
      }

      .discount-actions {
        align-items: flex-start;
        width: 100%;
      }

      .package-modal-dialog {
        max-width: calc(100% - 24px);
        margin-left: auto;
        margin-right: auto;
      }

      .package-modal-footer {
        flex-direction: column;
        padding: 22px;
      }

      .package-modal-footer .btn,
      .package-modal-cancel-btn,
      .package-modal-submit-btn {
        width: 100%;
        min-width: 0;
      }

      .package-modal-status-card {
        align-items: flex-start;
        flex-direction: column;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const filterWrap = document.getElementById('photoPackageCategoryFilter');

      if (filterWrap) {
        const chips = Array.from(filterWrap.querySelectorAll('.package-filter-chip'));
        const rows = Array.from(document.querySelectorAll('.js-photo-package-row'));
        const countEl = document.getElementById('photoPackageVisibleCount');
        const subtitleEl = document.getElementById('photoPackageSubtitle');
        const noResultRow = document.getElementById('photoPackageNoResult');

        function setRowVisibility(row, visible) {
          row.hidden = !visible;
          row.style.display = visible ? '' : 'none';
        }

        function setNoResult(visible) {
          if (noResultRow) {
            noResultRow.style.display = visible ? '' : 'none';
          }
        }

        function setSubtitle(categoryId, categoryName) {
          if (!subtitleEl) {
            return;
          }

          subtitleEl.textContent = categoryId === 'all'
            ? 'Menampilkan semua paket foto. Pilih kategori di bawah untuk memfilter paket.'
            : 'Menampilkan paket foto untuk kategori ' + categoryName + '.';
        }

        function filterPackages(categoryId, categoryName) {
          let visibleTotal = 0;

          rows.forEach(function (row) {
            const visible = categoryId === 'all' || row.getAttribute('data-category-id') === categoryId;

            setRowVisibility(row, visible);

            if (visible) {
              visibleTotal++;
            }
          });

          if (countEl) {
            countEl.textContent = visibleTotal;
          }

          setNoResult(visibleTotal === 0);
          setSubtitle(categoryId, categoryName);
        }

        chips.forEach(function (chip) {
          chip.addEventListener('click', function () {
            const categoryId = chip.dataset.categoryId || 'all';
            const categoryName = chip.dataset.categoryName || 'Semua Paket';

            chips.forEach(item => item.classList.remove('active'));
            chip.classList.add('active');

            filterPackages(categoryId, categoryName);
          });
        });
      }

      const modalName = @json($modalName);

      if (modalName === 'create-category') {
        const modalElement = document.getElementById('createCategoryModal');

        if (modalElement && window.bootstrap) {
          new bootstrap.Modal(modalElement).show();
        }
      }

      if (modalName === 'create-print-price') {
        const modalElement = document.getElementById('createPrintPriceModal');

        if (modalElement && window.bootstrap) {
          new bootstrap.Modal(modalElement).show();
        }
      }
    });
  </script>
@endsection
