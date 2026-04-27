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
    Schema::create('schedule_booking_slot', function (Blueprint $table) {
      $table->id();
      $table->foreignId('schedule_booking_id')->constrained('schedule_bookings')->cascadeOnDelete();
      $table->foreignId('schedule_slot_id')->constrained('schedule_slots')->cascadeOnDelete();
      $table->timestamps();

      $table->unique(['schedule_booking_id', 'schedule_slot_id'], 'booking_slot_unique');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('schedule_booking_slot');
  }
};
