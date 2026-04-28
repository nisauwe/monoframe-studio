@extends('layouts/contentNavbarLayout')

@section('title', 'Users')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">

      {{-- HERO HEADER --}}
      <div class="user-hero-card mb-4">
        <div class="user-hero-left">
          <div class="user-hero-icon">
            <i class="bx bx-group"></i>
          </div>

          <div>
            <div class="user-hero-kicker">MANAJEMEN AKUN</div>
            <h4>Manajemen User</h4>
            <p>
              Kelola data user Monoframe Studio berdasarkan nama, email, role,
              dan akses pengguna agar operasional admin, front office, fotografer,
              editor, dan klien tetap tertata rapi.
            </p>
          </div>
        </div>

        <div class="user-hero-actions">
          <a href="{{ route('admin.users.create') }}" class="btn user-hero-btn">
            <i class="bx bx-plus me-1"></i>
            Tambah User
          </a>
        </div>
      </div>

      {{-- ALERT SUCCESS --}}
      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      @endif

      {{-- STAT CARDS --}}
      <div class="row g-4 mb-4">
        <div class="col-md-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">Total User</div>
                  <div class="stat-number">{{ $totalUsers }}</div>
                  <div class="stat-helper">Seluruh user terdaftar</div>
                </div>

                <div class="stat-icon">
                  <i class="bx bx-group"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">User Baru</div>
                  <div class="stat-number">{{ $newUsers }}</div>
                  <div class="stat-helper">User baru bulan ini</div>
                </div>

                <div class="stat-icon info">
                  <i class="bx bx-user-plus"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start gap-3">
                <div>
                  <div class="stat-label">User Aktif</div>
                  <div class="stat-number">{{ $activeUsers }}</div>
                  <div class="stat-helper">Akun yang aktif digunakan</div>
                </div>

                <div class="stat-icon success">
                  <i class="bx bx-user-check"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {{-- USER TABLE CARD --}}
      <div class="card section-card user-index-card">
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
            <div>
              <h5 class="section-title">Daftar User</h5>
              <p class="section-subtitle mb-0">
                Cari, filter, tambah, edit, atau hapus user sesuai kebutuhan admin.
              </p>
            </div>

            <div class="mf-badge-total">
              <i class="bx bx-user"></i>
              {{ $users->total() ?? $users->count() }} user tampil
            </div>
          </div>
        </div>

        <div class="card-body user-filter-body">
          <div class="user-toolbar">
            <form method="GET" action="{{ route('admin.users.index') }}" id="filterForm" class="user-filter-form">
              <div class="row g-3 align-items-center">
                <div class="col-lg-5 col-md-6">
                  <label class="form-label">Pencarian User</label>
                  <div class="input-group user-search-group">
                    <span class="input-group-text">
                      <i class="bx bx-search"></i>
                    </span>
                    <input
                      type="text"
                      name="search"
                      class="form-control"
                      placeholder="Cari nama atau email..."
                      value="{{ $search ?? '' }}">
                  </div>
                </div>

                <div class="col-lg-3 col-md-6">
                  <label class="form-label">Filter Role</label>
                  <select name="role" class="form-select user-filter-select" onchange="this.form.submit()">
                    <option value="">Semua Role</option>
                    <option value="Admin" {{ ($role ?? '') == 'Admin' ? 'selected' : '' }}>Admin</option>
                    <option value="Front Office" {{ ($role ?? '') == 'Front Office' ? 'selected' : '' }}>Front Office</option>
                    <option value="Fotografer" {{ ($role ?? '') == 'Fotografer' ? 'selected' : '' }}>Fotografer</option>
                    <option value="Editor" {{ ($role ?? '') == 'Editor' ? 'selected' : '' }}>Editor</option>
                    <option value="Klien" {{ ($role ?? '') == 'Klien' ? 'selected' : '' }}>Klien</option>
                  </select>
                </div>

                <div class="col-lg-4 col-md-12">
                  <label class="form-label d-none d-lg-block">&nbsp;</label>
                  <div class="d-flex flex-wrap justify-content-lg-end gap-2 user-filter-actions">
                    <button type="submit" class="btn btn-primary">
                      <i class="bx bx-search me-1"></i>
                      Cari
                    </button>

                    <a href="{{ route('admin.users.index') }}" class="btn btn-outline-secondary">
                      Refresh
                    </a>
                  </div>
                </div>
              </div>
            </form>

            <div class="user-action-row">
              <form
                action="{{ route('admin.users.reset') }}"
                method="POST"
                onsubmit="return confirm('Yakin ingin menghapus semua user selain Admin? Data Admin tidak akan dihapus.');">
                @csrf
                @method('DELETE')

                <button type="submit" class="btn btn-outline-secondary">
                  <i class="bx bx-refresh me-1"></i>
                  Reset Data Non-Admin
                </button>
              </form>

              <a
                href="{{ route('admin.users.export.excel', request()->query()) }}"
                class="btn btn-outline-success">
                <i class="bx bx-table me-1"></i>
                Export Excel
              </a>

              <a
                href="{{ route('admin.users.export.pdf', request()->query()) }}"
                class="btn btn-outline-danger">
                <i class="bx bx-file me-1"></i>
                Export PDF
              </a>
            </div>
          </div>
        </div>

        <div class="user-table-wrap">
          <div class="table-responsive">
            <table class="table user-table">
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
                  @php
                    $roleClass = match ($user->role) {
                        'Admin' => 'bg-label-primary',
                        'Front Office' => 'bg-label-info',
                        'Fotografer' => 'bg-label-warning',
                        'Editor' => 'bg-label-success',
                        'Klien' => 'bg-label-secondary',
                        default => 'bg-label-primary',
                    };

                    $nameParts = preg_split('/\s+/', trim($user->name));
                    $initial = '';

                    if (!empty($nameParts[0])) {
                        $initial .= mb_substr($nameParts[0], 0, 1);
                    }

                    if (!empty($nameParts[1])) {
                        $initial .= mb_substr($nameParts[1], 0, 1);
                    }

                    $initial = strtoupper($initial ?: 'U');
                  @endphp

                  <tr>
                    <td>
                      <div class="user-info-cell">
                        <div class="user-avatar-initial">
                          {{ $initial }}
                        </div>

                        <div>
                          <div class="user-name">
                            {{ $user->name }}
                          </div>
                          <div class="user-subtext">
                            ID User #{{ $user->id }}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td>
                      <div class="user-email">
                        {{ $user->email }}
                      </div>
                    </td>

                    <td>
                      <span class="badge {{ $roleClass }}">
                        {{ $user->role }}
                      </span>
                    </td>

                    <td>
                      <div class="user-date">
                        {{ $user->created_at->format('d M Y') }}
                      </div>
                    </td>

                    <td>
                      <div class="d-flex flex-wrap gap-2">
                        <a href="{{ route('admin.users.edit', $user->id) }}" class="btn btn-outline-primary btn-sm">
                          <i class="bx bx-edit-alt me-1"></i>
                          Edit
                        </a>

                        <form
                          action="{{ route('admin.users.destroy', $user->id) }}"
                          method="POST"
                          onsubmit="return confirm('Yakin ingin menghapus user ini?');">
                          @csrf
                          @method('DELETE')

                          <button type="submit" class="btn btn-outline-danger btn-sm">
                            <i class="bx bx-trash me-1"></i>
                            Hapus
                          </button>
                        </form>
                      </div>
                    </td>
                  </tr>
                @empty
                  <tr>
                    <td colspan="5">
                      <div class="user-empty-state">
                        <i class="bx bx-user-x"></i>
                        <h6>Belum ada data user</h6>
                        <p>Data user akan tampil setelah admin menambahkan atau user terdaftar di sistem.</p>
                        <a href="{{ route('admin.users.create') }}" class="btn btn-primary">
                          <i class="bx bx-plus me-1"></i>
                          Tambah User
                        </a>
                      </div>
                    </td>
                  </tr>
                @endforelse
              </tbody>
            </table>
          </div>
        </div>

        <div class="card-footer user-pagination-footer">
          {{ $users->appends(request()->query())->links() }}
        </div>
      </div>
    </div>
  </div>

  <style>
    .user-hero-card {
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

    .user-hero-card::after {
      content: "";
      position: absolute;
      width: 260px;
      height: 260px;
      right: -90px;
      bottom: -130px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.14);
    }

    .user-hero-left {
      position: relative;
      z-index: 2;
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
      max-width: 940px;
    }

    .user-hero-icon {
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

    .user-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .user-hero-card h4 {
      color: #ffffff;
      font-size: 30px;
      font-weight: 900;
      line-height: 1.2;
      margin-bottom: 10px;
    }

    .user-hero-card p {
      color: rgba(255, 255, 255, 0.86);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .user-hero-actions {
      position: relative;
      z-index: 2;
      flex-shrink: 0;
    }

    .user-hero-btn {
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
      white-space: nowrap;
      box-shadow: 0 16px 30px rgba(22, 43, 77, 0.16);
      transition: 0.2s ease;
    }

    .user-hero-btn:hover {
      background: #ffffff;
      color: var(--mf-primary);
      transform: translateY(-2px);
      box-shadow: 0 20px 36px rgba(22, 43, 77, 0.18);
    }

    .user-index-card .card-header {
      padding: 30px 34px 22px !important;
    }

    .user-filter-body {
      padding: 24px 34px 26px !important;
      border-bottom: 1px solid var(--mf-border);
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.18), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .user-toolbar {
      display: flex;
      flex-direction: column;
      gap: 18px;
    }

    .user-filter-form {
      width: 100%;
    }

    .user-filter-form .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .user-search-group {
      height: 52px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      overflow: hidden;
      background: #ffffff;
      transition: 0.18s ease;
    }

    .user-search-group:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .user-search-group .input-group-text {
      width: 58px;
      min-width: 58px;
      height: 100%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border: 0;
      border-right: 1px solid var(--mf-border);
      background: #ffffff;
      color: var(--mf-ink);
      font-size: 20px;
    }

    .user-search-group .form-control {
      height: 100% !important;
      border: 0 !important;
      border-radius: 0 !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      padding: 0 18px !important;
      box-shadow: none !important;
      outline: none !important;
    }

    .user-search-group .form-control::placeholder {
      color: rgba(107, 124, 147, 0.62) !important;
      font-size: 14px !important;
      font-weight: 700 !important;
    }

    .user-filter-select {
      height: 52px !important;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      background: #ffffff !important;
      color: var(--mf-ink) !important;
      font-size: 14px !important;
      font-weight: 800 !important;
      box-shadow: none !important;
    }

    .user-filter-select:focus {
      border-color: rgba(88, 115, 220, 0.48) !important;
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10) !important;
    }

    .user-filter-actions .btn,
    .user-action-row .btn {
      min-height: 46px;
      border-radius: 15px;
      font-weight: 900;
      padding-left: 16px;
      padding-right: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .user-action-row {
      display: flex;
      justify-content: flex-end;
      align-items: center;
      flex-wrap: wrap;
      gap: 10px;
    }

    .user-table-wrap {
      margin: 28px 34px 30px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      overflow: hidden;
      background: #ffffff;
    }

    .user-table thead th {
      padding: 20px 22px !important;
    }

    .user-table tbody td {
      padding: 22px !important;
    }

    .user-info-cell {
      display: flex;
      align-items: center;
      gap: 14px;
      min-width: 220px;
    }

    .user-avatar-initial {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      color: #ffffff;
      font-weight: 900;
      box-shadow: 0 12px 24px rgba(88, 115, 220, 0.18);
    }

    .user-name {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.35;
    }

    .user-subtext {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 600;
      margin-top: 3px;
    }

    .user-email,
    .user-date {
      color: var(--mf-ink);
      font-weight: 700;
      white-space: nowrap;
    }

    .user-empty-state {
      padding: 46px 20px;
      text-align: center;
      color: var(--mf-muted);
    }

    .user-empty-state i {
      display: block;
      font-size: 48px;
      color: var(--mf-primary);
      margin-bottom: 12px;
    }

    .user-empty-state h6 {
      font-weight: 900;
      margin-bottom: 6px;
    }

    .user-empty-state p {
      margin: 0 auto 18px;
      max-width: 420px;
      line-height: 1.7;
    }

    .user-pagination-footer {
      padding: 20px 34px 28px !important;
    }

    @media (max-width: 992px) {
      .user-hero-card {
        align-items: flex-start;
        flex-direction: column;
      }

      .user-hero-actions,
      .user-hero-btn {
        width: 100%;
      }
    }

    @media (max-width: 768px) {
      .user-hero-card {
        padding: 26px 22px;
      }

      .user-hero-left {
        flex-direction: column;
      }

      .user-hero-btn {
        min-height: 50px;
      }

      .user-index-card .card-header,
      .user-filter-body,
      .user-pagination-footer {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .user-table-wrap {
        margin: 22px;
      }

      .user-action-row {
        justify-content: flex-start;
      }

      .user-action-row .btn,
      .user-action-row form,
      .user-filter-actions .btn {
        width: 100%;
      }

      .user-filter-actions {
        flex-direction: column;
      }

      .user-info-cell {
        min-width: 180px;
      }
    }
  </style>
@endsection