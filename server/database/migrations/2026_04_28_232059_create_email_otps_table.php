<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
  public function up(): void
  {
    Schema::create('email_otps', function (Blueprint $table) {
      $table->id();
      $table->string('email')->index();
      $table->string('purpose')->index(); // register / reset_password
      $table->string('code_hash');
      $table->json('payload')->nullable();
      $table->unsignedTinyInteger('attempts')->default(0);
      $table->timestamp('expires_at')->index();
      $table->timestamp('resend_available_at')->nullable();
      $table->timestamp('verified_at')->nullable();
      $table->string('ip_address')->nullable();
      $table->timestamps();

      $table->index(['email', 'purpose', 'created_at']);
    });
  }

  public function down(): void
  {
    Schema::dropIfExists('email_otps');
  }
};
