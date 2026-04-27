@extends('layouts/contentNavbarLayout')

@section('title', 'Role & Akses')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <style>
      .role-tab {
        border: 0;
        background: transparent;
        color: #697a8d;
        font-weight: 500;
        padding: 0.75rem 1rem;
        border-bottom: 2px solid transparent;
      }

      .role-tab.active {
        color: #696cff;
        border-bottom-color: #696cff;
      }

      .permission-toggle {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
      }

      .permission-toggle input {
        display: none;
      }

      .permission-box {
        width: 22px;
        height: 22px;
        border-radius: 6px;
        border: 1px solid #d9dee3;
        background: #fff;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        transition: all .2s ease;
      }

      .permission-box i {
        font-size: 14px;
        color: transparent;
        transition: all .2s ease;
      }

      .permission-toggle input:checked+.permission-box {
        background: rgba(40, 199, 111, 0.12);
        border-color: #28c76f;
      }

      .permission-toggle input:checked+.permission-box i {
        color: #28c76f;
      }

      .permission-toggle input:not(:checked)+.permission-box {
        background: rgba(168, 170, 174, 0.08);
        border-color: #d9dee3;
      }

      .permission-toggle input:disabled+.permission-box {
        opacity: .55;
        cursor: not-allowed;
      }

      .permission-toggle:hover .permission-box {
        transform: scale(1.05);
      }

      .role-col-hidden {
        display: none;
      }
    </style>

    @if (session('success'))
      <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    @if (session('error'))
      <div class="alert alert-danger">{{ session('error') }}</div>
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

    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Role & Akses</h4>
        <p class="text-muted mb-0">Kelola role pengguna dan batasi akses fitur sesuai kebutuhan operasional Monoframe
          Studio.</p>
      </div>

      <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addRoleModal">
        <i class="bx bx-plus me-1"></i> Tambah Role
      </button>
    </div>

    <div class="row">
      <div class="col-md-4 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Total Role</span>
                <h3 class="card-title mb-2">{{ $totalRoles }}</h3>
                <small class="text-primary fw-semibold">Role yang tersedia di sistem</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-primary">
                  <i class="bx bx-shield-quarter"></i>
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
                <span class="text-muted d-block mb-1">Role Aktif</span>
                <h3 class="card-title mb-2">{{ $activeRoles }}</h3>
                <small class="text-success fw-semibold">Role yang sedang digunakan</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-success">
                  <i class="bx bx-check-shield"></i>
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
                <span class="text-muted d-block mb-1">User Dibatasi</span>
                <h3 class="card-title mb-2">{{ $restrictedUsers }}</h3>
                <small class="text-warning fw-semibold">Akun dengan akses nonaktif</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-warning">
                  <i class="bx bx-lock-alt"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <form action="{{ route('admin.roles-akses.permissions.update') }}" method="POST">
      @csrf
      @method('PUT')

      <div class="card mb-4">
        <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-3">
          <div>
            <h5 class="mb-0">Manajemen Hak Akses Role</h5>
            <small class="text-muted">Centang fitur yang boleh diakses oleh setiap role.</small>
          </div>

          <div class="d-flex gap-2">
            <form action="{{ route('admin.roles-akses.reset-defaults') }}" method="POST" class="d-inline">
              @csrf
              <button type="submit" class="btn btn-outline-secondary btn-sm">Reset Default</button>
            </form>
            <button type="submit" class="btn btn-primary btn-sm">
              <i class="bx bx-save me-1"></i> Simpan Konfigurasi
            </button>
          </div>
        </div>

        <div class="card-body pb-0">
          <div class="d-flex flex-wrap gap-1 border-bottom mb-3">
            <button class="role-tab active" type="button" data-role-filter="all">Semua Role</button>
            @foreach ($roles as $role)
              <button class="role-tab" type="button" data-role-filter="{{ $role->slug }}">{{ $role->name }}</button>
            @endforeach
          </div>
        </div>

        <div class="table-responsive text-nowrap">
          <table class="table align-middle">
            <thead>
              <tr>
                <th style="min-width: 320px;">Modul & Fitur</th>
                @foreach ($roles as $role)
                  <th class="text-center role-col role-col-{{ $role->slug }}">{{ $role->name }}</th>
                @endforeach
              </tr>
            </thead>
            <tbody class="table-border-bottom-0">
              @foreach ($permissions as $moduleLabel => $items)
                <tr class="table-light">
                  <td colspan="{{ $roles->count() + 1 }}" class="fw-semibold text-primary">{{ $moduleLabel }}</td>
                </tr>

                @foreach ($items as $permission)
                  <tr>
                    <td>
                      <div class="fw-medium">{{ $permission->label }}</div>
                      <small class="text-muted">{{ $permission->description }}</small>
                      @if ($permission->admin_only)
                        <div class="mt-1">
                          <span class="badge bg-label-danger">Khusus Admin</span>
                        </div>
                      @endif
                    </td>

                    @foreach ($roles as $role)
                      @php
                        $checked = in_array($permission->key, $rolePermissionMap[$role->name] ?? []);
                        $disabled = $role->name === 'Admin' || ($permission->admin_only && $role->name !== 'Admin');
                      @endphp

                      <td class="text-center role-col role-col-{{ $role->slug }}">
                        <label class="permission-toggle"
                          title="{{ $disabled && $role->name !== 'Admin' && $permission->admin_only ? 'Hanya admin yang bisa memiliki akses ini' : '' }}">
                          <input type="checkbox" name="permissions[{{ $role->name }}][]"
                            value="{{ $permission->key }}" {{ $checked ? 'checked' : '' }}
                            {{ $disabled ? 'disabled' : '' }}>
                          <span class="permission-box">
                            <i class="bx bx-check"></i>
                          </span>
                        </label>
                      </td>
                    @endforeach
                  </tr>
                @endforeach
              @endforeach
            </tbody>
          </table>
        </div>

        <div class="card-footer d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div class="text-warning small">
            <i class="bx bx-error-circle me-1"></i>
            Permission khusus admin tidak bisa diberikan ke role lain.
          </div>
          <button type="submit" class="btn btn-primary btn-sm">
            <i class="bx bx-save me-1"></i> Simpan Konfigurasi
          </button>
        </div>
      </div>
    </form>

    <div class="card">
      <div class="card-header">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
          <div>
            <h5 class="mb-0">Akses User</h5>
            <small class="text-muted">Aktifkan atau nonaktifkan akun user secara langsung</small>
          </div>

          <form method="GET" action="{{ route('admin.roles-akses.index') }}" class="d-flex flex-wrap gap-2">
            <input type="text" name="search" class="form-control" placeholder="Cari nama atau email..."
              value="{{ request('search') }}" style="width: 240px;">

            <select name="role" class="form-select" style="width: 180px;">
              <option {{ !request('role') ? 'selected' : '' }}>Semua Role</option>
              @foreach ($roles as $role)
                <option value="{{ $role->name }}" {{ request('role') === $role->name ? 'selected' : '' }}>
                  {{ $role->name }}
                </option>
              @endforeach
            </select>

            <button type="submit" class="btn btn-outline-secondary">Filter</button>
          </form>
        </div>
      </div>

      <div class="table-responsive text-nowrap">
        <table class="table">
          <thead>
            <tr>
              <th>Nama</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status Akun</th>
              <th>Akses</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody class="table-border-bottom-0">
            @forelse($users as $user)
              <tr>
                <td>{{ $user->name }}</td>
                <td>{{ $user->email }}</td>
                <td>
                  <span class="badge bg-label-primary">{{ $user->role }}</span>
                </td>
                <td>
                  @if ($user->is_active ?? true)
                    <span class="badge bg-label-success">Aktif</span>
                  @else
                    <span class="badge bg-label-secondary">Nonaktif</span>
                  @endif
                </td>
                <td>
                  <form action="{{ route('admin.roles-akses.users.toggle', $user) }}" method="POST">
                    @csrf
                    @method('PATCH')
                    <div class="form-check form-switch">
                      <input class="form-check-input" type="checkbox" onchange="this.form.submit()"
                        {{ $user->is_active ?? true ? 'checked' : '' }}>
                    </div>
                  </form>
                </td>
                <td>
                  <a href="{{ route('admin.users.index') }}" class="btn btn-sm btn-warning">Kelola di Users</a>
                </td>
              </tr>
            @empty
              <tr>
                <td colspan="6" class="text-center text-muted py-4">Belum ada data user.</td>
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

  <div class="modal fade" id="addRoleModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <form action="{{ route('admin.roles-akses.roles.store') }}" method="POST">
          @csrf
          <div class="modal-header">
            <h5 class="modal-title">Tambah Role</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>

          <div class="modal-body">
            <div class="mb-3">
              <label class="form-label">Nama Role</label>
              <input type="text" name="name" class="form-control" placeholder="Contoh: Customer Service"
                required>
            </div>

            <div class="mb-3">
              <label class="form-label">Duplikasi Permission Dari</label>
              <select name="clone_from" class="form-select">
                <option value="">Tidak perlu</option>
                @foreach ($roles as $role)
                  <option value="{{ $role->name }}">{{ $role->name }}</option>
                @endforeach
              </select>
            </div>

            <small class="text-muted">Role baru nanti bisa dipakai juga untuk user, selama dropdown role di halaman user
              membaca data dari tabel roles.</small>
          </div>

          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Batal</button>
            <button type="submit" class="btn btn-primary">Simpan Role</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      const tabs = document.querySelectorAll('[data-role-filter]');
      const roleColumns = document.querySelectorAll('.role-col');

      tabs.forEach(tab => {
        tab.addEventListener('click', function() {
          tabs.forEach(btn => btn.classList.remove('active'));
          this.classList.add('active');

          const filter = this.dataset.roleFilter;

          roleColumns.forEach(col => {
            if (filter === 'all') {
              col.classList.remove('role-col-hidden');
            } else {
              if (col.classList.contains('role-col-' + filter)) {
                col.classList.remove('role-col-hidden');
              } else {
                col.classList.add('role-col-hidden');
              }
            }
          });
        });
      });
    });
  </script>
@endsection
