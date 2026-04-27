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
    Schema::create('discounts', function (Blueprint $table) {
      $table->id();
      $table->foreignId('category_id')->constrained()->cascadeOnDelete();
      $table->string('promo_name')->nullable();
      $table->unsignedTinyInteger('discount_percent');
      $table->date('discount_start_at')->nullable();
      $table->date('discount_end_at')->nullable();
      $table->boolean('is_active')->default(true);
      $table->timestamps();
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('discounts');
  }
};
