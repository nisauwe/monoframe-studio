<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  /**
   * Run the migrations.
   */
  public function up(): void
  {
    Schema::table('schedule_bookings', function (Blueprint $table) {
      $table->foreignId('client_user_id')
        ->nullable()
        ->after('package_id')
        ->constrained('users')
        ->nullOnDelete();

      $table->foreignId('photographer_user_id')
        ->nullable()
        ->after('client_user_id')
        ->constrained('users')
        ->nullOnDelete();

      $table->enum('location_type', ['indoor', 'outdoor'])
        ->default('indoor')
        ->after('photographer_name');

      $table->string('location_name')
        ->nullable()
        ->after('location_type');

      $table->time('blocked_until')
        ->nullable()
        ->after('end_time');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('schedule_bookings', function (Blueprint $table) {
      $table->dropConstrainedForeignId('client_user_id');
      $table->dropConstrainedForeignId('photographer_user_id');
      $table->dropColumn(['location_type', 'location_name', 'blocked_until']);
    });
  }
};
