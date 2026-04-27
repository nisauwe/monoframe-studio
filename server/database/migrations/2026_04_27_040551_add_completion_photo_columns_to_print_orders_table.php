<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('print_orders')) {
            return;
        }

        Schema::table('print_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('print_orders', 'completion_photo_path')) {
                $table->string('completion_photo_path')->nullable()->after('delivery_proof_url');
            }

            if (!Schema::hasColumn('print_orders', 'completion_photo_url')) {
                $table->string('completion_photo_url')->nullable()->after('completion_photo_path');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('print_orders')) {
            return;
        }

        Schema::table('print_orders', function (Blueprint $table) {
            if (Schema::hasColumn('print_orders', 'completion_photo_url')) {
                $table->dropColumn('completion_photo_url');
            }

            if (Schema::hasColumn('print_orders', 'completion_photo_path')) {
                $table->dropColumn('completion_photo_path');
            }
        });
    }
};
