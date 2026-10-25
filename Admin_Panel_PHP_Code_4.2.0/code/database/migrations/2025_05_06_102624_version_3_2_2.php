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
        Schema::table('tbl_news', function (Blueprint $table) {
            $table->boolean('is_comment')->default(1)->after('is_clone')->comment('0 - Comments disabled, 1 - Comments enabled');
        });

        Schema::table('tbl_notifications', function (Blueprint $table) {
            $table->boolean('category_preference')->default(0)->after('image');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_news', function (Blueprint $table) {
            $table->dropColumn('is_comment');
        });

        Schema::table('tbl_notifications', function (Blueprint $table) {
            $table->dropColumn('category_preference');
        });
    }
};
