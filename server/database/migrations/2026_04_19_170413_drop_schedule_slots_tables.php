<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void
  {
    Schema::dropIfExists('schedule_booking_slot');
    Schema::dropIfExists('schedule_slots');
  }

  public function down(): void
  {
    //
  }
};
