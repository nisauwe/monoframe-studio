@extends('layouts/contentNavbarLayout')

@section('title', 'Detail Pembayaran')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Detail Pembayaran</h4>
        <p class="text-muted mb-0">Lihat detail transaksi pembayaran booking klien.</p>
      </div>

      <a href="{{ route('admin.payments.index') }}" class="btn btn-outline-secondary">
        <i class="bx bx-arrow-back me-1"></i> Kembali
      </a>
    </div>

    @php
      $booking = $payment->scheduleBooking;
      $client = $booking?->clientUser;
      $package = $booking?->package;
      $photographer = $booking?->photographerUser;
    @endphp

    <div class="row">
      <div class="col-lg-8 mb-4">
        <div class="card mb-4">
          <div class="card-header">
            <h5 class="mb-0">Informasi Transaksi</h5>
          </div>
          <div class="card-body">
            <div class="row g-3">
              <div class="col-md-6">
                <strong>Order ID</strong>
                <div>{{ $payment->order_id }}</div>
              </div>
              <div class="col-md-6">
                <strong>Transaction ID</strong>
                <div>{{ $payment->transaction_id ?? '-' }}</div>
              </div>
              <div class="col-md-6">
                <strong>Provider</strong>
                <div>{{ ucfirst($payment->provider) }}</div>
              </div>
              <div class="col-md-6">
                <strong>Metode Pembayaran</strong>
                <div>{{ $payment->payment_type ?? '-' }}</div>
              </div>
              <div class="col-md-6">
                <strong>Status Transaksi</strong>
                <div>
                  <span class="badge bg-label-{{ $payment->statusBadge() }}">
                    {{ ucfirst($payment->transaction_status) }}
                  </span>
                </div>
              </div>
              <div class="col-md-6">
                <strong>Fraud Status</strong>
                <div>{{ $payment->fraud_status ?? '-' }}</div>
              </div>
              <div class="col-md-4">
                <strong>Base Amount</strong>
                <div>Rp {{ number_format($payment->base_amount, 0, ',', '.') }}</div>
              </div>
              <div class="col-md-4">
                <strong>Biaya Admin</strong>
                <div>Rp {{ number_format($payment->admin_fee, 0, ',', '.') }}</div>
              </div>
              <div class="col-md-4">
                <strong>Total</strong>
                <div>Rp {{ number_format($payment->gross_amount, 0, ',', '.') }}</div>
              </div>
              <div class="col-md-6">
                <strong>Kode Bayar</strong>
                <div>{{ $payment->payment_code ?? '-' }}</div>
              </div>
              <div class="col-md-6">
                <strong>PDF URL</strong>
                <div>
                  @if ($payment->pdf_url)
                    <a href="{{ $payment->pdf_url }}" target="_blank">Lihat PDF</a>
                  @else
                    -
                  @endif
                </div>
              </div>
              <div class="col-md-3">
                <strong>Dibuat</strong>
                <div>{{ $payment->created_at->format('d M Y H:i') }}</div>
              </div>
              <div class="col-md-3">
                <strong>Initiated</strong>
                <div>{{ $payment->initiated_at?->format('d M Y H:i') ?? '-' }}</div>
              </div>
              <div class="col-md-3">
                <strong>Paid At</strong>
                <div>{{ $payment->paid_at?->format('d M Y H:i') ?? '-' }}</div>
              </div>
              <div class="col-md-3">
                <strong>Expired At</strong>
                <div>{{ $payment->expired_at?->format('d M Y H:i') ?? '-' }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h5 class="mb-0">Payload Midtrans</h5>
          </div>
          <div class="card-body">
            <pre class="mb-0" style="white-space: pre-wrap;">{{ json_encode($payment->payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</pre>
          </div>
        </div>
      </div>

      <div class="col-lg-4 mb-4">
        <div class="card mb-4">
          <div class="card-header">
            <h5 class="mb-0">Informasi Booking</h5>
          </div>
          <div class="card-body">
            <div class="mb-3">
              <strong>Klien</strong>
              <div>{{ $client?->name ?? ($booking?->client_name ?? '-') }}</div>
              <small class="text-muted">{{ $client?->email ?? '-' }}</small>
            </div>

            <div class="mb-3">
              <strong>Paket</strong>
              <div>{{ $package?->name ?? '-' }}</div>
            </div>

            <div class="mb-3">
              <strong>Tanggal & Jam</strong>
              <div>
                {{ $booking?->booking_date ? \Carbon\Carbon::parse($booking->booking_date)->format('d M Y') : '-' }}
                @if ($booking?->start_time && $booking?->end_time)
                  • {{ \Carbon\Carbon::parse($booking->start_time)->format('H:i') }} -
                  {{ \Carbon\Carbon::parse($booking->end_time)->format('H:i') }}
                @endif
              </div>
            </div>

            <div class="mb-3">
              <strong>Fotografer</strong>
              <div>{{ $photographer?->name ?? ($booking?->photographer_name ?? '-') }}</div>
            </div>

            <div class="mb-3">
              <strong>Status Pembayaran di Booking</strong>
              <div>
                <span
                  class="badge bg-label-{{ ($booking?->payment_status ?? 'unpaid') === 'paid' ? 'success' : (($booking?->payment_status ?? 'unpaid') === 'pending' ? 'warning' : (($booking?->payment_status ?? 'unpaid') === 'failed' ? 'danger' : 'secondary')) }}">
                  {{ ucfirst($booking?->payment_status ?? 'unpaid') }}
                </span>
              </div>
            </div>

            <div class="mb-0">
              <strong>Order Booking</strong>
              <div>{{ $booking?->payment_order_id ?? '-' }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
@endsection
