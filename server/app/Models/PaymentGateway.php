<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PaymentGateway extends Model
{
  use HasFactory;

  public const DEFAULT_ENABLED_PAYMENT_TYPES = [
    'qris',
    'bank_transfer',
    'gopay',
    'bni_va',
    'bca_va',
    'permata_va',
  ];

  protected $fillable = [
    'provider',
    'environment',
    'merchant_id',
    'client_key',
    'server_key',
    'snap_url',
    'api_base_url',
    'notification_url',
    'finish_url',
    'unfinish_url',
    'error_url',
    'expiry_minutes',
    'admin_fee',
    'enabled_payment_types',
    'is_active',
    'auto_update_status',
    'is_visible_to_client',
    'webhook_enabled',
    'last_tested_at',
    'last_test_status',
    'last_test_message',
  ];

  protected $casts = [
    'enabled_payment_types' => 'array',
    'is_active' => 'boolean',
    'auto_update_status' => 'boolean',
    'is_visible_to_client' => 'boolean',
    'webhook_enabled' => 'boolean',
    'last_tested_at' => 'datetime',
    'client_key' => 'encrypted',
    'server_key' => 'encrypted',
  ];

  public function logs()
  {
    return $this->hasMany(PaymentGatewayLog::class);
  }

  public function resolvedEnabledPaymentTypes(): array
  {
    $types = array_values(array_filter($this->enabled_payment_types ?? []));

    return !empty($types)
      ? $types
      : self::DEFAULT_ENABLED_PAYMENT_TYPES;
  }
}
