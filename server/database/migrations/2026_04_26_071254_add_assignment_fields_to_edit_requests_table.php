<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
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
    }
};
