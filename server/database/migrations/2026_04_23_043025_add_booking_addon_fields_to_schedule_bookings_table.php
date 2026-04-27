<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('schedule_bookings', function (Blueprint $table) {
            $table->unsignedInteger('extra_duration_units')->default(0)->after('duration_minutes');
            $table->string('video_addon_type')->nullable()->after('extra_duration_fee');
            $table->string('video_addon_name')->nullable()->after('video_addon_type');
            $table->unsignedBigInteger('video_addon_price')->default(0)->after('video_addon_name');
        });
    }

    public function down(): void
    {
        Schema::table('schedule_bookings', function (Blueprint $table) {
            $table->dropColumn([
                'extra_duration_units',
                'video_addon_type',
                'video_addon_name',
                'video_addon_price',
            ]);
        });
    }
};
