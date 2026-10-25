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
        // news table add summarized_description column
        if(!Schema::hasColumn('tbl_news', 'summarized_description')){
            Schema::table('tbl_news', function (Blueprint $table) {
                $table->string('summarized_description')->nullable()->after('description');
            });
        }

        // breaking news table add summarized_description column
        if(!Schema::hasColumn('tbl_breaking_news', 'summarized_description')){
            Schema::table('tbl_breaking_news', function (Blueprint $table) {
                $table->string('summarized_description')->nullable()->after('description');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // news table drop summarized_description column
        Schema::table('tbl_news', function (Blueprint $table) {
            $table->dropColumn('summarized_description');
        });

        // breaking news table drop summarized_description column
        Schema::table('tbl_breaking_news', function (Blueprint $table) {
            $table->dropColumn('summarized_description');
        });
    }
};
