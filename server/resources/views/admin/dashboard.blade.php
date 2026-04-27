@extends('layouts.contentNavbarLayout')

@section('title', 'Dashboard Admin')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">

    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h4 class="fw-bold mb-1">Dashboard Admin</h4>
        <p class="text-muted mb-0">Ringkasan operasional Monoframe Studio hari ini.</p>
      </div>
    </div>

    <div class="row">
      <div class="col-md-6 col-lg-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Booking Aktif</span>
                <h3 class="card-title mb-2">{{ $bookingAktif }}</h3>
                <small class="text-success fw-semibold">Sudah DP atau sudah lunas</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-primary">
                  <i class="bx bx-calendar-check"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Belum Bayar</span>
                <h3 class="card-title mb-2">{{ $belumBayar }}</h3>
                <small class="text-warning fw-semibold">Menunggu pembayaran</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-warning">
                  <i class="bx bx-wallet"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Jadwal Hari Ini</span>
                <h3 class="card-title mb-2">{{ $jadwalHariIni }}</h3>
                <small class="text-info fw-semibold">Sesi pemotretan hari ini</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-info">
                  <i class="bx bx-time-five"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-lg-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <div>
                <span class="text-muted d-block mb-1">Review</span>
                <h3 class="card-title mb-2">{{ $reviewCount }}</h3>
                <small class="text-success fw-semibold">Ulasan dari klien</small>
              </div>
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-success">
                  <i class="bx bx-star"></i>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-lg-4 col-md-12 mb-4">
        <div class="card h-100">
          <div class="card-header d-flex justify-content-between align-items-center">
            <div>
              <h5 class="card-title mb-0">Quick Access</h5>
              <small class="text-muted">Akses cepat ke menu utama</small>
            </div>
          </div>
          <div class="card-body">
            <div class="d-grid gap-3">
              <a href="{{ route('admin.users.index') }}" class="btn btn-outline-primary">
                <i class="bx bx-user me-1"></i> Kelola User
              </a>

              <a href="{{ route('admin.packages.index') }}" class="btn btn-outline-success">
                <i class="bx bx-box me-1"></i> Kelola Paket
              </a>

              <a href="{{ route('admin.schedules.index') }}" class="btn btn-outline-warning">
                <i class="bx bx-calendar me-1"></i> Kelola Jadwal
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-8 col-md-12 mb-4">
        <div class="card h-100">
          <div class="card-header">
            <h5 class="card-title mb-0">Ringkasan Keuangan</h5>
            <small class="text-muted">Pemasukan dan pengeluaran operasional hari ini</small>
          </div>
          <div class="card-body">
            <div class="row text-center">
              <div class="col-md-4 mb-3 mb-md-0">
                <div class="border rounded p-3 h-100">
                  <span class="text-muted d-block mb-1">Pemasukan Hari Ini</span>
                  <h4 class="mb-0 text-success">Rp {{ number_format($pemasukanHariIni, 0, ',', '.') }}</h4>
                </div>
              </div>

              <div class="col-md-4 mb-3 mb-md-0">
                <div class="border rounded p-3 h-100">
                  <span class="text-muted d-block mb-1">Pengeluaran Hari Ini</span>
                  <h4 class="mb-0 text-danger">Rp {{ number_format($pengeluaranHariIni, 0, ',', '.') }}</h4>
                </div>
              </div>

              <div class="col-md-4">
                <div class="border rounded p-3 h-100">
                  <span class="text-muted d-block mb-1">Saldo Keseluruhan</span>
                  <h4 class="mb-0 text-primary">Rp {{ number_format($saldoKeseluruhan, 0, ',', '.') }}</h4>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-12">
        <div class="card">
          <div class="card-header">
            <h5 class="mb-0">Aktivitas Booking</h5>
            <small class="text-muted">Daftar aktivitas booking terpantau</small>
          </div>
          <div class="table-responsive text-nowrap">
            <table class="table">
              <thead>
                <tr>
                  <th>Nama Klien</th>
                  <th>Paket Foto</th>
                  <th>Tanggal Foto</th>
                  <th>Status Foto</th>
                </tr>
              </thead>
              <tbody class="table-border-bottom-0">
                @forelse ($aktivitasBooking as $booking)
                  <tr>
                    <td>{{ $booking->client_name ?? '-' }}</td>
                    <td>{{ $booking->package->name ?? '-' }}</td>
                    <td>{{ $booking->dashboard_date_label }}</td>
                    <td>
                      <span class="badge bg-label-{{ $booking->dashboard_status_badge }}">
                        {{ $booking->dashboard_status_label }}
                      </span>
                    </td>
                  </tr>
                @empty
                  <tr>
                    <td colspan="4" class="text-center text-muted py-4">
                      Belum ada aktivitas booking.
                    </td>
                  </tr>
                @endforelse
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
@endsection
