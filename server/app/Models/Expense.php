<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Expense extends Model
{
  use HasFactory;

  protected $fillable = [
    'expense_date',
    'category',
    'amount',
    'description',
    'created_by_user_id',
  ];

  protected $casts = [
    'expense_date' => 'date',
    'amount' => 'decimal:2',
  ];

  public function createdBy()
  {
    return $this->belongsTo(User::class, 'created_by_user_id');
  }
}
