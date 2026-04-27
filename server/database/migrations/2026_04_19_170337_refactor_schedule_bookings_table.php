<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void
  {
    if (!Schema::hasTable('schedule_bookings')) {
      Schema::create('schedule_bookings', function (Blueprint $table) {
        $table->id();

        $table->foreignId('package_id')->constrained('packages')->cascadeOnDelete();
        $table->foreignId('client_user_id')->constrained('users')->cascadeOnDelete();
        $table->foreignId('photographer_user_id')->constrained('users')->cascadeOnDelete();

        $table->string('client_name');
        $table->string('client_phone')->nullable();
        $table->string('photographer_name');

        $table->date('booking_date');
        $table->time('start_time');
        $table->time('end_time');
        $table->time('blocked_until');

        $table->unsignedInteger('duration_minutes')->default(0);
        $table->unsignedInteger('extra_duration_minutes')->default(0);
        $table->unsignedBigInteger('extra_duration_fee')->default(0);

        $table->enum('location_type', ['indoor', 'outdoor'])->default('indoor');
        $table->string('location_name')->nullable();

        $table->string('status')->default('confirmed');
        $table->string('source')->default('manual_request');
        $table->text('notes')->nullable();

        $table->timestamps();
      });

      return;
    }

    Schema::table('schedule_bookings', function (Blueprint $table) {
      if (!Schema::hasColumn('schedule_bookings', 'client_user_id')) {
        $table->foreignId('client_user_id')->nullable()->after('package_id')->constrained('users')->nullOnDelete();
      }

      if (!Schema::hasColumn('schedule_bookings', 'photographer_user_id')) {
        $table->foreignId('photographer_user_id')->nullable()->after('client_user_id')->constrained('users')->nullOnDelete();
      }

      if (!Schema::hasColumn('schedule_bookings', 'client_name')) {
        $table->string('client_name')->nullable()->after('photographer_user_id');
      }

      if (!Schema::hasColumn('schedule_bookings', 'client_phone')) {
        $table->string('client_phone')->nullable()->after('client_name');
      }

      if (!Schema::hasColumn('schedule_bookings', 'photographer_name')) {
        $table->string('photographer_name')->nullable()->after('client_phone');
      }

      if (!Schema::hasColumn('schedule_bookings', 'blocked_until')) {
        $table->time('blocked_until')->nullable()->after('end_time');
      }

      if (!Schema::hasColumn('schedule_bookings', 'duration_minutes')) {
        $table->unsignedInteger('duration_minutes')->default(0)->after('blocked_until');
      }

      if (!Schema::hasColumn('schedule_bookings', 'extra_duration_minutes')) {
        $table->unsignedInteger('extra_duration_minutes')->default(0)->after('duration_minutes');
      }

      if (!Schema::hasColumn('schedule_bookings', 'extra_duration_fee')) {
        $table->unsignedBigInteger('extra_duration_fee')->default(0)->after('extra_duration_minutes');
      }

      if (!Schema::hasColumn('schedule_bookings', 'location_type')) {
        $table->enum('location_type', ['indoor', 'outdoor'])->default('indoor')->after('extra_duration_fee');
      }

      if (!Schema::hasColumn('schedule_bookings', 'location_name')) {
        $table->string('location_name')->nullable()->after('location_type');
      }

      if (!Schema::hasColumn('schedule_bookings', 'status')) {
        $table->string('status')->default('confirmed')->after('location_name');
      }

      if (!Schema::hasColumn('schedule_bookings', 'source')) {
        $table->string('source')->default('manual_request')->after('status');
      }

      if (!Schema::hasColumn('schedule_bookings', 'notes')) {
        $table->text('notes')->nullable()->after('source');
      }
    });
  }

  public function down(): void
  {
    //
  }
};
