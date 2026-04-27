<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use App\Models\Role;
use App\Models\RolePermission;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;

class RoleAccessController extends Controller
{
  public function index(Request $request)
  {
    $roles = Role::where('is_active', true)
      ->orderBy('display_order')
      ->get();

    $permissions = Permission::orderBy('module_order')
      ->orderBy('sort_order')
      ->get()
      ->groupBy('module_label');

    $rolePermissionMap = RolePermission::get()
      ->groupBy('role_name')
      ->map(fn($items) => $items->pluck('permission_key')->all())
      ->toArray();

    $usersQuery = User::query();

    if ($request->filled('search')) {
      $search = $request->search;
      $usersQuery->where(function ($q) use ($search) {
        $q->where('name', 'like', "%{$search}%")
          ->orWhere('email', 'like', "%{$search}%");
      });
    }

    if ($request->filled('role') && $request->role !== 'Semua Role') {
      $usersQuery->where('role', $request->role);
    }

    $users = $usersQuery->latest()->paginate(10)->withQueryString();

    $totalRoles = Role::count();
    $activeRoles = Role::where('is_active', true)->count();
    $restrictedUsers = Schema::hasColumn('users', 'is_active')
      ? User::where('is_active', false)->count()
      : 0;

    return view('admin.roles-akses.index', compact(
      'roles',
      'permissions',
      'rolePermissionMap',
      'users',
      'totalRoles',
      'activeRoles',
      'restrictedUsers'
    ));
  }

  public function storeRole(Request $request)
  {
    $validated = $request->validate([
      'name' => ['required', 'string', 'max:50', 'unique:roles,name'],
      'clone_from' => ['nullable', 'exists:roles,name'],
    ]);

    $role = Role::create([
      'name' => $validated['name'],
      'slug' => Str::slug($validated['name']),
      'is_active' => true,
      'is_system' => false,
      'display_order' => (int) Role::max('display_order') + 1,
    ]);

    if (!empty($validated['clone_from'])) {
      $sourcePermissions = RolePermission::where('role_name', $validated['clone_from'])->pluck('permission_key');

      $rows = $sourcePermissions->map(fn($permissionKey) => [
        'role_name' => $role->name,
        'permission_key' => $permissionKey,
        'created_at' => now(),
        'updated_at' => now(),
      ])->all();

      if (!empty($rows)) {
        RolePermission::insert($rows);
      }
    }

    return back()->with('success', 'Role baru berhasil ditambahkan.');
  }

  public function updatePermissions(Request $request)
  {
    $roles = Role::where('is_active', true)->get();
    $allPermissionKeys = Permission::pluck('key')->all();
    $nonAdminPermissionKeys = Permission::where('admin_only', false)->pluck('key')->all();

    DB::transaction(function () use ($roles, $request, $allPermissionKeys, $nonAdminPermissionKeys) {
      foreach ($roles as $role) {
        RolePermission::where('role_name', $role->name)->delete();

        if ($role->name === 'Admin') {
          $keys = $allPermissionKeys;
        } else {
          $keys = $request->input("permissions.{$role->name}", []);
          $keys = array_values(array_intersect($keys, $nonAdminPermissionKeys));
        }

        $rows = collect($keys)->unique()->map(fn($permissionKey) => [
          'role_name' => $role->name,
          'permission_key' => $permissionKey,
          'created_at' => now(),
          'updated_at' => now(),
        ])->all();

        if (!empty($rows)) {
          RolePermission::insert($rows);
        }
      }
    });

    return back()->with('success', 'Hak akses role berhasil diperbarui.');
  }

  public function resetDefaults()
  {
    $defaultRolePermissions = [
      'Admin' => Permission::pluck('key')->all(),
      'Front Office' => [
        'packages.view',
        'packages.manage',
        'schedules.operational.view',
        'schedules.daily.view',
        'bookings.view',
        'bookings.manual.create',
        'calendar.view',
      ],
      'Fotografer' => [
        'schedules.daily.view',
        'bookings.view',
        'calendar.view',
      ],
      'Editor' => [
        'bookings.view',
        'calendar.view',
      ],
      'Klien' => [],
    ];

    DB::transaction(function () use ($defaultRolePermissions) {
      RolePermission::query()->delete();

      $rows = [];
      foreach ($defaultRolePermissions as $roleName => $keys) {
        foreach ($keys as $permissionKey) {
          $rows[] = [
            'role_name' => $roleName,
            'permission_key' => $permissionKey,
            'created_at' => now(),
            'updated_at' => now(),
          ];
        }
      }

      if (!empty($rows)) {
        RolePermission::insert($rows);
      }
    });

    return back()->with('success', 'Konfigurasi default berhasil dipulihkan.');
  }

  public function toggleUserAccess(User $user)
  {
    if (!Schema::hasColumn('users', 'is_active')) {
      return back()->with('error', 'Kolom is_active belum ada di tabel users.');
    }

    if (Auth::id() === $user->id && $user->role === 'Admin' && $user->is_active) {
      return back()->with('error', 'Admin yang sedang login tidak bisa menonaktifkan akun sendiri.');
    }

    $user->update([
      'is_active' => !$user->is_active,
    ]);

    return back()->with('success', 'Status akses user berhasil diubah.');
  }
}
