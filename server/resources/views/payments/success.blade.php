<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pembayaran Berhasil</title>
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

    .ok {
      color: #16a34a;
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
    <div class="ok">Pembayaran Berhasil</div>
    <p class="muted">Transaksi booking kamu sudah berhasil dibayar.</p>

    @if ($payment)
      <div class="row"><strong>Order ID:</strong> {{ $payment->order_id }}</div>
      <div class="row"><strong>Status:</strong> {{ $payment->transaction_status }}</div>
      <div class="row"><strong>Metode:</strong> {{ $payment->payment_type ?? '-' }}</div>
      <div class="row"><strong>Total:</strong> Rp {{ number_format($payment->gross_amount, 0, ',', '.') }}</div>
    @endif
  </div>
</body>

</html>
