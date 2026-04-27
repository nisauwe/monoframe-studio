<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Sinkron kolom print_prices lama dan baru
        |--------------------------------------------------------------------------
        | Admin server kamu saat ini masih pakai:
        | size_label, base_price, frame_price, is_active, notes
        |
        | API mobile memakai:
        | size_name, print_price, frame_price, is_available, paper_type
        |--------------------------------------------------------------------------
        */

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

        DB::table('print_prices')->update([
            'size_name' => DB::raw("COALESCE(NULLIF(size_name, ''), size_label)"),
            'paper_type' => DB::raw("COALESCE(NULLIF(paper_type, ''), notes)"),
        ]);

        DB::statement("
            UPDATE print_prices
            SET print_price = CASE
                WHEN print_price IS NULL OR print_price = 0 THEN base_price
                ELSE print_price
            END
        ");

        DB::statement("
            UPDATE print_prices
            SET is_available = CASE
                WHEN is_available IS NULL THEN is_active
                ELSE is_available
            END
        ");

        /*
        |--------------------------------------------------------------------------
        | Header print_orders
        |--------------------------------------------------------------------------
        | print_orders tidak perlu print_price_id, karena ukuran cetak ada di
        | print_order_items supaya 1 order bisa banyak ukuran.
        |--------------------------------------------------------------------------
        */

        if (!Schema::hasTable('print_orders')) {
            Schema::create('print_orders', function (Blueprint $table) {
                $table->id();
                $table->foreignId('schedule_booking_id')->constrained('schedule_bookings')->cascadeOnDelete();
                $table->foreignId('client_user_id')->constrained('users')->cascadeOnDelete();

                $table->json('selected_files')->nullable();
                $table->unsignedInteger('quantity')->default(0);

                $table->string('size_name')->nullable();
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
                    $table->unsignedInteger('quantity')->default(0);
                }

                if (!Schema::hasColumn('print_orders', 'size_name')) {
                    $table->string('size_name')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'paper_type')) {
                    $table->string('paper_type')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'use_frame')) {
                    $table->boolean('use_frame')->default(false);
                }

                if (!Schema::hasColumn('print_orders', 'print_unit_price')) {
                    $table->decimal('print_unit_price', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_orders', 'frame_unit_price')) {
                    $table->decimal('frame_unit_price', 15, 2)->default(0);
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

                if (!Schema::hasColumn('print_orders', 'paid_at')) {
                    $table->timestamp('paid_at')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'processed_at')) {
                    $table->timestamp('processed_at')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'completed_at')) {
                    $table->timestamp('completed_at')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'delivery_proof_path')) {
                    $table->string('delivery_proof_path')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'delivery_proof_url')) {
                    $table->string('delivery_proof_url')->nullable();
                }

                if (!Schema::hasColumn('print_orders', 'notes')) {
                    $table->text('notes')->nullable();
                }
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Detail print_order_items
        |--------------------------------------------------------------------------
        */

        if (!Schema::hasTable('print_order_items')) {
            Schema::create('print_order_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('print_order_id')->constrained('print_orders')->cascadeOnDelete();
                $table->foreignId('print_price_id')->nullable()->constrained('print_prices')->nullOnDelete();

                $table->string('file_name');
                $table->unsignedInteger('qty')->default(1);
                $table->boolean('use_frame')->default(false);

                $table->decimal('unit_print_price', 15, 2)->default(0);
                $table->decimal('unit_frame_price', 15, 2)->default(0);
                $table->decimal('line_total', 15, 2)->default(0);

                $table->timestamps();
            });
        } else {
            Schema::table('print_order_items', function (Blueprint $table) {
                if (!Schema::hasColumn('print_order_items', 'print_order_id')) {
                    $table->foreignId('print_order_id')->nullable()->constrained('print_orders')->cascadeOnDelete();
                }

                if (!Schema::hasColumn('print_order_items', 'print_price_id')) {
                    $table->foreignId('print_price_id')->nullable()->constrained('print_prices')->nullOnDelete();
                }

                if (!Schema::hasColumn('print_order_items', 'file_name')) {
                    $table->string('file_name')->nullable();
                }

                if (!Schema::hasColumn('print_order_items', 'qty')) {
                    $table->unsignedInteger('qty')->default(1);
                }

                if (!Schema::hasColumn('print_order_items', 'use_frame')) {
                    $table->boolean('use_frame')->default(false);
                }

                if (!Schema::hasColumn('print_order_items', 'unit_print_price')) {
                    $table->decimal('unit_print_price', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_order_items', 'unit_frame_price')) {
                    $table->decimal('unit_frame_price', 15, 2)->default(0);
                }

                if (!Schema::hasColumn('print_order_items', 'line_total')) {
                    $table->decimal('line_total', 15, 2)->default(0);
                }
            });
        }
    }

    public function down(): void
    {
        // Sengaja tidak drop kolom/tabel supaya data cetak tidak hilang.
    }
};
