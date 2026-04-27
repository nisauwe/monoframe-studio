<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Category extends Model
{
  use HasFactory;

  protected $fillable = [
    'name',
    'description',
    'is_active',
  ];

  public function packages()
  {
    return $this->hasMany(Package::class);
  }
  public function discounts()
  {
    return $this->hasMany(Discount::class);
  }
}
