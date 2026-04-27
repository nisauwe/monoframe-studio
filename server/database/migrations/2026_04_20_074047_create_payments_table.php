<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('payments', function (Blueprint $table) {
      $table->id();

      $table->foreignId('schedule_booking_id')
        ->nullable()
        ->constrained('schedule_bookings')
        ->nullOnDelete();

      $table->foreignId('payment_gateway_id')
        ->nullable()
        ->constrained('payment_gateways')
        ->nullOnDelete();

      $table->string('provider')->default('midtrans');
      $table->string('order_id')->unique();
      $table->string('transaction_id')->nullable();

      $table->bigInteger('base_amount')->default(0);
      $table->bigInteger('admin_fee')->default(0);
      $table->bigInteger('gross_amount')->default(0);

      $table->string('snap_token')->nullable();
      $table->text('snap_redirect_url')->nullable();

      $table->string('payment_type')->nullable();
      $table->string('transaction_status')->default('created');
      $table->string('fraud_status')->nullable();
      $table->text('status_message')->nullable();

      $table->string('payment_code')->nullable();
      $table->json('va_numbers')->nullable();
      $table->text('pdf_url')->nullable();

      $table->timestamp('initiated_at')->nullable();
      $table->timestamp('paid_at')->nullable();
      $table->timestamp('expired_at')->nullable();
      $table->timestamp('settled_at')->nullable();

      $table->json('payload')->nullable();

      $table->timestamps();
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('payments');
  }
};
