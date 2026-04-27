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
    Schema::create('schedule_rules', function (Blueprint $table) {
      $table->id();
      $table->unsignedTinyInteger('day_of_week')->unique(); // 0=minggu, 1=senin, dst
      $table->string('day_name');
      $table->boolean('is_active')->default(true);
      $table->time('open_time')->nullable();
      $table->time('close_time')->nullable();

      $table->unsignedInteger('slot_interval_minutes')->default(30);
      $table->unsignedInteger('buffer_minutes')->default(0);
      $table->unsignedInteger('default_capacity')->default(1);

      $table->unsignedInteger('extra_duration_minutes')->default(30);
      $table->decimal('extra_duration_fee', 12, 2)->default(150000);

      $table->boolean('allow_manual_request')->default(true);
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('schedule_rules');
  }
};
