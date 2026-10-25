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
        if(Schema::hasTable('tbl_ad_spaces')) {

            Schema::table('tbl_ad_spaces', function (Blueprint $table) {
                // update column ad_space to nullable
                $table->string('ad_space')->nullable()->change();

                $table->string('page')->nullable()->comment('page or screen names');
                $table->enum('platform', ['app', 'web'])->default('web')->nullable();
                $table->string('placement')->nullable();
                $table->string('ad_type')->nullable()->default('external_link');
                $table->unsignedInteger('duration_days')->default(1);
                $table->date('start_date')->nullable();
                $table->date('end_date')->nullable();

                // drop date column
                if (Schema::hasColumn('tbl_ad_spaces', 'date')) {
                    $table->dropColumn('date');
                }
            });

            // news_details_top
            DB::table('tbl_ad_spaces')
                ->where('ad_space', 'news_details_top')
                ->whereNull('page')
                ->update([
                    'page' => 'news_details',
                    'placement' => 'news_details_top',
                    'platform' => 'web',
                ]);

            // news_details_bottom
            DB::table('tbl_ad_spaces')
                ->where('ad_space', 'news_details_bottom')
                ->whereNull('page')
                ->update([
                    'page' => 'news_details',
                    'placement' => 'news_details_bottom',
                    'platform' => 'web',
                ]);

            // featured sections
            DB::table('tbl_ad_spaces')
                ->where('ad_space', 'LIKE', 'featuredsection-%')
                ->whereNull('page')
                ->update([
                    'page' => 'featured_section',
                    'platform' => 'web',
                ]);

            // placement = ad_space
            DB::table('tbl_ad_spaces')
                ->where('ad_space', 'LIKE', 'featuredsection-%')
                ->whereNull('placement')
                ->chunkById(100, function ($rows) {
                    foreach ($rows as $row) {
                        DB::table('tbl_ad_spaces')
                            ->where('id', $row->id)
                            ->update([
                                'placement' => $row->ad_space,
                            ]);
                    }
                });

            // external links
            DB::table('tbl_ad_spaces')
                ->whereNotNull('ad_url')
                ->whereNull('ad_type')
                ->update([
                    'ad_type' => 'external_link',
                ]);

            Schema::table('tbl_ad_spaces', function (Blueprint $table) {
                $table->dropColumn('ad_space');
            });
        }
        if (!Schema::hasTable('video_shorts')) {
            Schema::create('video_shorts', function (Blueprint $table) {

                $table->id();
                $table->unsignedBigInteger('language_id')->nullable();
                $table->unsignedBigInteger('category_id')->nullable();
                
                $table->foreign('language_id')
                      ->references('id')
                      ->on('tbl_languages')
                      ->onDelete('cascade');
                
                $table->foreign('category_id')
                      ->references('id')
                      ->on('tbl_category')
                      ->onDelete('cascade');
                      
                $table->string('title');
                $table->string('slug')->unique();
                $table->string('video_url');
                $table->longText('description')->nullable();
                $table->timestamp('published_date')->nullable();
                $table->boolean('status')->default(true);
                $table->unsignedBigInteger('views_count')->default(0);
                $table->unsignedBigInteger('shares_count')->default(0);
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('video_shorts_likes')) {

        Schema::create('video_shorts_likes', function (Blueprint $table) {

            $table->id();
            $table->unsignedBigInteger('video_shorts_id');
            $table->unsignedBigInteger('user_id');
        
            $table->foreign('video_shorts_id')
                  ->references('id')
                  ->on('video_shorts')
                  ->onDelete('cascade');
        
            $table->foreign('user_id')
                  ->references('id')
                  ->on('tbl_users')
                  ->onDelete('cascade');
                  
            $table->boolean('like')->default(false);
            $table->boolean('dislike')->default(false);
            $table->timestamps();
            $table->unique(['video_shorts_id', 'user_id']);

        });
        }

        if (!Schema::hasTable('video_shorts_comments')) {

        Schema::create('video_shorts_comments', function (Blueprint $table) {

            $table->id();
            $table->unsignedBigInteger('video_shorts_id');
            $table->unsignedBigInteger('user_id');
        
            $table->foreign('video_shorts_id')
                  ->references('id')
                  ->on('video_shorts')
                  ->onDelete('cascade');
        
            $table->foreign('user_id')
                  ->references('id')
                  ->on('tbl_users')
                  ->onDelete('cascade');
                  
            $table->text('comment');
            $table->boolean('status')->default(true);
            $table->timestamps();

        });
        }
        DB::table('tbl_settings')->insert([
                'type' => 'auth_short_video_views',
                'message' => '0',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_ad_spaces', function (Blueprint $table) {
            $table->string('ad_space')->nullable(false);
            $table->date('date')->nullable();
            $table->dropColumn(['page', 'platform', 'placement', 'ad_type', 'duration_days', 'start_date', 'end_date']);
        });

        // restore ad_space from placement
        DB::table('tbl_ad_spaces')
            ->whereNotNull('placement')
            ->update([
                'ad_space' => DB::raw('placement'),
            ]);

        DB::table('tbl_ad_spaces')->update([
            'page' => null,
            'placement' => null,
        ]);
        
        DB::table('tbl_settings')->where('type', 'auth_short_video_views')->delete();
        Schema::dropIfExists('video_shorts_comments');
        Schema::dropIfExists('video_shorts_likes');
        Schema::dropIfExists('video_shorts');

    }
};
