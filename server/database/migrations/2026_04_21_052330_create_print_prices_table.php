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
    Schema::create('print_prices', function (Blueprint $table) {
      $table->id();
      $table->string('size_label');
      $table->bigInteger('base_price')->default(0);
      $table->bigInteger('frame_price')->default(0);
      $table->boolean('is_active')->default(true);
      $table->text('notes')->nullable();
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('print_prices');
  }
};
