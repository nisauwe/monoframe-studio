<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmailOtp extends Model
{
  protected $fillable = [
    'email',
    'purpose',
    'code_hash',
    'payload',
    'attempts',
    'expires_at',
    'resend_available_at',
    'verified_at',
    'ip_address',
  ];

  protected $casts = [
    'payload' => 'array',
    'expires_at' => 'datetime',
    'resend_available_at' => 'datetime',
    'verified_at' => 'datetime',
  ];

  public function isExpired(): bool
  {
    return now()->greaterThan($this->expires_at);
  }

  public function canResend(): bool
  {
    return $this->resend_available_at === null || now()->greaterThanOrEqualTo($this->resend_available_at);
  }

  public function markVerified(): void
  {
    $this->forceFill([
      'verified_at' => now(),
    ])->save();
  }
}
