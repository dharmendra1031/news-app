<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_featured_sections', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id');
            $table->string('title', 500)->nullable();
            $table->string('slug', 500)->nullable();
            $table->string('short_description', 500)->nullable();
            $table->string('news_type', 500)->nullable();
            $table->string('videos_type', 100)->nullable();
            $table->string('filter_type', 500)->nullable();
            $table->string('category_ids');
            $table->string('subcategory_ids');
            $table->string('news_ids');
            $table->string('style_app', 100)->nullable();
            $table->string('style_web', 100)->nullable();
            $table->integer('row_order')->default(0);
            $table->tinyInteger('status')->default(1)->comment('0-deactive, 1-active');
            $table->tinyInteger('is_based_on_user_choice')->comment('0-filter_section, 1-news from users category');
            $table->text('meta_title')->nullable();
            $table->text('meta_description')->nullable();
            $table->text('meta_keyword')->nullable();
            $table->text('schema_markup')->nullable();
            $table->text('og_image')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_featured_sections');
    }
};
