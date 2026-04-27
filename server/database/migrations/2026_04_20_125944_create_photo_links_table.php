<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('photo_links', function (Blueprint $table) {
      $table->id();
      $table->foreignId('schedule_booking_id')
        ->constrained('schedule_bookings')
        ->cascadeOnDelete();

      $table->foreignId('photographer_user_id')
        ->nullable()
        ->constrained('users')
        ->nullOnDelete();

      $table->string('drive_url');
      $table->string('drive_label')->nullable();
      $table->text('notes')->nullable();
      $table->timestamp('uploaded_at')->nullable();
      $table->boolean('is_active')->default(true);
      $table->timestamps();

      $table->unique('schedule_booking_id');
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('photo_links');
  }
};
