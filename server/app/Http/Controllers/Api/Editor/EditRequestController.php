<?php

namespace App\Http\Controllers\Api\Editor;

use App\Http\Controllers\Controller;
use App\Models\EditRequest;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;

class EditRequestController extends Controller
{
    public function index(Request $request)
    {
        $editRequests = EditRequest::with([
            'booking.package',
            'booking.clientUser',
            'photoLink',
            'client',
            'editor',
        ])
            ->where('editor_user_id', $request->user()->id)
            ->orderByRaw("
                CASE
                    WHEN status = 'assigned' THEN 0
                    WHEN status = 'in_progress' THEN 1
                    WHEN status = 'completed' THEN 2
                    ELSE 3
                END
            ")
            ->orderBy('edit_deadline_at')
            ->get();

        return response()->json([
            'message' => 'Daftar pekerjaan edit berhasil diambil',
            'data' => $editRequests,
        ]);
    }

    public function show(Request $request, EditRequest $editRequest)
    {
        if ((int) $editRequest->editor_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        return response()->json([
            'message' => 'Detail pekerjaan edit berhasil diambil',
            'data' => $editRequest->load([
                'booking.package',
                'booking.clientUser',
                'photoLink',
                'client',
                'editor',
            ]),
        ]);
    }

    public function start(Request $request, EditRequest $editRequest)
    {
        if ((int) $editRequest->editor_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        if ($editRequest->status === 'completed') {
            return response()->json([
                'message' => 'Pekerjaan edit sudah selesai.',
            ], 422);
        }

        if ($editRequest->status === 'in_progress') {
            return response()->json([
                'message' => 'Pekerjaan edit sudah sedang diproses.',
                'data' => $editRequest->fresh([
                    'booking.package',
                    'booking.clientUser',
                    'photoLink',
                    'client',
                    'editor',
                ]),
            ]);
        }

        $editRequest->update([
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        return response()->json([
            'message' => 'Pekerjaan edit dimulai',
            'data' => $editRequest->fresh([
                'booking.package',
                'booking.clientUser',
                'photoLink',
                'client',
                'editor',
            ]),
        ]);
    }

    public function complete(
        Request $request,
        EditRequest $editRequest,
        BookingTrackingService $trackingService
    ) {
        $validated = $request->validate([
            'result_drive_url' => ['required', 'url'],
            'result_drive_label' => ['nullable', 'string', 'max:255'],
            'editor_notes' => ['nullable', 'string'],
        ]);

        if ((int) $editRequest->editor_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        if ($editRequest->status === 'completed') {
            return response()->json([
                'message' => 'Permintaan edit ini sudah selesai sebelumnya',
            ], 422);
        }

        $editRequest->update([
            'status' => 'completed',
            'completed_at' => now(),
            'editor_notes' => $validated['editor_notes'] ?? null,
            'result_drive_url' => $validated['result_drive_url'],
            'result_drive_label' => $validated['result_drive_label'] ?? 'Hasil Edit',
        ]);

        $booking = $editRequest->booking;

        $trackingService->markDone(
            $booking,
            'edit_upload',
            'Hasil edit telah selesai. Link hasil edit sudah tersedia untuk klien.'
        );

        $trackingService->markCurrent(
            $booking,
            'print',
            'Hasil edit sudah selesai. Silakan pilih cetak foto atau lanjut ke review.'
        );

        return response()->json([
            'message' => 'Permintaan edit berhasil ditandai selesai',
            'data' => $editRequest->fresh([
                'booking.package',
                'booking.clientUser',
                'photoLink',
                'client',
                'editor',
            ]),
        ]);
    }
}
