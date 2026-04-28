@extends('layouts/contentNavbarLayout')

@section('title', 'Pembayaran & Keuangan')

@section('content')
  @php
    $money = fn ($value) => 'Rp ' . number_format((float) ($value ?? 0), 0, ',', '.');

    $statusOptions = [
        'created' => 'Created',
        'pending' => 'Pending',
        'authorize' => 'Authorize',
        'settlement' => 'Settlement',
        'capture' => 'Capture',
        'expire' => 'Expire',
        'cancel' => 'Cancel',
        'deny' => 'Deny',
        'failure' => 'Failure',
        'failed' => 'Failed',
    ];

    $paymentTypeOptions = [
        'booking' => 'Booking',
        'dp' => 'DP Booking',
        'full' => 'Pelunasan',
        'print' => 'Pembayaran Cetak',
    ];

    $paymentStatusBadge = function ($status) {
        return match ($status) {
            'settlement', 'capture' => 'success',
            'pending', 'created', 'authorize' => 'warning',
            'expire', 'cancel', 'deny', 'failure', 'failed' => 'danger',
            'refund', 'partial_refund' => 'info',
            default => 'secondary',
        };
    };

    $paymentStatusLabel = function ($status) {
        return match ($status) {
            'created' => 'Created',
            'pending' => 'Pending',
            'authorize' => 'Authorize',
            'settlement' => 'Settlement',
            'capture' => 'Capture',
            'expire' => 'Expire',
            'cancel' => 'Cancel',
            'deny' => 'Deny',
            'failure' => 'Failure',
            'failed' => 'Failed',
            'refund' => 'Refund',
            'partial_refund' => 'Partial Refund',
            default => ucfirst($status ?: '-'),
        };
    };

    $paymentTypeLabel = function ($payment) {
        if ($payment->print_order_id || in_array($payment->payment_context, ['print', 'print_order'], true)) {
            return 'Bayar Cetak';
        }

        if ($payment->payment_stage === 'dp') {
            return 'DP Booking';
        }

        if ($payment->payment_stage === 'full') {
            return 'Pelunasan';
        }

        return 'Booking';
    };

    $paymentTypeBadge = function ($payment) {
        if ($payment->print_order_id || in_array($payment->payment_context, ['print', 'print_order'], true)) {
            return 'dark';
        }

        if ($payment->payment_stage === 'dp') {
            return 'info';
        }

        if ($payment->payment_stage === 'full') {
            return 'success';
        }

        return 'primary';
    };

    $bookingPaymentBadge = function ($booking) {
        if (!$booking) {
            return 'secondary';
        }

        if ($booking->isFullyPaid()) {
            return 'success';
        }

        if ($booking->isDpPaid()) {
            return 'info';
        }

        return 'danger';
    };

    $bookingPaymentLabel = function ($booking) {
        if (!$booking) {
            return '-';
        }

        if ($booking->isFullyPaid()) {
            return 'Lunas';
        }

        if ($booking->isDpPaid()) {
            return 'DP Terbayar';
        }

        return 'Belum Bayar DP';
    };

    $clientName = function ($booking) {
        return $booking?->clientUser?->name ?? $booking?->client_name ?? 'Klien';
    };

    $clientPhone = function ($booking) {
        return $booking?->clientUser?->phone ?? $booking?->client_phone ?? '-';
    };
  @endphp

  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="dashboard-shell payment-page">

      @if (session('success'))
        <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-check-circle me-1"></i>
          {{ session('success') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      @if (session('error'))
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <i class="bx bx-error-circle me-1"></i>
          {{ session('error') }}
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      @if ($errors->any())
        <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
          <strong>Data belum valid.</strong>
          <ul class="mb-0 mt-2 ps-3">
            @foreach ($errors->all() as $error)
              <li>{{ $error }}</li>
            @endforeach
          </ul>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      {{-- HERO --}}
      <div class="payment-hero-card mb-4">
        <div class="payment-hero-left">
          <div class="payment-hero-icon">
            <i class="bx bx-wallet"></i>
          </div>

          <div>
            <div class="payment-hero-kicker">Akses Keuangan Studio</div>
            <h4>Monitoring Keuangan</h4>
            <p>
              Pantau pembayaran booking, DP, pelunasan, pembayaran cetak, pemasukan manual,
              pengeluaran studio, dan saldo bersih Monoframe Studio.
            </p>
          </div>
        </div>

        <div class="payment-hero-actions">
          <button type="button" class="btn btn-light" data-bs-toggle="modal" data-bs-target="#incomeModal">
            <i class="bx bx-plus-circle me-1"></i>
            Tambah Pemasukan
          </button>

          <button type="button" class="btn btn-outline-light" data-bs-toggle="modal" data-bs-target="#expenseModal">
            <i class="bx bx-minus-circle me-1"></i>
            Tambah Pengeluaran
          </button>
        </div>
      </div>

      {{-- PERIODE --}}
      <div class="payment-period-card mb-4">
        <form method="GET" action="{{ route('admin.payments.index') }}" class="payment-period-form">
          <div>
            <h6>Periode Keuangan</h6>
            <p>
              Ringkasan dihitung dari
              <strong>{{ $dateFrom->translatedFormat('d F Y') }}</strong>
              sampai
              <strong>{{ $dateTo->translatedFormat('d F Y') }}</strong>.
            </p>
          </div>

          <div class="payment-period-controls">
            <div>
              <label class="form-label">Dari Tanggal</label>
              <input type="date" name="date_from" class="form-control" value="{{ request('date_from', $dateFrom->toDateString()) }}">
            </div>

            <div>
              <label class="form-label">Sampai Tanggal</label>
              <input type="date" name="date_to" class="form-control" value="{{ request('date_to', $dateTo->toDateString()) }}">
            </div>

            <div class="payment-period-buttons">
              <button type="submit" class="btn btn-primary">
                <i class="bx bx-filter-alt me-1"></i>
                Terapkan
              </button>

              <a href="{{ route('admin.payments.index') }}" class="btn btn-outline-secondary">
                Reset
              </a>
            </div>
          </div>
        </form>
      </div>

      {{-- RINGKASAN KEUANGAN --}}
      <div class="row g-4 mb-4">
        <div class="col-xl-3 col-md-6">
          <div class="payment-finance-card">
            <div>
              <span>Total Pemasukan</span>
              <h3>{{ $money($totalIncome) }}</h3>
              <p>Payment sukses + pemasukan manual</p>
            </div>

            <div class="payment-finance-icon bg-label-success">
              <i class="bx bx-trending-up"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-finance-card">
            <div>
              <span>Total Pengeluaran</span>
              <h3>{{ $money($totalExpense) }}</h3>
              <p>Pengeluaran operasional studio</p>
            </div>

            <div class="payment-finance-icon bg-label-danger">
              <i class="bx bx-trending-down"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-finance-card">
            <div>
              <span>Saldo Bersih</span>
              <h3>{{ $money($netBalance) }}</h3>
              <p>Pemasukan dikurangi pengeluaran</p>
            </div>

            <div class="payment-finance-icon bg-label-primary">
              <i class="bx bx-bank"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-finance-card">
            <div>
              <span>Bayar Cetak</span>
              <h3>{{ $money($printPaymentIncome) }}</h3>
              <p>Pemasukan dari pesanan cetak</p>
            </div>

            <div class="payment-finance-icon bg-label-dark">
              <i class="bx bx-printer"></i>
            </div>
          </div>
        </div>
      </div>

      {{-- STATUS TRANSAKSI --}}
      <div class="row g-4 mb-4">
        <div class="col-xl-3 col-md-6">
          <div class="payment-stat-card">
            <div>
              <span>Total Transaksi</span>
              <h3>{{ $totalPayments }}</h3>
              <p>Semua payment gateway</p>
            </div>

            <div class="payment-stat-icon bg-label-primary">
              <i class="bx bx-receipt"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-stat-card">
            <div>
              <span>Menunggu Bayar</span>
              <h3>{{ $pendingPayments }}</h3>
              <p>Created / pending / authorize</p>
            </div>

            <div class="payment-stat-icon bg-label-warning">
              <i class="bx bx-time-five"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-stat-card">
            <div>
              <span>Sukses</span>
              <h3>{{ $paidPayments }}</h3>
              <p>Settlement / capture</p>
            </div>

            <div class="payment-stat-icon bg-label-success">
              <i class="bx bx-check-shield"></i>
            </div>
          </div>
        </div>

        <div class="col-xl-3 col-md-6">
          <div class="payment-stat-card">
            <div>
              <span>Gagal / Expired</span>
              <h3>{{ $failedPayments }}</h3>
              <p>Cancel / expire / deny / failed</p>
            </div>

            <div class="payment-stat-icon bg-label-danger">
              <i class="bx bx-x-circle"></i>
            </div>
          </div>
        </div>
      </div>

      {{-- MONITOR BOOKING --}}
      <div class="payment-monitor-card mb-4">
        <div class="payment-monitor-head">
          <div>
            <h5>Status Pembayaran Booking</h5>
            <p>Pantau booking yang belum DP, sudah DP, sudah lunas, dan pembayaran cetak.</p>
          </div>
        </div>

        <div class="payment-monitor-grid">
          <div class="payment-monitor-item monitor-unpaid">
            <div class="payment-monitor-icon">
              <i class="bx bx-error-circle"></i>
            </div>

            <div>
              <span>Belum Bayar DP</span>
              <h3>{{ $unpaidBookings->count() }}</h3>
              <p>Sudah pilih jadwal, belum DP</p>
            </div>
          </div>

          <div class="payment-monitor-item monitor-dp">
            <div class="payment-monitor-icon">
              <i class="bx bx-credit-card"></i>
            </div>

            <div>
              <span>Sudah Bayar DP</span>
              <h3>{{ $dpPaidBookings->count() }}</h3>
              <p>DP masuk, belum lunas</p>
            </div>
          </div>

          <div class="payment-monitor-item monitor-paid">
            <div class="payment-monitor-icon">
              <i class="bx bx-check-circle"></i>
            </div>

            <div>
              <span>Sudah Lunas</span>
              <h3>{{ $fullyPaidBookings->count() }}</h3>
              <p>Booking sudah lunas</p>
            </div>
          </div>

          <div class="payment-monitor-item monitor-print">
            <div class="payment-monitor-icon">
              <i class="bx bx-printer"></i>
            </div>

            <div>
              <span>Bayar Cetak</span>
              <h3>{{ $printPaidCount }}</h3>
              <p>Transaksi cetak sukses</p>
            </div>
          </div>
        </div>
      </div>

      {{-- BREAKDOWN --}}
      <div class="row g-4 mb-4">
        <div class="col-xl-4">
          <div class="payment-breakdown-card h-100">
            <div class="payment-card-title">
              <h5>Breakdown Pemasukan</h5>
              <p>Rincian pemasukan periode ini.</p>
            </div>

            <div class="payment-breakdown-list">
              <div>
                <span>Booking / DP / Pelunasan</span>
                <strong>{{ $money($bookingPaymentIncome) }}</strong>
              </div>

              <div>
                <span>Pembayaran Cetak</span>
                <strong>{{ $money($printPaymentIncome) }}</strong>
              </div>

              <div>
                <span>Pemasukan Manual</span>
                <strong>{{ $money($manualIncome) }}</strong>
              </div>

              <div class="total">
                <span>Total Pemasukan</span>
                <strong>{{ $money($totalIncome) }}</strong>
              </div>
            </div>
          </div>
        </div>

        <div class="col-xl-4">
          <div class="payment-ledger-card h-100">
            <div class="payment-card-title with-action">
              <div>
                <h5>Pemasukan Manual</h5>
                <p>Catatan pemasukan tambahan.</p>
              </div>

              <button type="button" class="btn btn-success btn-sm" data-bs-toggle="modal" data-bs-target="#incomeModal">
                <i class="bx bx-plus"></i>
              </button>
            </div>

            <div class="payment-ledger-list">
              @forelse ($recentIncomes as $income)
                <div class="payment-ledger-item">
                  <div>
                    <h6>{{ $income->category ?: 'Pemasukan Manual' }}</h6>
                    <p>{{ $income->income_date?->format('d M Y') }} • {{ $income->createdBy?->name ?? 'Admin' }}</p>
                  </div>

                  <div class="payment-ledger-right">
                    <strong class="text-success">+ {{ $money($income->amount) }}</strong>

                    <form method="POST" action="{{ route('admin.payments.incomes.destroy', $income) }}" onsubmit="return confirm('Hapus pemasukan ini?')">
                      @csrf
                      @method('DELETE')

                      <button type="submit" class="btn btn-outline-danger btn-sm">
                        <i class="bx bx-trash"></i>
                      </button>
                    </form>
                  </div>
                </div>
              @empty
                <div class="payment-small-empty">
                  <i class="bx bx-notepad"></i>
                  <p>Belum ada pemasukan manual.</p>
                </div>
              @endforelse
            </div>
          </div>
        </div>

        <div class="col-xl-4">
          <div class="payment-ledger-card h-100">
            <div class="payment-card-title with-action">
              <div>
                <h5>Pengeluaran Studio</h5>
                <p>Catatan pengeluaran operasional.</p>
              </div>

              <button type="button" class="btn btn-danger btn-sm" data-bs-toggle="modal" data-bs-target="#expenseModal">
                <i class="bx bx-plus"></i>
              </button>
            </div>

            <div class="payment-ledger-list">
              @forelse ($recentExpenses as $expense)
                <div class="payment-ledger-item">
                  <div>
                    <h6>{{ $expense->category ?: 'Pengeluaran Studio' }}</h6>
                    <p>{{ $expense->expense_date?->format('d M Y') }} • {{ $expense->createdBy?->name ?? 'Admin' }}</p>
                  </div>

                  <div class="payment-ledger-right">
                    <strong class="text-danger">- {{ $money($expense->amount) }}</strong>

                    <form method="POST" action="{{ route('admin.payments.expenses.destroy', $expense) }}" onsubmit="return confirm('Hapus pengeluaran ini?')">
                      @csrf
                      @method('DELETE')

                      <button type="submit" class="btn btn-outline-danger btn-sm">
                        <i class="bx bx-trash"></i>
                      </button>
                    </form>
                  </div>
                </div>
              @empty
                <div class="payment-small-empty">
                  <i class="bx bx-notepad"></i>
                  <p>Belum ada pengeluaran studio.</p>
                </div>
              @endforelse
            </div>
          </div>
        </div>
      </div>

      {{-- BOOKING BELUM DP --}}
      <div class="payment-booking-section mb-4">
        <div class="payment-booking-head">
          <div>
            <h5>Klien Belum Bayar DP</h5>
            <p>Klien yang sudah memilih jadwal booking tetapi belum melakukan DP.</p>
          </div>

          <span>{{ $unpaidBookings->count() }} booking</span>
        </div>

        <div class="payment-booking-grid">
          @forelse ($unpaidBookings->take(6) as $booking)
            <div class="payment-booking-card">
              <div class="payment-booking-top">
                <div class="payment-booking-avatar">
                  {{ mb_strtoupper(mb_substr($clientName($booking), 0, 1)) }}
                </div>

                <span class="badge bg-label-danger">Belum DP</span>
              </div>

              <h6>{{ $clientName($booking) }}</h6>

              <div class="payment-booking-meta">
                <i class="bx bx-phone"></i>
                {{ $clientPhone($booking) }}
              </div>

              <div class="payment-booking-meta">
                <i class="bx bx-package"></i>
                {{ $booking->package?->name ?? 'Paket Foto' }}
              </div>

              <div class="payment-booking-meta">
                <i class="bx bx-calendar"></i>
                {{ $booking->booking_date ? \Carbon\Carbon::parse($booking->booking_date)->format('d M Y') : '-' }}
                @if ($booking->start_time)
                  • {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                @endif
              </div>

              <div class="payment-booking-money">
                <div>
                  <span>Total</span>
                  <strong>{{ $money($booking->total_booking_amount) }}</strong>
                </div>

                <div>
                  <span>Minimal DP</span>
                  <strong>{{ $money($booking->minimum_dp_amount) }}</strong>
                </div>
              </div>
            </div>
          @empty
            <div class="payment-empty-card">
              <i class="bx bx-check-circle"></i>
              <p>Tidak ada booking yang belum bayar DP.</p>
            </div>
          @endforelse
        </div>
      </div>

      {{-- DAFTAR PEMBAYARAN --}}
      <div class="card section-card payment-list-card">
        <div class="card-header">
          <div class="payment-card-head">
            <div>
              <h5 class="section-title">Daftar Pembayaran Masuk</h5>
              <p class="section-subtitle mb-0">
                Monitor pembayaran booking, DP, pelunasan, dan pembayaran cetak.
              </p>
            </div>

            <div class="payment-total-badge">
              <i class="bx bx-wallet"></i>
              {{ $payments->total() }} transaksi
            </div>
          </div>
        </div>

        <div class="card-body payment-filter-body">
          <form method="GET" action="{{ route('admin.payments.index') }}" class="payment-filter-form">
            <input type="hidden" name="date_from" value="{{ $dateFrom->toDateString() }}">
            <input type="hidden" name="date_to" value="{{ $dateTo->toDateString() }}">

            <div class="payment-filter-grid">
              <div class="payment-filter-field payment-search-group">
                <label class="form-label">Cari Pembayaran</label>

                <div class="payment-search-input-group">
                  <span>
                    <i class="bx bx-search"></i>
                  </span>

                  <input type="text"
                    name="search"
                    class="form-control"
                    placeholder="Cari order ID, klien, email, metode..."
                    value="{{ request('search') }}">
                </div>
              </div>

              <div class="payment-filter-field">
                <label class="form-label">Jenis</label>
                <select name="payment_type" class="form-select">
                  <option value="">Semua Jenis</option>

                  @foreach ($paymentTypeOptions as $value => $label)
                    <option value="{{ $value }}" @selected(request('payment_type') === $value)>
                      {{ $label }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="payment-filter-field">
                <label class="form-label">Status</label>
                <select name="status" class="form-select">
                  <option value="">Semua Status</option>

                  @foreach ($statusOptions as $value => $label)
                    <option value="{{ $value }}" @selected(request('status') === $value)>
                      {{ $label }}
                    </option>
                  @endforeach
                </select>
              </div>

              <div class="payment-filter-actions">
                <button type="submit" class="btn btn-primary">
                  <i class="bx bx-filter-alt me-1"></i>
                  Filter
                </button>

                <a href="{{ route('admin.payments.index', [
                  'date_from' => $dateFrom->toDateString(),
                  'date_to' => $dateTo->toDateString(),
                ]) }}" class="btn btn-outline-secondary">
                  Reset
                </a>
              </div>
            </div>
          </form>
        </div>

        <div class="payment-table-wrap">
          <div class="table-responsive">
            <table class="table align-middle payment-table">
              <thead>
                <tr>
                  <th>Order ID</th>
                  <th>Jenis</th>
                  <th>Klien</th>
                  <th>Booking / Cetak</th>
                  <th>Total</th>
                  <th>Metode</th>
                  <th>Status Transaksi</th>
                  <th>Status Booking</th>
                  <th>Waktu</th>
                  <th>Action</th>
                </tr>
              </thead>

              <tbody>
                @forelse($payments as $payment)
                  @php
                    $booking = $payment->scheduleBooking;
                    $printOrder = $payment->printOrder;
                    $client = $booking?->clientUser ?? $printOrder?->client;
                    $package = $booking?->package;

                    $displayClientName = $client?->name
                        ?? $booking?->client_name
                        ?? $printOrder?->recipient_name
                        ?? 'Klien';

                    $displayClientEmail = $client?->email ?? '-';
                    $clientInitial = mb_strtoupper(mb_substr($displayClientName ?: 'K', 0, 1));
                  @endphp

                  <tr>
                    <td>
                      <div class="payment-order-cell">
                        <div class="payment-order-icon">
                          <i class="bx bx-receipt"></i>
                        </div>

                        <div>
                          <div class="payment-order-id">
                            {{ $payment->order_id ?? '-' }}
                          </div>

                          <div class="payment-provider">
                            {{ $payment->provider ?? '-' }}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td>
                      <span class="badge bg-label-{{ $paymentTypeBadge($payment) }} payment-status-badge">
                        {{ $paymentTypeLabel($payment) }}
                      </span>
                    </td>

                    <td>
                      <div class="payment-client-cell">
                        <div class="payment-client-avatar">
                          {{ $clientInitial }}
                        </div>

                        <div>
                          <div class="payment-client-name">
                            {{ $displayClientName }}
                          </div>

                          <div class="payment-client-email">
                            {{ $displayClientEmail }}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td>
                      <div class="payment-booking-cell">
                        <div class="payment-booking-name">
                          @if ($payment->print_order_id || in_array($payment->payment_context, ['print', 'print_order'], true))
                            Pesanan Cetak Foto
                          @else
                            {{ $package?->name ?? 'Booking Foto' }}
                          @endif
                        </div>

                        <div class="payment-booking-date">
                          @if ($booking?->booking_date)
                            <i class="bx bx-calendar"></i>
                            {{ \Carbon\Carbon::parse($booking->booking_date)->format('d M Y') }}

                            @if ($booking?->start_time)
                              <span class="payment-dot">•</span>
                              <i class="bx bx-time-five"></i>
                              {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                            @endif
                          @else
                            <i class="bx bx-printer"></i>
                            Print Order #{{ $payment->print_order_id ?? '-' }}
                          @endif
                        </div>
                      </div>
                    </td>

                    <td>
                      <div class="payment-amount">
                        {{ $money($payment->base_amount ?: $payment->gross_amount) }}
                      </div>

                      @if ($payment->admin_fee > 0)
                        <div class="payment-time-sub">
                          Admin fee: {{ $money($payment->admin_fee) }}
                        </div>
                      @endif
                    </td>

                    <td>
                      <span class="payment-method-badge">
                        <i class="bx bx-credit-card"></i>
                        {{ $payment->payment_type ?? '-' }}
                      </span>
                    </td>

                    <td>
                      <span class="badge bg-label-{{ $paymentStatusBadge($payment->transaction_status) }} payment-status-badge">
                        {{ $paymentStatusLabel($payment->transaction_status) }}
                      </span>
                    </td>

                    <td>
                      @if ($payment->print_order_id || in_array($payment->payment_context, ['print', 'print_order'], true))
                        <span class="badge bg-label-dark payment-status-badge">
                          Cetak
                        </span>
                      @else
                        <span class="badge bg-label-{{ $bookingPaymentBadge($booking) }} payment-status-badge">
                          {{ $bookingPaymentLabel($booking) }}
                        </span>
                      @endif
                    </td>

                    <td>
                      <div class="payment-time">
                        <i class="bx bx-calendar-event"></i>
                        {{ $payment->created_at ? $payment->created_at->format('d M Y') : '-' }}
                      </div>

                      <div class="payment-time-sub">
                        {{ $payment->created_at ? $payment->created_at->format('H:i') . ' WIB' : '-' }}
                      </div>
                    </td>

                    <td>
                      <a href="{{ route('admin.payments.show', $payment) }}" class="btn btn-primary btn-sm payment-detail-btn">
                        <i class="bx bx-show-alt me-1"></i>
                        Detail
                      </a>
                    </td>
                  </tr>
                @empty
                  <tr>
                    <td colspan="10">
                      <div class="payment-empty-state">
                        <i class="bx bx-wallet"></i>
                        <h6>Belum ada transaksi pembayaran</h6>
                        <p>Transaksi pembayaran booking, DP, pelunasan, dan cetak akan tampil di sini.</p>
                      </div>
                    </td>
                  </tr>
                @endforelse
              </tbody>
            </table>
          </div>
        </div>

        @if ($payments->hasPages())
          <div class="card-footer payment-footer">
            {{ $payments->links() }}
          </div>
        @endif
      </div>
    </div>
  </div>

  {{-- MODAL PEMASUKAN --}}
  <div class="modal fade" id="incomeModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <form method="POST" action="{{ route('admin.payments.incomes.store') }}" class="modal-content payment-modal-content">
        @csrf

        <div class="modal-header payment-modal-header income-header">
          <div>
            <h5 class="modal-title">Tambah Pemasukan</h5>
            <small>Catat pemasukan manual selain payment gateway.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body payment-modal-body">
          <div class="mb-3">
            <label class="form-label">Tanggal Pemasukan</label>
            <input type="date" name="income_date" class="form-control" value="{{ now()->toDateString() }}" required>
          </div>

          <div class="mb-3">
            <label class="form-label">Kategori</label>
            <input type="text" name="category" class="form-control" placeholder="Contoh: Pemasukan tambahan / Cash / Jasa studio">
          </div>

          <div class="mb-3">
            <label class="form-label">Nominal</label>
            <input type="number" name="amount" class="form-control" min="1" placeholder="Contoh: 250000" required>
          </div>

          <div>
            <label class="form-label">Keterangan</label>
            <textarea name="description" class="form-control" rows="4" placeholder="Catatan pemasukan..."></textarea>
          </div>
        </div>

        <div class="modal-footer payment-modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-success">
            <i class="bx bx-save me-1"></i>
            Simpan Pemasukan
          </button>
        </div>
      </form>
    </div>
  </div>

  {{-- MODAL PENGELUARAN --}}
  <div class="modal fade" id="expenseModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
      <form method="POST" action="{{ route('admin.payments.expenses.store') }}" class="modal-content payment-modal-content">
        @csrf

        <div class="modal-header payment-modal-header expense-header">
          <div>
            <h5 class="modal-title">Tambah Pengeluaran</h5>
            <small>Catat pengeluaran operasional studio.</small>
          </div>

          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body payment-modal-body">
          <div class="mb-3">
            <label class="form-label">Tanggal Pengeluaran</label>
            <input type="date" name="expense_date" class="form-control" value="{{ now()->toDateString() }}" required>
          </div>

          <div class="mb-3">
            <label class="form-label">Kategori</label>
            <input type="text" name="category" class="form-control" placeholder="Contoh: Operasional / Alat / Transport">
          </div>

          <div class="mb-3">
            <label class="form-label">Nominal</label>
            <input type="number" name="amount" class="form-control" min="1" placeholder="Contoh: 150000" required>
          </div>

          <div>
            <label class="form-label">Keterangan</label>
            <textarea name="description" class="form-control" rows="4" placeholder="Catatan pengeluaran..."></textarea>
          </div>
        </div>

        <div class="modal-footer payment-modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
            Batal
          </button>

          <button type="submit" class="btn btn-danger">
            <i class="bx bx-save me-1"></i>
            Simpan Pengeluaran
          </button>
        </div>
      </form>
    </div>
  </div>

  <style>
    .payment-page {
      max-width: 1480px;
      margin: 0 auto;
    }

    .payment-hero-card {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 24px;
      padding: 30px 34px;
      border-radius: 32px;
      background:
        radial-gradient(circle at top right, rgba(255, 255, 255, 0.36), transparent 32%),
        linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 24px 54px rgba(52, 79, 165, 0.24);
      color: #ffffff;
      overflow: hidden;
    }

    .payment-hero-left {
      display: flex;
      align-items: flex-start;
      gap: 18px;
      min-width: 0;
    }

    .payment-hero-icon {
      width: 66px;
      height: 66px;
      border-radius: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: rgba(255, 255, 255, 0.18);
      color: #ffffff;
      font-size: 34px;
      box-shadow: 0 16px 32px rgba(22, 43, 77, 0.16);
    }

    .payment-hero-kicker {
      color: rgba(255, 255, 255, 0.78);
      font-size: 12px;
      font-weight: 900;
      letter-spacing: 0.11em;
      text-transform: uppercase;
      margin-bottom: 7px;
    }

    .payment-hero-card h4 {
      color: #ffffff;
      font-size: 28px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .payment-hero-card p {
      color: rgba(255, 255, 255, 0.84);
      font-size: 15px;
      font-weight: 600;
      line-height: 1.75;
      margin-bottom: 0;
    }

    .payment-hero-actions {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-shrink: 0;
    }

    .payment-hero-actions .btn {
      height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding: 0 18px;
      white-space: nowrap;
    }

    .payment-period-card,
    .payment-monitor-card,
    .payment-breakdown-card,
    .payment-ledger-card,
    .payment-booking-section {
      border-radius: 30px;
      background: #ffffff;
      box-shadow: var(--mf-shadow-soft);
      overflow: hidden;
    }

    .payment-period-card,
    .payment-monitor-card,
    .payment-breakdown-card,
    .payment-ledger-card,
    .payment-booking-section {
      padding: 26px;
    }

    .payment-period-form {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      gap: 20px;
      flex-wrap: wrap;
    }

    .payment-period-form h6,
    .payment-monitor-head h5,
    .payment-card-title h5,
    .payment-booking-head h5 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .payment-period-form p,
    .payment-monitor-head p,
    .payment-card-title p,
    .payment-booking-head p {
      color: var(--mf-muted);
      font-weight: 700;
      line-height: 1.55;
      margin-bottom: 0;
    }

    .payment-period-controls {
      display: flex;
      align-items: flex-end;
      gap: 12px;
      flex-wrap: wrap;
    }

    .payment-period-controls .form-label,
    .payment-filter-field .form-label,
    .payment-modal-body .form-label {
      color: var(--mf-ink);
      font-size: 12px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .payment-period-controls .form-control,
    .payment-filter-field .form-select,
    .payment-modal-body .form-control {
      height: 48px;
      border-radius: 16px;
      border: 1px solid var(--mf-border);
      font-weight: 800;
      box-shadow: none;
    }

    .payment-modal-body textarea.form-control {
      height: auto;
    }

    .payment-period-buttons {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .payment-period-buttons .btn {
      height: 48px;
      border-radius: 16px;
      font-weight: 900;
      padding: 0 17px;
    }

    .payment-finance-card,
    .payment-stat-card {
      min-height: 142px;
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 18px;
      padding: 24px;
      border-radius: 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.16), transparent 36%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
      box-shadow: var(--mf-shadow-soft);
      transition: 0.22s ease;
    }

    .payment-finance-card:hover,
    .payment-stat-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 24px 48px rgba(52, 79, 165, 0.14);
    }

    .payment-finance-card span,
    .payment-stat-card span {
      display: block;
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 900;
      margin-bottom: 8px;
    }

    .payment-finance-card h3 {
      color: var(--mf-ink);
      font-size: 25px;
      font-weight: 900;
      line-height: 1.25;
      margin-bottom: 10px;
    }

    .payment-stat-card h3 {
      color: var(--mf-ink);
      font-size: 34px;
      font-weight: 900;
      line-height: 1;
      margin-bottom: 10px;
    }

    .payment-finance-card p,
    .payment-stat-card p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-bottom: 0;
    }

    .payment-finance-icon,
    .payment-stat-icon {
      width: 58px;
      height: 58px;
      border-radius: 20px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      font-size: 28px;
    }

    .payment-monitor-head {
      margin-bottom: 20px;
    }

    .payment-monitor-grid {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 16px;
    }

    .payment-monitor-item {
      display: grid;
      grid-template-columns: 52px 1fr;
      gap: 14px;
      align-items: flex-start;
      padding: 18px;
      border-radius: 24px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .payment-monitor-icon {
      width: 52px;
      height: 52px;
      border-radius: 18px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 25px;
    }

    .monitor-unpaid .payment-monitor-icon {
      background: rgba(255, 62, 29, 0.12);
      color: #ff3e1d;
    }

    .monitor-dp .payment-monitor-icon {
      background: rgba(3, 195, 236, 0.12);
      color: #03a9d6;
    }

    .monitor-paid .payment-monitor-icon {
      background: rgba(47, 177, 140, 0.12);
      color: #167a64;
    }

    .monitor-print .payment-monitor-icon {
      background: rgba(67, 89, 113, 0.12);
      color: #435971;
    }

    .payment-monitor-item span {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }

    .payment-monitor-item h3[object Object],[object Object],[object Object],[object Object] {
      color: var(--mf-ink);
      font-size: 32px;
      font-weight: 900;
      margin: 4px 0 6px;
    }

    .payment-monitor-item p {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.5;
      margin-bottom: 0;
    }

    .payment-card-title {
      margin-bottom: 18px;
    }

    .payment-card-title.with-action {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
    }

    .payment-card-title .btn {
      border-radius: 14px;
      font-weight: 900;
    }

    .payment-breakdown-list {
      display: grid;
      gap: 12px;
    }

    .payment-breakdown-list > div {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 15px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .payment-breakdown-list .total {
      background: linear-gradient(135deg, rgba(88, 115, 220, 0.10), rgba(3, 169, 244, 0.08));
      border-color: rgba(88, 115, 220, 0.18);
    }

    .payment-breakdown-list span {
      color: var(--mf-muted);
      font-weight: 800;
    }

    .payment-breakdown-list strong {
      color: var(--mf-ink);
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-ledger-list {
      display: grid;
      gap: 12px;
    }

    .payment-ledger-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      padding: 14px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
    }

    .payment-ledger-item h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 4px;
    }

    .payment-ledger-item p {
      color: var(--mf-muted);
      font-size: 12px;
      font-weight: 700;
      margin-bottom: 0;
    }

    .payment-ledger-right {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-shrink: 0;
    }

    .payment-ledger-right strong {
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-ledger-right .btn {
      width: 34px;
      height: 34px;
      padding: 0;
      border-radius: 12px;
    }

    .payment-small-empty,
    .payment-empty-card {
      text-align: center;
      padding: 38px 20px;
      border: 1px dashed var(--mf-border);
      border-radius: 22px;
      background: #ffffff;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .payment-small-empty i,
    .payment-empty-card i {
      display: block;
      color: var(--mf-primary);
      font-size: 44px;
      margin-bottom: 10px;
    }

    .payment-booking-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
      flex-wrap: wrap;
      margin-bottom: 18px;
    }

    .payment-booking-head span {
      display: inline-flex;
      padding: 9px 13px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.1);
      color: var(--mf-primary);
      font-size: 12px;
      font-weight: 900;
    }

    .payment-booking-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 16px;
    }

    .payment-booking-card {
      padding: 18px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background:
        radial-gradient(circle at top right, rgba(255, 62, 29, 0.08), transparent 34%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .payment-booking-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 14px;
    }

    .payment-booking-avatar {
      width: 48px;
      height: 48px;
      border-radius: 17px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: #ffffff;
      font-weight: 900;
      background: linear-gradient(135deg, var(--mf-primary), var(--mf-blue));
      box-shadow: 0 12px 26px rgba(88, 115, 220, 0.18);
    }

    .payment-booking-card h6 {
      color: var(--mf-ink);
      font-size: 17px;
      font-weight: 900;
      margin-bottom: 10px;
    }

    .payment-booking-meta {
      display: flex;
      align-items: center;
      gap: 7px;
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      line-height: 1.55;
    }

    .payment-booking-meta i {
      color: var(--mf-primary);
      font-size: 16px;
    }

    .payment-booking-money {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-top: 14px;
    }

    .payment-booking-money div {
      padding: 12px;
      border-radius: 17px;
      border: 1px solid var(--mf-border);
      background: #ffffff;
    }

    .payment-booking-money span {
      display: block;
      color: var(--mf-muted);
      font-size: 11px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 4px;
    }

    .payment-booking-money strong {
      color: var(--mf-ink);
      font-size: 13px;
      font-weight: 900;
    }

    .payment-list-card {
      border: 0;
      border-radius: 30px;
      overflow: hidden;
      box-shadow: var(--mf-shadow-soft);
      background: #ffffff;
    }

    .payment-list-card .card-header {
      padding: 30px 34px 22px !important;
      background: #ffffff;
      border-bottom: 1px solid var(--mf-border);
    }

    .payment-card-head {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 16px;
    }

    .payment-total-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 13px;
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-filter-body {
      padding: 26px 34px 30px !important;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .payment-filter-form {
      border: 1px solid var(--mf-border);
      border-radius: 26px;
      padding: 20px;
      background: #ffffff;
      box-shadow: 0 10px 24px rgba(22, 43, 77, 0.04);
    }

    .payment-filter-grid {
      display: grid;
      grid-template-columns: minmax(320px, 1.6fr) minmax(180px, 0.8fr) minmax(180px, 0.8fr) auto;
      gap: 14px;
      align-items: end;
    }

    .payment-filter-field {
      min-width: 0;
    }

    .payment-search-input-group {
      display: flex;
      align-items: stretch;
      width: 100%;
      height: 52px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      background: #ffffff;
      overflow: hidden;
      transition: 0.18s ease;
    }

    .payment-search-input-group:focus-within {
      border-color: rgba(88, 115, 220, 0.48);
      box-shadow: 0 0 0 0.22rem rgba(88, 115, 220, 0.10);
    }

    .payment-search-input-group span {
      width: 58px;
      min-width: 58px;
      height: 100%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: #ffffff;
      color: var(--mf-ink);
      border-right: 1px solid var(--mf-border);
      font-size: 20px;
    }

    .payment-search-input-group input {
      height: 100% !important;
      flex: 1;
      min-width: 0;
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

    .payment-search-input-group input::placeholder {
      color: rgba(107, 124, 147, 0.62) !important;
      font-weight: 700 !important;
    }

    .payment-filter-field .form-select {
      height: 52px !important;
      border-radius: 18px !important;
      border: 1px solid var(--mf-border) !important;
      font-weight: 800 !important;
      box-shadow: none !important;
    }

    .payment-filter-actions {
      display: flex;
      align-items: end;
      gap: 10px;
      min-width: 200px;
    }

    .payment-filter-actions .btn {
      height: 52px;
      border-radius: 18px;
      font-weight: 900;
      padding-left: 18px;
      padding-right: 18px;
      white-space: nowrap;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }

    .payment-table-wrap {
      margin: 0 34px 30px;
      border: 1px solid var(--mf-border);
      border-radius: 24px;
      background: #ffffff;
      overflow: hidden;
    }

    .payment-table {
      min-width: 1320px;
      margin-bottom: 0;
    }

    .payment-table thead th {
      background: #f4f7fb !important;
      color: var(--mf-muted) !important;
      font-size: 12px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      padding: 16px 18px !important;
      border-bottom: 1px solid var(--mf-border) !important;
      white-space: nowrap;
    }

    .payment-table tbody td {
      padding: 18px !important;
      vertical-align: middle;
      border-bottom: 1px solid rgba(224, 231, 241, 0.8);
    }

    .payment-table tbody tr:hover {
      background: #f8fbfd;
    }

    .payment-table tbody tr:last-child td {
      border-bottom: 0;
    }

    .payment-order-cell,
    .payment-client-cell {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 220px;
    }

    .payment-order-icon {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      background: rgba(88, 115, 220, 0.10);
      color: var(--mf-primary);
      font-size: 22px;
    }

    .payment-order-id {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.25;
      word-break: break-word;
    }

    .payment-provider {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-top: 4px;
    }

    .payment-client-avatar {
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

    .payment-client-name,
    .payment-booking-name {
      color: var(--mf-ink);
      font-weight: 900;
      line-height: 1.25;
    }

    .payment-client-email,
    .payment-booking-date,
    .payment-time-sub {
      color: var(--mf-muted);
      font-size: 13px;
      font-weight: 700;
      margin-top: 4px;
    }

    .payment-booking-cell {
      min-width: 210px;
    }

    .payment-booking-date {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 5px;
    }

    .payment-booking-date i {
      font-size: 15px;
      color: var(--mf-primary);
    }

    .payment-dot {
      color: var(--mf-muted);
      margin: 0 2px;
    }

    .payment-amount {
      color: var(--mf-ink);
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-method-badge {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 8px 11px;
      border-radius: 999px;
      background: #f4f7fb;
      color: #607086;
      font-size: 12px;
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-method-badge i {
      font-size: 16px;
      color: var(--mf-primary);
    }

    .payment-status-badge {
      font-size: 12px;
      font-weight: 900;
      padding: 8px 10px;
      border-radius: 999px;
      white-space: nowrap;
    }

    .payment-time {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: var(--mf-ink);
      font-weight: 900;
      white-space: nowrap;
    }

    .payment-time i {
      color: var(--mf-primary);
      font-size: 17px;
    }

    .payment-detail-btn {
      border-radius: 14px;
      font-weight: 900;
      padding: 8px 12px;
      white-space: nowrap;
      box-shadow: 0 10px 22px rgba(88, 115, 220, 0.18);
    }

    .payment-empty-state {
      text-align: center;
      padding: 54px 20px;
      color: var(--mf-muted);
      font-weight: 700;
    }

    .payment-empty-state i {
      display: block;
      color: var(--mf-primary);
      font-size: 52px;
      margin-bottom: 12px;
    }

    .payment-empty-state h6 {
      color: var(--mf-ink);
      font-weight: 900;
      margin-bottom: 6px;
    }

    .payment-empty-state p {
      margin-bottom: 0;
    }

    .payment-footer {
      padding: 18px 34px !important;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
    }

    .payment-modal-content {
      border: 0;
      border-radius: 28px;
      overflow: hidden;
      box-shadow: 0 24px 60px rgba(22, 43, 77, 0.18);
    }

    .payment-modal-header {
      padding: 24px 28px;
      color: #ffffff;
      border-bottom: 0;
    }

    .payment-modal-header.income-header {
      background: linear-gradient(135deg, #2fb18c, #168f70);
    }

    .payment-modal-header.expense-header {
      background: linear-gradient(135deg, #ff5b5c, #d9363e);
    }

    .payment-modal-header .modal-title {
      color: #ffffff;
      font-weight: 900;
      margin-bottom: 4px;
    }

    .payment-modal-header small {
      color: rgba(255, 255, 255, 0.82);
      font-weight: 600;
    }

    .payment-modal-body {
      padding: 26px 28px;
      background:
        radial-gradient(circle at top right, rgba(159, 191, 210, 0.12), transparent 35%),
        linear-gradient(180deg, #ffffff 0%, #f8fbfd 100%);
    }

    .payment-modal-footer {
      padding: 18px 28px 24px;
      background: #ffffff;
      border-top: 1px solid var(--mf-border);
    }

    .payment-modal-footer .btn {
      border-radius: 14px;
      font-weight: 900;
      padding-left: 18px;
      padding-right: 18px;
    }

    @media (max-width: 1400px) {
      .payment-monitor-grid,
      .payment-booking-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .payment-filter-grid {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }

      .payment-search-group {
        grid-column: span 3;
      }

      .payment-filter-actions {
        grid-column: span 3;
        justify-content: flex-end;
      }
    }

    @media (max-width: 992px) {
      .payment-hero-card,
      .payment-period-form {
        align-items: flex-start;
        flex-direction: column;
      }

      .payment-hero-left {
        flex-direction: column;
      }

      .payment-hero-actions,
      .payment-hero-actions .btn,
      .payment-period-controls,
      .payment-period-controls > div,
      .payment-period-buttons,
      .payment-period-buttons .btn {
        width: 100%;
      }

      .payment-hero-actions,
      .payment-period-buttons {
        flex-direction: column;
      }

      .payment-filter-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .payment-search-group,
      .payment-filter-actions {
        grid-column: span 2;
      }
    }

    @media (max-width: 768px) {
      .payment-hero-card,
      .payment-period-card,
      .payment-monitor-card,
      .payment-breakdown-card,
      .payment-ledger-card,
      .payment-booking-section,
      .payment-list-card .card-header,
      .payment-filter-body {
        padding-left: 22px !important;
        padding-right: 22px !important;
      }

      .payment-monitor-grid,
      .payment-booking-grid,
      .payment-filter-grid {
        grid-template-columns: 1fr;
      }

      .payment-search-group,
      .payment-filter-actions {
        grid-column: span 1;
      }

      .payment-filter-actions {
        flex-direction: column;
        min-width: 0;
      }

      .payment-filter-actions .btn {
        width: 100%;
      }

      .payment-table-wrap {
        margin-left: 22px;
        margin-right: 22px;
      }

      .payment-ledger-item {
        align-items: flex-start;
        flex-direction: column;
      }

      .payment-ledger-right {
        justify-content: space-between;
        width: 100%;
      }

      .payment-booking-money {
        grid-template-columns: 1fr;
      }
    }
  </style>
@endsection