<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\CallCenterContact;
use Illuminate\Http\Request;

class CallCenterContactController extends Controller
{
    public function index(Request $request)
    {
        $contacts = CallCenterContact::query()
            ->where('is_visible_to_client', true)
            ->whereIn('status', ['active', 'standby'])
            ->when($request->filled('platform'), function ($query) use ($request) {
                $query->where('platform', $request->platform);
            })
            ->orderByDesc('is_emergency')
            ->orderBy('sort_order')
            ->orderBy('title')
            ->get()
            ->map(function (CallCenterContact $contact) {
                return [
                    'id' => $contact->id,
                    'title' => $contact->title,
                    'division' => $contact->division,
                    'description' => $contact->description,
                    'contact_person' => $contact->contact_person,
                    'platform' => $contact->platform,
                    'platform_label' => $contact->platform_label,
                    'contact_value' => $contact->contact_value,
                    'whatsapp_number' => $contact->whatsapp_number,
                    'url' => $contact->url,
                    'contact_url' => $contact->contact_url,
                    'service_hours' => $contact->service_hours,
                    'priority' => $contact->priority,
                    'priority_label' => $contact->priority_label,
                    'status' => $contact->status,
                    'status_label' => $contact->status_label,
                    'is_emergency' => (bool) $contact->is_emergency,
                ];
            })
            ->values();

        return response()->json([
            'message' => 'Daftar kontak berhasil diambil',
            'data' => $contacts,
            'template_messages' => [
                'package_question' => 'Halo Monoframe Studio, saya ingin bertanya tentang paket foto yang tersedia.',
                'custom_request' => 'Halo Monoframe Studio, saya ingin bertanya tentang request foto/custom foto yang tidak ada di dalam paket.',
                'payment_question' => 'Halo Monoframe Studio, saya ingin bertanya tentang pembayaran booking saya.',
                'system_problem' => 'Halo Monoframe Studio, saya ingin melaporkan kendala pada aplikasi/sistem.',
            ],
        ]);
    }
}
