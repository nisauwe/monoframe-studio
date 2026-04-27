<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('booking_trackings', function (Blueprint $table) {
      $table->id();
      $table->foreignId('schedule_booking_id')
        ->constrained('schedule_bookings')
        ->cascadeOnDelete();

      $table->unsignedTinyInteger('stage_order');
      $table->string('stage_key'); // booking, dp_payment, full_payment, shooting, photo_upload, edit_upload, print, review
      $table->string('stage_name');

      $table->enum('status', ['pending', 'current', 'done', 'skipped'])
        ->default('pending');

      $table->text('description')->nullable();
      $table->timestamp('occurred_at')->nullable();
      $table->json('meta')->nullable();

      $table->timestamps();

      $table->unique(['schedule_booking_id', 'stage_key']);
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('booking_trackings');
  }
};
