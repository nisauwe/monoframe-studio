<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ScheduleBooking;
use App\Services\BookingTrackingService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class TrackingController extends Controller
{
    public function show(
        Request $request,
        ScheduleBooking $booking,
        BookingTrackingService $trackingService
    ) {
        if ((int) $booking->client_user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'Akses ditolak',
            ], 403);
        }

        $booking->load($this->relations());

        $trackingService->syncTrackingState($booking);

        $booking = $booking->fresh($this->relations());

        $timeline = $trackingService->getTimeline($booking);

        $hasPhotographerAssigned = (bool) $booking->photographer_user_id;

        $hasPhotoLink = (bool) ($booking->photoLink && $booking->photoLink->is_active);

        $canOpenPhotoLink = in_array($booking->payment_status, ['paid', 'fully_paid'], true)
            || $booking->isFullyPaid();

        $maxPhotoEdit = (int) ($booking->package?->photo_count ?? 0);

        $canSubmitEditRequest = $canOpenPhotoLink
            && $hasPhotoLink
            && (!$booking->editRequest || $booking->editRequest->status === 'submitted');

        return response()->json([
            'message' => 'Tracking booking berhasil diambil',
            'data' => [
                'booking' => [
                    'id' => $booking->id,
                    'booking_date' => $booking->booking_date,
                    'start_time' => $booking->start_time,
                    'end_time' => $booking->end_time,
                    'status' => $booking->status,
                    'payment_status' => $booking->payment_status,

                    'client_name' => $booking->client_name,
                    'client_phone' => $booking->client_phone,
                    'location_type' => $booking->location_type,
                    'location_name' => $booking->location_name,
                    'notes' => $booking->notes,

                    'package' => $booking->package,

                    'video_addon_type' => $booking->video_addon_type,
                    'video_addon_name' => $booking->video_addon_name,
                    'video_addon_price' => (int) $booking->video_addon_price,

                    'extra_duration_minutes' => (int) $booking->extra_duration_minutes,
                    'extra_duration_fee' => (int) $booking->extra_duration_fee,

                    'total_booking_amount' => (int) $booking->total_booking_amount,
                    'minimum_dp_amount' => (int) $booking->minimum_dp_amount,
                    'paid_booking_amount' => (int) $booking->paid_booking_amount,
                    'remaining_booking_amount' => (int) $booking->remaining_booking_amount,

                    'payment_warning' => $this->paymentWarning($booking),

                    'can_pay_dp' => in_array($booking->payment_status, ['unpaid', 'pending', 'failed'], true),
                    'can_pay_full' => in_array($booking->payment_status, ['unpaid', 'pending', 'failed'], true),
                    'can_pay_remaining' => in_array($booking->payment_status, ['dp_paid', 'partially_paid'], true)
                        && $hasPhotographerAssigned,

                    'has_photographer_assigned' => $hasPhotographerAssigned,
                    'is_waiting_photographer_assignment' => in_array($booking->payment_status, [
                        'dp_paid',
                        'partially_paid',
                        'paid',
                        'fully_paid',
                    ], true) && !$hasPhotographerAssigned,

                    'photographer' => $booking->photographerUser ? [
                        'id' => $booking->photographerUser->id,
                        'name' => $booking->photographerUser->name,
                        'email' => $booking->photographerUser->email,
                        'phone' => $booking->photographerUser->phone,
                    ] : null,

                    'has_photo_link' => $hasPhotoLink,
                    'can_open_photo_link' => $canOpenPhotoLink,
                    'photo_link' => $hasPhotoLink ? [
                        'id' => $booking->photoLink->id,
                        'drive_url' => $booking->photoLink->drive_url,
                        'drive_label' => $booking->photoLink->drive_label,
                        'notes' => $booking->photoLink->notes,
                        'is_active' => (bool) $booking->photoLink->is_active,
                    ] : null,

                    'max_photo_edit' => $maxPhotoEdit,
                    'can_submit_edit_request' => $canSubmitEditRequest,
                    'edit_request' => $booking->editRequest ? [
                        'id' => $booking->editRequest->id,
                        'selected_files' => $booking->editRequest->selected_files ?? [],
                        'request_notes' => $booking->editRequest->request_notes,
                        'status' => $booking->editRequest->status,
                        'status_label' => $booking->editRequest->status_label,
                        'assigned_at' => optional($booking->editRequest->assigned_at)->toIso8601String(),
                        'edit_deadline_at' => optional($booking->editRequest->edit_deadline_at)->toIso8601String(),
                        'started_at' => optional($booking->editRequest->started_at)->toIso8601String(),
                        'completed_at' => optional($booking->editRequest->completed_at)->toIso8601String(),
                        'editor_notes' => $booking->editRequest->editor_notes,
                        'result_drive_url' => $booking->editRequest->result_drive_url ?? null,
                        'result_drive_label' => $booking->editRequest->result_drive_label ?? null,
                        'remaining_days' => $booking->editRequest->remaining_days,
                        'editor' => $booking->editRequest->editor ? [
                            'id' => $booking->editRequest->editor->id,
                            'name' => $booking->editRequest->editor->name,
                            'email' => $booking->editRequest->editor->email,
                            'phone' => $booking->editRequest->editor->phone,
                        ] : null,
                    ] : null,

                    'moodboards' => $booking->moodboards->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'file_name' => $item->file_name,
                            'file_url' => $item->file_url,
                        ];
                    })->values(),

                    'can_print' => $this->canPrint($booking),
                    'print_order' => $this->formatPrintOrder($booking),
                    'can_review' => $this->canReview($booking),

                    'review' => $booking->review ? [
                        'id' => $booking->review->id,
                        'rating' => (int) $booking->review->rating,
                        'schedule_booking_id' => $booking->review->schedule_booking_id,
                        'client_user_id' => $booking->review->client_user_id,
                        'rating' => (int) $booking->review->rating,
                        'comment' => $booking->review->comment,
                        'created_at' => optional($booking->review->created_at)->toIso8601String(),
                        'updated_at' => optional($booking->review->updated_at)->toIso8601String(),
                    ] : null,
                ],
                'timeline' => $timeline,
            ],
        ]);
    }

    private function relations(): array
    {
        return [
            'package',
            'payments',
            'photographerUser',
            'photoLink',
            'moodboards',
            'editRequest.editor',

            // INI YANG BENAR UNTUK SISTEM CETAK MULTI ITEM
            'printOrder.items.printPrice',
            'printOrder.payment',

            'review',
        ];
    }

    private function formatPrintOrder(ScheduleBooking $booking): ?array
    {
        $order = $booking->printOrder;

        if (!$order) {
            return null;
        }

        return [
            'id' => $order->id,
            'schedule_booking_id' => $order->schedule_booking_id,
            'client_user_id' => $order->client_user_id,

            'selected_files' => $order->selected_files ?? [],
            'quantity' => (int) $order->quantity,

            'size_name' => $order->size_name,
            'paper_type' => $order->paper_type,
            'use_frame' => (bool) $order->use_frame,

            'print_unit_price' => (int) $order->print_unit_price,
            'frame_unit_price' => (int) $order->frame_unit_price,
            'subtotal_print' => (int) $order->subtotal_print,
            'subtotal_frame' => (int) $order->subtotal_frame,
            'total_amount' => (int) $order->total_amount,

            'delivery_method' => $order->delivery_method,
            'delivery_method_label' => $order->delivery_method_label,
            'recipient_name' => $order->recipient_name,
            'recipient_phone' => $order->recipient_phone,
            'delivery_address' => $order->delivery_address,

            'status' => $order->status,
            'status_label' => $order->status_label,
            'payment_status' => $order->payment_status,

            'paid_at' => optional($order->paid_at)->toIso8601String(),
            'processed_at' => optional($order->processed_at)->toIso8601String(),
            'completed_at' => optional($order->completed_at)->toIso8601String(),

            'delivery_proof_path' => $order->delivery_proof_path,
            'delivery_proof_url' => $order->delivery_proof_url,

            'notes' => $order->notes,

            'items' => $order->items->map(function ($item) {
                return [
                    'id' => $item->id,
                    'print_order_id' => $item->print_order_id,
                    'print_price_id' => $item->print_price_id,
                    'file_name' => $item->file_name,
                    'qty' => (int) $item->qty,
                    'use_frame' => (bool) $item->use_frame,
                    'unit_print_price' => (int) $item->unit_print_price,
                    'unit_frame_price' => (int) $item->unit_frame_price,
                    'line_total' => (int) $item->line_total,
                    'print_price' => $item->printPrice ? [
                        'id' => $item->printPrice->id,
                        'size_name' => $item->printPrice->size_name ?: $item->printPrice->size_label,
                        'size_label' => $item->printPrice->size_label,
                        'paper_type' => $item->printPrice->paper_type ?: $item->printPrice->notes,
                        'notes' => $item->printPrice->notes,
                        'print_price' => (int) (($item->printPrice->print_price ?? 0) ?: ($item->printPrice->base_price ?? 0)),
                        'base_price' => (int) ($item->printPrice->base_price ?? 0),
                        'frame_price' => (int) ($item->printPrice->frame_price ?? 0),
                        'is_available' => (bool) ($item->printPrice->is_available ?? $item->printPrice->is_active ?? true),
                    ] : null,
                ];
            })->values(),

            'payment' => $order->payment ? [
                'id' => $order->payment->id,
                'order_id' => $order->payment->order_id,
                'transaction_status' => $order->payment->transaction_status,
                'gross_amount' => (int) $order->payment->gross_amount,
                'snap_redirect_url' => $order->payment->snap_redirect_url,
            ] : null,
        ];
    }

    private function paymentWarning(ScheduleBooking $booking): ?string
    {
        if (!in_array($booking->payment_status, ['dp_paid', 'partially_paid'], true)) {
            return null;
        }

        $formattedBookingDate = $booking->booking_date
            ? Carbon::parse($booking->booking_date)->locale('id')->translatedFormat('d F Y')
            : 'tanggal pemotretan';

        return 'Pelunasan wajib dilakukan sebelum jadwal pemotretan, yaitu sebelum tanggal '
            . $formattedBookingDate
            . '. Jika tidak melakukan pelunasan, maka link hasil foto tidak akan dapat diakses.';
    }

    private function canPrint(ScheduleBooking $booking): bool
    {
        return $booking->editRequest
            && $booking->editRequest->status === 'completed'
            && !$this->printWasSkipped($booking);
    }

    private function canReview(ScheduleBooking $booking): bool
    {
        if ($booking->review) {
            return false;
        }

        if ($booking->printOrder) {
            return $booking->printOrder->status === 'completed';
        }

        $printTracking = $booking->trackings()
            ->where('stage_key', 'print')
            ->first();

        return $printTracking && in_array($printTracking->status, ['done', 'skipped'], true);
    }

    private function printWasSkipped(ScheduleBooking $booking): bool
    {
        $printTracking = $booking->trackings()
            ->where('stage_key', 'print')
            ->first();

        return $printTracking && $printTracking->status === 'skipped';
    }
}
