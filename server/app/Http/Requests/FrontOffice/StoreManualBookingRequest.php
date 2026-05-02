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
            'booking_date' => ['required', 'date', 'after:today'],
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

    public function messages(): array
    {
        return [
            'booking_date.after' => 'Booking manual hanya bisa dibuat minimal H-1. Silakan pilih tanggal mulai besok.',
            'booking_date.required' => 'Tanggal booking wajib dipilih.',
            'package_id.required' => 'Paket foto wajib dipilih.',
            'start_time.required' => 'Jam booking wajib dipilih.',
            'photographer_user_id.required' => 'Fotografer wajib dipilih.',
            'client_name.required' => 'Nama klien wajib diisi.',
            'client_phone.required' => 'Nomor HP klien wajib diisi.',
        ];
    }
}
