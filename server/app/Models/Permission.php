<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Permission extends Model
{
  use HasFactory;

  protected $fillable = [
    'key',
    'module_key',
    'module_label',
    'label',
    'description',
    'admin_only',
    'module_order',
    'sort_order',
  ];
}
