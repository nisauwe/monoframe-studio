<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Lupa Password Admin - Monoframe</title>
  <link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * {
      box-sizing: border-box;
      font-family: 'Public Sans', sans-serif;
    }

    body {
      margin: 0;
      background: #f5f7fb;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .card {
      width: 100%;
      max-width: 440px;
      background: #fff;
      border-radius: 22px;
      box-shadow: 0 14px 35px rgba(0, 0, 0, 0.08);
      padding: 32px;
    }

    .title {
      font-size: 26px;
      font-weight: 700;
      color: #2f3e4d;
      margin-bottom: 8px;
    }

    .subtitle {
      font-size: 14px;
      color: #7b8794;
      margin-bottom: 24px;
      line-height: 1.6;
    }

    label {
      display: block;
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #4a5568;
    }

    input[type="email"] {
      width: 100%;
      height: 46px;
      border: 1px solid #d9dee7;
      border-radius: 12px;
      padding: 0 14px;
      font-size: 14px;
      margin-bottom: 18px;
    }

    .btn {
      width: 100%;
      height: 46px;
      border: none;
      border-radius: 12px;
      background: #696cff;
      color: #fff;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
    }

    .btn:hover {
      background: #5b5ef5;
    }

    .message {
      background: #ecfdf3;
      color: #067647;
      border: 1px solid #abefc6;
      padding: 12px 14px;
      border-radius: 12px;
      margin-bottom: 18px;
      font-size: 14px;
    }

    .error-box {
      background: #fff1f2;
      color: #b42318;
      border: 1px solid #fecdca;
      padding: 12px 14px;
      border-radius: 12px;
      margin-bottom: 18px;
      font-size: 14px;
    }

    .helper {
      text-align: center;
      margin-top: 18px;
      font-size: 13px;
    }

    .helper a {
      color: #696cff;
      text-decoration: none;
      font-weight: 600;
    }
  </style>
</head>

<body>
  <div class="card">
    <div class="title">Lupa Password Admin</div>
    <div class="subtitle">Masukkan email admin. Link reset password akan dikirim ke email tersebut.</div>

    @if (session('status'))
      <div class="message">{{ session('status') }}</div>
    @endif

    @if ($errors->any())
      <div class="error-box">{{ $errors->first() }}</div>
    @endif

    <form method="POST" action="{{ route('admin.password.email') }}">
      @csrf

      <label>Email Admin</label>
      <input type="email" name="email" value="{{ old('email') }}" placeholder="Masukkan email admin">

      <button type="submit" class="btn">Kirim Link Reset</button>
    </form>

    <div class="helper">
      <a href="{{ route('admin.login') }}">Kembali ke login</a>
    </div>
  </div>
</body>

</html>
