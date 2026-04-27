<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'print_order_id')) {
                $table->unsignedBigInteger('print_order_id')->nullable()->after('schedule_booking_id');
            }

            if (!Schema::hasColumn('payments', 'payment_context')) {
                $table->string('payment_context', 50)->nullable()->after('print_order_id');
            }

            if (!Schema::hasColumn('payments', 'payment_stage')) {
                $table->string('payment_stage', 50)->nullable()->after('payment_context');
            }
        });

        DB::statement("ALTER TABLE payments MODIFY payment_context VARCHAR(50) NULL");
        DB::statement("ALTER TABLE payments MODIFY payment_stage VARCHAR(50) NULL");

        if (!$this->hasForeignKey('payments', 'payments_print_order_id_foreign')) {
            Schema::table('payments', function (Blueprint $table) {
                $table->foreign('print_order_id')
                    ->references('id')
                    ->on('print_orders')
                    ->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE payments MODIFY payment_context VARCHAR(50) NULL");
        DB::statement("ALTER TABLE payments MODIFY payment_stage VARCHAR(50) NULL");
    }

    private function hasForeignKey(string $table, string $foreignKeyName): bool
    {
        $database = DB::getDatabaseName();

        $result = DB::selectOne("
            SELECT CONSTRAINT_NAME
            FROM information_schema.TABLE_CONSTRAINTS
            WHERE CONSTRAINT_SCHEMA = ?
              AND TABLE_NAME = ?
              AND CONSTRAINT_NAME = ?
              AND CONSTRAINT_TYPE = 'FOREIGN KEY'
            LIMIT 1
        ", [$database, $table, $foreignKeyName]);

        return $result !== null;
    }
};
