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
        //
        Schema::table('tbl_news', function (Blueprint $table) {
            // updating the published_date column with adding null constraint and removing the index
            // $table->dropIndex(['published_date']);

            // Change column to allow NULL
            $table->date('published_date')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
        Schema::table('tbl_news', function (Blueprint $table) {
            $table->date('published_date')->nullable(false)->change();

            // Recreate index
            // $table->index('published_date');
        });
    }
};
