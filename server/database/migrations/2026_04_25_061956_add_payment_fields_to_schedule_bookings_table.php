<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('schedule_bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('schedule_bookings', 'payment_status')) {
                $table->string('payment_status')->default('unpaid')->after('status');
            }

            if (!Schema::hasColumn('schedule_bookings', 'payment_order_id')) {
                $table->string('payment_order_id')->nullable()->after('payment_status');
            }

            if (!Schema::hasColumn('schedule_bookings', 'payment_due_at')) {
                $table->timestamp('payment_due_at')->nullable()->after('payment_order_id');
            }

            if (!Schema::hasColumn('schedule_bookings', 'extra_duration_units')) {
                $table->unsignedInteger('extra_duration_units')->default(0)->after('duration_minutes');
            }
        });
    }

    public function down(): void
    {
        Schema::table('schedule_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('schedule_bookings', 'payment_status')) {
                $table->dropColumn('payment_status');
            }

            if (Schema::hasColumn('schedule_bookings', 'payment_order_id')) {
                $table->dropColumn('payment_order_id');
            }

            if (Schema::hasColumn('schedule_bookings', 'payment_due_at')) {
                $table->dropColumn('payment_due_at');
            }

            if (Schema::hasColumn('schedule_bookings', 'extra_duration_units')) {
                $table->dropColumn('extra_duration_units');
            }
        });
    }
};
