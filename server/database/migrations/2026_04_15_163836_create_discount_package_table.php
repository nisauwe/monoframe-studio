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
    Schema::create('discount_package', function (Blueprint $table) {
      $table->id();
      $table->foreignId('discount_id')->constrained()->cascadeOnDelete();
      $table->foreignId('package_id')->constrained()->cascadeOnDelete();
      $table->timestamps();

      $table->unique(['discount_id', 'package_id']);
    });
  }

  /**
   * Reverse the migrations.
   */
  public function down(): void
  {
    Schema::dropIfExists('discount_package');
  }
};
