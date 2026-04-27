<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CallCenterContact extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'division',
        'description',
        'contact_person',
        'platform',
        'contact_value',
        'whatsapp_number',
        'url',
        'service_hours',
        'priority',
        'status',
        'is_emergency',
        'is_visible_to_client',
        'sort_order',
    ];

    protected $casts = [
        'is_emergency' => 'boolean',
        'is_visible_to_client' => 'boolean',
        'sort_order' => 'integer',
    ];

    protected $appends = [
        'contact_url',
        'platform_label',
        'priority_label',
        'status_label',
    ];

    public function getContactUrlAttribute(): ?string
    {
        $platform = strtolower((string) $this->platform);
        $value = trim((string) $this->contact_value);

        if ($platform === 'whatsapp') {
            $number = $this->normalizeWhatsappNumber(
                $this->whatsapp_number ?: $value
            );

            return $number ? 'https://wa.me/' . $number : null;
        }

        if ($platform === 'instagram') {
            if ($this->url) {
                return $this->url;
            }

            $username = ltrim($value, '@');
            return $username ? 'https://www.instagram.com/' . $username : null;
        }

        if ($platform === 'tiktok') {
            if ($this->url) {
                return $this->url;
            }

            $username = ltrim($value, '@');
            return $username ? 'https://www.tiktok.com/@' . $username : null;
        }

        if ($platform === 'email') {
            return $value ? 'mailto:' . $value : null;
        }

        if ($platform === 'phone') {
            return $value ? 'tel:' . $value : null;
        }

        if ($platform === 'website') {
            if (!$this->url && !$value) {
                return null;
            }

            $url = $this->url ?: $value;

            if (!str_starts_with($url, 'http://') && !str_starts_with($url, 'https://')) {
                $url = 'https://' . $url;
            }

            return $url;
        }

        return $this->url;
    }

    public function getPlatformLabelAttribute(): string
    {
        return match (strtolower((string) $this->platform)) {
            'whatsapp' => 'WhatsApp',
            'instagram' => 'Instagram',
            'tiktok' => 'TikTok',
            'email' => 'Email',
            'phone' => 'Telepon',
            'website' => 'Website',
            default => ucfirst((string) $this->platform),
        };
    }

    public function getPriorityLabelAttribute(): string
    {
        return match (strtolower((string) $this->priority)) {
            'low' => 'Rendah',
            'normal' => 'Normal',
            'high' => 'Tinggi',
            'urgent' => 'Darurat',
            default => ucfirst((string) $this->priority),
        };
    }

    public function getStatusLabelAttribute(): string
    {
        return match (strtolower((string) $this->status)) {
            'active' => 'Aktif',
            'standby' => 'Standby',
            'inactive' => 'Nonaktif',
            default => ucfirst((string) $this->status),
        };
    }

    public function normalizeWhatsappNumber(?string $number): ?string
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
