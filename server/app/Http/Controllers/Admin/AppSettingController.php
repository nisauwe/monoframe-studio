<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\CallCenterContact;
use App\Models\PaymentGateway;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AppSettingController extends Controller
{
    public function index()
    {
        $setting = AppSetting::current();

        $gateway = PaymentGateway::query()->latest('id')->first();

        $contactSummary = [
            'total' => CallCenterContact::query()->count(),
            'active' => CallCenterContact::query()->where('status', 'active')->count(),
            'visible_to_client' => CallCenterContact::query()->where('is_visible_to_client', true)->count(),
        ];

        $reviewSummary = [
            'total' => Review::query()->count(),
            'average_rating' => round((float) Review::query()->avg('rating'), 1),
            'displayable' => Review::query()
                ->where('rating', '>=', (int) $setting->minimum_rating_display)
                ->count(),
        ];

        return view('admin.settings.index', compact(
            'setting',
            'gateway',
            'contactSummary',
            'reviewSummary'
        ));
    }

    public function update(Request $request)
    {
        $setting = AppSetting::current();

        $validated = $request->validate([
            'studio_name' => ['required', 'string', 'max:255'],
            'studio_tagline' => ['nullable', 'string', 'max:255'],
            'studio_logo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'remove_studio_logo' => ['nullable', 'boolean'],
            'studio_address' => ['nullable', 'string', 'max:3000'],
            'studio_maps_url' => ['nullable', 'url', 'max:500'],
            'studio_email' => ['nullable', 'email', 'max:255'],
            'studio_whatsapp' => ['nullable', 'string', 'max:30'],
            'instagram_url' => ['nullable', 'url', 'max:500'],
            'tiktok_url' => ['nullable', 'url', 'max:500'],
            'website_url' => ['nullable', 'url', 'max:500'],

            'client_home_title' => ['required', 'string', 'max:255'],
            'client_home_subtitle' => ['nullable', 'string', 'max:3000'],
            'client_home_banner' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'remove_client_home_banner' => ['nullable', 'boolean'],
            'client_cta_text' => ['required', 'string', 'max:80'],
            'show_popular_packages' => ['nullable', 'boolean'],
            'show_client_reviews' => ['nullable', 'boolean'],
            'show_support_contact' => ['nullable', 'boolean'],

            'booking_is_active' => ['nullable', 'boolean'],
            'booking_closed_message' => ['nullable', 'string', 'max:3000'],
            'max_moodboard_upload' => ['required', 'integer', 'min:0', 'max:20'],
            'max_extra_duration_units' => ['required', 'integer', 'min:0', 'max:20'],
            'min_reschedule_days' => ['required', 'integer', 'min:0', 'max:30'],
            'booking_policy' => ['nullable', 'string', 'max:5000'],
            'booking_terms' => ['nullable', 'string', 'max:10000'],

            'review_is_active' => ['nullable', 'boolean'],
            'show_reviews_on_client' => ['nullable', 'boolean'],
            'minimum_rating_display' => ['required', 'integer', 'min:1', 'max:5'],
            'auto_hide_low_rating' => ['nullable', 'boolean'],
            'review_invitation_message' => ['nullable', 'string', 'max:3000'],

            'email_notifications_enabled' => ['nullable', 'boolean'],
            'whatsapp_notifications_enabled' => ['nullable', 'boolean'],
            'in_app_notifications_enabled' => ['nullable', 'boolean'],
            'notification_sender_name' => ['required', 'string', 'max:100'],
            'booking_created_template' => ['nullable', 'string', 'max:5000'],
            'payment_success_template' => ['nullable', 'string', 'max:5000'],
            'edit_completed_template' => ['nullable', 'string', 'max:5000'],
            'review_request_template' => ['nullable', 'string', 'max:5000'],

            'maintenance_mode' => ['nullable', 'boolean'],
            'maintenance_message' => ['nullable', 'string', 'max:3000'],
            'allow_client_registration' => ['nullable', 'boolean'],
            'default_client_role' => ['required', 'string', 'max:50'],
            'login_attempt_limit' => ['required', 'integer', 'min:1', 'max:20'],
        ]);

        unset(
            $validated['studio_logo'],
            $validated['client_home_banner'],
            $validated['remove_studio_logo'],
            $validated['remove_client_home_banner']
        );

        $validated['show_popular_packages'] = $request->boolean('show_popular_packages');
        $validated['show_client_reviews'] = $request->boolean('show_client_reviews');
        $validated['show_support_contact'] = $request->boolean('show_support_contact');
        $validated['booking_is_active'] = $request->boolean('booking_is_active');
        $validated['review_is_active'] = $request->boolean('review_is_active');
        $validated['show_reviews_on_client'] = $request->boolean('show_reviews_on_client');
        $validated['auto_hide_low_rating'] = $request->boolean('auto_hide_low_rating');
        $validated['email_notifications_enabled'] = $request->boolean('email_notifications_enabled');
        $validated['whatsapp_notifications_enabled'] = $request->boolean('whatsapp_notifications_enabled');
        $validated['in_app_notifications_enabled'] = $request->boolean('in_app_notifications_enabled');
        $validated['maintenance_mode'] = $request->boolean('maintenance_mode');
        $validated['allow_client_registration'] = $request->boolean('allow_client_registration');

        if ($request->boolean('remove_studio_logo') && $setting->studio_logo) {
            Storage::disk('public')->delete($setting->studio_logo);
            $validated['studio_logo'] = null;
        }

        if ($request->hasFile('studio_logo')) {
            if ($setting->studio_logo) {
                Storage::disk('public')->delete($setting->studio_logo);
            }

            $validated['studio_logo'] = $request->file('studio_logo')->store('app-settings/logos', 'public');
        }

        if ($request->boolean('remove_client_home_banner') && $setting->client_home_banner) {
            Storage::disk('public')->delete($setting->client_home_banner);
            $validated['client_home_banner'] = null;
        }

        if ($request->hasFile('client_home_banner')) {
            if ($setting->client_home_banner) {
                Storage::disk('public')->delete($setting->client_home_banner);
            }

            $validated['client_home_banner'] = $request->file('client_home_banner')->store('app-settings/banners', 'public');
        }

        $setting->update($validated);

        return redirect()
            ->route('admin.settings.index')
            ->with('success', 'Pengaturan aplikasi berhasil disimpan.');
    }
}
