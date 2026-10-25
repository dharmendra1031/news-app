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
        Schema::create('tbl_notifications', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->default(0)->index('language_id');
            $table->integer('category_id')->default(0)->index('category_id');
            $table->integer('subcategory_id')->default(0)->index('subcategory_id');
            $table->integer('news_id');
            $table->integer('location_id')->default(0)->index('location_id');
            $table->string('title')->nullable();
            $table->text('message')->nullable();
            $table->string('type', 12)->nullable();
            $table->string('image')->nullable();
            $table->dateTime('date_sent');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_notifications');
    }
};
