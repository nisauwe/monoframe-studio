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
    Schema::create('print_order_items', function (Blueprint $table) {
      $table->id();

      $table->foreignId('print_order_id')
        ->constrained('print_orders')
        ->cascadeOnDelete();

      $table->foreignId('print_price_id')
        ->constrained('print_prices')
        ->cascadeOnDelete();

      $table->string('file_name');
      $table->unsignedInteger('qty')->default(1);
      $table->boolean('use_frame')->default(false);

      $table->bigInteger('unit_print_price')->default(0);
      $table->bigInteger('unit_frame_price')->default(0);
      $table->bigInteger('line_total')->default(0);

      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('print_order_items');
  }
};
