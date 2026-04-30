<?php

namespace App\Http\Requests\FrontOffice;

use Illuminate\Foundation\Http\FormRequest;

class StoreManualBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'package_id' => ['required', 'exists:packages,id'],
            'booking_date' => ['required', 'date'],
            'start_time' => ['required'],
            'extra_duration_units' => ['nullable', 'integer', 'min:0', 'max:10'],

            'photographer_user_id' => ['required', 'exists:users,id'],

            'client_name' => ['required', 'string', 'max:255'],
            'client_phone' => ['required', 'string', 'max:25'],
            'client_email' => ['nullable', 'email', 'max:255'],

            'location_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],

            'video_addon_type' => ['nullable', 'in:iphone,camera'],

            'moodboards' => ['nullable', 'array', 'max:10'],
            'moodboards.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }
}
