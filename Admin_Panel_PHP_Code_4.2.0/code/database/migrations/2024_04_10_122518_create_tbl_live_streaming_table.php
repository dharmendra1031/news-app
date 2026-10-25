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
        Schema::create('tbl_live_streaming', function (Blueprint $table) {
            $table->id();
            $table->integer('language_id')->index('language_id'); // Nullable foreign key
            $table->text('title');
            $table->string('image')->nullable();
            $table->string('type', 20)->nullable();
            $table->text('url')->nullable();
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
        Schema::dropIfExists('tbl_live_streaming');
    }
};
