<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Schema::hasTable('tbl_rss')) {
        Schema::create('tbl_rss', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id');
            $table->integer('category_id')->index('category_id');
            $table->integer('subcategory_id')->default(0)->index('subcategory_id');
            $table->string('tag_id');
            $table->string('feed_name');
            $table->string('feed_url');
            $table->tinyInteger('status')->index('status')->default(0)->comment('1-active, 0-deactive'); // 1=Active, 0=Deactive
            $table->timestamps();
        });
    }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_rss');
    }
};
