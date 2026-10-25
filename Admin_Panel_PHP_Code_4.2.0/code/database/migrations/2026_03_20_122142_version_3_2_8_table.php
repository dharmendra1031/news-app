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
        // update the row in tbl_users table where tpye fb to facebook and gmail to google
        DB::table('tbl_users')->where('type', 'fb')->update(['type' => 'facebook']);
        DB::table('tbl_users')->where('type', 'Facebook')->update(['type' => 'facebook']);
        DB::table('tbl_users')->where('type', 'gmail')->update(['type' => 'google']);
        DB::table('tbl_users')->where('type', 'Google')->update(['type' => 'google']);


        Schema::table('tbl_languages', function (Blueprint $table) {
             if (!Schema::hasColumn('tbl_languages', 'app_file')) {
                $table->string('app_file')->nullable();
            }

            if (!Schema::hasColumn('tbl_languages', 'web_file')) {
                $table->string('web_file')->nullable();
            }

            if (!Schema::hasColumn('tbl_languages', 'panel_file')) {
                $table->string('panel_file')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_languages', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_languages', 'app_file')) {
                $table->dropColumn('app_file');
            }
            if (Schema::hasColumn('tbl_languages', 'web_file')) {
                $table->dropColumn('web_file');
            }
            if (Schema::hasColumn('tbl_languages', 'panel_file')) {
                $table->dropColumn('panel_file');
            }
        });
    }
};
