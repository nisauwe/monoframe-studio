<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class EditRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'schedule_booking_id',
        'photo_link_id',
        'client_user_id',
        'editor_user_id',
        'selected_files',
        'request_notes',
        'status',
        'assigned_at',
        'edit_deadline_at',
        'started_at',
        'completed_at',
        'editor_notes',
        'result_drive_url',
        'result_drive_label',
    ];

    protected $casts = [
        'selected_files' => 'array',
        'assigned_at' => 'datetime',
        'edit_deadline_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    protected $appends = [
        'status_label',
        'remaining_days',
    ];

    public function booking()
    {
        return $this->belongsTo(ScheduleBooking::class, 'schedule_booking_id');
    }

    public function photoLink()
    {
        return $this->belongsTo(PhotoLink::class);
    }

    public function client()
    {
        return $this->belongsTo(User::class, 'client_user_id');
    }

    public function editor()
    {
        return $this->belongsTo(User::class, 'editor_user_id');
    }

    public function getStatusLabelAttribute(): string
    {
        return match ($this->status) {
            'submitted' => 'Menunggu Assign Editor',
            'assigned' => 'Sudah Dikirim ke Editor',
            'in_progress' => 'Sedang Diedit',
            'completed' => 'Edit Selesai',
            default => ucfirst((string) $this->status),
        };
    }

    public function getRemainingDaysAttribute(): ?int
    {
        if (!$this->edit_deadline_at || $this->status === 'completed') {
            return null;
        }

        return now()->diffInDays($this->edit_deadline_at, false);
    }

    public function isAssigned(): bool
    {
        return !empty($this->editor_user_id);
    }

    public function isCompleted(): bool
    {
        return $this->status === 'completed';
    }
}
