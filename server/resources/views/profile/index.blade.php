@extends('layouts/contentNavbarLayout')

@section('title', 'Profile Admin')

@section('content')
  @php
    $profilePhotoUrl = $user->profile_photo
      ? asset('storage/' . $user->profile_photo)
      : asset('assets/img/avatars/1.png');
  @endphp

  <style>
    .profile-avatar-wrapper {
      display: flex;
      align-items: center;
      gap: 18px;
      flex-wrap: wrap;
    }

    .profile-avatar-preview {
      width: 118px;
      height: 118px;
      border-radius: 28px;
      object-fit: cover;
      border: 4px solid #ffffff;
      box-shadow: 0 16px 36px rgba(47, 68, 143, 0.18);
      background: #ffffff;
    }

    .profile-role-badge {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 13px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.12);
      color: #5873dc;
      font-weight: 800;
      font-size: 13px;
    }

    .profile-help-text {
      font-size: 13px;
      color: #728199;
      margin-bottom: 0;
    }

    .profile-section-title {
      font-weight: 800;
      color: #162b4d;
      margin-bottom: 4px;
    }

    .profile-section-subtitle {
      color: #728199;
      font-size: 13px;
      margin-bottom: 0;
    }

    .profile-readonly-card {
      border: 1px solid #dfe7ef;
      border-radius: 18px;
      padding: 16px;
      background: #f7fbfd;
    }

    .profile-readonly-label {
      font-size: 12px;
      color: #728199;
      font-weight: 800;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 4px;
    }

    .profile-readonly-value {
      color: #162b4d;
      font-weight: 800;
      margin-bottom: 0;
    }
  </style>

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <div class="dashboard-kicker">
          <i class="bx bx-user"></i>
          PROFIL ADMIN
        </div>
        <h4 class="fw-bold mb-1">Profile Saya</h4>
        <p class="text-muted mb-0">
          Ubah identitas admin, foto profile, dan password akun.
        </p>
      </div>
    </div>

    @if (session('success'))
      <div class="alert alert-success alert-dismissible" role="alert">
        {{ session('success') }}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    @endif

    @if ($errors->any())
      <div class="alert alert-danger alert-dismissible" role="alert">
        <strong>Terjadi kesalahan.</strong>
        <ul class="mb-0 mt-2">
          @foreach ($errors->all() as $error)
            <li>{{ $error }}</li>
          @endforeach
        </ul>
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    @endif

    <div class="row">
      <div class="col-xl-4 col-lg-5 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="profile-avatar-wrapper mb-4">
              <img
                src="{{ $profilePhotoUrl }}"
                alt="{{ $user->name }}"
                class="profile-avatar-preview"
                id="profileAvatarPreview">

              <div>
                <h5 class="mb-1">{{ $user->name }}</h5>
                <div class="profile-role-badge mb-2">
                  <i class="bx bx-shield-quarter"></i>
                  {{ $user->role ?? 'Admin' }}
                </div>
                <p class="profile-help-text">
                  Foto yang tampil di kanan atas navbar akan mengikuti foto ini.
                </p>
              </div>
            </div>

            <div class="row g-3">
              <div class="col-12">
                <div class="profile-readonly-card">
                  <div class="profile-readonly-label">Email Login</div>
                  <p class="profile-readonly-value">{{ $user->email }}</p>
                </div>
              </div>

              <div class="col-12">
                <div class="profile-readonly-card">
                  <div class="profile-readonly-label">Username</div>
                  <p class="profile-readonly-value">{{ $user->username ?? '-' }}</p>
                </div>
              </div>

              <div class="col-12">
                <div class="profile-readonly-card">
                  <div class="profile-readonly-label">Status Akun</div>
                  <p class="profile-readonly-value">
                    {{ $user->is_active ? 'Aktif' : 'Tidak Aktif' }}
                  </p>
                </div>
              </div>
            </div>

            @if ($user->profile_photo)
              <form action="{{ route('admin.profile.photo.destroy') }}" method="POST" class="mt-4"
                onsubmit="return confirm('Yakin ingin menghapus foto profile?');">
                @csrf
                @method('DELETE')

                <button type="submit" class="btn btn-outline-danger w-100">
                  <i class="bx bx-trash me-1"></i>
                  Hapus Foto Profile
                </button>
              </form>
            @endif
          </div>
        </div>
      </div>

      <div class="col-xl-8 col-lg-7">
        <form action="{{ route('admin.profile.update') }}" method="POST" enctype="multipart/form-data">
          @csrf
          @method('PUT')

          <div class="card mb-4">
            <div class="card-header">
              <h5 class="profile-section-title">Data Identitas</h5>
              <p class="profile-section-subtitle">
                Data ini akan digunakan untuk tampilan profile admin di navbar.
              </p>
            </div>

            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-6">
                  <label for="name" class="form-label">Nama Lengkap</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    class="form-control"
                    value="{{ old('name', $user->name) }}"
                    required>
                </div>

                <div class="col-md-6">
                  <label for="username" class="form-label">Username</label>
                  <input
                    type="text"
                    id="username"
                    name="username"
                    class="form-control"
                    value="{{ old('username', $user->username) }}"
                    placeholder="Contoh: adminmonoframe">
                </div>

                <div class="col-md-6">
                  <label for="email" class="form-label">Email</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    class="form-control"
                    value="{{ old('email', $user->email) }}"
                    required>
                </div>

                <div class="col-md-6">
                  <label for="phone" class="form-label">Nomor HP</label>
                  <input
                    type="text"
                    id="phone"
                    name="phone"
                    class="form-control"
                    value="{{ old('phone', $user->phone) }}"
                    placeholder="Contoh: 08123456789">
                </div>

                <div class="col-12">
                  <label for="address" class="form-label">Alamat</label>
                  <textarea
                    id="address"
                    name="address"
                    rows="3"
                    class="form-control"
                    placeholder="Alamat admin">{{ old('address', $user->address) }}</textarea>
                </div>

                <div class="col-12">
                  <label for="profile_photo" class="form-label">Foto Profile</label>
                  <input
                    type="file"
                    id="profile_photo"
                    name="profile_photo"
                    class="form-control"
                    accept="image/png,image/jpeg,image/jpg,image/webp">
                  <small class="text-muted">
                    Format: JPG, JPEG, PNG, WEBP. Maksimal 2MB.
                  </small>
                </div>
              </div>
            </div>
          </div>

          <div class="card mb-4">
            <div class="card-header">
              <h5 class="profile-section-title">Ubah Password</h5>
              <p class="profile-section-subtitle">
                Kosongkan bagian ini jika tidak ingin mengganti password.
              </p>
            </div>

            <div class="card-body">
              <div class="row g-3">
                <div class="col-md-4">
                  <label for="current_password" class="form-label">Password Lama</label>
                  <input
                    type="password"
                    id="current_password"
                    name="current_password"
                    class="form-control"
                    autocomplete="current-password">
                </div>

                <div class="col-md-4">
                  <label for="password" class="form-label">Password Baru</label>
                  <input
                    type="password"
                    id="password"
                    name="password"
                    class="form-control"
                    autocomplete="new-password">
                </div>

                <div class="col-md-4">
                  <label for="password_confirmation" class="form-label">Konfirmasi Password Baru</label>
                  <input
                    type="password"
                    id="password_confirmation"
                    name="password_confirmation"
                    class="form-control"
                    autocomplete="new-password">
                </div>
              </div>
            </div>
          </div>

          <div class="d-flex justify-content-end gap-2 mb-4">
            <a href="{{ route('admin.dashboard') }}" class="btn btn-outline-secondary">
              Batal
            </a>

            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i>
              Simpan Perubahan
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const photoInput = document.getElementById('profile_photo');
      const preview = document.getElementById('profileAvatarPreview');

      if (photoInput && preview) {
        photoInput.addEventListener('change', function (event) {
          const file = event.target.files && event.target.files[0];

          if (!file) {
            return;
          }

          const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

          if (!allowedTypes.includes(file.type)) {
            alert('Format foto harus JPG, JPEG, PNG, atau WEBP.');
            photoInput.value = '';
            return;
          }

          if (file.size > 2 * 1024 * 1024) {
            alert('Ukuran foto maksimal 2MB.');
            photoInput.value = '';
            return;
          }

          const reader = new FileReader();

          reader.onload = function (e) {
            preview.src = e.target.result;
          };

          reader.readAsDataURL(file);
        });
      }
    });
  </script>
@endsection