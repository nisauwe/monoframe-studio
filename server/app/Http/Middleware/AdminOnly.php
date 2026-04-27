<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminOnly
{
  public function handle(Request $request, Closure $next): Response
  {
    $user = $request->user();

    if (!$user) {
      return redirect()->route('admin.login');
    }

    if (($user->role ?? null) !== 'Admin') {
      abort(403, 'Akses hanya untuk admin.');
    }

    if (isset($user->is_active) && !$user->is_active) {
      abort(403, 'Akun admin sedang dinonaktifkan.');
    }

    return $next($request);
  }
}
