<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('payment_gateway_logs', function (Blueprint $table) {
      $table->id();
      $table->foreignId('payment_gateway_id')->nullable()->constrained('payment_gateways')->nullOnDelete();
      $table->string('activity');
      $table->string('status')->default('info');
      $table->text('message')->nullable();
      $table->json('payload')->nullable();
      $table->timestamps();
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('payment_gateway_logs');
  }
};
