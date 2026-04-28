<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class AppSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'studio_name',
        'studio_tagline',
        'studio_logo',
        'studio_address',
        'studio_maps_url',
        'studio_email',
        'studio_whatsapp',
        'instagram_url',
        'tiktok_url',
        'website_url',

        'client_home_title',
        'client_home_subtitle',
        'client_home_banner',
        'client_cta_text',
        'show_popular_packages',
        'show_client_reviews',
        'show_support_contact',

        'booking_is_active',
        'booking_closed_message',
        'max_moodboard_upload',
        'max_extra_duration_units',
        'min_reschedule_days',
        'booking_policy',
        'booking_terms',

        'review_is_active',
        'show_reviews_on_client',
        'minimum_rating_display',
        'auto_hide_low_rating',
        'review_invitation_message',

        'email_notifications_enabled',
        'whatsapp_notifications_enabled',
        'in_app_notifications_enabled',
        'notification_sender_name',
        'booking_created_template',
        'payment_success_template',
        'edit_completed_template',
        'review_request_template',

        'maintenance_mode',
        'maintenance_message',
        'allow_client_registration',
        'default_client_role',
        'login_attempt_limit',
    ];

    protected $casts = [
        'show_popular_packages' => 'boolean',
        'show_client_reviews' => 'boolean',
        'show_support_contact' => 'boolean',
        'booking_is_active' => 'boolean',
        'max_moodboard_upload' => 'integer',
        'max_extra_duration_units' => 'integer',
        'min_reschedule_days' => 'integer',
        'review_is_active' => 'boolean',
        'show_reviews_on_client' => 'boolean',
        'minimum_rating_display' => 'integer',
        'auto_hide_low_rating' => 'boolean',
        'email_notifications_enabled' => 'boolean',
        'whatsapp_notifications_enabled' => 'boolean',
        'in_app_notifications_enabled' => 'boolean',
        'maintenance_mode' => 'boolean',
        'allow_client_registration' => 'boolean',
        'login_attempt_limit' => 'integer',
    ];

    protected $appends = [
        'studio_logo_url',
        'client_home_banner_url',
    ];

    public static function defaults(): array
    {
        return [
            'studio_name' => 'Monoframe Studio',
            'studio_tagline' => 'Capture Your Best Moment',
            'studio_logo' => null,
            'studio_address' => null,
            'studio_maps_url' => null,
            'studio_email' => null,
            'studio_whatsapp' => null,
            'instagram_url' => null,
            'tiktok_url' => null,
            'website_url' => null,

            'client_home_title' => 'Abadikan momen terbaik bersama Monoframe Studio',
            'client_home_subtitle' => 'Pilih paket foto, tentukan jadwal, lakukan pembayaran, dan pantau progres hasil foto langsung dari aplikasi.',
            'client_home_banner' => null,
            'client_cta_text' => 'Booking Sekarang',
            'show_popular_packages' => true,
            'show_client_reviews' => true,
            'show_support_contact' => true,

            'booking_is_active' => true,
            'booking_closed_message' => 'Booking sementara ditutup. Silakan hubungi admin untuk informasi lebih lanjut.',
            'max_moodboard_upload' => 10,
            'max_extra_duration_units' => 10,
            'min_reschedule_days' => 2,
            'booking_policy' => 'Booking dapat dilakukan selama jadwal tersedia dan pembayaran DP sudah dilakukan sesuai ketentuan.',
            'booking_terms' => 'Dengan melakukan booking, klien menyetujui jadwal, paket, pembayaran, dan ketentuan layanan Monoframe Studio.',

            'review_is_active' => true,
            'show_reviews_on_client' => true,
            'minimum_rating_display' => 4,
            'auto_hide_low_rating' => true,
            'review_invitation_message' => 'Bagikan pengalaman Anda setelah sesi foto selesai.',

            'email_notifications_enabled' => false,
            'whatsapp_notifications_enabled' => false,
            'in_app_notifications_enabled' => true,
            'notification_sender_name' => 'Monoframe Studio',
            'booking_created_template' => 'Booking Anda berhasil dibuat. Silakan lanjutkan pembayaran.',
            'payment_success_template' => 'Pembayaran Anda sudah kami terima. Jadwal booking Anda akan diproses.',
            'edit_completed_template' => 'Permintaan edit Anda telah selesai diproses.',
            'review_request_template' => 'Terima kasih sudah menggunakan layanan Monoframe Studio. Silakan berikan review Anda.',

            'maintenance_mode' => false,
            'maintenance_message' => 'Aplikasi sedang dalam perbaikan. Silakan coba kembali beberapa saat lagi.',
            'allow_client_registration' => true,
            'default_client_role' => 'Klien',
            'login_attempt_limit' => 5,
        ];
    }

    public static function current(): self
    {
        $setting = self::query()->first();

        if ($setting) {
            return $setting;
        }

        return self::query()->create(self::defaults());
    }

    public function getStudioLogoUrlAttribute(): ?string
    {
        return $this->toPublicUrl($this->studio_logo);
    }

    public function getClientHomeBannerUrlAttribute(): ?string
    {
        return $this->toPublicUrl($this->client_home_banner);
    }

    public function toClientArray(): array
    {
        return [
            'studio' => [
                'name' => $this->studio_name,
                'tagline' => $this->studio_tagline,
                'logo' => $this->studio_logo,
                'logo_url' => $this->studio_logo_url,
                'address' => $this->studio_address,
                'maps_url' => $this->studio_maps_url,
                'email' => $this->studio_email,
                'whatsapp' => $this->studio_whatsapp,
                'instagram_url' => $this->instagram_url,
                'tiktok_url' => $this->tiktok_url,
                'website_url' => $this->website_url,
            ],
            'client_home' => [
                'title' => $this->client_home_title,
                'subtitle' => $this->client_home_subtitle,
                'banner' => $this->client_home_banner,
                'banner_url' => $this->client_home_banner_url,
                'cta_text' => $this->client_cta_text,
                'show_popular_packages' => (bool) $this->show_popular_packages,
                'show_client_reviews' => (bool) $this->show_client_reviews,
                'show_support_contact' => (bool) $this->show_support_contact,
            ],
            'booking' => [
                'is_active' => (bool) $this->booking_is_active,
                'closed_message' => $this->booking_closed_message,
                'max_moodboard_upload' => (int) $this->max_moodboard_upload,
                'max_extra_duration_units' => (int) $this->max_extra_duration_units,
                'min_reschedule_days' => (int) $this->min_reschedule_days,
                'policy' => $this->booking_policy,
                'terms' => $this->booking_terms,
            ],
            'review' => [
                'is_active' => (bool) $this->review_is_active,
                'show_on_client' => (bool) $this->show_reviews_on_client,
                'minimum_rating_display' => (int) $this->minimum_rating_display,
                'auto_hide_low_rating' => (bool) $this->auto_hide_low_rating,
                'invitation_message' => $this->review_invitation_message,
            ],
            'notification' => [
                'email_enabled' => (bool) $this->email_notifications_enabled,
                'whatsapp_enabled' => (bool) $this->whatsapp_notifications_enabled,
                'in_app_enabled' => (bool) $this->in_app_notifications_enabled,
                'sender_name' => $this->notification_sender_name,
                'templates' => [
                    'booking_created' => $this->booking_created_template,
                    'payment_success' => $this->payment_success_template,
                    'edit_completed' => $this->edit_completed_template,
                    'review_request' => $this->review_request_template,
                ],
            ],
            'system' => [
                'maintenance_mode' => (bool) $this->maintenance_mode,
                'maintenance_message' => $this->maintenance_message,
                'allow_client_registration' => (bool) $this->allow_client_registration,
                'default_client_role' => $this->default_client_role,
                'login_attempt_limit' => (int) $this->login_attempt_limit,
            ],
        ];
    }

    private function toPublicUrl(?string $path): ?string
    {
        if (!$path) {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return url(Storage::url($path));
    }
}
