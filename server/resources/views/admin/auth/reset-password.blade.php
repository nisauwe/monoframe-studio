<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset Password Admin - Monoframe</title>
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
      max-width: 460px;
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
    }

    label {
      display: block;
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #4a5568;
    }

    input {
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

    .error-box {
      background: #fff1f2;
      color: #b42318;
      border: 1px solid #fecdca;
      padding: 12px 14px;
      border-radius: 12px;
      margin-bottom: 18px;
      font-size: 14px;
    }
  </style>
</head>

<body>
  <div class="card">
    <div class="title">Reset Password Admin</div>
    <div class="subtitle">Masukkan password baru untuk akun admin.</div>

    @if ($errors->any())
      <div class="error-box">{{ $errors->first() }}</div>
    @endif

    <form method="POST" action="{{ route('admin.password.update') }}">
      @csrf

      <input type="hidden" name="token" value="{{ $token }}">

      <label>Email</label>
      <input type="email" name="email" value="{{ old('email', $email) }}" placeholder="Email admin">

      <label>Password Baru</label>
      <input type="password" name="password" placeholder="Masukkan password baru">

      <label>Konfirmasi Password</label>
      <input type="password" name="password_confirmation" placeholder="Ulangi password baru">

      <button type="submit" class="btn">Reset Password</button>
    </form>
  </div>
</body>

</html>
