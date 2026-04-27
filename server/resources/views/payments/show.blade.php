@extends('layouts/contentNavbarLayout')

@section('title', 'Detail Pembayaran')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Detail Pembayaran</h4>
        <p class="text-muted mb-0">Lihat detail transaksi pembayaran booking Anda.</p>
      </div>

      <a href="{{ route('payments.history') }}" class="btn btn-outline-secondary">
        <i class="bx bx-arrow-back me-1"></i> Kembali
      </a>
    </div>

    <div class="card">
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-6">
            <strong>Order ID</strong>
            <div>{{ $payment->order_id }}</div>
          </div>
          <div class="col-md-6">
            <strong>Status</strong>
            <div>
              <span class="badge bg-label-{{ $payment->statusBadge() }}">
                {{ ucfirst($payment->transaction_status) }}
              </span>
            </div>
          </div>
          <div class="col-md-6">
            <strong>Booking</strong>
            <div>{{ $payment->scheduleBooking?->package?->name ?? 'Booking Foto' }}</div>
          </div>
          <div class="col-md-6">
            <strong>Metode Pembayaran</strong>
            <div>{{ $payment->payment_type ?? '-' }}</div>
          </div>
          <div class="col-md-6">
            <strong>Total</strong>
            <div>Rp {{ number_format($payment->gross_amount, 0, ',', '.') }}</div>
          </div>
          <div class="col-md-6">
            <strong>Kode Bayar / VA</strong>
            <div>{{ $payment->payment_code ?? '-' }}</div>
          </div>
          <div class="col-md-6">
            <strong>Dibuat</strong>
            <div>{{ $payment->created_at->format('d M Y H:i') }}</div>
          </div>
          <div class="col-md-6">
            <strong>Dibayar</strong>
            <div>{{ $payment->paid_at?->format('d M Y H:i') ?? '-' }}</div>
          </div>
          <div class="col-md-12">
            @if ($payment->pdf_url)
              <a href="{{ $payment->pdf_url }}" target="_blank" class="btn btn-outline-primary">Lihat Instruksi
                Pembayaran</a>
            @endif

            @if ($payment->isPending() && $payment->snap_redirect_url)
              <a href="{{ $payment->snap_redirect_url }}" target="_blank" class="btn btn-primary">Lanjutkan
                Pembayaran</a>
            @endif
          </div>
        </div>
      </div>
    </div>
  </div>
@endsection
