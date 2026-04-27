<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckPermission
{
  public function handle(Request $request, Closure $next, string $permissionKey): Response
  {
    $user = $request->user();

    if (!$user) {
      abort(403);
    }

    if (isset($user->is_active) && !$user->is_active) {
      abort(403, 'Akun Anda dinonaktifkan.');
    }

    if (!$user->hasPermission($permissionKey)) {
      abort(403, 'Anda tidak memiliki akses ke fitur ini.');
    }

    return $next($request);
  }
}
