<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('schedule_rules', function (Blueprint $table) {
            $table->dropColumn([
                'open_time',
                'close_time',
                'slot_interval_minutes',
                'buffer_minutes',
                'default_capacity',
            ]);
        });
    }

    public function down(): void
    {
        Schema::table('schedule_rules', function (Blueprint $table) {
            $table->time('open_time')->nullable();
            $table->time('close_time')->nullable();
            $table->integer('slot_interval_minutes')->nullable();
            $table->integer('buffer_minutes')->nullable();
            $table->integer('default_capacity')->nullable();
        });
    }
};
