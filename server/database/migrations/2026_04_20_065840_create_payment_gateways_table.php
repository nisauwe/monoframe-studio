<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('payment_gateways', function (Blueprint $table) {
      $table->id();
      $table->string('provider')->default('midtrans')->unique();
      $table->enum('environment', ['sandbox', 'production'])->default('sandbox');

      $table->string('merchant_id')->nullable();
      $table->text('client_key')->nullable();
      $table->text('server_key')->nullable();

      $table->string('snap_url')->nullable();
      $table->string('api_base_url')->nullable();

      $table->string('notification_url')->nullable();
      $table->string('finish_url')->nullable();
      $table->string('unfinish_url')->nullable();
      $table->string('error_url')->nullable();

      $table->unsignedInteger('expiry_minutes')->default(60);
      $table->integer('admin_fee')->default(0);

      $table->json('enabled_payment_types')->nullable();

      $table->boolean('is_active')->default(true);
      $table->boolean('auto_update_status')->default(true);
      $table->boolean('is_visible_to_client')->default(true);
      $table->boolean('webhook_enabled')->default(true);

      $table->timestamp('last_tested_at')->nullable();
      $table->string('last_test_status')->nullable();
      $table->text('last_test_message')->nullable();

      $table->timestamps();
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('payment_gateways');
  }
};
