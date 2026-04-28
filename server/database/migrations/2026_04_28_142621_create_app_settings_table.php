<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_settings', function (Blueprint $table) {
            $table->id();

            // Identitas Studio
            $table->string('studio_name')->default('Monoframe Studio');
            $table->string('studio_tagline')->nullable();
            $table->string('studio_logo')->nullable();
            $table->text('studio_address')->nullable();
            $table->string('studio_maps_url')->nullable();
            $table->string('studio_email')->nullable();
            $table->string('studio_whatsapp')->nullable();
            $table->string('instagram_url')->nullable();
            $table->string('tiktok_url')->nullable();
            $table->string('website_url')->nullable();

            // Tampilan aplikasi client Flutter
            $table->string('client_home_title')->default('Abadikan momen terbaik bersama Monoframe Studio');
            $table->text('client_home_subtitle')->nullable();
            $table->string('client_home_banner')->nullable();
            $table->string('client_cta_text')->default('Booking Sekarang');
            $table->boolean('show_popular_packages')->default(true);
            $table->boolean('show_client_reviews')->default(true);
            $table->boolean('show_support_contact')->default(true);

            // Booking global
            $table->boolean('booking_is_active')->default(true);
            $table->text('booking_closed_message')->nullable();
            $table->unsignedInteger('max_moodboard_upload')->default(10);
            $table->unsignedInteger('max_extra_duration_units')->default(10);
            $table->unsignedInteger('min_reschedule_days')->default(2);
            $table->text('booking_policy')->nullable();
            $table->longText('booking_terms')->nullable();

            // Review global
            $table->boolean('review_is_active')->default(true);
            $table->boolean('show_reviews_on_client')->default(true);
            $table->unsignedTinyInteger('minimum_rating_display')->default(4);
            $table->boolean('auto_hide_low_rating')->default(true);
            $table->text('review_invitation_message')->nullable();

            // Notifikasi
            $table->boolean('email_notifications_enabled')->default(false);
            $table->boolean('whatsapp_notifications_enabled')->default(false);
            $table->boolean('in_app_notifications_enabled')->default(true);
            $table->string('notification_sender_name')->default('Monoframe Studio');
            $table->text('booking_created_template')->nullable();
            $table->text('payment_success_template')->nullable();
            $table->text('edit_completed_template')->nullable();
            $table->text('review_request_template')->nullable();

            // Sistem
            $table->boolean('maintenance_mode')->default(false);
            $table->text('maintenance_message')->nullable();
            $table->boolean('allow_client_registration')->default(true);
            $table->string('default_client_role')->default('Klien');
            $table->unsignedInteger('login_attempt_limit')->default(5);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
    }
};
