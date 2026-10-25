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
        Schema::create('tbl_news_like', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id')->index('user_id');
            $table->integer('news_id')->index('news_id');
            $table->tinyInteger('status')->index('status')->comment('1-like, 2-dislike, 0-none');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_news_like');
    }
};
