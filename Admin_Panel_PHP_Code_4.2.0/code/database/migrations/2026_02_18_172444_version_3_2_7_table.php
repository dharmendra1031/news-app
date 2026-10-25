<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // tbl_news table add is_short_news boolean column
        Schema::table('tbl_news', function (Blueprint $table) {
            // is short news boolean column
            if(!Schema::hasColumn('tbl_news', 'is_short_news')){
                $table->boolean('is_short_news')->default(0)->comment('0-no, 1-yes');
            }
        });

        // new table for eNews (consists news id and news title)
        if(!Schema::hasTable('tbl_e_news')){
            Schema::create('tbl_e_news', function (Blueprint $table) {
                $table->id();
                $table->foreignId('language_id')->references('id')->on('tbl_languages')->onDelete('cascade');
                // $table->foreignId('news_id')->references('id')->on('tbl_news')->onDelete('cascade');
                $table->string('title');
                $table->string('slug')->index('slug');
                $table->text('description')->nullable();
                $table->string('thumbnail')->nullable();
                $table->string('attachment');
                $table->date('date')->nullable();
                // seo fields keyword, title description and schema markup
                $table->text('meta_keyword')->nullable();
                $table->text('meta_title')->nullable();
                $table->text('meta_description')->nullable();
                $table->text('schema_markup')->nullable();

                $table->tinyInteger('status')->default(1)->comment('1-active, 0-deactive'); // 1=Active, 0=Deactive

                $table->timestamps();
            });
        }

        Schema::table('tbl_token', function (Blueprint $table) {
            if(!Schema::hasColumn('tbl_token', 'user_id')){

                $table->unsignedBigInteger('user_id')->nullable()->after('id');
                // $table->string('device_id')->nullable()->unique()->after('user_id');
                // $table->string('platform', 20)->nullable()->after('longitude');

                $table->foreign('user_id')->references('id')->on('tbl_users')->onDelete('set null');
                $table->index('user_id');
            }
        });

        Schema::table('tbl_users', function (Blueprint $table) {
            // firebase_id and fcm_id nullable
            if(!Schema::hasColumn('tbl_users', 'firebase_id')){
                $table->string('firebase_id')->nullable()->after('id');
            }
            if(!Schema::hasColumn('tbl_users', 'fcm_id')){
                $table->string('fcm_id')->nullable()->after('firebase_id');
            }
        });

        if (!Schema::hasColumn('tbl_web_seo_pages', 'language_id')) {
            Schema::table('tbl_web_seo_pages', function (Blueprint $table) {
                // $table->integer('language_id')->nullable()->after('id');
                $table->foreignId('language_id')->nullable()->references('id')->on('tbl_languages')->onDelete('cascade');
            });
        }


        // create_rss_sources_table
        Schema::table('tbl_rss', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_rss', 'last_fetched_at')) {
                $table->timestamp('last_fetched_at')->nullable();
            }
        });

        if(!Schema::hasTable('feed_items')){

            Schema::create('feed_items', function (Blueprint $table) {
                $table->id();
                $table->foreignId('rss_source_id')->references('id')->on('tbl_rss')->onDelete('cascade');
                $table->string('guid');
                $table->string('title');
                $table->text('url');
                $table->longText('description')->nullable();
                $table->string('image_url')->nullable();  // enclosure or media:thumbnail
                $table->string('author')->nullable();
                $table->timestamp('published_at')->nullable();
                $table->timestamp('fetched_at')->nullable();
                $table->timestamps();

                $table->unique(['guid', 'rss_source_id'], 'feed_items_guid_rss_source_unique');

                $table->index(['rss_source_id', 'published_at']);
            });
        }

        if (!Schema::hasColumn('tbl_web_seo_pages', 'language_id')) {
            Schema::table('tbl_web_seo_pages', function (Blueprint $table) {
                // $table->integer('language_id')->nullable()->after('id');
                $table->foreignId('language_id')->nullable()->references('id')->on('tbl_languages')->onDelete('cascade');
            });
        }

        DB::table('tbl_users')
        ->whereNotNull('fcm_id')
        ->orderBy('id')
        ->chunkById(200, function ($users) {
            foreach ($users as $user) {
                DB::table('tbl_token')->updateOrInsert(
                    ['token' => $user->fcm_id],
                    [
                        'user_id'    => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        });

        // Clean up old guest tokens without loading them into memory at all
        DB::table('tbl_token')
            ->whereNull('user_id')
            ->where('updated_at', '<', now()->subMonths(2))
            ->delete();

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
        Schema::table('tbl_news', function (Blueprint $table) {
            $table->dropColumn('is_short_news');
        });
        Schema::dropIfExists('tbl_e_news');

        Schema::table('tbl_token', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropIndex(['user_id']);
            $table->dropUnique(['device_id']);
            $table->dropColumn(['user_id', 'device_id']);
        });
        if (Schema::hasColumn('tbl_web_seo_pages', 'language_id')) {
            Schema::table('tbl_web_seo_pages', function (Blueprint $table) {
                $table->dropColumn('language_id');
            });
        }

        Schema::dropIfExists('feed_items');
        Schema::table('tbl_rss', function (Blueprint $table) {
            $table->dropColumn('last_fetched_at');
        });

        if (Schema::hasColumn('tbl_web_seo_pages', 'language_id')) {
            Schema::table('tbl_web_seo_pages', function (Blueprint $table) {
                $table->dropColumn('language_id');
            });
        }
    }
};
