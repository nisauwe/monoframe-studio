<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PaymentGatewayLog extends Model
{
  use HasFactory;

  protected $fillable = [
    'payment_gateway_id',
    'activity',
    'status',
    'message',
    'payload',
  ];

  protected $casts = [
    'payload' => 'array',
  ];

  public function gateway()
  {
    return $this->belongsTo(PaymentGateway::class, 'payment_gateway_id');
  }
}
