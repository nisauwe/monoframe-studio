<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('incomes')) {
            return;
        }

        Schema::create('incomes', function (Blueprint $table) {
            $table->id();
            $table->date('income_date');
            $table->string('category')->nullable();
            $table->decimal('amount', 12, 2);
            $table->text('description')->nullable();

            $table->foreignId('created_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamps();

            $table->index('income_date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('incomes');
    }
};