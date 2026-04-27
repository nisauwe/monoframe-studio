<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_addon_settings', function (Blueprint $table) {
            $table->id();
            $table->string('addon_key')->unique();
            $table->string('addon_name');
            $table->unsignedBigInteger('price')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        DB::table('booking_addon_settings')->insert([
            [
                'addon_key' => 'iphone',
                'addon_name' => 'Video Cinematic - iPhone',
                'price' => 0,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'addon_key' => 'camera',
                'addon_name' => 'Video Cinematic - Camera',
                'price' => 0,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_addon_settings');
    }
};
