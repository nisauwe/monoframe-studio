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
    Schema::create('schedule_slots', function (Blueprint $table) {
      $table->id();
      $table->date('schedule_date');
      $table->time('start_time');
      $table->time('end_time');

      $table->unsignedInteger('capacity_total')->default(1);
      $table->unsignedInteger('booked_count')->default(0);

      $table->boolean('is_active')->default(true);
      $table->enum('source', ['regular', 'manual_request', 'override'])->default('regular');
      $table->text('notes')->nullable();

      $table->timestamps();

      $table->unique(['schedule_date', 'start_time', 'end_time', 'source'], 'schedule_slot_unique');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('schedule_slots');
  }
};
