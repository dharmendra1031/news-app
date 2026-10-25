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
        Schema::create('tbl_breaking_news_view', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id')->index('user_id');
            $table->integer('breaking_news_id')->index('breaking_news_id');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_breaking_news_view');
    }
};
