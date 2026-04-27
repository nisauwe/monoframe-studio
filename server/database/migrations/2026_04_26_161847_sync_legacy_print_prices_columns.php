<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('print_prices', function (Blueprint $table) {
            if (!Schema::hasColumn('print_prices', 'size_name')) {
                $table->string('size_name')->nullable()->after('size_label');
            }

            if (!Schema::hasColumn('print_prices', 'paper_type')) {
                $table->string('paper_type')->nullable()->after('size_name');
            }

            if (!Schema::hasColumn('print_prices', 'print_price')) {
                $table->decimal('print_price', 15, 2)->default(0)->after('base_price');
            }

            if (!Schema::hasColumn('print_prices', 'is_available')) {
                $table->boolean('is_available')->default(true)->after('is_active');
            }
        });

        DB::table('print_prices')
            ->whereNull('size_name')
            ->update([
                'size_name' => DB::raw('size_label'),
            ]);

        DB::table('print_prices')
            ->where(function ($query) {
                $query->whereNull('print_price')
                    ->orWhere('print_price', 0);
            })
            ->update([
                'print_price' => DB::raw('base_price'),
            ]);

        DB::table('print_prices')
            ->whereNull('paper_type')
            ->update([
                'paper_type' => DB::raw('notes'),
            ]);

        DB::table('print_prices')
            ->whereNull('is_available')
            ->update([
                'is_available' => DB::raw('is_active'),
            ]);
    }

    public function down(): void
    {
        // Tidak di-drop supaya tidak merusak data yang sudah dipakai API mobile.
    }
};
