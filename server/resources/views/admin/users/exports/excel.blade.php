<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Data User Monoframe</title>
</head>
<body>
  <table border="1">
    <thead>
      <tr>
        <th colspan="5" style="font-size: 18px; font-weight: bold; text-align: center;">
          DATA USER MONOFRAME STUDIO
        </th>
      </tr>
      <tr>
        <th style="font-weight: bold; background: #dfe7ef;">Nama</th>
        <th style="font-weight: bold; background: #dfe7ef;">Email</th>
        <th style="font-weight: bold; background: #dfe7ef;">Role</th>
        <th style="font-weight: bold; background: #dfe7ef;">Nomor HP</th>
        <th style="font-weight: bold; background: #dfe7ef;">Created</th>
      </tr>
    </thead>
    <tbody>
      @forelse ($users as $user)
        <tr>
          <td>{{ $user->name ?? '-' }}</td>
          <td>{{ $user->email ?? '-' }}</td>
          <td>{{ $user->role ?? '-' }}</td>
          <td>{{ $user->phone ?? '-' }}</td>
          {{ $user->created_at ? $user->created_at->timezone('Asia/Jakarta')->format('d M Y H:i') : '-' }}
        </tr>
      @empty
        <tr>
          <td colspan="5" style="text-align: center;">Tidak ada data user.</td>
        </tr>
      @endforelse
    </tbody>
  </table>
</body>
</html>