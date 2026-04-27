<?php

namespace App\Http\Controllers\Api\FrontOffice;

use App\Http\Controllers\Controller;
use App\Models\EditRequest;
use App\Models\User;
use App\Services\BookingTrackingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class EditAssignmentController extends Controller
{
    private const EDIT_STATUSES = [
        'submitted',
        'assigned',
        'in_progress',
        'completed',
    ];

    public function index(Request $request)
    {
        $validated = $request->validate([
            'status' => [
                'nullable',
                'string',
                Rule::in(array_merge(['all'], self::EDIT_STATUSES)),
            ],
        ]);

        $status = $validated['status'] ?? null;

        $query = EditRequest::with([
            'booking.package',
            'booking.clientUser',
            'booking.photoLink',
            'client',
            'editor',
            'photoLink',
        ])
            ->whereIn('status', self::EDIT_STATUSES)
            ->orderByRaw("
                CASE
                    WHEN status = 'submitted' THEN 0
                    WHEN status = 'assigned' THEN 1
                    WHEN status = 'in_progress' THEN 2
                    WHEN status = 'completed' THEN 3
                    ELSE 4
                END
            ")
            ->latest('updated_at');

        if ($status && $status !== 'all') {
            $query->where('status', $status);
        }

        return response()->json([
            'message' => 'Daftar permintaan edit berhasil diambil',
            'data' => $query->get(),
        ]);
    }

    public function show(EditRequest $editRequest)
    {
        return response()->json([
            'message' => 'Detail permintaan edit berhasil diambil',
            'data' => $editRequest->load([
                'booking.package',
                'booking.clientUser',
                'booking.photoLink',
                'client',
                'editor',
                'photoLink',
            ]),
        ]);
    }

    public function editors()
    {
        $editors = User::query()
            ->where('role', 'Editor')
            ->where('is_active', true)
            ->orderBy('name')
            ->get([
                'id',
                'name',
                'email',
                'phone',
                'role',
                'is_active',
            ]);

        return response()->json([
            'message' => 'Daftar editor aktif berhasil diambil',
            'data' => $editors,
        ]);
    }

    public function assign(
        Request $request,
        EditRequest $editRequest,
        BookingTrackingService $trackingService
    ) {
        $validated = $request->validate([
            'editor_user_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(function ($query) {
                    $query->where('role', 'Editor')
                        ->where('is_active', true);
                }),
            ],
        ], [
            'editor_user_id.required' => 'Editor wajib dipilih.',
            'editor_user_id.exists' => 'Editor tidak valid atau sedang tidak aktif.',
        ]);

        $editor = User::query()
            ->where('id', $validated['editor_user_id'])
            ->where('role', 'Editor')
            ->where('is_active', true)
            ->firstOrFail();

        $deadline = now()->addDays(7);

        $updatedEditRequest = DB::transaction(function () use (
            $editRequest,
            $editor,
            $deadline,
            $trackingService
        ) {
            $lockedEditRequest = EditRequest::query()
                ->whereKey($editRequest->id)
                ->lockForUpdate()
                ->firstOrFail();

            if ($lockedEditRequest->status === 'completed') {
                throw ValidationException::withMessages([
                    'edit_request' => 'Permintaan edit ini sudah selesai dan tidak bisa di-assign ulang.',
                ]);
            }

            $lockedEditRequest->update([
                'editor_user_id' => $editor->id,
                'status' => 'assigned',
                'assigned_at' => now(),
                'edit_deadline_at' => $deadline,
                'started_at' => null,
                'completed_at' => null,
            ]);

            $booking = $lockedEditRequest->booking()->firstOrFail();

            $trackingService->markCurrent(
                $booking,
                'edit_upload',
                'List foto sudah dikirim ke editor, mohon ditunggu kurang lebih selama 7 hari. Foto akan diedit sesuai dengan urutan editan yang masuk.',
                [
                    'editor_id' => $editor->id,
                    'editor_name' => $editor->name,
                    'edit_deadline_at' => $deadline->toDateTimeString(),
                ]
            );

            return $lockedEditRequest->fresh([
                'booking.package',
                'booking.clientUser',
                'booking.photoLink',
                'client',
                'editor',
                'photoLink',
            ]);
        });

        return response()->json([
            'message' => 'Editor berhasil di-assign. Deadline edit otomatis 7 hari dari tanggal assign.',
            'data' => $updatedEditRequest,
        ]);
    }
}
