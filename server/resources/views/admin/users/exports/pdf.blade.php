<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Data User Monoframe</title>

  <style>
    body {
      font-family: DejaVu Sans, sans-serif;
      color: #162b4d;
      font-size: 12px;
      margin: 0;
      padding: 0;
    }

    .header {
      margin-bottom: 18px;
      padding-bottom: 12px;
      border-bottom: 2px solid #5873dc;
    }

    .title {
      font-size: 20px;
      font-weight: bold;
      margin-bottom: 4px;
      color: #162b4d;
    }

    .subtitle {
      font-size: 12px;
      color: #728199;
    }

    .meta {
      margin-top: 8px;
      font-size: 11px;
      color: #728199;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th {
      background: #eef2ff;
      color: #162b4d;
      font-weight: bold;
      text-align: left;
      padding: 9px 8px;
      border: 1px solid #dfe7ef;
      font-size: 11px;
      text-transform: uppercase;
    }

    td {
      padding: 8px;
      border: 1px solid #dfe7ef;
      vertical-align: top;
    }

    tr:nth-child(even) td {
      background: #f8fbfd;
    }

    .role-badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 999px;
      background: #eef2ff;
      color: #5873dc;
      font-weight: bold;
      font-size: 11px;
    }

    .empty {
      text-align: center;
      color: #728199;
      padding: 18px;
    }

    .footer {
      margin-top: 16px;
      font-size: 10px;
      color: #728199;
      text-align: right;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">Data User Monoframe Studio</div>
    <div class="subtitle">Daftar user berdasarkan data pada sistem admin Monoframe.</div>
    <div class="meta">
      Dicetak pada: {{ now('Asia/Jakarta')->format('d M Y H:i') }} WIB |
      Total data: {{ $users->count() }}
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th style="width: 22%;">Nama</th>
        <th style="width: 27%;">Email</th>
        <th style="width: 16%;">Role</th>
        <th style="width: 17%;">Nomor HP</th>
        <th style="width: 18%;">Created</th>
      </tr>
    </thead>

    <tbody>
      @forelse ($users as $user)
        <tr>
          <td>{{ $user->name ?? '-' }}</td>
          <td>{{ $user->email ?? '-' }}</td>
          <td>
            <span class="role-badge">{{ $user->role ?? '-' }}</span>
          </td>
          <td>{{ $user->phone ?? '-' }}</td>
          <td>{{ $user->created_at ? $user->created_at->format('d M Y H:i') : '-' }}</td>
        </tr>
      @empty
        <tr>
          <td colspan="5" class="empty">Tidak ada data user.</td>
        </tr>
      @endforelse
    </tbody>
  </table>

  <div class="footer">
    Monoframe Studio - Export Data User
  </div>
</body>
</html>