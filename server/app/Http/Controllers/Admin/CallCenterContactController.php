<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CallCenterContact;
use Illuminate\Http\Request;

class CallCenterContactController extends Controller
{
    public function index(Request $request)
    {
        $query = CallCenterContact::query();

        if ($request->filled('q')) {
            $search = $request->q;

            $query->where(function ($item) use ($search) {
                $item->where('title', 'like', '%' . $search . '%')
                    ->orWhere('division', 'like', '%' . $search . '%')
                    ->orWhere('contact_person', 'like', '%' . $search . '%')
                    ->orWhere('contact_value', 'like', '%' . $search . '%')
                    ->orWhere('description', 'like', '%' . $search . '%');
            });
        }

        if ($request->filled('division')) {
            $query->where('division', $request->division);
        }

        if ($request->filled('platform')) {
            $query->where('platform', $request->platform);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $contacts = $query
            ->orderByDesc('is_emergency')
            ->orderBy('sort_order')
            ->orderBy('title')
            ->get();

        $divisions = CallCenterContact::query()
            ->whereNotNull('division')
            ->where('division', '!=', '')
            ->select('division')
            ->distinct()
            ->orderBy('division')
            ->pluck('division');

        $summary = [
            'total' => CallCenterContact::count(),
            'active' => CallCenterContact::where('status', 'active')->count(),
            'emergency' => CallCenterContact::where('is_emergency', true)->count(),
        ];

        return view('admin.call-center.index', compact(
            'contacts',
            'divisions',
            'summary'
        ));
    }

    public function store(Request $request)
    {
        $validated = $this->validateContact($request);

        $validated['is_emergency'] = $request->boolean('is_emergency');
        $validated['is_visible_to_client'] = $request->boolean('is_visible_to_client');

        if (($validated['platform'] ?? null) === 'whatsapp') {
            $validated['whatsapp_number'] = $this->normalizeWhatsappNumber(
                $validated['whatsapp_number'] ?? $validated['contact_value']
            );
        }

        CallCenterContact::create($validated);

        return redirect()
            ->route('admin.call-center.index')
            ->with('success', 'Kontak call center berhasil ditambahkan.');
    }

    public function update(Request $request, CallCenterContact $callCenter)
    {
        $validated = $this->validateContact($request);

        $validated['is_emergency'] = $request->boolean('is_emergency');
        $validated['is_visible_to_client'] = $request->boolean('is_visible_to_client');

        if (($validated['platform'] ?? null) === 'whatsapp') {
            $validated['whatsapp_number'] = $this->normalizeWhatsappNumber(
                $validated['whatsapp_number'] ?? $validated['contact_value']
            );
        }

        $callCenter->update($validated);

        return redirect()
            ->route('admin.call-center.index')
            ->with('success', 'Kontak call center berhasil diperbarui.');
    }

    public function destroy(CallCenterContact $callCenter)
    {
        $callCenter->delete();

        return redirect()
            ->route('admin.call-center.index')
            ->with('success', 'Kontak call center berhasil dihapus.');
    }

    public function toggleStatus(CallCenterContact $callCenter)
    {
        $callCenter->update([
            'status' => $callCenter->status === 'active' ? 'inactive' : 'active',
        ]);

        return redirect()
            ->route('admin.call-center.index')
            ->with('success', 'Status kontak berhasil diperbarui.');
    }

    private function validateContact(Request $request): array
    {
        return $request->validate([
            'title' => ['required', 'string', 'max:100'],
            'division' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:500'],
            'contact_person' => ['nullable', 'string', 'max:100'],

            'platform' => ['required', 'in:whatsapp,instagram,tiktok,email,phone,website'],
            'contact_value' => ['required', 'string', 'max:255'],
            'whatsapp_number' => ['nullable', 'string', 'max:50'],
            'url' => ['nullable', 'string', 'max:255'],

            'service_hours' => ['nullable', 'string', 'max:100'],
            'priority' => ['required', 'in:low,normal,high,urgent'],
            'status' => ['required', 'in:active,standby,inactive'],

            'sort_order' => ['nullable', 'integer', 'min:0'],
        ]);
    }

    private function normalizeWhatsappNumber(?string $number): ?string
    {
        if (!$number) {
            return null;
        }

        $number = preg_replace('/\D+/', '', $number);

        if (!$number) {
            return null;
        }

        if (str_starts_with($number, '0')) {
            $number = '62' . substr($number, 1);
        }

        if (str_starts_with($number, '8')) {
            $number = '62' . $number;
        }

        return $number;
    }
}
