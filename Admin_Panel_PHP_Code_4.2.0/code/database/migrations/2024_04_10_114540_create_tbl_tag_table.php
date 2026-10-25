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
        Schema::create('tbl_tag', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id'); // Nullable foreign key
            $table->string('tag_name', 100)->nullable();
            $table->string('slug')->index('slug');
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
        Schema::dropIfExists('tbl_tag');
    }
};
