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
    Schema::table('schedule_rules', function (Blueprint $table) {
      $table->unsignedInteger('indoor_buffer_minutes')
        ->default(15)
        ->after('buffer_minutes');

      $table->unsignedInteger('outdoor_buffer_minutes')
        ->default(45)
        ->after('indoor_buffer_minutes');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('schedule_rules', function (Blueprint $table) {
      $table->dropColumn([
        'indoor_buffer_minutes',
        'outdoor_buffer_minutes',
      ]);
    });
  }
};
