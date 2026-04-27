<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
  public function run(): void
  {
    User::updateOrCreate(
      ['email' => 'anisarisma95@gmail.com'],
      [
        'username' => 'admin',
        'name' => 'Admin Monoframe',
        'phone' => '082323426600',
        'address' => 'Monoframe Studio',
        'role' => 'Admin',
        'is_active' => true,
        'password' => Hash::make('11111111'),
      ]
    );
  }
}
