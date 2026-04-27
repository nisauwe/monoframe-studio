<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('call_center_contacts', function (Blueprint $table) {
            $table->id();

            $table->string('title');
            $table->string('division')->nullable();
            $table->text('description')->nullable();

            $table->string('contact_person')->nullable();

            // whatsapp, instagram, tiktok, email, phone, website
            $table->string('platform')->default('whatsapp');

            // nomor WA / username IG / username TikTok / email / URL
            $table->string('contact_value');

            // untuk WhatsApp bisa diisi nomor yang sudah dinormalisasi,
            // untuk platform lain boleh null
            $table->string('whatsapp_number')->nullable();

            // kalau platform website / instagram / tiktok bisa simpan URL langsung
            $table->string('url')->nullable();

            $table->string('service_hours')->nullable();

            // low, normal, high, urgent
            $table->string('priority')->default('normal');

            // active, standby, inactive
            $table->string('status')->default('active');

            $table->boolean('is_emergency')->default(false);
            $table->boolean('is_visible_to_client')->default(true);

            $table->unsignedInteger('sort_order')->default(0);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('call_center_contacts');
    }
};
