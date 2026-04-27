@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Paket Cetak')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Tambah Paket Cetak</h4>
        <p class="text-muted mb-0">
          Tambahkan ukuran cetak, harga cetak, dan harga bingkai.
        </p>
      </div>
      <a href="{{ route('admin.packages.index', ['tab' => 'print-prices']) }}" class="btn btn-outline-secondary">
        <i class="bx bx-arrow-back me-1"></i> Kembali
      </a>
    </div>

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
        <h5 class="mb-0">Form Paket Cetak</h5>
      </div>

      <div class="card-body">
        <form action="{{ route('admin.print-prices.store') }}" method="POST">
          @csrf

          <div class="row">
            <div class="col-md-6 mb-3">
              <label for="size_label" class="form-label">Ukuran Cetak</label>
              <input type="text" name="size_label" id="size_label" class="form-control" value="{{ old('size_label') }}"
                placeholder="Contoh: 4R" required>
            </div>

            <div class="col-md-6 mb-3">
              <label for="base_price" class="form-label">Harga Cetak</label>
              <input type="number" name="base_price" id="base_price" class="form-control" value="{{ old('base_price') }}"
                min="0" placeholder="Contoh: 15000" required>
            </div>

            <div class="col-md-6 mb-3">
              <label for="frame_price" class="form-label">Harga Bingkai</label>
              <input type="number" name="frame_price" id="frame_price" class="form-control"
                value="{{ old('frame_price') }}" min="0" placeholder="Contoh: 25000" required>
            </div>

            <div class="col-md-6 mb-3">
              <label for="is_active" class="form-label d-block">Status</label>
              <div class="form-check form-switch mt-2">
                <input class="form-check-input" type="checkbox" role="switch" id="is_active" name="is_active"
                  value="1" {{ old('is_active', true) ? 'checked' : '' }}>
                <label class="form-check-label" for="is_active">
                  Aktif
                </label>
              </div>
              <small class="text-muted">Jika aktif, paket cetak akan tampil ke klien.</small>
            </div>

            <div class="col-12 mb-3">
              <label for="notes" class="form-label">Catatan</label>
              <textarea name="notes" id="notes" rows="4" class="form-control" placeholder="Catatan tambahan (opsional)">{{ old('notes') }}</textarea>
            </div>
          </div>

          <div class="d-flex gap-2">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i> Simpan
            </button>

            <a href="{{ route('admin.packages.index', ['tab' => 'print-prices']) }}" class="btn btn-outline-secondary">
              Batal
            </a>
          </div>
        </form>
      </div>
    </div>
  </div>
@endsection
