<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pembayaran Gagal</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f6f7fb;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0
    }

    .card {
      background: #fff;
      padding: 32px;
      border-radius: 20px;
      box-shadow: 0 10px 30px rgba(0, 0, 0, .08);
      max-width: 520px;
      width: 100%
    }

    .title {
      color: #dc2626;
      font-size: 28px;
      font-weight: 700;
      margin-bottom: 10px
    }

    .muted {
      color: #64748b
    }

    .row {
      margin: 10px 0
    }
  </style>
</head>

<body>
  <div class="card">
    <div class="title">Pembayaran Gagal</div>
    <p class="muted">Terjadi masalah saat pembayaran atau transaksi dibatalkan / kedaluwarsa.</p>

    @if ($payment)
      <div class="row"><strong>Order ID:</strong> {{ $payment->order_id }}</div>
      <div class="row"><strong>Status:</strong> {{ $payment->transaction_status }}</div>
      <div class="row"><strong>Pesan:</strong> {{ $payment->status_message ?? '-' }}</div>
    @endif
  </div>
</body>

</html>
