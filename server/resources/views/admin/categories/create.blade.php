@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Kategori')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Tambah Kategori</h4>
        <p class="text-muted mb-0">Tambahkan kategori layanan foto baru.</p>
      </div>

      <a href="{{ route('admin.packages.index') }}" class="btn btn-outline-secondary">
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
        <h5 class="mb-0">Form Tambah Kategori</h5>
      </div>

      <div class="card-body">
        <form action="{{ route('admin.categories.store') }}" method="POST">
          @csrf

          <div class="mb-3">
            <label class="form-label">Nama Kategori</label>
            <input type="text" name="name" class="form-control" value="{{ old('name') }}"
              placeholder="Contoh: Prewedding">
          </div>

          <div class="mb-3">
            <label class="form-label">Deskripsi</label>
            <textarea name="description" class="form-control" rows="4" placeholder="Masukkan deskripsi kategori...">{{ old('description') }}</textarea>
          </div>

          <div class="mb-4">
            <div class="form-check form-switch">
              <input class="form-check-input" type="checkbox" name="is_active" value="1"
                {{ old('is_active', true) ? 'checked' : '' }}>
              <label class="form-check-label">Kategori Aktif</label>
            </div>
          </div>

          <div class="d-flex justify-content-end gap-2">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i> Simpan Kategori
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
@endsection
