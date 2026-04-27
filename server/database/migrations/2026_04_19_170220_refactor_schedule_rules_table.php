<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
  public function up(): void
  {
    if (!Schema::hasTable('schedule_rules')) {
      Schema::create('schedule_rules', function (Blueprint $table) {
        $table->id();
        $table->unsignedTinyInteger('day_of_week');
        $table->string('day_name');

        $table->boolean('is_active')->default(true);

        $table->time('indoor_open_time')->nullable();
        $table->time('indoor_close_time')->nullable();

        $table->time('outdoor_open_time')->nullable();
        $table->time('outdoor_close_time')->nullable();

        $table->unsignedInteger('slot_grid_minutes')->default(15);

        $table->unsignedInteger('indoor_capacity')->default(1);

        $table->unsignedInteger('indoor_buffer_minutes')->default(15);
        $table->unsignedInteger('outdoor_buffer_minutes')->default(45);

        $table->unsignedInteger('extra_duration_minutes')->default(30);
        $table->unsignedBigInteger('extra_duration_fee')->default(150000);

        $table->timestamps();
      });

      return;
    }

    Schema::table('schedule_rules', function (Blueprint $table) {
      if (!Schema::hasColumn('schedule_rules', 'indoor_open_time')) {
        $table->time('indoor_open_time')->nullable()->after('is_active');
      }

      if (!Schema::hasColumn('schedule_rules', 'indoor_close_time')) {
        $table->time('indoor_close_time')->nullable()->after('indoor_open_time');
      }

      if (!Schema::hasColumn('schedule_rules', 'outdoor_open_time')) {
        $table->time('outdoor_open_time')->nullable()->after('indoor_close_time');
      }

      if (!Schema::hasColumn('schedule_rules', 'outdoor_close_time')) {
        $table->time('outdoor_close_time')->nullable()->after('outdoor_open_time');
      }

      if (!Schema::hasColumn('schedule_rules', 'slot_grid_minutes')) {
        $table->unsignedInteger('slot_grid_minutes')->default(15)->after('outdoor_close_time');
      }

      if (!Schema::hasColumn('schedule_rules', 'indoor_capacity')) {
        $table->unsignedInteger('indoor_capacity')->default(1)->after('slot_grid_minutes');
      }

      if (!Schema::hasColumn('schedule_rules', 'indoor_buffer_minutes')) {
        $table->unsignedInteger('indoor_buffer_minutes')->default(15)->after('indoor_capacity');
      }

      if (!Schema::hasColumn('schedule_rules', 'outdoor_buffer_minutes')) {
        $table->unsignedInteger('outdoor_buffer_minutes')->default(45)->after('indoor_buffer_minutes');
      }

      if (!Schema::hasColumn('schedule_rules', 'extra_duration_minutes')) {
        $table->unsignedInteger('extra_duration_minutes')->default(30)->after('outdoor_buffer_minutes');
      }

      if (!Schema::hasColumn('schedule_rules', 'extra_duration_fee')) {
        $table->unsignedBigInteger('extra_duration_fee')->default(150000)->after('extra_duration_minutes');
      }
    });

    if (Schema::hasColumn('schedule_rules', 'open_time')) {
      DB::table('schedule_rules')
        ->whereNull('indoor_open_time')
        ->update(['indoor_open_time' => DB::raw('open_time')]);

      DB::table('schedule_rules')
        ->whereNull('outdoor_open_time')
        ->update(['outdoor_open_time' => DB::raw('open_time')]);
    }

    if (Schema::hasColumn('schedule_rules', 'close_time')) {
      DB::table('schedule_rules')
        ->whereNull('indoor_close_time')
        ->update(['indoor_close_time' => DB::raw('close_time')]);

      DB::table('schedule_rules')
        ->whereNull('outdoor_close_time')
        ->update(['outdoor_close_time' => DB::raw('close_time')]);
    }

    if (Schema::hasColumn('schedule_rules', 'default_capacity')) {
      DB::table('schedule_rules')
        ->where('indoor_capacity', 1)
        ->update(['indoor_capacity' => DB::raw('default_capacity')]);
    }

    if (Schema::hasColumn('schedule_rules', 'buffer_minutes')) {
      DB::table('schedule_rules')
        ->where('indoor_buffer_minutes', 15)
        ->update(['indoor_buffer_minutes' => DB::raw('buffer_minutes')]);

      DB::table('schedule_rules')
        ->where('outdoor_buffer_minutes', 45)
        ->update(['outdoor_buffer_minutes' => DB::raw('buffer_minutes')]);
    }
  }

  public function down(): void
  {
    //
  }
};
