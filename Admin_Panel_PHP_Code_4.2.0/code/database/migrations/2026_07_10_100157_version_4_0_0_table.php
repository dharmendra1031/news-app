<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
       DB::table('tbl_settings')->insert([
         ['type'      => 'news_buzz_mode',
         'message'    => '1',
         'created_at' => now(),
         'updated_at' => now(),
        ],
        [
        'type'       => 'podcast_mode',
        'message'    => '1',
        'created_at' => now(),
        'updated_at' => now(),
        ],
        [
        'type'       => 'ad_after_page_clicks',
        'message'    => '1',
        'created_at' => now(),
        'updated_at' => now(),
        ],
        [
        'type'       => 'youtube_api_key',
        'message'    => '',
        'created_at' => now(),
        'updated_at' => now(),
        ],
        [
        'type'       => 'finnhub_api_key',
        'message'    => '',
        'created_at' => now(),
        'updated_at' => now(),
        ],
        [
        'type'       => 'twelvedata_api_key',
        'message'    => '',
        'created_at' => now(),
        'updated_at' => now(),
        ]
       ]);

       if(!Schema::hasTable('podcasts')){
            Schema::create('podcasts', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->nullable()->references('id')->on('tbl_users')->onDelete('cascade');
                $table->string('title');
                $table->string('slug')->unique();
                $table->text('description');
                $table->string('image');
                $table->boolean('draft')->default(false);
                $table->string('status')->default('1');
                $table->timestamp('published_at')->nullable();

                $table->text('meta_title')->nullable();
                $table->text('meta_description')->nullable();
                $table->text('meta_keyword')->nullable();
                $table->text('schema_markup')->nullable();

                $table->timestamps();
            });
       }
       if(!Schema::hasTable('podcast_episodes')){
            Schema::create('podcast_episodes', function (Blueprint $table) {
                $table->id();
                $table->foreignId('podcast_id')->references('id')->on('podcasts')->onDelete('cascade');
                $table->integer('episode_no');
                $table->string('title');
                $table->string('slug')->unique();
                $table->text('description');
                $table->string('image');
                $table->string('source_type');
                $table->string('audio_url');
                $table->string('status');
                $table->integer('duration_seconds');
                $table->boolean('draft')->default(false);
                $table->timestamp('published_at')->nullable();
                $table->timestamps();
            });
       }
       if(!Schema::hasTable('episode_bookmarks')){
          Schema::create('episode_bookmarks', function (Blueprint $table){
               $table->id();
               $table->foreignId('episode_id')->references('id')->on('podcast_episodes')->onDelete('cascade');
               $table->foreignId('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
               $table->timestamp('followed_at');
               $table->timestamps();
          });
       }
        if(!Schema::hasTable('episode_play_history')){
          Schema::create('episode_play_history', function (Blueprint $table){
               $table->id();
               $table->foreignId('episode_id')->references('id')->on('podcast_episodes')->onDelete('cascade');
               $table->foreignId('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
               $table->integer('listened_seconds');
               $table->boolean('completed');
               $table->timestamps();
          });
        }
        if(!Schema::hasTable('podcast_follows')){
          Schema::create('podcast_follows', function (Blueprint $table){
              $table->id();
              $table->foreignId('podcast_id')->references('id')->on('podcasts')->onDelete('cascade');
              $table->foreignId('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
              $table->timestamp('followed_at');
          });
        }
        Schema::table('tbl_authors', function (Blueprint $table) {
            $table->boolean('auto_approve')->nullable()->after('status')->default(false);
        });
        Schema::table('video_shorts', function (Blueprint $table) {
            $table->string('video_type')->after('slug')->default('video_upload');
        });

        if(!Schema::hasTable('alerts')) {
            Schema::create('alerts', function (Blueprint $table) {
                $table->id();
                $table->enum('alert_type', ['stock','commodity','forex','Crypto','IPO']);
                $table->string('name');
                $table->string('symbol')->nullable();
                $table->string('exchange')->nullable();
                $table->string('ipo_price')->nullable();
                $table->decimal('current_price', 15, 4)->nullable();
                $table->string('currency', 10)->nullable();
                $table->decimal('percent_change', 8, 4)->nullable();
                $table->enum('direction', ['up', 'down', 'unchanged'])->nullable();
                $table->boolean('status')->default(true);
                $table->timestamp('last_updated_at')->nullable();
                $table->timestamps();
            });
        }


        if (!Schema::hasTable('notification_types')) {
            Schema::create('notification_types', function (Blueprint $table) {
                $table->id();
                $table->string('key')->unique();
                $table->string('label');
                $table->timestamps();
            });
        }

        DB::table('notification_types')->insert([
            ['key' => 'news', 'label' => 'News', 'created_at' => now(), 'updated_at' => now()],
            ['key' => 'podcasts', 'label' => 'Podcasts', 'created_at' => now(), 'updated_at' => now()],
            ['key' => 'alerts', 'label' => 'Alerts', 'created_at' => now(), 'updated_at' => now()],
            ['key' => 'comments', 'label' => 'Comments', 'created_at' => now(), 'updated_at' => now()],
            ['key' => 'announcements', 'label' => 'Announcements', 'created_at' => now(), 'updated_at' => now()],

        ]);

        if (!Schema::hasTable('notification_preferences')) {
            Schema::create('notification_preferences', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
                $table->foreignId('notification_type_id')->references('id')->on('notification_types')->onDelete('cascade');
                $table->boolean('status')->default(true);
                $table->timestamps();
                $table->unique(['user_id', 'notification_type_id']);
            });
        }

        if (!Schema::hasColumn('tbl_users', 'slug')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->string('slug')->nullable()->unique()->after('name');
            });
            // Backfill existing approved authors so lookups by slug work retroactively.
            User::where('is_author', 1)->whereNull('slug')->each(function (User $user) {
                $user->ensureSlug();
            });
        }

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('tbl_settings')->whereIn('type', ['news_buzz_mode', 'podcast_mode', 'ad_after_page_clicks', 'youtube_api_key'])->delete();
        Schema::dropIfExists('alerts');
        Schema::dropIfExists('podcast_follows');
        Schema::dropIfExists('episode_play_history');
        Schema::dropIfExists('episode_bookmarks');
        Schema::dropIfExists('podcast_episodes');
        Schema::dropIfExists('podcasts');
        Schema::dropIfExists('notification_preferences');
        Schema::dropIfExists('notification_types');
        if (Schema::hasColumn('tbl_authors', 'auto_approve')) {
            Schema::table('tbl_authors', function (Blueprint $table) {
                $table->dropColumn('auto_approve');
            });
        }
        if (Schema::hasColumn('video_shorts', 'video_type')) {
            Schema::table('video_shorts', function (Blueprint $table) {
                $table->dropColumn('video_type');
            });
        }

        if (Schema::hasColumn('tbl_users', 'slug')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropColumn('slug');
            });
        }
    }
};
