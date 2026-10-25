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
        Schema::create('tbl_breaking_news', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id'); // Nullable foreign key
            $table->text('title');
            $table->string('slug')->index('slug');
            $table->string('image')->nullable();
            $table->string('content_type', 50)->nullable();
            $table->text('content_value')->nullable();
            $table->text('description')->nullable();
            $table->text('meta_title')->nullable();
            $table->text('meta_description')->nullable();
            $table->text('meta_keyword')->nullable();
            $table->text('schema_markup')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_breaking_news');
    }
};
