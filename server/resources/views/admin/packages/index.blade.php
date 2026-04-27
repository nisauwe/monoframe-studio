@extends('layouts/contentNavbarLayout')

@section('title', 'Paket & Kategori')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Paket & Kategori</h4>
        <p class="text-muted mb-0">
          Kelola kategori, paket foto, paket cetak, dan diskon dalam satu halaman.
        </p>
      </div>
    </div>

    @if (session('success'))
      <div class="alert alert-success">
        {{ session('success') }}
      </div>
    @endif

    @if (session('error'))
      <div class="alert alert-danger">
        {{ session('error') }}
      </div>
    @endif

    @if ($errors->any())
      <div class="alert alert-danger">
        <ul class="mb-0 ps-3">
          @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
          @endforeach
        </ul>
      </div>
    @endif

    {{-- TAB MENU --}}
    <ul class="nav nav-tabs mb-4 custom-tabs">
      <li class="nav-item">
        <a class="nav-link {{ ($activeTab ?? 'categories') === 'categories' ? 'active' : '' }}"
          href="{{ route('admin.packages.index', ['tab' => 'categories', 'category' => request('category')]) }}">
          <i class="bx bx-category-alt me-1"></i> Kategori
        </a>
      </li>

      <li class="nav-item">
        <a class="nav-link {{ ($activeTab ?? 'categories') === 'photo-packages' ? 'active' : '' }}"
          href="{{ route('admin.packages.index', ['tab' => 'photo-packages', 'category' => request('category')]) }}">
          <i class="bx bx-camera me-1"></i> Paket Foto
        </a>
      </li>

      <li class="nav-item">
        <a class="nav-link {{ ($activeTab ?? 'categories') === 'print-prices' ? 'active' : '' }}"
          href="{{ route('admin.packages.index', ['tab' => 'print-prices']) }}">
          <i class="bx bx-printer me-1"></i> Paket Cetak
        </a>
      </li>

      <li class="nav-item">
        <a class="nav-link {{ ($activeTab ?? 'categories') === 'discounts' ? 'active' : '' }}"
          href="{{ route('admin.packages.index', ['tab' => 'discounts', 'category' => request('category')]) }}">
          <i class="bx bx-purchase-tag-alt me-1"></i> Diskon
        </a>
      </li>
    </ul>

    {{-- ========================= TAB KATEGORI ========================= --}}
    @if (($activeTab ?? 'categories') === 'categories')
      <div class="row mb-4">
        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Total Kategori</span>
                  <h3 class="card-title mb-2">{{ $totalCategories }}</h3>
                  <small class="text-primary fw-semibold">Kategori paket terdaftar</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-primary">
                    <i class="bx bx-category"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Aktif</span>
                  <h3 class="card-title mb-2">{{ $activePackages }}</h3>
                  <small class="text-success fw-semibold">Paket yang bisa dibooking</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-success">
                    <i class="bx bx-check-circle"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Diskon</span>
                  <h3 class="card-title mb-2">{{ $discountPackages }}</h3>
                  <small class="text-warning fw-semibold">Paket dengan promo aktif</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-warning">
                    <i class="bx bx-purchase-tag"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        {{-- LIST KATEGORI --}}
        <div class="col-lg-5 col-md-12 mb-4">
          <div class="card h-100">
            <div class="card-header d-flex justify-content-between align-items-center">
              <div>
                <h5 class="mb-0">Kategori Paket</h5>
                <small class="text-muted">Daftar kategori layanan foto</small>
              </div>

              <a href="{{ route('admin.categories.create') }}" class="btn btn-primary btn-sm">
                <i class="bx bx-plus me-1"></i> Tambah Kategori
              </a>
            </div>

            <div class="card-body">
              <div class="list-group">
                @forelse ($categories as $category)
                  <a href="{{ route('admin.packages.index', ['tab' => 'categories', 'category' => $category->id]) }}"
                    class="list-group-item list-group-item-action category-item {{ $selectedCategory && $selectedCategory->id === $category->id ? 'active' : '' }}">
                    <div class="d-flex justify-content-between align-items-center gap-3 w-100">
                      <div>
                        <h6 class="mb-1 category-title">{{ $category->name }}</h6>
                        <small class="category-subtitle">{{ $category->packages_count }} paket tersedia</small>
                      </div>

                      @if ($category->is_active)
                        <span class="badge category-status-badge category-status-active">Aktif</span>
                      @else
                        <span class="badge category-status-badge category-status-inactive">Tidak Aktif</span>
                      @endif
                    </div>
                  </a>
                @empty
                  <div class="text-center text-muted py-4">
                    Belum ada kategori.
                  </div>
                @endforelse
              </div>
            </div>
          </div>
        </div>

        {{-- DETAIL KATEGORI --}}
        <div class="col-lg-7 col-md-12 mb-4">
          <div class="card h-100">
            <div class="card-header">
              <h5 class="mb-0">Detail Kategori</h5>
              <small class="text-muted">Lihat dan kelola kategori yang dipilih.</small>
            </div>

            <div class="card-body">
              @if ($selectedCategory)
                <div class="mb-3">
                  <label class="form-label">Nama Kategori</label>
                  <input type="text" class="form-control" value="{{ $selectedCategory->name }}" readonly>
                </div>

                <div class="mb-3">
                  <label class="form-label">Deskripsi Kategori</label>
                  <textarea class="form-control" rows="4" readonly>{{ $selectedCategory->description }}</textarea>
                </div>

                <div class="mb-3">
                  <label class="form-label d-block">Status</label>

                  <form action="{{ route('admin.categories.toggle-status', $selectedCategory->id) }}" method="POST"
                    class="mb-3">
                    @csrf
                    @method('PATCH')

                    <input type="hidden" name="is_active" value="0">

                    <div class="form-check form-switch d-flex align-items-center gap-2">
                      <input class="form-check-input" type="checkbox" role="switch" id="statusSwitchCategory"
                        name="is_active" value="1" {{ $selectedCategory->is_active ? 'checked' : '' }}
                        onchange="
                          document.getElementById('statusTextCategory').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                          this.form.submit();
                        ">

                      <label class="form-check-label fw-semibold" for="statusSwitchCategory" id="statusTextCategory">
                        {{ $selectedCategory->is_active ? 'Aktif' : 'Tidak Aktif' }}
                      </label>
                    </div>
                  </form>

                  <form action="{{ route('admin.categories.destroy', $selectedCategory->id) }}" method="POST"
                    onsubmit="return confirm('Yakin ingin menghapus kategori ini?')">
                    @csrf
                    @method('DELETE')

                    <button type="submit" class="btn btn-danger btn-sm">
                      <i class="bx bx-trash me-1"></i> Hapus Kategori
                    </button>
                  </form>
                </div>
              @else
                <div class="text-muted">
                  Pilih kategori untuk melihat detail.
                </div>
              @endif
            </div>
          </div>
        </div>
      </div>
    @endif

    {{-- ========================= TAB PAKET FOTO ========================= --}}
    @if (($activeTab ?? 'categories') === 'photo-packages')
      <div class="row mb-4">
        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Total Kategori</span>
                  <h3 class="card-title mb-2">{{ $totalCategories }}</h3>
                  <small class="text-primary fw-semibold">Kategori paket terdaftar</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-primary">
                    <i class="bx bx-category"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Aktif</span>
                  <h3 class="card-title mb-2">{{ $activePackages }}</h3>
                  <small class="text-success fw-semibold">Paket yang bisa dibooking</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-success">
                    <i class="bx bx-check-circle"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Diskon</span>
                  <h3 class="card-title mb-2">{{ $discountPackages }}</h3>
                  <small class="text-warning fw-semibold">Paket dengan promo aktif</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-warning">
                    <i class="bx bx-purchase-tag"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card h-100">
        <div class="card-header">
          <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
              <h5 class="mb-0">Daftar Paket Foto</h5>
              <small class="text-muted">
                Kelola paket, harga, jumlah edit, durasi, lokasi, dan status paket.
              </small>
            </div>

            <div class="d-flex flex-wrap gap-2">
              <button type="button" class="btn btn-outline-success" disabled>
                <i class="bx bx-table me-1"></i> Export Excel
              </button>
              <button type="button" class="btn btn-outline-danger" disabled>
                <i class="bx bx-file me-1"></i> Export PDF
              </button>
              <a href="{{ route('admin.packages.create') }}" class="btn btn-primary">
                <i class="bx bx-plus me-1"></i> Tambah Paket
              </a>
            </div>
          </div>
        </div>

        <div class="table-responsive text-nowrap">
          <table class="table align-middle">
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
                @endphp

                <tr>
                  <td>{{ $package->name }}</td>
                  <td>{{ $package->category->name ?? '-' }}</td>

                  <td>
                    @if ($activeDiscount)
                      @php
                        $discountedPrice =
                            $package->price - ($package->price * $activeDiscount->discount_percent) / 100;
                      @endphp

                      <div class="d-flex flex-column">
                        <span class="text-muted text-decoration-line-through small">
                          Rp {{ number_format($package->price, 0, ',', '.') }}
                        </span>
                        <span class="fw-bold text-danger">
                          Rp {{ number_format($discountedPrice, 0, ',', '.') }}
                        </span>
                      </div>
                    @else
                      <span class="fw-semibold">
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
                      <div class="d-flex flex-column">
                        <span class="badge bg-label-warning mb-1">
                          {{ $activeDiscount->discount_percent }}%
                        </span>
                        <small class="text-muted">
                          {{ $activeDiscount->promo_name ?: 'Promo Diskon' }}
                        </small>
                      </div>
                    @else
                      -
                    @endif
                  </td>

                  <td>
                    <form action="{{ route('admin.packages.toggle-status', $package->id) }}" method="POST"
                      class="m-0">
                      @csrf
                      @method('PATCH')

                      <input type="hidden" name="is_active" value="0">

                      <div class="form-check form-switch d-flex align-items-center gap-2 mb-0">
                        <input class="form-check-input" type="checkbox" role="switch"
                          id="packageStatusSwitch{{ $package->id }}" name="is_active" value="1"
                          {{ $package->is_active ? 'checked' : '' }}
                          onchange="
                            document.getElementById('packageStatusText{{ $package->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                            this.form.submit();
                          ">

                        <label class="form-check-label fw-semibold text-nowrap"
                          for="packageStatusSwitch{{ $package->id }}" id="packageStatusText{{ $package->id }}">
                          {{ $package->is_active ? 'Aktif' : 'Tidak Aktif' }}
                        </label>
                      </div>
                    </form>
                  </td>

                  <td>
                    <div class="d-flex flex-wrap gap-2">
                      <a href="{{ route('admin.packages.edit', $package->id) }}"
                        class="btn btn-outline-primary btn-sm">
                        <i class="bx bx-edit-alt me-1"></i> Edit
                      </a>

                      <form action="{{ route('admin.packages.destroy', $package->id) }}" method="POST"
                        onsubmit="return confirm('Yakin ingin menghapus paket ini?')" class="m-0">
                        @csrf
                        @method('DELETE')

                        <button type="submit" class="btn btn-outline-danger btn-sm">
                          <i class="bx bx-trash me-1"></i> Hapus
                        </button>
                      </form>
                    </div>
                  </td>
                </tr>
              @empty
                <tr>
                  <td colspan="9" class="text-center text-muted py-4">
                    Belum ada paket pada kategori ini.
                  </td>
                </tr>
              @endforelse
            </tbody>
          </table>
        </div>
      </div>
    @endif

    {{-- ========================= TAB PAKET CETAK ========================= --}}
    @if (($activeTab ?? 'categories') === 'print-prices')
      <div class="row mb-4">
        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Total Paket Cetak</span>
                  <h3 class="card-title mb-2">{{ $totalPrintPrices ?? 0 }}</h3>
                  <small class="text-primary fw-semibold">Ukuran cetak terdaftar</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-primary">
                    <i class="bx bx-printer"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Cetak Aktif</span>
                  <h3 class="card-title mb-2">{{ $activePrintPrices ?? 0 }}</h3>
                  <small class="text-success fw-semibold">Bisa dipilih klien</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-success">
                    <i class="bx bx-check-circle"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Cetak Nonaktif</span>
                  <h3 class="card-title mb-2">{{ $inactivePrintPrices ?? 0 }}</h3>
                  <small class="text-warning fw-semibold">Tidak tampil ke klien</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-warning">
                    <i class="bx bx-x-circle"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card h-100">
        <div class="card-header">
          <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
              <h5 class="mb-0">Daftar Paket Cetak</h5>
              <small class="text-muted">
                Kelola ukuran cetak, harga cetak, harga bingkai, dan status.
              </small>
            </div>

            <a href="{{ route('admin.print-prices.create') }}" class="btn btn-primary">
              <i class="bx bx-plus me-1"></i> Tambah Paket Cetak
            </a>
          </div>
        </div>

        <div class="table-responsive text-nowrap">
          <table class="table align-middle">
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
              @forelse (($printPrices ?? collect()) as $item)
                <tr>
                  <td>{{ $item->size_label }}</td>
                  <td>Rp {{ number_format($item->base_price, 0, ',', '.') }}</td>
                  <td>Rp {{ number_format($item->frame_price, 0, ',', '.') }}</td>
                  <td>
                    <form action="{{ route('admin.print-prices.toggle-status', $item->id) }}" method="POST"
                      class="m-0">
                      @csrf
                      @method('PATCH')
                      <input type="hidden" name="is_active" value="0">

                      <div class="form-check form-switch d-flex align-items-center gap-2 mb-0">
                        <input class="form-check-input" type="checkbox" role="switch"
                          id="printPriceStatusSwitch{{ $item->id }}" name="is_active" value="1"
                          {{ $item->is_active ? 'checked' : '' }}
                          onchange="
                            document.getElementById('printPriceStatusText{{ $item->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                            this.form.submit();
                          ">

                        <label class="form-check-label fw-semibold text-nowrap"
                          for="printPriceStatusSwitch{{ $item->id }}"
                          id="printPriceStatusText{{ $item->id }}">
                          {{ $item->is_active ? 'Aktif' : 'Tidak Aktif' }}
                        </label>
                      </div>
                    </form>
                  </td>
                  <td>{{ $item->notes ?? '-' }}</td>
                  <td>
                    <div class="d-flex flex-wrap gap-2">
                      <a href="{{ route('admin.print-prices.edit', $item->id) }}"
                        class="btn btn-outline-primary btn-sm">
                        <i class="bx bx-edit-alt me-1"></i> Edit
                      </a>

                      <form action="{{ route('admin.print-prices.destroy', $item->id) }}" method="POST"
                        onsubmit="return confirm('Yakin ingin menghapus paket cetak ini?')" class="m-0">
                        @csrf
                        @method('DELETE')

                        <button type="submit" class="btn btn-outline-danger btn-sm">
                          <i class="bx bx-trash me-1"></i> Hapus
                        </button>
                      </form>
                    </div>
                  </td>
                </tr>
              @empty
                <tr>
                  <td colspan="6" class="text-center text-muted py-4">
                    Belum ada paket cetak.
                  </td>
                </tr>
              @endforelse
            </tbody>
          </table>
        </div>
      </div>
    @endif

    {{-- ========================= TAB DISKON ========================= --}}
    @if (($activeTab ?? 'categories') === 'discounts')
      <div class="row mb-4">
        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Total Kategori</span>
                  <h3 class="card-title mb-2">{{ $totalCategories }}</h3>
                  <small class="text-primary fw-semibold">Kategori paket terdaftar</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-primary">
                    <i class="bx bx-category"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Aktif</span>
                  <h3 class="card-title mb-2">{{ $activePackages }}</h3>
                  <small class="text-success fw-semibold">Paket yang bisa dibooking</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-success">
                    <i class="bx bx-check-circle"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4 mb-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <span class="text-muted d-block mb-1">Paket Diskon</span>
                  <h3 class="card-title mb-2">{{ $discountPackages }}</h3>
                  <small class="text-warning fw-semibold">Paket dengan promo aktif</small>
                </div>
                <div class="avatar">
                  <span class="avatar-initial rounded bg-label-warning">
                    <i class="bx bx-purchase-tag"></i>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <div>
            <h5 class="mb-0">Daftar Diskon</h5>
            <small class="text-muted">
              {{ $selectedCategory ? 'Kelola diskon yang sudah dibuat untuk kategori ini.' : 'Menampilkan seluruh diskon dari semua kategori.' }}
            </small>
          </div>

          @if ($selectedCategory)
            <a href="{{ route('admin.discounts.create', ['category' => $selectedCategory->id]) }}"
              class="btn btn-primary btn-sm">
              <i class="bx bx-plus me-1"></i> Tambah Diskon
            </a>
          @endif
        </div>

        <div class="card-body">
          @unless ($selectedCategory)
            <div class="alert alert-info mb-3">
              Pilih kategori jika ingin menambah diskon baru atau memfilter daftar diskon.
            </div>
          @endunless

          @forelse ($discounts as $discount)
            <div class="discount-item">
              <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
                <div>
                  <h6 class="mb-1">{{ $discount->promo_name ?: 'Tanpa Nama Promo' }}</h6>

                  <div class="mb-2 d-flex flex-wrap gap-2 align-items-center">
                    <span class="badge bg-label-warning">{{ $discount->discount_percent }}%</span>
                    <span class="badge bg-label-secondary">{{ $discount->category->name ?? 'Tanpa Kategori' }}</span>
                    @if ($discount->discount_start_at || $discount->discount_end_at)
                      <small class="text-muted">
                        {{ $discount->discount_start_at ? \Illuminate\Support\Carbon::parse($discount->discount_start_at)->format('d M Y') : '-' }}
                        -
                        {{ $discount->discount_end_at ? \Illuminate\Support\Carbon::parse($discount->discount_end_at)->format('d M Y') : '-' }}
                      </small>
                    @endif
                  </div>

                  <div class="d-flex flex-wrap gap-2">
                    @forelse ($discount->packages as $package)
                      <span class="badge bg-label-primary">{{ $package->name }}</span>
                    @empty
                      <small class="text-muted">Belum ada paket dipilih</small>
                    @endforelse
                  </div>
                </div>

                <div class="d-flex flex-column align-items-md-end gap-2">
                  <form action="{{ route('admin.discounts.toggle-status', $discount->id) }}" method="POST">
                    @csrf
                    @method('PATCH')

                    <input type="hidden" name="is_active" value="0">

                    <div class="form-check form-switch d-flex align-items-center gap-2 justify-content-end mb-0">
                      <input class="form-check-input" type="checkbox" role="switch"
                        id="discountSwitch{{ $discount->id }}" name="is_active" value="1"
                        {{ $discount->is_active ? 'checked' : '' }}
                        onchange="
                          document.getElementById('discountText{{ $discount->id }}').innerText = this.checked ? 'Aktif' : 'Tidak Aktif';
                          this.form.submit();
                        ">

                      <label class="form-check-label fw-semibold text-nowrap" for="discountSwitch{{ $discount->id }}"
                        id="discountText{{ $discount->id }}">
                        {{ $discount->is_active ? 'Aktif' : 'Tidak Aktif' }}
                      </label>
                    </div>
                  </form>

                  <a href="{{ route('admin.discounts.edit', $discount->id) }}"
                    class="btn btn-outline-primary btn-sm">
                    <i class="bx bx-edit-alt me-1"></i> Edit Diskon
                  </a>
                </div>
              </div>
            </div>
          @empty
            <div class="text-muted">
              {{ $selectedCategory ? 'Belum ada diskon untuk kategori ini.' : 'Belum ada diskon yang tersimpan.' }}
            </div>
          @endforelse
        </div>
      </div>
    @endif
  </div>
@endsection

@push('styles')
  <style>
    .custom-tabs .nav-link {
      border-radius: 0.6rem 0.6rem 0 0;
      font-weight: 600;
      color: #697a8d;
    }

    .custom-tabs .nav-link.active {
      color: #696cff;
      background-color: #fff;
      border-color: #d9dee3 #d9dee3 #fff;
    }

    .category-item {
      background-color: #e9e7ff !important;
      border-color: #e9e7ff !important;
      color: #000 !important;
      border-radius: 8px !important;
      margin-bottom: 10px;
      padding: 14px 16px !important;
    }

    .category-item:hover {
      background-color: #e3e1ff !important;
      border-color: #e3e1ff !important;
      color: #000 !important;
    }

    .category-item.active {
      background-color: #e9e7ff !important;
      border-color: #e9e7ff !important;
      color: #000 !important;
    }

    .category-item .category-title,
    .category-item .category-subtitle,
    .category-item.active .category-title,
    .category-item.active .category-subtitle {
      color: #000 !important;
    }

    .category-item .category-title {
      font-weight: 700;
      font-size: 1rem;
    }

    .category-item .category-subtitle {
      font-size: 0.9rem;
      opacity: 1;
    }

    .category-status-badge {
      font-size: 0.85rem;
      font-weight: 600;
      padding: 0.45rem 0.8rem;
      border-radius: 0.5rem;
      white-space: nowrap;
      flex-shrink: 0;
    }

    .category-status-active {
      background-color: #ffffff !important;
      color: #696cff !important;
    }

    .category-status-inactive {
      background-color: #ffffff !important;
      color: #6c757d !important;
    }

    .discount-item {
      border: 1px solid #eceef1;
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 12px;
      background-color: #fff;
    }

    .discount-item:last-child {
      margin-bottom: 0;
    }
  </style>
@endpush
