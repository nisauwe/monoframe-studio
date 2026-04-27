<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureApiRole
{
  public function handle(Request $request, Closure $next, string ...$roles): Response
  {
    $user = $request->user();

    if (!$user) {
      return response()->json([
        'message' => 'Unauthenticated'
      ], 401);
    }

    if (!$user->is_active) {
      return response()->json([
        'message' => 'Akun dinonaktifkan'
      ], 403);
    }

    if (!in_array($user->role, $roles)) {
      return response()->json([
        'message' => 'Akses ditolak'
      ], 403);
    }

    return $next($request);
  }
}
