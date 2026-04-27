<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('print_prices')) {
            Schema::create('print_prices', function (Blueprint $table) {
                $table->id();
                $table->string('size_name');
                $table->string('paper_type')->nullable();
                $table->decimal('print_price', 15, 2)->default(0);
                $table->decimal('frame_price', 15, 2)->default(0);
                $table->boolean('is_available')->default(true);
                $table->timestamps();
            });
        } else {
            Schema::table('print_prices', function (Blueprint $table) {
                if (!Schema::hasColumn('print_prices', 'size_name')) {
                    $table->string('size_name')->nullable();
                }

                if (!Schema::hasColumn('print_prices', 'paper_type')) {
                    $table->string('paper_type')->nullable();
                }

                if (!Schema::hasColumn('print_prices', 'print_price')) {
                    $table->decimal('print_price', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_prices', 'frame_price')) {
                    $table->decimal('frame_price', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_prices', 'is_available')) {
                    $table->boolean('is_available')->default(true);
                }
            });
        }

        if (!Schema::hasTable('print_orders')) {
            Schema::create('print_orders', function (Blueprint $table) {
                $table->id();
                $table->foreignId('schedule_booking_id')->constrained('schedule_bookings')->cascadeOnDelete();
                $table->foreignId('client_user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('print_price_id')->nullable()->constrained('print_prices')->nullOnDelete();

                $table->json('selected_files');
                $table->unsignedInteger('quantity')->default(1);

                $table->string('size_name');
                $table->string('paper_type')->nullable();

                $table->boolean('use_frame')->default(false);
                $table->decimal('print_unit_price', 15, 2)->default(0);
                $table->decimal('frame_unit_price', 15, 2)->default(0);
                $table->decimal('subtotal_print', 15, 2)->default(0);
                $table->decimal('subtotal_frame', 15, 2)->default(0);
                $table->decimal('total_amount', 15, 2)->default(0);

                $table->enum('delivery_method', ['pickup', 'delivery'])->default('pickup');
                $table->string('recipient_name')->nullable();
                $table->string('recipient_phone')->nullable();
                $table->text('delivery_address')->nullable();

                $table->string('status')->default('pending_payment');
                $table->string('payment_status')->default('unpaid');

                $table->timestamp('paid_at')->nullable();
                $table->timestamp('processed_at')->nullable();
                $table->timestamp('completed_at')->nullable();

                $table->string('delivery_proof_path')->nullable();
                $table->string('delivery_proof_url')->nullable();

                $table->text('notes')->nullable();
                $table->timestamps();
            });
        } else {
            Schema::table('print_orders', function (Blueprint $table) {
                if (!Schema::hasColumn('print_orders', 'selected_files')) {
                    $table->json('selected_files')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'quantity')) {
                    $table->unsignedInteger('quantity')->default(1);
                }

                if (!Schema::hasColumn('print_orders', 'use_frame')) {
                    $table->boolean('use_frame')->default(false);
                }

                if (!Schema::hasColumn('print_orders', 'subtotal_print')) {
                    $table->decimal('subtotal_print', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_orders', 'subtotal_frame')) {
                    $table->decimal('subtotal_frame', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_orders', 'total_amount')) {
                    $table->decimal('total_amount', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_orders', 'delivery_method')) {
                    $table->enum('delivery_method', ['pickup', 'delivery'])->default('pickup');
                }

                if (!Schema::hasColumn('print_orders', 'recipient_name')) {
                    $table->string('recipient_name')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'recipient_phone')) {
                    $table->string('recipient_phone')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'delivery_address')) {
                    $table->text('delivery_address')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'status')) {
                    $table->string('status')->default('pending_payment');
                }

                if (!Schema::hasColumn('print_orders', 'payment_status')) {
                    $table->string('payment_status')->default('unpaid');
                }

                if (!Schema::hasColumn('print_orders', 'delivery_proof_path')) {
                    $table->string('delivery_proof_path')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'delivery_proof_url')) {
                    $table->string('delivery_proof_url')->nullable();
                }
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('print_orders');
        Schema::dropIfExists('print_prices');
    }
};
