<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {


        // Rename column from role to is_author and change to boolean
        // Using raw SQL to avoid requiring doctrine/dbal package

        if (Schema::hasColumn('tbl_users', 'role')) {
            DB::statement('ALTER TABLE `tbl_users` CHANGE `role` `is_author` TINYINT(1) NOT NULL DEFAULT 0 COMMENT \'0-no, 1-yes\'');
        }

        if(!Schema::hasTable('tbl_authors')){

            Schema::create('tbl_authors', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
                $table->text('bio')->nullable();
                $table->string('telegram_link')->nullable();
                $table->string('linkedin_link')->nullable();
                $table->string('facebook_link')->nullable();
                $table->string('whatsapp_link')->nullable();
                // enum
                $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
                $table->timestamps();
            });
        }

        Schema::table('tbl_news', function(Blueprint $table) {

            if(!Schema::hasColumn('tbl_news', 'is_draft')){
            // default 0
                $table->boolean('is_draft')->default(0)->comment('0-no, 1-yes')->after('status');
            }
        });


        Schema::table('tbl_featured_sections', function(Blueprint $table){
            if(!Schema::hasColumn('tbl_featured_sections', 'user_ids')){
                $table->string('user_ids')->nullable()->after('news_type')->comment('comma separated user_ids of authors');
            }
        });


        // // permission adding record
        // DB::table('permissions')->insert([
        //     'name' => 'author-list',
        //     'guard_name' => 'admin',
        //     'created_at' => now(),
        //     'updated_at' => now()
        // ], [
        //     'name' => 'author-edit',
        //     'guard_name' => 'admin',
        //     'created_at' => now(),
        //     'updated_at' => now()
        // ]);


    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {


        Schema::table('tbl_news', function(Blueprint $table) {
            $table->dropColumn('is_draft');
        });

        Schema::dropIfExists('tbl_authors');

        // Revert column rename from is_author back to role
        if (Schema::hasColumn('tbl_users', 'is_author')) {
            DB::statement('ALTER TABLE `tbl_users` CHANGE `is_author` `role` INT(11) NOT NULL');
        }



        Schema::table('tbl_featured_sections', function(Blueprint $table){
            $table->dropColumn('user_ids');
        });

    }
};
