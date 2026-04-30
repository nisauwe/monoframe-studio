<?php

namespace App\Http\Requests\FrontOffice;

use Illuminate\Foundation\Http\FormRequest;

class StoreIncomeRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'income_date' => ['required', 'date'],
      'category' => ['nullable', 'string', 'max:255'],
      'amount' => ['required', 'numeric', 'min:1'],
      'description' => ['nullable', 'string'],
    ];
  }
}
