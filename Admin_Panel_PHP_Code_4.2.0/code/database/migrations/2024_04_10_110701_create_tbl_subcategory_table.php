<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_subcategory', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id');
            $table->integer('category_id')->index('category_id');
            $table->string('subcategory_name');
            $table->string('slug')->index('slug');
            $table->integer('row_order')->default(0)->index('row_order');
            $table->string('image');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_subcategory');
    }
};
