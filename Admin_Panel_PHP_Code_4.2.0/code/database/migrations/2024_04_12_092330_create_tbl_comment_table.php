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
        Schema::create('tbl_comment', function (Blueprint $table) {
            $table->id();
            $table->integer('parent_id')->default(0)->index('parent_id');
            $table->integer('user_id')->index('user_id');
            $table->integer('news_id')->index('news_id');
            $table->text('message');
            $table->tinyInteger('status')->default(0)->comment('0-unapproved, 1-approved');
            $table->dateTime('date');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_comment');
    }
};
