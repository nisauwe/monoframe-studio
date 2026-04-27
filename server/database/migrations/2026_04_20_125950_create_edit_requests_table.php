<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('edit_requests', function (Blueprint $table) {
      $table->id();

      $table->foreignId('schedule_booking_id')
        ->constrained('schedule_bookings')
        ->cascadeOnDelete();

      $table->foreignId('photo_link_id')
        ->nullable()
        ->constrained('photo_links')
        ->nullOnDelete();

      $table->foreignId('client_user_id')
        ->constrained('users')
        ->cascadeOnDelete();

      $table->foreignId('editor_user_id')
        ->nullable()
        ->constrained('users')
        ->nullOnDelete();

      $table->json('selected_files');
      $table->text('request_notes')->nullable();

      $table->enum('status', ['submitted', 'completed'])->default('submitted');
      $table->timestamp('completed_at')->nullable();
      $table->text('editor_notes')->nullable();

      $table->timestamps();

      $table->unique('schedule_booking_id');
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('edit_requests');
  }
};
