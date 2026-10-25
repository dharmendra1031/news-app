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
        //
        if (!Schema::hasTable('featured_section_rss_feeds')) {

            Schema::create('featured_section_rss_feeds', function (Blueprint $table) {
                $table->id();
                $table->foreignId('featured_section_id')->references('id')->on('tbl_featured_sections')->onDelete('cascade');
                $table->foreignId('rss_feed_id')->references('id')->on('tbl_rss')->onDelete('cascade');
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('featured_section_rss_feeds')) {
            Schema::dropIfExists('featured_section_rss_feeds');
        }
    }
};
