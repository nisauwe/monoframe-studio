@extends('layouts/contentNavbarLayout')

@section('title', 'Edit Diskon')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Edit Diskon</h4>
        <p class="text-muted mb-0">Perbarui promo diskon dan paket yang terhubung.</p>
      </div>

      <a href="{{ route('admin.packages.index', ['category' => $selectedCategory->id]) }}"
        class="btn btn-outline-secondary">
        <i class="bx bx-arrow-back me-1"></i> Kembali
      </a>
    </div>

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

    <div class="card">
      <div class="card-header">
        <h5 class="mb-0">Form Edit Diskon</h5>
      </div>

      <div class="card-body">
        <form action="{{ route('admin.discounts.update', $discount->id) }}" method="POST">
          @csrf
          @method('PUT')

          <input type="hidden" name="category_id" value="{{ $selectedCategory->id }}">

          <div class="row">
            <div class="col-md-6 mb-3">
              <label class="form-label">Kategori</label>
              <input type="text" class="form-control" value="{{ $selectedCategory->name }}" readonly>
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Nama Kampanye</label>
              <input type="text" name="promo_name" class="form-control"
                value="{{ old('promo_name', $discount->promo_name) }}" placeholder="Contoh: Promo Lebaran">
            </div>

            <div class="col-md-4 mb-3">
              <label class="form-label">Besar Diskon (%)</label>
              <input type="number" name="discount_percent" class="form-control" min="1" max="100"
                value="{{ old('discount_percent', $discount->discount_percent) }}" required>
            </div>

            <div class="col-md-4 mb-3">
              <label class="form-label">Mulai Tanggal</label>
              <input type="date" name="discount_start_at" class="form-control"
                value="{{ old('discount_start_at', optional($discount->discount_start_at)->format('Y-m-d')) }}">
            </div>

            <div class="col-md-4 mb-3">
              <label class="form-label">Selesai Tanggal</label>
              <input type="date" name="discount_end_at" class="form-control"
                value="{{ old('discount_end_at', optional($discount->discount_end_at)->format('Y-m-d')) }}">
            </div>

            <div class="col-12 mb-3">
              <label class="form-label d-block">Status Diskon</label>
              <input type="hidden" name="is_active" value="0">

              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" role="switch" id="isActive" name="is_active"
                  value="1" {{ old('is_active', $discount->is_active) ? 'checked' : '' }}>
                <label class="form-check-label" for="isActive">Aktif</label>
              </div>
            </div>

            <div class="col-12 mb-3">
              <label class="form-label d-block">Pilih Paket</label>
              <div class="row">
                @forelse ($packages as $package)
                  <div class="col-md-6 mb-2">
                    <div class="form-check border rounded p-3">
                      <input class="form-check-input" type="checkbox" name="package_ids[]" value="{{ $package->id }}"
                        id="package{{ $package->id }}"
                        {{ in_array($package->id, old('package_ids', $selectedPackageIds)) ? 'checked' : '' }}>
                      <label class="form-check-label w-100" for="package{{ $package->id }}">
                        <span class="fw-semibold d-block">{{ $package->name }}</span>
                        <small class="text-muted">
                          Rp {{ number_format($package->price, 0, ',', '.') }} •
                          {{ $package->duration_minutes }} menit •
                          {{ $package->photo_count }} foto
                        </small>
                      </label>
                    </div>
                  </div>
                @empty
                  <div class="col-12">
                    <div class="text-muted">
                      Belum ada paket pada kategori ini.
                    </div>
                  </div>
                @endforelse
              </div>
            </div>
          </div>

          <div class="d-flex gap-2">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i> Update Diskon
            </button>

            <a href="{{ route('admin.packages.index', ['category' => $selectedCategory->id]) }}"
              class="btn btn-outline-secondary">
              Batal
            </a>
          </div>
        </form>
      </div>
    </div>
  </div>
@endsection
