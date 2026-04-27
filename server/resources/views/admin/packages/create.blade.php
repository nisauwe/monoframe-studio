@extends('layouts/contentNavbarLayout')

@section('title', 'Tambah Paket')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Tambah Paket Baru</h4>
        <p class="text-muted mb-0">Tambahkan paket layanan beserta portofolio studio.</p>
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
        <h5 class="mb-0">Informasi Paket</h5>
      </div>

      <div class="card-body">
        <form action="{{ route('admin.packages.store') }}" method="POST" enctype="multipart/form-data">
          @csrf

          <div class="row">
            <div class="col-12 mb-3">
              <label class="form-label">Nama Paket</label>
              <input type="text" name="name" class="form-control" value="{{ old('name') }}"
                placeholder="Contoh: Paket Wisuda Silver" required>
            </div>

            <div class="col-12 mb-3">
              <label class="form-label">Kategori</label>
              <select name="category_id" class="form-select" required>
                <option value="">Pilih Kategori</option>
                @foreach ($categories as $category)
                  <option value="{{ $category->id }}" {{ old('category_id') == $category->id ? 'selected' : '' }}>
                    {{ $category->name }}
                  </option>
                @endforeach
              </select>
            </div>

            <div class="col-12 mb-3">
              <label class="form-label">Portofolio</label>
              <input type="file" name="portfolio[]" class="form-control" accept=".jpg,.jpeg,.png,.webp" multiple>

              <small class="text-muted">
                Pilih maksimal 20 gambar. Format JPG, JPEG, PNG, WEBP.
              </small>

              <div id="imagePreview" class="row g-2 mt-2"></div>

              @if (!empty($package->portfolio))
                <div class="mt-3">
                  <label class="form-label d-block">Gambar Portofolio Saat Ini</label>

                  <div class="row g-2">
                    @foreach ($package->portfolio as $image)
                      <div class="col-md-3 col-6">
                        <img src="{{ asset('storage/' . $image) }}" class="img-fluid rounded border" alt="Portfolio">
                      </div>
                    @endforeach
                  </div>
                </div>
              @endif
            </div>

            <div class="col-12 mb-3">
              <label class="form-label">Deskripsi Paket</label>
              <textarea name="description" class="form-control" rows="4" placeholder="Deskripsi lengkap paket...">{{ old('description') }}</textarea>
            </div>

            <div class="col-md-4 mb-3">
              <label class="form-label">Harga (Rp)</label>
              <input type="number" name="price" class="form-control" value="{{ old('price', 0) }}" min="0"
                required>
            </div>

            <div class="col-md-4 mb-3">
              <label class="form-label">Durasi (menit)</label>
              <input type="number" name="duration_minutes" class="form-control" value="{{ old('duration_minutes') }}"
                placeholder="Contoh: 30" min="0" required>
            </div>

            <div class="mb-3">
              <label for="location_type" class="form-label">Jenis Lokasi</label>
              <select name="location_type" id="location_type" class="form-select" required>
                <option value="">Pilih jenis lokasi</option>
                <option value="indoor"
                  {{ old('location_type', $package->location_type ?? '') === 'indoor' ? 'selected' : '' }}>
                  Indoor
                </option>
                <option value="outdoor"
                  {{ old('location_type', $package->location_type ?? '') === 'outdoor' ? 'selected' : '' }}>
                  Outdoor
                </option>
              </select>
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Jumlah Orang</label>
              <input type="number" name="person_count" class="form-control" value="{{ old('person_count') }}"
                placeholder="Boleh dikosongkan" min="1">
              <small class="text-muted">
                Kosongkan untuk paket seperti prewed atau wedding.
              </small>
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Jumlah Foto Edit</label>
              <input type="number" name="photo_count" class="form-control" value="{{ old('photo_count') }}"
                placeholder="Contoh: 10" min="0" required>
            </div>

            <div class="col-12 mb-4">
              <label class="form-label d-block">Status Paket</label>
              <input type="hidden" name="is_active" value="0">

              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" role="switch" id="isActive" name="is_active"
                  value="1" {{ old('is_active', 1) ? 'checked' : '' }}>
                <label class="form-check-label" for="isActive">Aktif (tampil di halaman publik)</label>
              </div>
            </div>
          </div>

          <div class="d-flex gap-2">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i> Simpan Paket
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
@endsection

@push('scripts')
  <script>
    const portfolioInput = document.getElementById('portfolioImages');
    const previewContainer = document.getElementById('imagePreview');

    portfolioInput.addEventListener('change', function() {
      previewContainer.innerHTML = '';

      const files = Array.from(this.files);

      if (files.length > 20) {
        alert('Maksimal 20 gambar portofolio.');
        this.value = '';
        return;
      }

      files.forEach(file => {
        if (!file.type.startsWith('image/')) return;

        const reader = new FileReader();

        reader.onload = function(e) {
          const col = document.createElement('div');
          col.className = 'col-md-2 col-4';

          col.innerHTML = `
            <div class="border rounded p-1">
              <img src="${e.target.result}" class="img-fluid rounded" style="height: 100px; width: 100%; object-fit: cover;">
              <small class="d-block text-truncate mt-1">${file.name}</small>
            </div>
          `;

          previewContainer.appendChild(col);
        };

        reader.readAsDataURL(file);
      });
    });
  </script>
@endpush
