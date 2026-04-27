<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('edit_requests')) {
            return;
        }

        DB::statement("
            ALTER TABLE `edit_requests`
            MODIFY `status`
            ENUM('submitted', 'assigned', 'in_progress', 'completed')
            NOT NULL
            DEFAULT 'submitted'
        ");

        Schema::table('edit_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('edit_requests', 'assigned_at')) {
                $table->timestamp('assigned_at')->nullable()->after('status');
            }

            if (!Schema::hasColumn('edit_requests', 'edit_deadline_at')) {
                $table->timestamp('edit_deadline_at')->nullable()->after('assigned_at');
            }

            if (!Schema::hasColumn('edit_requests', 'started_at')) {
                $table->timestamp('started_at')->nullable()->after('edit_deadline_at');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('edit_requests')) {
            return;
        }

        DB::table('edit_requests')
            ->whereIn('status', ['assigned', 'in_progress'])
            ->update(['status' => 'submitted']);

        Schema::table('edit_requests', function (Blueprint $table) {
            if (Schema::hasColumn('edit_requests', 'started_at')) {
                $table->dropColumn('started_at');
            }

            if (Schema::hasColumn('edit_requests', 'edit_deadline_at')) {
                $table->dropColumn('edit_deadline_at');
            }

            if (Schema::hasColumn('edit_requests', 'assigned_at')) {
                $table->dropColumn('assigned_at');
            }
        });

        DB::statement("
            ALTER TABLE `edit_requests`
            MODIFY `status`
            ENUM('submitted', 'completed')
            NOT NULL
            DEFAULT 'submitted'
        ");
    }
};
