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
      $table->string('promo_name')->nullable()->after('discount_percent');
      $table->date('discount_start_at')->nullable()->after('promo_name');
      $table->date('discount_end_at')->nullable()->after('discount_start_at');
      $table->boolean('is_discount_active')->default(false)->after('discount_end_at');
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::table('packages', function (Blueprint $table) {
      $table->dropColumn([
        'promo_name',
        'discount_start_at',
        'discount_end_at',
        'is_discount_active',
      ]);
    });
  }
};
