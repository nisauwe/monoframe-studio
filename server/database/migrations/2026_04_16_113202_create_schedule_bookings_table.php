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
    Schema::create('schedule_bookings', function (Blueprint $table) {
      $table->id();

      $table->foreignId('package_id')->constrained('packages')->cascadeOnDelete();

      $table->string('client_name');
      $table->string('client_phone')->nullable();
      $table->string('photographer_name')->nullable();

      $table->date('booking_date');
      $table->time('start_time');
      $table->time('end_time');

      $table->unsignedInteger('duration_minutes');
      $table->unsignedInteger('extra_duration_minutes')->default(0);
      $table->decimal('extra_duration_fee', 12, 2)->default(0);

      $table->enum('status', ['pending', 'confirmed', 'completed', 'cancelled'])->default('confirmed');
      $table->enum('source', ['client', 'manual_request', 'admin'])->default('admin');

      $table->text('notes')->nullable();
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('schedule_bookings');
  }
};
