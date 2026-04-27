<?php

namespace App\Http\Requests\FrontOffice;

use Illuminate\Foundation\Http\FormRequest;

class CalendarFilterRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'start_date' => ['nullable', 'date'],
      'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
      'photographer_user_id' => ['nullable', 'exists:users,id'],
    ];
  }
}
