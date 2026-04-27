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
    Schema::table('packages', function (Blueprint $table) {
      $table->dropColumn([
        'discount_percent',
        'promo_name',
        'discount_start_at',
        'discount_end_at',
        'is_discount_active',
      ]);
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('packages', function (Blueprint $table) {
      $table->unsignedTinyInteger('discount_percent')->nullable();
      $table->string('promo_name')->nullable();
      $table->date('discount_start_at')->nullable();
      $table->date('discount_end_at')->nullable();
      $table->boolean('is_discount_active')->default(false);
    });
  }
};
