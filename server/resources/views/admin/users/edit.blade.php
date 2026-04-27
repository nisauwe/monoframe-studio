@extends('layouts/contentNavbarLayout')

@section('title', 'Edit User')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Edit User</h4>
        <p class="text-muted mb-0">Ubah data user tanpa mengubah password.</p>
      </div>

      <a href="{{ route('admin.users.index') }}" class="btn btn-outline-secondary">
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
        <h5 class="mb-0">Form Edit User</h5>
      </div>

      <div class="card-body">
        <form action="{{ route('admin.users.update', $user->id) }}" method="POST">
          @csrf
          @method('PUT')

          <div class="row">
            <div class="col-md-6 mb-3">
              <label class="form-label">Username</label>
              <input type="text" name="username" class="form-control" value="{{ old('username', $user->username) }}"
                placeholder="Masukkan username">
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Nama Lengkap</label>
              <input type="text" name="name" class="form-control" value="{{ old('name', $user->name) }}"
                placeholder="Masukkan nama lengkap">
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Email</label>
              <input type="email" name="email" class="form-control" value="{{ old('email', $user->email) }}"
                placeholder="Masukkan email">
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Nomor HP</label>
              <input type="text" name="phone" class="form-control" value="{{ old('phone', $user->phone) }}"
                placeholder="Masukkan nomor HP">
            </div>

            <div class="col-md-12 mb-3">
              <label class="form-label">Alamat</label>
              <textarea name="address" class="form-control" rows="3" placeholder="Masukkan alamat">{{ old('address', $user->address) }}</textarea>
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label">Role</label>
              <select name="role" class="form-select">
                <option value="">Pilih Role</option>
                <option value="Admin" {{ old('role', $user->role) == 'Admin' ? 'selected' : '' }}>Admin</option>
                <option value="Front Office" {{ old('role', $user->role) == 'Front Office' ? 'selected' : '' }}>Front
                  Office</option>
                <option value="Fotografer" {{ old('role', $user->role) == 'Fotografer' ? 'selected' : '' }}>Fotografer
                </option>
                <option value="Editor" {{ old('role', $user->role) == 'Editor' ? 'selected' : '' }}>Editor</option>
                <option value="Klien" {{ old('role', $user->role) == 'Klien' ? 'selected' : '' }}>Klien</option>
              </select>
            </div>

            <div class="col-md-6 mb-3">
              <label class="form-label d-block">Status User</label>
              <div class="form-check form-switch mt-2">
                <input class="form-check-input" type="checkbox" name="is_active" value="1"
                  {{ old('is_active', $user->is_active) ? 'checked' : '' }}>
                <label class="form-check-label">User Aktif</label>
              </div>
            </div>
          </div>

          <div class="d-flex justify-content-end gap-2 mt-3">
            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i> Update User
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
@endsection
