<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('edit_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('edit_requests', 'result_drive_url')) {
                $table->text('result_drive_url')->nullable()->after('editor_notes');
            }

            if (!Schema::hasColumn('edit_requests', 'result_drive_label')) {
                $table->string('result_drive_label')->nullable()->after('result_drive_url');
            }
        });
    }

    public function down(): void
    {
        Schema::table('edit_requests', function (Blueprint $table) {
            if (Schema::hasColumn('edit_requests', 'result_drive_label')) {
                $table->dropColumn('result_drive_label');
            }

            if (Schema::hasColumn('edit_requests', 'result_drive_url')) {
                $table->dropColumn('result_drive_url');
            }
        });
    }
};
