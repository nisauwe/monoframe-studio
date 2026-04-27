<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::table('packages', function (Blueprint $table) {
      if (!Schema::hasColumn('packages', 'location_type')) {
        $table->enum('location_type', ['indoor', 'outdoor'])
          ->nullable()
          ->after('duration_minutes');
      }
    });

    $packages = DB::table('packages')->select('id', 'session_type', 'location')->get();

    foreach ($packages as $package) {
      $raw = strtolower(trim((string) ($package->location ?: $package->session_type)));

      $locationType = str_contains($raw, 'outdoor') ? 'outdoor' : 'indoor';

      DB::table('packages')
        ->where('id', $package->id)
        ->update([
          'location_type' => $locationType,
        ]);
    }

    Schema::table('packages', function (Blueprint $table) {
      if (Schema::hasColumn('packages', 'session_type')) {
        $table->dropColumn('session_type');
      }

      if (Schema::hasColumn('packages', 'location')) {
        $table->dropColumn('location');
      }
    });
  }

  public function down(): void
  {
    Schema::table('packages', function (Blueprint $table) {
      if (!Schema::hasColumn('packages', 'session_type')) {
        $table->string('session_type')->nullable()->after('duration_minutes');
      }

      if (!Schema::hasColumn('packages', 'location')) {
        $table->string('location')->nullable()->after('session_type');
      }
    });

    $packages = DB::table('packages')->select('id', 'location_type')->get();

    foreach ($packages as $package) {
      DB::table('packages')
        ->where('id', $package->id)
        ->update([
          'session_type' => $package->location_type,
          'location' => $package->location_type,
        ]);
    }

    Schema::table('packages', function (Blueprint $table) {
      if (Schema::hasColumn('packages', 'location_type')) {
        $table->dropColumn('location_type');
      }
    });
  }
};
