@extends('layouts/contentNavbarLayout')

@section('title', 'Riwayat Pembayaran')

@section('content')
  <div class="container-xxl flex-grow-1 container-p-y">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h4 class="fw-bold mb-1">Riwayat Pembayaran</h4>
        <p class="text-muted mb-0">Lihat semua transaksi pembayaran booking Anda.</p>
      </div>
    </div>

    <div class="card">
      <div class="table-responsive text-nowrap">
        <table class="table align-middle">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Booking</th>
              <th>Total</th>
              <th>Metode</th>
              <th>Status</th>
              <th>Tanggal</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody class="table-border-bottom-0">
            @forelse($payments as $payment)
              <tr>
                <td>{{ $payment->order_id }}</td>
                <td>{{ $payment->scheduleBooking?->package?->name ?? 'Booking Foto' }}</td>
                <td>Rp {{ number_format($payment->gross_amount, 0, ',', '.') }}</td>
                <td>{{ $payment->payment_type ?? '-' }}</td>
                <td>
                  <span class="badge bg-label-{{ $payment->statusBadge() }}">
                    {{ ucfirst($payment->transaction_status) }}
                  </span>
                </td>
                <td>{{ $payment->created_at->format('d M Y H:i') }}</td>
                <td>
                  <a href="{{ route('payments.show', $payment) }}" class="btn btn-sm btn-primary">Detail</a>
                </td>
              </tr>
            @empty
              <tr>
                <td colspan="7" class="text-center text-muted py-4">Belum ada riwayat pembayaran.</td>
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
