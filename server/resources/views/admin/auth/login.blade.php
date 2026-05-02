<!DOCTYPE html>
<html lang="id">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Login Admin - Monoframe Studio</title>

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

  <style>
    :root {
      --mf-blue-dark: #233B93;
      --mf-blue-mid: #344FA5;
      --mf-blue-light: #5E7BDA;
      --mf-soft-1: #F0FAFF;
      --mf-soft-2: #D9F0FA;
      --mf-soft-3: #C5E4F2;
      --mf-text-dark: #17384D;
      --mf-muted: #7A8A99;
      --mf-border: #DDEAF3;
      --mf-danger: #DC2626;
      --mf-success: #16A34A;
    }

    * {
      box-sizing: border-box;
      font-family: 'Public Sans', sans-serif;
    }

    body {
      margin: 0;
      min-height: 100vh;
      overflow-x: hidden;
      background:
        radial-gradient(circle at 10% 20%, rgba(221, 239, 255, 0.65), transparent 28%),
        radial-gradient(circle at 92% 78%, rgba(168, 203, 224, 0.50), transparent 34%),
        linear-gradient(135deg, #EEF7FC 0%, #DCECF7 50%, #C9DCEF 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 28px;
      color: var(--mf-text-dark);
    }

    .auth-bg {
      position: fixed;
      inset: 0;
      overflow: hidden;
      pointer-events: none;
      z-index: 0;
    }

    .blob {
      position: absolute;
      border-radius: 999px;
      filter: blur(0.2px);
    }

    .blob.one {
      width: 360px;
      height: 360px;
      top: -145px;
      right: -115px;
      background: rgba(94, 123, 218, 0.20);
    }

    .blob.two {
      width: 310px;
      height: 310px;
      left: -135px;
      bottom: 50px;
      background: rgba(111, 159, 190, 0.18);
    }

    .blob.three {
      width: 240px;
      height: 240px;
      right: 10%;
      bottom: -110px;
      background: rgba(221, 239, 255, 0.48);
    }

    .dot {
      position: absolute;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.72);
      box-shadow: 0 0 20px rgba(255, 255, 255, 0.55);
    }

    .dot.d1 {
      width: 9px;
      height: 9px;
      top: 18%;
      left: 12%;
    }

    .dot.d2 {
      width: 7px;
      height: 7px;
      top: 22%;
      right: 18%;
    }

    .dot.d3 {
      width: 11px;
      height: 11px;
      bottom: 20%;
      left: 20%;
    }

    .dot.d4 {
      width: 6px;
      height: 6px;
      bottom: 28%;
      right: 13%;
    }

    .auth-shell {
      position: relative;
      z-index: 1;
      width: min(980px, 100%);
      min-height: 560px;
      display: grid;
      grid-template-columns: 1.05fr 0.95fr;
      border-radius: 34px;
      overflow: hidden;
      background: rgba(255, 255, 255, 0.82);
      border: 1px solid rgba(255, 255, 255, 0.78);
      box-shadow:
        0 28px 70px rgba(35, 59, 147, 0.22),
        0 10px 28px rgba(23, 56, 77, 0.10);
      backdrop-filter: blur(16px);
    }

    .brand-panel {
      position: relative;
      isolation: isolate;
      overflow: hidden;
      padding: 48px;
      color: #fff;
      background:
        radial-gradient(circle at 20% 20%, rgba(255, 255, 255, 0.18), transparent 26%),
        linear-gradient(135deg, var(--mf-blue-dark) 0%, var(--mf-blue-mid) 52%, var(--mf-blue-light) 100%);
    }

    .brand-panel::before,
    .brand-panel::after {
      content: '';
      position: absolute;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.12);
      z-index: -1;
    }

    .brand-panel::before {
      width: 280px;
      height: 280px;
      top: -110px;
      right: -92px;
    }

    .brand-panel::after {
      width: 330px;
      height: 330px;
      left: -140px;
      bottom: -130px;
      background: rgba(255, 255, 255, 0.08);
    }

    .mini-label {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 9px 13px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.13);
      border: 1px solid rgba(255, 255, 255, 0.20);
      font-size: 11px;
      font-weight: 900;
      letter-spacing: 1.8px;
      text-transform: uppercase;
    }

    .mini-label span {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #CFEAFF;
      box-shadow: 0 0 18px rgba(207, 234, 255, 0.82);
    }

    .brand-content {
      height: calc(100% - 45px);
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: flex-start;
      gap: 24px;
      position: relative;
      z-index: 2;
    }

    .logo-wrap {
      width: 250px;
      max-width: 100%;
      filter: drop-shadow(0 18px 30px rgba(0, 0, 0, 0.18));
    }

    .logo-wrap img {
      width: 100%;
      display: block;
      object-fit: contain;
    }

    .fallback-logo {
      display: none;
      font-size: 30px;
      font-weight: 900;
      letter-spacing: 1.8px;
      line-height: 1.12;
    }

    .brand-title {
      margin: 0;
      max-width: 420px;
      font-size: 38px;
      line-height: 1.08;
      letter-spacing: -1.1px;
      font-weight: 900;
    }

    .brand-text {
      margin: 0;
      max-width: 390px;
      color: rgba(255, 255, 255, 0.80);
      font-size: 14px;
      line-height: 1.75;
      font-weight: 600;
    }

    .cloud-divider {
      position: absolute;
      top: 0;
      right: -74px;
      width: 148px;
      height: 100%;
      z-index: 3;
      pointer-events: none;
    }

    .cloud-divider span {
      position: absolute;
      display: block;
      border-radius: 999px;
      background: #fff;
      box-shadow: 0 10px 25px rgba(35, 59, 147, 0.06);
    }

    .cloud-divider span:nth-child(1) { width: 132px; height: 132px; top: -28px; right: 12px; }
    .cloud-divider span:nth-child(2) { width: 102px; height: 102px; top: 75px; right: 30px; }
    .cloud-divider span:nth-child(3) { width: 138px; height: 138px; top: 155px; right: 2px; }
    .cloud-divider span:nth-child(4) { width: 98px; height: 98px; top: 285px; right: 35px; }
    .cloud-divider span:nth-child(5) { width: 145px; height: 145px; bottom: 70px; right: -6px; }
    .cloud-divider span:nth-child(6) { width: 110px; height: 110px; bottom: -25px; right: 30px; }

    .form-panel {
      position: relative;
      background: #fff;
      padding: 52px 48px;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .form-card {
      width: 100%;
      max-width: 372px;
    }

    .mobile-logo {
      display: none;
      width: 155px;
      margin: 0 auto 22px;
      filter: drop-shadow(0 14px 24px rgba(35, 59, 147, 0.18));
    }

    .mobile-logo img {
      width: 100%;
      display: block;
    }

    .form-kicker {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 14px;
      padding: 8px 12px;
      border-radius: 999px;
      background: linear-gradient(135deg, var(--mf-soft-1), var(--mf-soft-3));
      color: var(--mf-blue-dark);
      font-size: 11px;
      font-weight: 900;
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    .form-kicker::before {
      content: '';
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--mf-blue-mid);
    }

    .title {
      margin: 0 0 8px;
      font-size: 31px;
      line-height: 1.12;
      font-weight: 900;
      color: var(--mf-text-dark);
      letter-spacing: -0.7px;
    }

    .subtitle {
      margin: 0 0 26px;
      font-size: 14px;
      color: var(--mf-muted);
      line-height: 1.55;
      font-weight: 600;
    }

    .message,
    .error-box {
      padding: 13px 14px;
      border-radius: 17px;
      margin-bottom: 18px;
      font-size: 13px;
      line-height: 1.5;
      font-weight: 700;
    }

    .message {
      background: rgba(22, 163, 74, 0.10);
      color: #067647;
      border: 1px solid rgba(22, 163, 74, 0.18);
    }

    .error-box {
      background: rgba(220, 38, 38, 0.09);
      color: #B42318;
      border: 1px solid rgba(220, 38, 38, 0.16);
    }

    .form-group {
      margin-bottom: 16px;
    }

    label.form-label {
      display: block;
      margin-bottom: 8px;
      font-size: 13px;
      font-weight: 800;
      color: var(--mf-text-dark);
    }

    .input-wrap {
      position: relative;
    }

    .input-icon {
      position: absolute;
      top: 50%;
      left: 15px;
      width: 18px;
      height: 18px;
      transform: translateY(-50%);
      opacity: 0.58;
      color: var(--mf-blue-dark);
      pointer-events: none;
    }

    input[type="email"],
    input[type="password"] {
      width: 100%;
      height: 52px;
      border: 1px solid var(--mf-border);
      border-radius: 18px;
      padding: 0 16px 0 46px;
      font-size: 14px;
      font-weight: 600;
      color: var(--mf-text-dark);
      background: #F8FCFE;
      transition: 0.22s ease;
    }

    input::placeholder {
      color: #A3AFBA;
      font-weight: 600;
    }

    input:focus {
      outline: none;
      border-color: var(--mf-blue-mid);
      background: #fff;
      box-shadow: 0 0 0 4px rgba(52, 79, 165, 0.11);
    }

    .form-options {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      margin: 4px 0 22px;
    }

    .remember {
      display: inline-flex;
      align-items: center;
      gap: 9px;
      font-size: 13px;
      font-weight: 700;
      color: var(--mf-text-dark);
      cursor: pointer;
      user-select: none;
    }

    .remember input {
      width: 17px;
      height: 17px;
      accent-color: var(--mf-blue-dark);
      cursor: pointer;
    }

    .forgot-link {
      font-size: 13px;
      font-weight: 800;
      color: var(--mf-blue-mid);
      text-decoration: none;
      white-space: nowrap;
    }

    .forgot-link:hover {
      color: var(--mf-blue-dark);
      text-decoration: underline;
    }

    .btn {
      width: 100%;
      height: 54px;
      border: none;
      border-radius: 20px;
      background: linear-gradient(135deg, var(--mf-blue-dark), var(--mf-blue-mid), var(--mf-blue-light));
      color: #fff;
      font-size: 15px;
      font-weight: 900;
      letter-spacing: 0.2px;
      cursor: pointer;
      box-shadow: 0 16px 28px rgba(35, 59, 147, 0.25);
      transition: 0.22s ease;
    }

    .btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 20px 34px rgba(35, 59, 147, 0.32);
    }

    .btn:active {
      transform: translateY(0);
      box-shadow: 0 12px 22px rgba(35, 59, 147, 0.22);
    }

    .helper {
      margin-top: 22px;
      text-align: center;
      font-size: 12.5px;
      color: var(--mf-muted);
      font-weight: 600;
      line-height: 1.55;
    }

    .helper strong {
      color: var(--mf-blue-dark);
      font-weight: 900;
    }

    @media (max-width: 860px) {
      body {
        padding: 18px;
        align-items: flex-start;
      }

      .auth-shell {
        min-height: auto;
        display: block;
        border-radius: 30px;
      }

      .brand-panel {
        display: none;
      }

      .form-panel {
        min-height: calc(100vh - 36px);
        padding: 36px 22px;
        background:
          radial-gradient(circle at 10% 0%, rgba(221, 239, 255, 0.8), transparent 36%),
          #fff;
      }

      .mobile-logo {
        display: block;
      }

      .form-card {
        max-width: 420px;
      }

      .title,
      .subtitle,
      .form-kicker {
        text-align: left;
      }
    }

    @media (max-width: 460px) {
      body {
        padding: 0;
      }

      .auth-shell {
        min-height: 100vh;
        border-radius: 0;
        box-shadow: none;
      }

      .form-panel {
        min-height: 100vh;
        padding: 34px 20px;
      }

      .title {
        font-size: 28px;
      }

      .form-options {
        align-items: flex-start;
        flex-direction: column;
      }

      .forgot-link {
        align-self: flex-end;
      }
    }
  </style>
