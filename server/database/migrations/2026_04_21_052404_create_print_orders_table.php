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
    Schema::create('print_orders', function (Blueprint $table) {
      $table->id();

      $table->foreignId('schedule_booking_id')
        ->constrained('schedule_bookings')
        ->cascadeOnDelete();

      $table->foreignId('client_user_id')
        ->constrained('users')
        ->cascadeOnDelete();

      $table->foreignId('confirmed_by_user_id')
        ->nullable()
        ->constrained('users')
        ->nullOnDelete();

      $table->string('status')->default('requested');
      $table->string('payment_status')->default('unpaid');

      $table->string('delivery_method')->default('pickup'); // pickup | delivery
      $table->string('recipient_name')->nullable();
      $table->string('recipient_phone')->nullable();
      $table->text('delivery_address')->nullable();

      $table->bigInteger('subtotal_amount')->default(0);
      $table->bigInteger('frame_total')->default(0);
      $table->bigInteger('total_amount')->default(0);

      $table->text('client_notes')->nullable();
      $table->text('front_office_notes')->nullable();

      $table->timestamp('ready_at')->nullable();
      $table->timestamp('completed_at')->nullable();

      $table->timestamps();

      $table->unique('schedule_booking_id');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('print_orders');
  }
};
