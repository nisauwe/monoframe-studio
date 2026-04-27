@extends('layouts/contentNavbarLayout')

@section('title', 'Users')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Users</h4>
        <p class="text-muted mb-0">Kelola data user Monoframe Studio.</p>
      </div>
    </div>

    @if (session('success'))
      <div class="alert alert-success">
        {{ session('success') }}
      </div>
    @endif

    <div class="row">
      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Total User</span>
                <h3 class="card-title mb-2">{{ $totalUsers }}</h3>
                <small class="text-primary fw-semibold">Seluruh user terdaftar</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-primary">
                  <i class="bx bx-group"></i>
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
                <span class="text-muted d-block mb-1">User Baru</span>
                <h3 class="card-title mb-2">{{ $newUsers }}</h3>
                <small class="text-info fw-semibold">User baru bulan ini</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-info">
                  <i class="bx bx-user-plus"></i>
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
                <span class="text-muted d-block mb-1">User Aktif</span>
                <h3 class="card-title mb-2">{{ $activeUsers }}</h3>
                <small class="text-success fw-semibold">Akun yang aktif digunakan</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-success">
                  <i class="bx bx-user-check"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <div class="d-flex justify-content-end mb-3">
          <a href="{{ route('admin.users.create') }}" class="btn btn-primary">
            <i class="bx bx-plus me-1"></i> Tambah User
          </a>
        </div>

        <div class="row g-3 align-items-center">
          <div class="col-md-8">
            <form method="GET" action="{{ route('admin.users.index') }}" id="filterForm">
              <div class="row g-3">
                <div class="col-md-7">
                  <input type="text" name="search" class="form-control" placeholder="Cari nama atau email..."
                    value="{{ $search ?? '' }}">
                </div>

                <div class="col-md-5">
                  <select name="role" class="form-select" onchange="this.form.submit()">
                    <option value="">Semua Role</option>
                    <option value="Admin" {{ ($role ?? '') == 'Admin' ? 'selected' : '' }}>Admin</option>
                    <option value="Front Office" {{ ($role ?? '') == 'Front Office' ? 'selected' : '' }}>Front Office
                    </option>
                    <option value="Fotografer" {{ ($role ?? '') == 'Fotografer' ? 'selected' : '' }}>Fotografer</option>
                    <option value="Editor" {{ ($role ?? '') == 'Editor' ? 'selected' : '' }}>Editor</option>
                    <option value="Klien" {{ ($role ?? '') == 'Klien' ? 'selected' : '' }}>Klien</option>
                  </select>
                </div>
              </div>
            </form>
          </div>

          <div class="col-md-4">
            <div class="d-flex flex-wrap justify-content-md-end align-items-center gap-2">
              <form action="{{ route('admin.users.reset') }}" method="POST"
                onsubmit="return confirm('Yakin ingin menghapus SEMUA data user dari database?');">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn btn-outline-secondary">
                  Reset
                </button>
              </form>

              <button type="button" class="btn btn-outline-success">
                <i class="bx bx-table me-1"></i> Export Excel
              </button>

              <button type="button" class="btn btn-outline-danger">
                <i class="bx bx-file me-1"></i> Export PDF
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="table-responsive text-nowrap">
        <table class="table">
          <thead>
            <tr>
              <th>Nama</th>
              <th>Email</th>
              <th>Role</th>
              <th>Created</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody class="table-border-bottom-0">
            @forelse ($users as $user)
              <tr>
                <td>{{ $user->name }}</td>
                <td>{{ $user->email }}</td>
                <td>
                  <span class="badge bg-label-primary">{{ $user->role }}</span>
                </td>
                <td>{{ $user->created_at->format('d M Y') }}</td>
                <td>
                  <div class="d-flex gap-2">
                    <a href="{{ route('admin.users.edit', $user->id) }}" class="btn btn-outline-primary btn-sm">
                      <i class="bx bx-edit-alt me-1"></i> Edit
                    </a>
                    <form action="{{ route('admin.users.destroy', $user->id) }}" method="POST"
                      onsubmit="return confirm('Yakin ingin menghapus user ini?');">
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
                <td colspan="5" class="text-center">Belum ada data user.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>

      <div class="card-footer">
        {{ $users->links() }}
      </div>
    </div>
  </div>
@endsection
