@extends('layouts/contentNavbarLayout')

@section('title', 'Pembayaran')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    @if (session('success'))
      <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    @if (session('error'))
      <div class="alert alert-danger">{{ session('error') }}</div>
    @endif

    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Pembayaran</h4>
        <p class="text-muted mb-0">Pantau status pembayaran booking klien Monoframe Studio.</p>
      </div>
    </div>

    <div class="row">
      <div class="col-md-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Total Transaksi</span>
            <h3 class="card-title mb-2">{{ $totalPayments }}</h3>
            <small class="text-primary fw-semibold">Semua pembayaran booking</small>
          </div>
        </div>
      </div>

      <div class="col-md-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Menunggu Pembayaran</span>
            <h3 class="card-title mb-2">{{ $pendingPayments }}</h3>
            <small class="text-warning fw-semibold">Pending / belum selesai</small>
          </div>
        </div>
      </div>

      <div class="col-md-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Sudah Dibayar</span>
            <h3 class="card-title mb-2">{{ $paidPayments }}</h3>
            <small class="text-success fw-semibold">Capture / settlement</small>
          </div>
        </div>
      </div>

      <div class="col-md-3 mb-4">
        <div class="card h-100">
          <div class="card-body">
            <span class="text-muted d-block mb-1">Gagal / Expired</span>
            <h3 class="card-title mb-2">{{ $failedPayments }}</h3>
            <small class="text-danger fw-semibold">Cancel / expire / deny</small>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
          <div>
            <h5 class="mb-0">Daftar Pembayaran Booking</h5>
            <small class="text-muted">Monitor transaksi pembayaran klien</small>
          </div>
        </div>

        <form method="GET" action="{{ route('admin.payments.index') }}">
          <div class="row g-3">
            <div class="col-md-5">
              <input type="text" name="search" class="form-control"
                placeholder="Cari order id, klien, email, metode..." value="{{ request('search') }}">
            </div>

            <div class="col-md-4">
              <select name="status" class="form-select">
                <option {{ !request('status') ? 'selected' : '' }}>Semua Status</option>
                <option value="created" {{ request('status') === 'created' ? 'selected' : '' }}>Created</option>
                <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>Pending</option>
                <option value="settlement" {{ request('status') === 'settlement' ? 'selected' : '' }}>Settlement</option>
                <option value="capture" {{ request('status') === 'capture' ? 'selected' : '' }}>Capture</option>
                <option value="expire" {{ request('status') === 'expire' ? 'selected' : '' }}>Expire</option>
                <option value="cancel" {{ request('status') === 'cancel' ? 'selected' : '' }}>Cancel</option>
                <option value="deny" {{ request('status') === 'deny' ? 'selected' : '' }}>Deny</option>
                <option value="failure" {{ request('status') === 'failure' ? 'selected' : '' }}>Failure</option>
              </select>
            </div>

            <div class="col-md-3 d-flex gap-2">
              <button type="submit" class="btn btn-primary w-100">Filter</button>
              <a href="{{ route('admin.payments.index') }}" class="btn btn-outline-secondary w-100">Reset</a>
            </div>
          </div>
        </form>
      </div>

      <div class="table-responsive text-nowrap">
        <table class="table align-middle">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Klien</th>
              <th>Booking</th>
              <th>Total</th>
              <th>Metode</th>
              <th>Status Pembayaran</th>
              <th>Status Booking</th>
              <th>Waktu</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody class="table-border-bottom-0">
            @forelse($payments as $payment)
              @php
                $booking = $payment->scheduleBooking;
                $client = $booking?->clientUser;
                $package = $booking?->package;
              @endphp
              <tr>
                <td>
                  <div class="d-flex flex-column">
                    <span class="fw-medium">{{ $payment->order_id }}</span>
                    <small class="text-muted">{{ $payment->provider }}</small>
                  </div>
                </td>
                <td>
                  <div class="d-flex flex-column">
                    <span class="fw-medium">{{ $client?->name ?? ($booking?->client_name ?? '-') }}</span>
                    <small class="text-muted">{{ $client?->email ?? '-' }}</small>
                  </div>
                </td>
                <td>
                  <div class="d-flex flex-column">
                    <span class="fw-medium">{{ $package?->name ?? 'Booking Foto' }}</span>
                    <small class="text-muted">
                      {{ $booking?->booking_date ? \Carbon\Carbon::parse($booking->booking_date)->format('d M Y') : '-' }}
                      @if ($booking?->start_time)
                        • {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }}
                      @endif
                    </small>
                  </div>
                </td>
                <td>Rp {{ number_format($payment->gross_amount, 0, ',', '.') }}</td>
                <td>{{ $payment->payment_type ?? '-' }}</td>
                <td>
                  <span class="badge bg-label-{{ $payment->statusBadge() }}">
                    {{ ucfirst($payment->transaction_status) }}
                  </span>
                </td>
                <td>
                  <span
                    class="badge bg-label-{{ ($booking?->payment_status ?? 'unpaid') === 'paid' ? 'success' : (($booking?->payment_status ?? 'unpaid') === 'pending' ? 'warning' : (($booking?->payment_status ?? 'unpaid') === 'failed' ? 'danger' : 'secondary')) }}">
                    {{ ucfirst($booking?->payment_status ?? 'unpaid') }}
                  </span>
                </td>
                <td>
                  {{ $payment->created_at->format('d M Y H:i') }}
                </td>
                <td>
                  <a href="{{ route('admin.payments.show', $payment) }}" class="btn btn-sm btn-primary">Detail</a>
                </td>
              </tr>
            @empty
              <tr>
                <td colspan="9" class="text-center text-muted py-4">Belum ada transaksi pembayaran.</td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>

      <div class="card-footer">
        {{ $payments->links() }}
      </div>
    </div>
  </div>
@endsection
