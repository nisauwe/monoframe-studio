<?php

namespace App\Http\Requests\FrontOffice;

use Illuminate\Foundation\Http\FormRequest;

class StoreExpenseRequest extends FormRequest
{
  public function authorize(): bool
  {
    return true;
  }

  public function rules(): array
  {
    return [
      'expense_date' => ['required', 'date'],
      'category' => ['nullable', 'string', 'max:255'],
      'amount' => ['required', 'numeric', 'min:0'],
      'description' => ['nullable', 'string'],
    ];
  }
}
