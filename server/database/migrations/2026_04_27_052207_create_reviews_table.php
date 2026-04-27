<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('reviews')) {
            return;
        }

        Schema::create('reviews', function (Blueprint $table) {
            $table->id();

            $table->foreignId('schedule_booking_id')
                ->constrained('schedule_bookings')
                ->cascadeOnDelete();

            $table->foreignId('client_user_id')
                ->constrained('users')
                ->cascadeOnDelete();

            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();

            $table->timestamps();

            $table->unique(['schedule_booking_id', 'client_user_id'], 'reviews_booking_client_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
