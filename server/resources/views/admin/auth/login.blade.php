<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login Admin - Monoframe</title>
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
      max-width: 420px;
      background: #fff;
      border-radius: 22px;
      box-shadow: 0 14px 35px rgba(0, 0, 0, 0.08);
      padding: 32px;
    }

    .title {
      font-size: 28px;
      font-weight: 700;
      color: #2f3e4d;
      margin-bottom: 8px;
    }

    .subtitle {
      font-size: 14px;
      color: #7b8794;
      margin-bottom: 24px;
    }

    .form-group {
      margin-bottom: 18px;
    }

    label {
      display: block;
      margin-bottom: 8px;
      font-size: 14px;
      font-weight: 600;
      color: #4a5568;
    }

    input[type="email"],
    input[type="password"] {
      width: 100%;
      height: 46px;
      border: 1px solid #d9dee7;
      border-radius: 12px;
      padding: 0 14px;
      font-size: 14px;
    }

    input:focus {
      outline: none;
      border-color: #696cff;
    }

    .remember {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 20px;
      font-size: 14px;
      color: #4a5568;
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
      background: #eff8ff;
      color: #175cd3;
      border: 1px solid #b2ddff;
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
      color: #7b8794;
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
    <div class="title">Login Admin</div>
    <div class="subtitle">Masuk ke panel admin Monoframe Studio</div>

    @if (session('status'))
      <div class="message">{{ session('status') }}</div>
    @endif

    @if ($errors->any())
      <div class="error-box">{{ $errors->first() }}</div>
    @endif

    <form method="POST" action="{{ route('admin.login.submit') }}">
      @csrf

      <div class="form-group">
        <label>Email</label>
        <input type="email" name="email" value="{{ old('email') }}" placeholder="Masukkan email admin">
      </div>

      <div class="form-group">
        <label>Password</label>
        <input type="password" name="password" placeholder="Masukkan password">
      </div>

      <label class="remember">
        <input type="checkbox" name="remember">
        Ingat saya
      </label>

      <button type="submit" class="btn">Masuk</button>
    </form>

    <div class="helper">
      <a href="{{ route('admin.password.request') }}">Lupa password?</a>
    </div>
  </div>
</body>

</html>
