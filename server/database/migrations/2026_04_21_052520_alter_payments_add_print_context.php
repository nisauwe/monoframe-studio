<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::table('payments', function (Blueprint $table) {
      $table->enum('payment_context', ['booking', 'print_order'])
        ->default('booking')
        ->after('schedule_booking_id');

      $table->foreignId('print_order_id')
        ->nullable()
        ->after('payment_context')
        ->constrained('print_orders')
        ->nullOnDelete();
    });
  }

  public function down(): void
  {
    Schema::table('payments', function (Blueprint $table) {
      $table->dropConstrainedForeignId('print_order_id');
      $table->dropColumn('payment_context');
    });
  }
};
