<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('roles', function (Blueprint $table) {
      $table->id();
      $table->string('name')->unique();
      $table->string('slug')->unique();
      $table->boolean('is_active')->default(true);
      $table->boolean('is_system')->default(false);
      $table->unsignedInteger('display_order')->default(0);
      $table->timestamps();
    });

    Schema::create('permissions', function (Blueprint $table) {
      $table->id();
      $table->string('key')->unique();
      $table->string('module_key');
      $table->string('module_label');
      $table->string('label');
      $table->string('description')->nullable();
      $table->boolean('admin_only')->default(false);
      $table->unsignedInteger('module_order')->default(0);
      $table->unsignedInteger('sort_order')->default(0);
      $table->timestamps();
    });

    Schema::create('role_permissions', function (Blueprint $table) {
      $table->id();
      $table->string('role_name');
      $table->string('permission_key');
      $table->timestamps();

      $table->unique(['role_name', 'permission_key']);
    });

    $roles = [
      ['name' => 'Admin', 'slug' => 'admin', 'is_system' => true, 'display_order' => 1],
      ['name' => 'Front Office', 'slug' => 'front-office', 'is_system' => true, 'display_order' => 2],
      ['name' => 'Fotografer', 'slug' => 'fotografer', 'is_system' => true, 'display_order' => 3],
      ['name' => 'Editor', 'slug' => 'editor', 'is_system' => true, 'display_order' => 4],
      ['name' => 'Klien', 'slug' => 'klien', 'is_system' => true, 'display_order' => 5],
    ];

    DB::table('roles')->insert(array_map(function ($role) {
      return [
        ...$role,
        'is_active' => true,
        'created_at' => now(),
        'updated_at' => now(),
      ];
    }, $roles));

    $permissions = [
      [
        'key' => 'packages.view',
        'module_key' => 'packages',
        'module_label' => 'Paket & Kategori',
        'label' => 'Lihat paket dan kategori',
        'description' => 'Melihat daftar paket dan kategori.',
        'admin_only' => false,
        'module_order' => 1,
        'sort_order' => 1,
      ],
      [
        'key' => 'packages.manage',
        'module_key' => 'packages',
        'module_label' => 'Paket & Kategori',
        'label' => 'Buat paket dan kategori',
        'description' => 'Menambah, mengubah, dan mengelola paket & kategori.',
        'admin_only' => false,
        'module_order' => 1,
        'sort_order' => 2,
      ],
      [
        'key' => 'schedules.operational.view',
        'module_key' => 'schedules',
        'module_label' => 'Jadwal & Slot',
        'label' => 'Lihat operasional jadwal',
        'description' => 'Melihat dan membuka tab operasional jadwal.',
        'admin_only' => false,
        'module_order' => 2,
        'sort_order' => 1,
      ],
      [
        'key' => 'schedules.daily.view',
        'module_key' => 'schedules',
        'module_label' => 'Jadwal & Slot',
        'label' => 'Lihat jadwal harian',
        'description' => 'Melihat jadwal harian studio.',
        'admin_only' => false,
        'module_order' => 2,
        'sort_order' => 2,
      ],
      [
        'key' => 'bookings.view',
        'module_key' => 'bookings',
        'module_label' => 'Booking',
        'label' => 'Lihat booking',
        'description' => 'Melihat daftar booking.',
        'admin_only' => false,
        'module_order' => 3,
        'sort_order' => 1,
      ],
      [
        'key' => 'bookings.manual.create',
        'module_key' => 'bookings',
        'module_label' => 'Booking',
        'label' => 'Buat booking manual',
        'description' => 'Menambah booking manual dari backend.',
        'admin_only' => false,
        'module_order' => 3,
        'sort_order' => 2,
      ],
      [
        'key' => 'calendar.view',
        'module_key' => 'calendar',
        'module_label' => 'Kalender',
        'label' => 'Lihat kalender',
        'description' => 'Melihat kalender jadwal bulanan/mingguan/harian.',
        'admin_only' => false,
        'module_order' => 4,
        'sort_order' => 1,
      ],
      [
        'key' => 'finance.report.view',
        'module_key' => 'finance',
        'module_label' => 'Keuangan',
        'label' => 'Akses laporan keuangan',
        'description' => 'Melihat laporan keuangan.',
        'admin_only' => true,
        'module_order' => 5,
        'sort_order' => 1,
      ],
      [
        'key' => 'photographer.assign',
        'module_key' => 'tasks',
        'module_label' => 'Tugas Fotografer',
        'label' => 'Assign tugas fotografer',
        'description' => 'Menetapkan fotografer ke booking tertentu.',
        'admin_only' => true,
        'module_order' => 6,
        'sort_order' => 1,
      ],
      [
        'key' => 'photos.upload',
        'module_key' => 'photos',
        'module_label' => 'Hasil Foto',
        'label' => 'Upload hasil foto',
        'description' => 'Mengunggah hasil foto.',
        'admin_only' => true,
        'module_order' => 7,
        'sort_order' => 1,
      ],
      [
        'key' => 'users.manage',
        'module_key' => 'users',
        'module_label' => 'Sistem',
        'label' => 'Kelola user',
        'description' => 'Mengelola akun user.',
        'admin_only' => true,
        'module_order' => 8,
        'sort_order' => 1,
      ],
      [
        'key' => 'system.settings.manage',
        'module_key' => 'system',
        'module_label' => 'Sistem',
        'label' => 'Pengaturan sistem',
        'description' => 'Mengelola konfigurasi sistem.',
        'admin_only' => true,
        'module_order' => 8,
        'sort_order' => 2,
      ],
    ];

    DB::table('permissions')->insert(array_map(function ($permission) {
      return [
        ...$permission,
        'created_at' => now(),
        'updated_at' => now(),
      ];
    }, $permissions));

    $defaultRolePermissions = [
      'Admin' => collect($permissions)->pluck('key')->all(),
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

    $rows = [];
    foreach ($defaultRolePermissions as $roleName => $keys) {
      foreach ($keys as $key) {
        $rows[] = [
          'role_name' => $roleName,
          'permission_key' => $key,
          'created_at' => now(),
          'updated_at' => now(),
        ];
      }
    }

    if (!empty($rows)) {
      DB::table('role_permissions')->insert($rows);
    }
  }

  public function down(): void
  {
    Schema::dropIfExists('role_permissions');
    Schema::dropIfExists('permissions');
    Schema::dropIfExists('roles');
  }
};
