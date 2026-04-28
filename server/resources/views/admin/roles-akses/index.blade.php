@extends('layouts/contentNavbarLayout')

@section('title', 'Role & Akses')

@section('content')
  @php
    $activeTab = request('tab', 'roles');
    $allowedTabs = ['roles', 'permissions', 'users'];

    if (!in_array($activeTab, $allowedTabs, true)) {
        $activeTab = 'roles';
    }

    $roleCount = $roles->count();
    $permissionCount = collect($permissions)->flatten(1)->count();

    $roleBadgeClass = function ($roleName) {
        return match ($roleName) {
            'Admin' => 'danger',
            'Front Office' => 'info',
            'Fotografer' => 'warning',
            'Editor' => 'success',
            'Klien' => 'primary',
            default => 'secondary',
        };
    };

    $roleIcon = function ($roleName) {
        return match ($roleName) {
            'Admin' => 'bx bx-shield-quarter',
            'Front Office' => 'bx bx-desktop',
            'Fotografer' => 'bx bx-camera',
            'Editor' => 'bx bx-edit-alt',
            'Klien' => 'bx bx-user',
            default => 'bx bx-user-check',
        };
    };
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell role-access-page">

      {{-- ALERT --}}
      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

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

      {{-- HERO HEADER --}}
      <div class="role-hero-card mb-4">
        <div class="role-hero-left">
          <div class="role-hero-icon">
            <i class="bx bx-shield-quarter"></i>
          </div>

          <div>
            <div class="role-hero-kicker">PENGATURAN AKSES</div>
            <h4>Role & Akses</h4>
            <p>
              Kelola role, hak akses fitur, dan status akses akun user Monoframe Studio
              agar setiap pengguna hanya dapat membuka menu sesuai tugas dan tanggung jawabnya.
            </p>
          </div>
        </div>

        <div class="role-hero-actions">
          <div class="role-hero-badge">
            <i class="bx bx-shield-quarter"></i>
            {{ $totalRoles }} Role Terdaftar
          </div>
        </div>
      </div>

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        <div class="col-md-4">
          <div class="card stat-card h-100 role-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Total Role</div>
                  <h3 class="stat-number">{{ $totalRoles }}</h3>
                  <div class="stat-helper">Role yang tersedia di sistem</div>
                </div>

                <div class="stat-icon">
                  <i class="bx bx-shield-quarter"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4">
          <div class="card stat-card h-100 role-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Role Aktif</div>
                  <h3 class="stat-number">{{ $activeRoles }}</h3>
                  <div class="stat-helper">Role yang dapat digunakan user</div>
                </div>

                <div class="stat-icon success">
                  <i class="bx bx-check-shield"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4">
          <div class="card stat-card h-100 role-stat-card">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">User Dibatasi</div>
                  <h3 class="stat-number">{{ $restrictedUsers }}</h3>
                  <div class="stat-helper">Akun user yang sedang nonaktif</div>
                </div>

                <div class="stat-icon warning">
                  <i class="bx bx-lock-alt"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {{-- INFO CARD --}}
      <div class="role-info-card mb-4">
        <div class="role-info-icon">
          <i class="bx bx-info-circle"></i>
        </div>

        <div>
          <h6>Konsep Role & Akses</h6>
          <p>
            Role menentukan fitur apa saja yang boleh diakses user. Admin selalu memiliki semua akses.
            Jika hanya ingin membatasi satu user tertentu, nonaktifkan akses login user tersebut di tab Akses User.
          </p>
        </div>
      </div>

      {{-- TAB NAVIGATION --}}
      <div class="role-tabs-card mb-4">
        <ul class="nav role-page-tabs" role="tablist">
          <li class="nav-item" role="presentation">
            <button type="button"
              class="nav-link {{ $activeTab === 'roles' ? 'active' : '' }}"
              id="roles-tab"
              data-bs-toggle="tab"
              data-bs-target="#tab-roles"
              data-role-page-tab="roles"
              role="tab">
              <i class="bx bx-shield-quarter me-1"></i>
              Manajemen Role
            </button>
          </li>

          <li class="nav-item" role="presentation">
            <button type="button"
              class="nav-link {{ $activeTab === 'permissions' ? 'active' : '' }}"
              id="permissions-tab"
              data-bs-toggle="tab"
              data-bs-target="#tab-permissions"
              data-role-page-tab="permissions"
              role="tab">
              <i class="bx bx-lock-open-alt me-1"></i>
              Manajemen Hak Akses
            </button>
          </li>

          <li class="nav-item" role="presentation">
            <button type="button"
              class="nav-link {{ $activeTab === 'users' ? 'active' : '' }}"
              id="users-tab"
              data-bs-toggle="tab"
              data-bs-target="#tab-users"
              data-role-page-tab="users"
              role="tab">
              <i class="bx bx-user-check me-1"></i>
              Akses User
            </button>
          </li>
        </ul>
      </div>

      {{-- RESET DEFAULT FORM DI LUAR FORM PERMISSION --}}
      <form id="resetDefaultRoleForm"
        action="{{ route('admin.roles-akses.reset-defaults', ['tab' => 'permissions']) }}"
        method="POST"
        class="d-none">
        @csrf
      </form>

      <div class="tab-content role-tab-content">

        {{-- TAB 1: MANAJEMEN ROLE --}}
        <div class="tab-pane fade {{ $activeTab === 'roles' ? 'show active' : '' }}"
          id="tab-roles"
          role="tabpanel"
          aria-labelledby="roles-tab">

          <div class="card section-card role-management-card">
            <div class="card-header">
              <div class="role-card-head">
                <div>
                  <h5 class="section-title">Manajemen Role</h5>
                  <p class="section-subtitle mb-0">
                    Lihat daftar role yang tersedia. Tambahkan role baru dan salin permission dari role yang sudah ada.
                  </p>
                </div>

                <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addRoleModal">
                  <i class="bx bx-plus me-1"></i>
                  Tambah Role
                </button>
              </div>
            </div>

            <div class="card-body role-management-body">
              <div class="role-list-grid">
                @foreach ($roles as $role)
                  @php
                    $allowedCount = count($rolePermissionMap[$role->name] ?? []);
                    $badge = $roleBadgeClass($role->name);
                    $icon = $roleIcon($role->name);
                    $isSystem = $role->is_system ?? false;
                    $isActive = $role->is_active ?? true;
                    $coverage = $permissionCount > 0 ? round(($allowedCount / $permissionCount) * 100) : 0;
                  @endphp

                  <div class="role-list-card">
                    <div class="role-list-top">
                      <div class="role-list-icon bg-label-{{ $badge }}">
                        <i class="{{ $icon }}"></i>
                      </div>

                      <div class="role-list-badges">
                        @if ($isSystem)
                          <span class="badge bg-label-secondary">System Role</span>
                        @else
                          <span class="badge bg-label-info">Custom Role</span>
                        @endif

                        @if ($isActive)
                          <span class="badge bg-label-success">Aktif</span>
                        @else
                          <span class="badge bg-label-secondary">Nonaktif</span>
                        @endif
                      </div>
                    </div>

                    <div class="role-list-name">{{ $role->name }}</div>
                    <div class="role-list-slug">{{ $role->slug }}</div>

                    <div class="role-list-meta">
                      <div>
                        <span>Permission Aktif</span>
                        <strong>{{ $allowedCount }}</strong>
                      </div>

                      <div>
                        <span>Total Permission</span>
                        <strong>{{ $permissionCount }}</strong>
                      </div>
                    </div>

                    <div class="role-progress">
                      <div class="role-progress-head">
                        <span>Coverage Akses</span>
                        <span>{{ $coverage }}%</span>
                      </div>

                      <div class="role-progress-bar">
                        <div style="width: {{ $coverage }}%;"></div>
                      </div>
                    </div>

                    <button type="button"
                      class="btn btn-outline-primary w-100 mt-3"
                      data-open-tab="permissions"
                      data-filter-role="{{ $role->slug }}">
                      <i class="bx bx-lock-open-alt me-1"></i>
                      Lihat Hak Akses
                    </button>
                  </div>
                @endforeach
              </div>

              <div class="role-note-panel mt-4">
                <div class="role-note-icon">
                  <i class="bx bx-bulb"></i>
                </div>

                <div>
                  <h6>Catatan Manajemen Role</h6>
                  <p>
                    Saat ini halaman ini mendukung tambah role dan pengaturan permission role.
                    Untuk edit nama role, hapus role, atau nonaktifkan role, perlu ditambahkan method dan route tambahan di controller.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {{-- TAB 2: MANAJEMEN HAK AKSES --}}
        <div class="tab-pane fade {{ $activeTab === 'permissions' ? 'show active' : '' }}"
          id="tab-permissions"
          role="tabpanel"
          aria-labelledby="permissions-tab">

          <form id="permissionsForm"
            action="{{ route('admin.roles-akses.permissions.update', ['tab' => 'permissions']) }}"
            method="POST">
            @csrf
            @method('PUT')

            <div class="card section-card role-permission-card">
              <div class="card-header">
                <div class="role-card-head">
                  <div>
                    <h5 class="section-title">Manajemen Hak Akses Role</h5>
                    <p class="section-subtitle mb-0">
                      Pilih kartu role di bawah untuk menampilkan hak akses role tertentu.
                      Pilih Semua Role untuk melihat seluruh matrix permission.
                    </p>
                  </div>

                  <div class="role-head-actions">
                    <button type="submit"
                      form="resetDefaultRoleForm"
                      class="btn btn-outline-secondary"
                      onclick="return confirm('Yakin ingin mengembalikan konfigurasi permission ke default?')">
                      <i class="bx bx-refresh me-1"></i>
                      Reset Default
                    </button>

                    <button type="submit" form="permissionsForm" class="btn btn-primary">
                      <i class="bx bx-save me-1"></i>
                      Simpan Hak Akses
                    </button>
                  </div>
                </div>
              </div>

              <div class="card-body role-permission-body">
                {{-- ROLE CARD FILTER --}}
                <div class="role-summary-grid role-summary-tabs mb-4">
                  <button type="button"
                    class="role-summary-card active"
                    data-role-filter-trigger="all">
                    <div class="role-summary-icon bg-label-primary">
                      <i class="bx bx-grid-alt"></i>
                    </div>

                    <div>
                      <div class="role-summary-name">Semua Role</div>
                      <div class="role-summary-sub">
                        Tampilkan semua role
                      </div>
                    </div>
                  </button>

                  @foreach ($roles as $role)
                    @php
                      $allowedCount = count($rolePermissionMap[$role->name] ?? []);
                    @endphp

                    <button type="button"
                      class="role-summary-card"
                      data-role-filter-trigger="{{ $role->slug }}">
                      <div class="role-summary-icon bg-label-{{ $roleBadgeClass($role->name) }}">
                        <i class="{{ $roleIcon($role->name) }}"></i>
                      </div>

                      <div>
                        <div class="role-summary-name">{{ $role->name }}</div>
                        <div class="role-summary-sub">
                          {{ $allowedCount }} dari {{ $permissionCount }} permission aktif
                        </div>
                      </div>
                    </button>
                  @endforeach
                </div>

                {{-- MATRIX PERMISSION --}}
                <div class="role-table-wrap">
                  <div class="table-responsive">
                    <table class="table align-middle role-permission-table">
                      <thead>
                        <tr>
                          <th class="permission-feature-col">Modul & Fitur</th>

                          @foreach ($roles as $role)
                            <th class="text-center role-col role-col-{{ $role->slug }}">
                              <div class="role-table-head">
                                <span class="badge bg-label-{{ $roleBadgeClass($role->name) }}">
                                  {{ $role->name }}
                                </span>
                              </div>
                            </th>
                          @endforeach
                        </tr>
                      </thead>

                      <tbody>
                        @foreach ($permissions as $moduleLabel => $items)
                          <tr class="permission-module-row">
                            <td colspan="{{ $roleCount + 1 }}">
                              <div class="permission-module-title">
                                <i class="bx bx-folder-open"></i>
                                {{ $moduleLabel }}
                              </div>
                            </td>
                          </tr>

                          @foreach ($items as $permission)
                            <tr>
                              <td class="permission-feature-col">
                                <div class="permission-feature">
                                  <div class="permission-feature-icon">
                                    <i class="bx bx-check-shield"></i>
                                  </div>

                                  <div>
                                    <div class="permission-title">
                                      {{ $permission->label }}
                                    </div>

                                    <div class="permission-desc">
                                      {{ $permission->description ?: 'Tidak ada deskripsi.' }}
                                    </div>

                                    <div class="permission-key-wrap">
                                      <span class="permission-key">
                                        {{ $permission->key }}
                                      </span>

                                      @if ($permission->admin_only)
                                        <span class="badge bg-label-danger">
                                          Khusus Admin
                                        </span>
                                      @endif
                                    </div>
                                  </div>
                                </div>
                              </td>

                              @foreach ($roles as $role)
                                @php
                                  $checked = in_array($permission->key, $rolePermissionMap[$role->name] ?? []);
                                  $isAdminRole = $role->name === 'Admin';
                                  $isAdminOnlyLocked = $permission->admin_only && !$isAdminRole;
                                  $disabled = $isAdminRole || $isAdminOnlyLocked;

                                  $tooltip = '';
                                  if ($isAdminRole) {
                                      $tooltip = 'Admin selalu memiliki semua hak akses.';
                                  } elseif ($isAdminOnlyLocked) {
                                      $tooltip = 'Permission ini khusus untuk Admin.';
                                  }
                                @endphp

                                <td class="text-center role-col role-col-{{ $role->slug }}">
                                  <label class="permission-toggle" title="{{ $tooltip }}">
                                    <input type="checkbox"
                                      name="permissions[{{ $role->name }}][]"
                                      value="{{ $permission->key }}"
                                      {{ $checked ? 'checked' : '' }}
                                      {{ $disabled ? 'disabled' : '' }}>

                                    <span class="permission-box {{ $disabled ? 'disabled' : '' }}">
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
                </div>
              </div>

              <div class="card-footer role-permission-footer">
                <div class="role-warning-text">
                  <i class="bx bx-error-circle"></i>
                  Admin otomatis mendapat semua permission. Permission khusus admin tidak bisa diberikan ke role lain.
                </div>

                <button type="submit" form="permissionsForm" class="btn btn-primary">
                  <i class="bx bx-save me-1"></i>
                  Simpan Hak Akses
                </button>
              </div>
            </div>
          </form>
        </div>

        {{-- TAB 3: AKSES USER --}}
        <div class="tab-pane fade {{ $activeTab === 'users' ? 'show active' : '' }}"
          id="tab-users"
          role="tabpanel"
          aria-labelledby="users-tab">

          <div class="card section-card user-access-card">
            <div class="card-header">
              <div class="role-card-head">
                <div>
                  <h5 class="section-title">Akses User</h5>
                  <p class="section-subtitle mb-0">
                    Aktifkan atau nonaktifkan akses login user. Hak fitur tetap mengikuti role masing-masing.
                  </p>
                </div>

                <div class="mf-badge-total">
                  <i class="bx bx-user"></i>
                  {{ $users->total() }} user
                </div>
              </div>
            </div>

            <div class="card-body user-access-body">
              <form method="GET" action="{{ route('admin.roles-akses.index') }}" class="user-access-filter">
                <input type="hidden" name="tab" value="users">

                <div class="row g-3 align-items-end">
                  <div class="col-lg-6">
                    <label class="form-label">Cari User</label>
                    <input type="text"
                      name="search"
                      class="form-control"
                      placeholder="Cari nama atau email..."
                      value="{{ request('search') }}">
                  </div>

                  <div class="col-lg-3">
                    <label class="form-label">Filter Role</label>
                    <select name="role" class="form-select">
                      <option value="" {{ !request('role') ? 'selected' : '' }}>
                        Semua Role
                      </option>

                      @foreach ($roles as $role)
                        <option value="{{ $role->name }}" {{ request('role') === $role->name ? 'selected' : '' }}>
                          {{ $role->name }}
                        </option>
                      @endforeach
                    </select>
                  </div>

                  <div class="col-lg-3">
                    <div class="d-flex gap-2">
                      <button type="submit" class="btn btn-primary flex-fill">
                        <i class="bx bx-search me-1"></i>
                        Filter
                      </button>

                      <a href="{{ route('admin.roles-akses.index', ['tab' => 'users']) }}"
                        class="btn btn-outline-secondary">
                        Reset
                      </a>
                    </div>
                  </div>
                </div>
              </form>
            </div>

            <div class="user-table-wrap">
              <div class="table-responsive">
                <table class="table align-middle user-access-table">
                  <thead>
                    <tr>
                      <th>User</th>
                      <th>Email</th>
                      <th>Role</th>
                      <th>Status Akun</th>
                      <th>Akses Login</th>
                    </tr>
                  </thead>

                  <tbody>
                    @forelse($users as $user)
                      @php
                        $isActive = $user->is_active ?? true;
                        $initial = mb_strtoupper(mb_substr($user->name ?: 'U', 0, 1));
                        $badge = $roleBadgeClass($user->role);
                      @endphp

                      <tr>
                        <td>
                          <div class="user-cell">
                            <div class="user-avatar">
                              {{ $initial }}
                            </div>

                            <div>
                              <div class="user-name">
                                {{ $user->name }}
                              </div>
                              <div class="user-id">
                                ID User: {{ $user->id }}
                              </div>
                            </div>
                          </div>
                        </td>

                        <td>
                          <span class="user-email">
                            {{ $user->email }}
                          </span>
                        </td>

                        <td>
                          <span class="badge bg-label-{{ $badge }}">
                            {{ $user->role }}
                          </span>
                        </td>

                        <td>
                          @if ($isActive)
                            <span class="badge bg-label-success">
                              Aktif
                            </span>
                          @else
                            <span class="badge bg-label-secondary">
                              Nonaktif
                            </span>
                          @endif
                        </td>

                        <td>
                          <form action="{{ route('admin.roles-akses.users.toggle', ['user' => $user->id, 'tab' => 'users']) }}"
                            method="POST">
                            @csrf
                            @method('PATCH')

                            <label class="access-switch">
                              <input type="checkbox"
                                onchange="this.form.submit()"
                                {{ $isActive ? 'checked' : '' }}>
                              <span class="access-slider"></span>
                            </label>
                          </form>
                        </td>
                      </tr>
                    @empty
                      <tr>
                        <td colspan="5">
                          <div class="role-empty-state">
                            <i class="bx bx-user-x"></i>
                            <h6>Belum ada data user</h6>
                            <p>User yang sesuai filter akan tampil di sini.</p>
                          </div>
                        </td>
                      </tr>
                    @endforelse
                  </tbody>
                </table>
              </div>
            </div>

            @if ($users->hasPages())
              <div class="card-footer">
                {{ $users->appends([
                    'tab' => 'users',
                    'search' => request('search'),
                    'role' => request('role'),
                ])->links() }}
              </div>
            @endif
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- MODAL TAMBAH ROLE --}}
  <div class="modal fade" id="addRoleModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <form action="{{ route('admin.roles-akses.roles.store', ['tab' => 'roles']) }}" method="POST">
          @csrf

          <div class="modal-header">
            <div>
              <h5 class="modal-title">Tambah Role</h5>
              <small class="text-white opacity-75">
                Buat role baru dan salin permission dari role yang sudah ada jika diperlukan.
              </small>
            </div>

            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>

          <div class="modal-body">
            <div class="mb-3">
              <label class="form-label">Nama Role</label>
              <input type="text"
                name="name"
                class="form-control"
                placeholder="Contoh: Customer Service"
                required>
            </div>

            <div class="mb-3">
              <label class="form-label">Duplikasi Permission Dari</label>
              <select name="clone_from" class="form-select">
                <option value="">Tidak perlu duplikasi</option>

                @foreach ($roles as $role)
                  <option value="{{ $role->name }}">
                    {{ $role->name }}
                  </option>
                @endforeach
              </select>
            </div>

            <div class="role-modal-note">
              <i class="bx bx-info-circle"></i>
              Role baru akan muncul di tab Manajemen Role dan Manajemen Hak Akses.
              Setelah role dibuat, centang permission yang boleh diakses role tersebut.
            </div>
          </div>

          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
              Batal
            </button>

            <button type="submit" class="btn btn-primary">
              <i class="bx bx-save me-1"></i>
              Simpan Role
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <style>
    .role-access-page {
      max-width: 1480px;
      margin: 0 auto;
    }

    .role-hero-card {
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

    .role-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .role-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .role-hero-icon {
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

    .role-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .role-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .role-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .role-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .role-hero-badge {
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
      gap: 9px;
      white-space: nowrap;
      box-shadow: 0 16px 30px rgba(22, 43, 77, 0.16);
    }

    .role-hero-badge i {
      font-size: 20px;
    }

    .role-stat-card {
      min-height: 142px;
    }

    .role-info-card {
      display: grid;
      grid-template-columns: 58px 1fr;
      gap: 16px;
      align-items: flex-start;
      padding: 22px 24px;
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
    }

    .role-info-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-size: 28px;
      box-shadow: 0 16px 32px rgba(88, 115, 220, 0.22);
    }

    .role-info-card h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .role-info-card p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .role-tabs-card {
      padding: 10px;
      border-radius: 26px;
      background: rgba(255, 255, 255, 0.98);
      box-shadow: var(--mf-shadow-soft);
      overflow-x: auto;
    }

    .role-page-tabs {
      display: flex;
      flex-wrap: nowrap;
      gap: 10px;
      min-width: max-content;
      border: 0;
    }

    .role-page-tabs .nav-link {
      border: 0 !important;
      border-radius: 18px !important;
      padding: 12px 18px;
      color: var(--mf-muted);
      font-weight: 900;
      display: inline-flex;
      align-items: center;
      white-space: nowrap;
      transition: 0.18s ease;
    }

    .role-page-tabs .nav-link:hover {
      background: var(--mf-primary-soft);
      color: var(--mf-primary);
    }

    .role-page-tabs .nav-link.active {
      color: #ffffff !important;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue)) !important;
      box-shadow: 0 14px 28px rgba(88, 115, 220, 0.24);
    }

    .role-tab-content {
      background: transparent !important;
      padding: 0 !important;
      box-shadow: none !important;
    }

    .role-card-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 16px;
    }

    .role-head-actions {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
    }

    .role-management-card .card-header,
    .role-permission-card .card-header,
    .user-access-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .role-management-body,
    .role-permission-body,
    .user-access-body {
      padding: 26px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .role-list-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }

    .role-list-card {
      border: 1px solid var(--mf-border);
      border-radius: 26px;
      background: #ffffff;
      padding: 22px;
      transition: 0.22s ease;
      box-shadow: var(--mf-shadow-soft);
    }

    .role-list-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.16);
    }

    .role-list-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 18px;
    }

    .role-list-icon {
      width: 54px;
      height: 54px;
      border-radius: 19px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      flex-shrink: 0;
    }

    .role-list-badges {
      display: flex;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 7px;
    }

    .role-list-name {
      color: var(--mf-ink);
      font-weight: 900;
      font-size: 20px;
      margin-bottom: 4px;
    }

    .role-list-slug {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 800;
      margin-bottom: 18px;
    }

    .role-list-meta {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 16px;
    }

    .role-list-meta div {
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 12px;
      background: #f8fbfd;
    }

    .role-list-meta span {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      margin-bottom: 4px;
    }

    .role-list-meta strong {
      color: var(--mf-ink);
      font-size: 18px;
      font-weight: 900;
    }

    .role-progress-head {
      display: flex;
      justify-content: space-between;
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .role-progress-bar {
      height: 9px;
      border-radius: 999px;
      background: #edf3fb;
      overflow: hidden;
    }

    .role-progress-bar div {
      height: 100%;
      border-radius: 999px;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
    }

    .role-note-panel {
      display: grid;
      grid-template-columns: 52px 1fr;
      gap: 14px;
      padding: 18px;
      border-radius: 24px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .role-note-icon {
      width: 52px;
      height: 52px;
      border-radius: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 25px;
    }

    .role-note-panel h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 5px;
    }

    .role-note-panel p {
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.7;
      margin-bottom: 0;
    }

    .role-summary-grid {
      display: grid;
      grid-template-columns: repeat(6, minmax(0, 1fr));
      gap: 12px;
    }

    .role-summary-tabs {
      align-items: stretch;
    }

    .role-summary-card {
      width: 100%;
      border: 1px solid var(--mf-border);
      border-radius: 22px;
      padding: 16px;
      background: #ffffff;
      text-align: left;
      display: flex;
      align-items: center;
      gap: 12px;
      transition: 0.2s ease;
      cursor: pointer;
    }

    .role-summary-card:hover {
      transform: translateY(-3px);
      background: #f8fbfd;
      box-shadow: var(--mf-shadow-soft);
    }

    .role-summary-card.active {
      border-color: rgba(88, 115, 220, 0.55);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.20), transparent 38%),
        linear-gradient(180deg, #ffffff 0%, #f4f8ff 100%);
      box-shadow: 0 16px 34px rgba(88, 115, 220, 0.18);
    }

    .role-summary-card.active .role-summary-name {
      color: var(--mf-primary);
    }

    .role-summary-icon {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 21px;
    }

    .role-summary-name {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 3px;
    }

    .role-summary-sub {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      line-height: 1.45;
    }

    .role-table-wrap,
    .user-table-wrap {
      margin: 0 34px 30px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
      overflow: hidden;
    }

    .role-table-wrap {
      margin-left: 0;
      margin-right: 0;
      margin-bottom: 0;
    }

    .role-permission-table {
      min-width: 980px;
    }

    .role-permission-table th,
    .role-permission-table td {
      vertical-align: middle;
    }

    .permission-feature-col {
      min-width: 360px;
      width: 42%;
    }

    .role-table-head {
      min-width: 120px;
      display: flex;
      justify-content: center;
    }

    .permission-module-row td {
      background: #f4f7fb !important;
      color: var(--mf-primary) !important;
      font-weight: 900 !important;
      padding: 15px 20px !important;
    }

    .permission-module-title {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-weight: 900;
      letter-spacing: 0.02em;
    }

    .permission-feature {
      display: grid;
      grid-template-columns: 44px 1fr;
      gap: 13px;
      align-items: flex-start;
      padding: 3px 0;
    }

    .permission-feature-icon {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 21px;
    }

    .permission-title {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.35;
      margin-bottom: 4px;
    }

    .permission-desc {
      color: var(--mf-muted);
      font-size: 13px;
      line-height: 1.6;
      font-weight: 600;
    }

    .permission-key-wrap {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 8px;
    }

    .permission-key {
      display: inline-flex;
      align-items: center;
      border-radius: 999px;
      padding: 5px 9px;
      background: #f4f7fb;
      color: #607086;
      font-size: 11px;
      font-weight: 900;
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
      width: 34px;
      height: 34px;
      border-radius: 13px;
      border: 1px solid var(--mf-border);
      background: rgba(107, 124, 147, 0.06);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      transition: 0.18s ease;
    }

    .permission-box i {
      font-size: 18px;
      color: transparent;
      transition: 0.18s ease;
    }

    .permission-toggle input:checked + .permission-box {
      background: rgba(47, 177, 140, 0.15);
      border-color: rgba(47, 177, 140, 0.55);
    }

    .permission-toggle input:checked + .permission-box i {
      color: #167a64;
    }

    .permission-toggle:hover .permission-box {
      transform: scale(1.06);
    }

    .permission-toggle input:disabled + .permission-box {
      opacity: 0.62;
      cursor: not-allowed;
    }

    .permission-box.disabled {
      background: rgba(88, 115, 220, 0.10);
      border-color: rgba(88, 115, 220, 0.16);
    }

    .role-col-hidden {
      display: none !important;
    }

    .role-permission-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 14px;
    }

    .role-warning-text {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      color: #9c6b12;
      font-size: 13px;
      font-weight: 800;
    }

    .user-access-filter {
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      padding: 18px;
      background: #ffffff;
    }

    .user-access-table {
      min-width: 760px;
    }

    .user-cell {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 210px;
    }

    .user-avatar {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      color: #ffffff;
      font-weight: 900;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 10px 22px rgba(88, 115, 220, 0.18);
    }

    .user-name {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.25;
    }

    .user-id,
    .user-email {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
    }

    .access-switch {
      position: relative;
      display: inline-flex;
      width: 54px;
      height: 30px;
      cursor: pointer;
    }

    .access-switch input {
      display: none;
    }

    .access-slider {
      position: absolute;
      inset: 0;
      border-radius: 999px;
      background: #dfe7ef;
      transition: 0.2s ease;
    }

    .access-slider::before {
      content: "";
      position: absolute;
      width: 24px;
      height: 24px;
      left: 3px;
      top: 3px;
      border-radius: 999px;
      background: #ffffff;
      box-shadow: 0 4px 10px rgba(22, 43, 77, 0.18);
      transition: 0.2s ease;
    }

    .access-switch input:checked + .access-slider {
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
    }

    .access-switch input:checked + .access-slider::before {
      transform: translateX(24px);
    }

    .role-empty-state {
      text-align: center;
      padding: 44px 20px;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .role-empty-state i {
      display: block;
      color: var(--mf-primary);
      font-size: 46px;
      margin-bottom: 10px;
    }

    .role-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .role-empty-state p {
      margin-bottom: 0;
    }

    .role-modal-note {
      display: grid;
      grid-template-columns: 34px 1fr;
      gap: 10px;
      align-items: flex-start;
      border-radius: 18px;
      padding: 13px;
      background: rgba(88, 115, 220, 0.08);
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.6;
    }

    .role-modal-note i {
      color: var(--mf-primary);
      font-size: 22px;
      margin-top: 2px;
    }

    @media (max-width: 1200px) {
      .role-list-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .role-summary-grid {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }
    }

    @media (max-width: 992px) {
      .role-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .role-hero-actions,
      .role-hero-badge {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .role-hero-card {
        padding: 26px 22px;
      }

      .role-hero-left {
        flex-direction: column;
      }

      .role-hero-badge {
        min-height: 50px;
      }

      .role-card-head {
        align-items: stretch;
      }

      .role-head-actions,
      .role-head-actions .btn {
        width: 100%;
      }

      .role-management-card .card-header,
      .role-permission-card .card-header,
      .user-access-card .card-header,
      .role-management-body,
      .role-permission-body,
      .user-access-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .role-list-grid,
      .role-summary-grid {
        grid-template-columns: 1fr;
      }

      .role-table-wrap,
      .user-table-wrap {
        margin-left: 22px;
        margin-right: 22px;
      }

      .role-info-card,
      .role-note-panel {
        grid-template-columns: 1fr;
      }
    }
  </style>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      const pageTabButtons = document.querySelectorAll('[data-role-page-tab]');
      const permissionTabs = document.querySelectorAll('[data-role-filter-trigger]');
      const roleColumns = document.querySelectorAll('.role-col');
      const openTabButtons = document.querySelectorAll('[data-open-tab]');

      function setRoleFilter(filter) {
        permissionTabs.forEach(function(tab) {
          tab.classList.toggle('active', tab.dataset.roleFilterTrigger === filter);
        });

        roleColumns.forEach(function(col) {
          if (filter === 'all') {
            col.classList.remove('role-col-hidden');
            return;
          }

          if (col.classList.contains('role-col-' + filter)) {
            col.classList.remove('role-col-hidden');
          } else {
            col.classList.add('role-col-hidden');
          }
        });
      }

      function openPageTab(tabKey) {
        const button = document.querySelector('[data-role-page-tab="' + tabKey + '"]');

        if (!button) {
          return;
        }

        const tab = new bootstrap.Tab(button);
        tab.show();
      }

      pageTabButtons.forEach(function(button) {
        button.addEventListener('shown.bs.tab', function() {
          const tabKey = button.dataset.rolePageTab;
          const url = new URL(window.location.href);

          url.searchParams.set('tab', tabKey);

          if (tabKey !== 'users') {
            url.searchParams.delete('search');
            url.searchParams.delete('role');
            url.searchParams.delete('page');
          }

          window.history.replaceState({}, '', url.toString());
        });
      });

      permissionTabs.forEach(function(tab) {
        tab.addEventListener('click', function() {
          setRoleFilter(this.dataset.roleFilterTrigger);
        });
      });

      openTabButtons.forEach(function(button) {
        button.addEventListener('click', function() {
          const tabKey = button.dataset.openTab;
          const filterRole = button.dataset.filterRole || 'all';

          openPageTab(tabKey);

          if (tabKey === 'permissions') {
            setTimeout(function() {
              setRoleFilter(filterRole);
            }, 120);
          }
        });
      });
    });
  </script>
@endsection