</head>

<body>
  <div class="auth-bg" aria-hidden="true">
    <div class="blob one"></div>
    <div class="blob two"></div>
    <div class="blob three"></div>
    <div class="dot d1"></div>
    <div class="dot d2"></div>
    <div class="dot d3"></div>
    <div class="dot d4"></div>
  </div>

  <main class="auth-shell">
    <section class="brand-panel">
      <div class="cloud-divider" aria-hidden="true">
        <span></span>
        <span></span>
        <span></span>
        <span></span>
        <span></span>
        <span></span>
      </div>

      <div class="mini-label">
        <span></span>
        Admin Panel
      </div>

      <div class="brand-content">
        <div class="logo-wrap">
          <img
            src="{{ asset('assets/img/monoframe/monoframe_logo_full.png') }}"
            alt="Monoframe Studio"
            onerror="this.style.display='none'; this.nextElementSibling.style.display='block';"
          >
          <div class="fallback-logo">MONOFRAME<br>STUDIO</div>
        </div>

        <div>
          <h1 class="brand-title">Kelola studio foto dalam satu dashboard.</h1>
          <p class="brand-text">
            Masuk sebagai admin untuk mengelola paket foto, booking, jadwal, pembayaran,
            keuangan, review klien, dan pengaturan Monoframe Studio.
          </p>
        </div>

      </div>
    </section>

    <section class="form-panel">
      <div class="form-card">
        <div class="mobile-logo">
          <img
            src="{{ asset('assets/img/monoframe/monoframe_logo_full.png') }}"
            alt="Monoframe Studio"
            onerror="this.style.display='none';"
          >
        </div>

        <h2 class="title">Login Admin</h2>
        <p class="subtitle">
          Masuk ke panel admin Monoframe Studio menggunakan email dan password admin.
        </p>

        @if (session('status'))
          <div class="message">{{ session('status') }}</div>
        @endif

        @if ($errors->any())
          <div class="error-box">{{ $errors->first() }}</div>
        @endif

        <form method="POST" action="{{ route('admin.login.submit', [], false) }}">
          @csrf

          <div class="form-group">
            <label class="form-label" for="email">Email Admin</label>
            <div class="input-wrap">
              <svg class="input-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20 4H4C2.897 4 2 4.897 2 6v12c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V6c0-1.103-.897-2-2-2Zm0 4.236-8 4.882-8-4.882V6l8 4.882L20 6v2.236Z"/>
              </svg>
              <input
                id="email"
                type="email"
                name="email"
                value="{{ old('email') }}"
                placeholder="admin@monoframe.com"
                autocomplete="email"
                autofocus
              >
            </div>
          </div>

          <div class="form-group">
            <label class="form-label" for="password">Password</label>
            <div class="input-wrap">
              <svg class="input-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18 8h-1V6c0-2.757-2.243-5-5-5S7 3.243 7 6v2H6c-1.103 0-2 .897-2 2v10c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2V10c0-1.103-.897-2-2-2ZM9 6c0-1.654 1.346-3 3-3s3 1.346 3 3v2H9V6Zm4 10.723V18h-2v-1.277A1.993 1.993 0 0 1 10 15c0-1.103.897-2 2-2s2 .897 2 2c0 .738-.405 1.376-1 1.723Z"/>
              </svg>
              <input
                id="password"
                type="password"
                name="password"
                placeholder="Masukkan password"
                autocomplete="current-password"
              >
            </div>
          </div>

          <div class="form-options">
            <label class="remember">
              <input type="checkbox" name="remember">
              Ingat saya
            </label>

            <a href="{{ route('admin.password.request') }}" class="forgot-link">
              Lupa password?
            </a>
          </div>

          <button type="submit" class="btn">Masuk Dashboard</button>
        </form>

        <div class="helper">
          Khusus akses internal <strong>Monoframe Studio</strong>.
        </div>
      </div>
    </section>
  </main>
</body>

</html>
