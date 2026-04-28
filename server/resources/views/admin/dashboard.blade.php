@extends('layouts.contentNavbarLayout')

@section('title', 'Dashboard Admin')

@section('content')

  @php
    $adminName = auth()->user()->name ?? auth()->user()->username ?? 'Admin';
    $todayLabel = \Carbon\Carbon::now()->translatedFormat('l, d F Y');
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell">
      <div class="dashboard-heading">
        <div>
          <h4 class="dashboard-title">Dashboard Admin</h4>
          <p class="dashboard-date">{{ $todayLabel }}</p>
        </div>

        <div class="dashboard-top-action">
          <i class="bx bx-bell"></i>
          <span>Pusat Monitoring Studio</span>
        </div>
      </div>

      <div class="card greeting-card">
        <div class="greeting-content">
          <div>
            <div class="greeting-eyebrow">
              <i class="bx bx-sparkles"></i>
              MONOFRAME STUDIO
            </div>
            <h2 class="greeting-title">Hi, {{ $adminName }}</h2>
            <p class="greeting-subtitle">
              Siap memantau operasional studio hari ini? Lihat ringkasan booking, pembayaran,
              jadwal, review, dan seluruh aktivitas pengguna dalam satu dashboard.
            </p>
          </div>

          <div class="greeting-visual">
            <span class="greeting-bubble one"></span>
            <span class="greeting-bubble two"></span>
            <span class="greeting-bubble three"></span>

            <div class="greeting-logo-circle">
              <img src="{{ asset('assets/img/logo/monoframe-logo.png') }}" alt="Monoframe Logo">
            </div>

            <div class="greeting-camera-card">
              <i class="bx bx-camera"></i>
            </div>
          </div>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 col-lg-3 mb-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <div class="stat-label">Booking Aktif</div>
                  <h3 class="stat-number">{{ $bookingAktif }}</h3>
                  <div class="stat-helper">Sudah DP atau sudah lunas</div>
                </div>
                <div class="stat-icon">
                  <i class="bx bx-calendar-check"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-6 col-lg-3 mb-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <div class="stat-label">Belum Bayar</div>
                  <h3 class="stat-number">{{ $belumBayar }}</h3>
                  <div class="stat-helper">Menunggu pembayaran</div>
                </div>
                <div class="stat-icon warning">
                  <i class="bx bx-wallet"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-6 col-lg-3 mb-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <div class="stat-label">Jadwal Hari Ini</div>
                  <h3 class="stat-number">{{ $jadwalHariIni }}</h3>
                  <div class="stat-helper">Sesi pemotretan hari ini</div>
                </div>
                <div class="stat-icon info">
                  <i class="bx bx-time-five"></i>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-6 col-lg-3 mb-4">
          <div class="card stat-card h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start">
                <div>
                  <div class="stat-label">Review</div>
                  <h3 class="stat-number">{{ $reviewCount }}</h3>
                  <div class="stat-helper">Ulasan dari klien</div>
                </div>
                <div class="stat-icon success">
                  <i class="bx bx-star"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {{-- RINGKASAN KEUANGAN --}}
      <div class="card section-card finance-card">
        <div class="card-header">
          <h5 class="section-title">Ringkasan Keuangan</h5>
          <div class="section-subtitle">Pemasukan dan pengeluaran operasional studio</div>
        </div>

        <div class="card-body">
          <div class="row">
            <div class="col-md-4 mb-3 mb-md-0">
              <div class="finance-item">
                <div class="finance-icon">
                  <i class="bx bx-trending-up"></i>
                </div>
                <span class="finance-label">Pemasukan Hari Ini</span>
                <h4 class="finance-value">
                  Rp {{ number_format($pemasukanHariIni, 0, ',', '.') }}
                </h4>
              </div>
            </div>

            <div class="col-md-4 mb-3 mb-md-0">
              <div class="finance-item">
                <div class="finance-icon">
                  <i class="bx bx-trending-down"></i>
                </div>
                <span class="finance-label">Pengeluaran Hari Ini</span>
                <h4 class="finance-value">
                  Rp {{ number_format($pengeluaranHariIni, 0, ',', '.') }}
                </h4>
              </div>
            </div>

            <div class="col-md-4">
              <div class="finance-item">
                <div class="finance-icon">
                  <i class="bx bx-credit-card"></i>
                </div>
                <span class="finance-label">Saldo Keseluruhan</span>
                <h4 class="finance-value">
                  Rp {{ number_format($saldoKeseluruhan, 0, ',', '.') }}
                </h4>
              </div>
            </div>
          </div>
        </div>
      </div>

      {{-- 10 AKTIVITAS TERBARU --}}
      <div class="card section-card activity-card">
        <div class="card-header activity-card-header">
          <div class="activity-card-title-wrap">
            <h5 class="section-title">Notifikasi & Aktivitas User</h5>
            <div class="section-subtitle">
              Menampilkan 10 aktivitas terbaru. Klik selengkapnya untuk melihat semua aktivitas.
            </div>
          </div>

          <div class="mf-badge-total activity-total-badge">
            <i class="bx bx-bell"></i>
            {{ $activityNotifications->count() }} total aktivitas
          </div>
        </div>

        <div class="table-responsive">
          <table class="table align-middle">
            <thead>
              <tr>
                <th>Nama</th>
                <th>Role</th>
                <th>Aktivitas</th>
                <th>Tanggal</th>
                <th>Jam</th>
              </tr>
            </thead>

            <tbody class="table-border-bottom-0">
              @forelse ($activityNotificationsPreview as $activity)
                @php
                  $role = $activity['role'] ?? '-';

                  $roleBadge = match ($role) {
                    'Klien' => 'primary',
                    'Front Office' => 'info',
                    'Fotografer' => 'warning',
                    'Editor' => 'success',
                    'Admin' => 'secondary',
                    default => 'secondary',
                  };

                  $occurredAt = $activity['occurred_at'] instanceof \Carbon\Carbon
                    ? $activity['occurred_at']
                    : \Carbon\Carbon::parse($activity['occurred_at']);
                @endphp

                <tr>
                  <td>
                    <span class="activity-name">{{ $activity['name'] ?? '-' }}</span>
                  </td>

                  <td>
                    <span class="badge bg-label-{{ $roleBadge }}">
                      {{ $role }}
                    </span>
                  </td>

                  <td class="activity-cell">
                    {{ $activity['activity'] ?? '-' }}
                  </td>

                  <td>
                    <span class="activity-time">
                      {{ $occurredAt->translatedFormat('d F Y') }}
                    </span>
                  </td>

                  <td>
                    <span class="activity-time">
                      {{ $occurredAt->format('H:i') }}
                    </span>
                  </td>
                </tr>
              @empty
                <tr>
                  <td colspan="5">
                    <div class="activity-empty">
                      <i class="bx bx-bell-off"></i>
                      Belum ada aktivitas user yang dapat ditampilkan.
                    </div>
                  </td>
                </tr>
              @endforelse
            </tbody>
          </table>
        </div>

        @if ($activityNotifications->count() > 5)
          <div class="activity-more-wrap">
            <button type="button"
              class="btn btn-primary"
              data-bs-toggle="modal"
              data-bs-target="#allActivityModal">
              <i class="bx bx-list-ul me-1"></i>
              Selengkapnya
            </button>
          </div>
        @endif
      </div>
    </div>
  </div>

  {{-- POPUP SEMUA AKTIVITAS --}}
  <div class="modal fade" id="allActivityModal" tabindex="-1" aria-labelledby="allActivityModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
      <div class="modal-content activity-modal-content">
        <div class="modal-header activity-modal-header">
          <div>
            <h5 class="modal-title text-white mb-1" id="allActivityModalLabel">
              Semua Aktivitas User
            </h5>
            <small class="text-white opacity-75">
              Cari aktivitas berdasarkan nama user dan filter berdasarkan tanggal.
            </small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body activity-modal-body">
          <div class="activity-filter-card">
            <form id="activitySearchForm" class="row g-3 align-items-end">
              <div class="col-lg-5">
                <label class="form-label">Search Nama User / Klien</label>
                <input type="text"
                  id="activitySearchInput"
                  class="form-control"
                  placeholder="Ketik nama user, lalu tekan Enter.">
              </div>

              <div class="col-lg-3">
                <label class="form-label">Tanggal Mulai</label>
                <input type="date" id="activityDateFrom" class="form-control">
              </div>

              <div class="col-lg-3">
                <label class="form-label">Tanggal Akhir</label>
                <input type="date" id="activityDateTo" class="form-control">
              </div>

              <div class="col-lg-1">
                <button type="button" id="activityRefreshFilter" class="btn btn-outline-secondary w-100">
                  Refresh
                </button>
              </div>

              <div class="col-12 d-flex justify-content-between align-items-center flex-wrap gap-2">
                <span class="activity-count-pill">
                  <i class="bx bx-bell"></i>
                  <span id="activityVisibleCount">{{ $activityNotifications->count() }}</span>
                  aktivitas tampil
                </span>
              </div>
            </form>
          </div>

          <div class="activity-modal-table-wrap">
            <div class="table-responsive activity-modal-scroll">
              <table class="table align-middle mb-0" id="allActivityTable">
                <thead>
                  <tr>
                    <th>Nama</th>
                    <th>Role</th>
                    <th>Aktivitas</th>
                    <th>Tanggal</th>
                    <th>Jam</th>
                  </tr>
                </thead>

                <tbody>
                  @forelse ($activityNotifications as $activity)
                    @php
                      $role = $activity['role'] ?? '-';

                      $roleBadge = match ($role) {
                        'Klien' => 'primary',
                        'Front Office' => 'info',
                        'Fotografer' => 'warning',
                        'Editor' => 'success',
                        'Admin' => 'secondary',
                        default => 'secondary',
                      };

                      $occurredAt = $activity['occurred_at'] instanceof \Carbon\Carbon
                        ? $activity['occurred_at']
                        : \Carbon\Carbon::parse($activity['occurred_at']);

                      $searchText = strtolower(
                        ($activity['name'] ?? '') . ' ' .
                        ($activity['role'] ?? '') . ' ' .
                        ($activity['activity'] ?? '')
                      );
                    @endphp

                    <tr class="js-activity-row"
                        data-name="{{ e(strtolower($activity['name'] ?? '')) }}"
                        data-search="{{ e($searchText) }}"
                        data-date="{{ $occurredAt->format('Y-m-d') }}">
                      <td>
                        <span class="activity-name">{{ $activity['name'] ?? '-' }}</span>
                      </td>

                      <td>
                        <span class="badge bg-label-{{ $roleBadge }}">
                          {{ $role }}
                        </span>
                      </td>

                      <td class="activity-cell">
                        {{ $activity['activity'] ?? '-' }}
                      </td>

                      <td>
                        <span class="activity-time">
                          {{ $occurredAt->translatedFormat('d F Y') }}
                        </span>
                      </td>

                      <td>
                        <span class="activity-time">
                          {{ $occurredAt->format('H:i') }}
                        </span>
                      </td>
                    </tr>
                  @empty
                    <tr>
                      <td colspan="5" class="text-center text-muted py-4">
                        Belum ada aktivitas user.
                      </td>
                    </tr>
                  @endforelse
                </tbody>
              </table>
            </div>
          </div>

          <div id="activityFilterEmpty" class="activity-filter-empty">
            <i class="bx bx-search-alt d-block mb-2" style="font-size: 38px;"></i>
            Tidak ada aktivitas yang cocok dengan filter.
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            Tutup
          </button>
        </div>
      </div>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function () {
      const modal = document.getElementById('allActivityModal');
      const searchForm = document.getElementById('activitySearchForm');
      const searchInput = document.getElementById('activitySearchInput');
      const dateFromInput = document.getElementById('activityDateFrom');
      const dateToInput = document.getElementById('activityDateTo');
      const refreshButton = document.getElementById('activityRefreshFilter');
      const visibleCount = document.getElementById('activityVisibleCount');
      const emptyState = document.getElementById('activityFilterEmpty');

      function normalizeText(value) {
        return (value || '').toString().toLowerCase().trim();
      }

      function getActivityRows() {
        return Array.from(document.querySelectorAll('#allActivityModal .js-activity-row'));
      }

      function setVisibleCount(total) {
        if (visibleCount) {
          visibleCount.textContent = total;
        }
      }

      function setEmptyState(total) {
        if (emptyState) {
          emptyState.style.display = total === 0 ? 'block' : 'none';
        }
      }

      function showRow(row) {
        row.hidden = false;
        row.style.removeProperty('display');
      }

      function hideRow(row) {
        row.hidden = true;
        row.style.display = 'none';
      }

      function showAllActivities() {
        const rows = getActivityRows();

        rows.forEach(function (row) {
          showRow(row);
        });

        setVisibleCount(rows.length);
        setEmptyState(rows.length);
      }

      function applyActivityFilter() {
        const rows = getActivityRows();

        const keyword = normalizeText(searchInput ? searchInput.value : '');
        const dateFrom = dateFromInput ? dateFromInput.value : '';
        const dateTo = dateToInput ? dateToInput.value : '';

        let totalVisible = 0;

        rows.forEach(function (row) {
          const rowName = normalizeText(row.dataset.name || '');
          const rowDate = row.dataset.date || '';

          const matchName = keyword === '' || rowName.includes(keyword);
          const matchFrom = dateFrom === '' || rowDate >= dateFrom;
          const matchTo = dateTo === '' || rowDate <= dateTo;

          const shouldShow = matchName && matchFrom && matchTo;

          if (shouldShow) {
            showRow(row);
            totalVisible++;
          } else {
            hideRow(row);
          }
        });

        setVisibleCount(totalVisible);
        setEmptyState(totalVisible);
      }

      function refreshActivityFilter() {
        if (searchForm) {
          searchForm.refresh();
        }

        if (searchInput) {
          searchInput.value = '';
        }

        if (dateFromInput) {
          dateFromInput.value = '';
        }

        if (dateToInput) {
          dateToInput.value = '';
        }

        showAllActivities();

        if (searchInput) {
          searchInput.focus();
        }
      }

      if (searchForm) {
        searchForm.addEventListener('submit', function (event) {
          event.preventDefault();
          applyActivityFilter();
        });
      }

      if (searchInput) {
        searchInput.addEventListener('keydown', function (event) {
          if (event.key === 'Enter') {
            event.preventDefault();
            applyActivityFilter();
          }
        });
      }

      if (dateFromInput) {
        dateFromInput.addEventListener('change', applyActivityFilter);
      }

      if (dateToInput) {
        dateToInput.addEventListener('change', applyActivityFilter);
      }

      if (refreshButton) {
        refreshButton.addEventListener('click', function (event) {
          event.preventDefault();
          event.stopPropagation();
          refreshActivityFilter();
        });
      }

      if (modal) {
        modal.addEventListener('shown.bs.modal', function () {
          refreshActivityFilter();
        });
      }
    });
  </script>
@endsection
