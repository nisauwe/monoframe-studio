<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_cancel_logs', function (Blueprint $table) {
            $table->id();

            $table->foreignId('client_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->unsignedBigInteger('schedule_booking_id')->nullable();

            $table->unsignedBigInteger('package_id')->nullable();
            $table->string('package_name')->nullable();

            $table->string('client_name')->nullable();
            $table->string('client_phone')->nullable();

            $table->date('booking_date')->nullable();
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();

            $table->string('location_type')->nullable();
            $table->string('location_name')->nullable();

            $table->integer('duration_minutes')->default(0);
            $table->integer('extra_duration_minutes')->default(0);
            $table->bigInteger('extra_duration_fee')->default(0);

            $table->string('video_addon_name')->nullable();
            $table->bigInteger('video_addon_price')->default(0);

            $table->bigInteger('total_booking_amount')->default(0);
            $table->text('notes')->nullable();
            $table->text('cancel_reason')->nullable();

            $table->json('snapshot')->nullable();

            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_cancel_logs');
    }
};
