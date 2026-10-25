<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/
use App\Http\Controllers\AdSpacesController;
use App\Http\Controllers\AlertsController;
use App\Http\Controllers\AppUserController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AuthorController;
use App\Http\Controllers\BreakingNewsController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\CommentsController;
use App\Http\Controllers\Controller;
use App\Http\Controllers\EnewsController;
use App\Http\Controllers\FeaturedSectionsController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\InstallerController;
use App\Http\Controllers\LanguageController;
use App\Http\Controllers\LiveStreamingController;
use App\Http\Controllers\LocationController;
use App\Http\Controllers\NewsController;
use App\Http\Controllers\PagesController;
use App\Http\Controllers\PodcastController;
use App\Http\Controllers\RSSController;
use App\Http\Controllers\SendNotificationController;
use App\Http\Controllers\SEOController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\SocialMediaController;
use App\Http\Controllers\SubCategoryController;
use App\Http\Controllers\SurveyController;
use App\Http\Controllers\TagController;
use App\Http\Controllers\UpdaterController;
use App\Http\Controllers\StaffController;
use App\Http\Controllers\RoleController;
use App\Http\Controllers\VideoShortsController;
use App\Models\Podcasts;
use App\Models\Settings;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

// Maintenance routes live inside auth:admin group below (protected, nothing removed).


Route::group(['prefix' => 'install'], static function () {
    Route::controller(InstallerController::class)->group(function () {
        Route::get('purchase-code', 'purchaseCodeIndex')->name('install.purchase-code.index');
        Route::post('purchase-code', 'checkPurchaseCode')->name('install.purchase-code.post');
    });
});

Route::get('settings/{type}', [SettingsController::class, 'view_data']);

// Route::get('/', [HomeController::class, 'index'])->name('home');

Route::group(['middleware' => 'checkNotLoggedIn'], function () {
    Route::controller(AuthController::class)->group(function () {
        Route::get('login', 'login')->name('login');
        Route::post('authenticate', 'authenticate')->name('authenticate');
        Route::post('check_email', 'check_email')->name('check_email');
        Route::get('reset_password', 'reset_password')->name('reset_password');
        Route::post('update_password', 'update_password')->name('update_password');
    });
});

Route::group(['middleware' => ['auth:admin', 'checkLogin', 'sanitize']], function () {
    Route::group(['middleware' => 'language'], function () {
        Route::get('logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('home', [HomeController::class, 'index'])->name('home');

        Route::post('get-slug', [HomeController::class, 'getSlug'])->name('get-slug');
        Route::post('upload_img', [HomeController::class, 'upload_img'])->name('upload_img');
        // Route::post('generate-ai-content', [GeminiController::class, 'generateAIContent'])->name('generate-ai-content');
        Route::post('generate-all-meta-fields', [GeminiController::class, 'generateAllMetaFields'])->name('generate-all-meta-fields');


        // Languages
        Route::get('language_list', [LanguageController::class, 'show'])->name('languageList');
        Route::post('store_default_language', [LanguageController::class, 'store_default_language']);
        Route::get('download-app-json', [LanguageController::class, 'downloadAppJson']);
        Route::get('download-web-json', [LanguageController::class, 'downloadWebJson']);
        Route::get('download-panel-json/{lang}', [LanguageController::class, 'downloadPanelJson']);
        Route::get('set-language/{lang}', [LanguageController::class, 'set_language']);
        Route::get('languageedit/{id}/{type}', [LanguageController::class, 'editLanguage'])->name('languageedit');
        Route::resource('language', LanguageController::class, ['except' => ['create', 'edit']]);


        //category
        Route::resource('category', CategoryController::class, ['except' => ['create', 'edit']]);
        Route::get('category_list', [CategoryController::class, 'show'])->name('categoryList');
        Route::post('update_category_order', [CategoryController::class, 'update_order'])->name('update_category_order');
        Route::post('get_category_by_language', [CategoryController::class, 'get_category_by_language'])->name('get_category_by_language');

        // sub_category
        Route::resource('sub_category', SubCategoryController::class, ['except' => ['create', 'edit']]);
        Route::get('sub_category_list', [SubCategoryController::class, 'show'])->name('subcategoryList');
        Route::post('get_subcategory_by_category', [SubCategoryController::class, 'get_subcategory_by_category'])->name('get_subcategory_by_category');
        Route::post('update_subcategory_order', [SubCategoryController::class, 'update_order'])->name('update_subcategory_order');

        // Tag
        Route::resource('tag', TagController::class, ['except' => ['create', 'edit']]);
        Route::get('tag_list', [TagController::class, 'show'])->name('tagList');
        Route::post('get_tag_by_language', [TagController::class, 'get_tag_by_language'])->name('get_tag_by_language');
         Route::post('tag_bulk_delete', [TagController::class, 'tagBulkDelete'])->name('tag_bulk_delete');

        //  Live Streaming
        Route::resource('live_streaming', LiveStreamingController::class, ['except' => ['create', 'edit']]);
        Route::get('live_streaming_list', [LiveStreamingController::class, 'show'])->name('liveStreamingList');

        // Location
        Route::resource('location', LocationController::class, ['except' => ['create', 'edit']]);
        Route::get('location_list', [LocationController::class, 'show'])->name('locationList');

        // News
        Route::resource('news', NewsController::class, ['except' => ['create', 'edit']]);
        Route::controller(NewsController::class)->group(function () {
            Route::get('news_list', 'show')->name('newsList');
            Route::put('news_update_description', 'update_description')->name('news_update_description');
            Route::post('clone_news', 'clone_news')->name('clone_news');
            Route::get('news-image/{id}', 'newsImage')->name('newsImage');
            Route::get('news-image-list', 'showImage')->name('news-image-list');
            Route::post('store-image', 'storeImage')->name('store-image');
            Route::delete('deleteImage/{id}', 'deleteImage')->name('deleteImage');
            Route::post('get_news_by_category', 'get_news_by_category')->name('get_news_by_category');
            Route::post('get_news_by_subcategory', 'get_news_by_subcategory')->name('get_news_by_subcategory');
            Route::post('bulk_news_delete', 'bulkNewsDelete')->name('bulk_news_delete');
        });

        // FeaturedSections
        Route::resource('featured_sections', FeaturedSectionsController::class, ['except' => ['create', 'edit']]);
        Route::controller(FeaturedSectionsController::class)->group(function () {
            Route::get('featured_sections_list', 'show')->name('featuredSectionList');
            Route::post('get_categories_tree', 'get_categories_tree')->name('get_categories_tree');
            Route::post('get_custom_news', 'getCustomNews')->name('get_custom_news');
            Route::post('update_featured_sections_order', 'update_order')->name('update_featured_sections_order');
            Route::post('get_feature_section_by_language', 'get_feature_section_by_language')->name('get_feature_section_by_language');
            Route::get('get_author_list', 'getAuthorList')->name('get_author_list');
        });

        // Breaking_newss
        Route::resource('breaking_news', BreakingNewsController::class, ['except' => ['create', 'edit']]);
        Route::get('breaking_news_list', [BreakingNewsController::class, 'show'])->name('breakingNewsList');
        Route::post('bulk_breaking_news_delete', [BreakingNewsController::class, 'bulkBreakingNewsDelete'])->name('bulk_breaking_news_delete');

        Route::resource('rss', RSSController::class, ['except' => ['create', 'edit']]);
        Route::get('rss_list', [RSSController::class, 'show'])->name('rssList');
        Route::post('bulk_rss_delete', [RSSController::class, 'bulkDeleteRss'])->name('bulk_rss_delete');
        Route::get('rss/{id}/feed-items', [RSSController::class, 'feedItems'])->name('rssFeedItems');
        Route::get('rss/{id}/feed-items-list', [RSSController::class, 'feedItemsList'])->name('rssFeedItemsList');
        Route::delete('feed-items/{id}', [RSSController::class, 'deleteFeedItem'])->name('deleteFeedItem');
        Route::post('bulk_feed_items_delete', [RSSController::class, 'bulkDeleteFeedItems'])->name('bulkDeleteFeedItems');
        Route::get('rss/{id}/crawlfeed', [RSSController::class, 'crawlFeed'])->name('rssCrawl');

        // Page
        Route::resource('pages', PagesController::class, ['except' => ['create', 'edit']]);
        Route::get('pages_list', [PagesController::class, 'show'])->name('pagesList');

        // AdSpaces
        Route::resource('ad_spaces', AdSpacesController::class, ['except' => ['create', 'edit']]);
        Route::get('ad_spaces_list', [AdSpacesController::class, 'show'])->name('adSpacesList');
        Route::post('get_featured_sections_by_language', [AdSpacesController::class, 'getFeaturedSectionsByLanguage'])->name('get_featured_sections_by_language');
        Route::post('bulk_ad_spaces_delete', [AdSpacesController::class, 'bulkAdSpacesDelete'])->name('bulk_ad_spaces_delete');

        // User List
        Route::resource('app_users', AppUserController::class, ['only' => ['index', 'show', 'update']]);
        Route::get('app_users_list', [AppUserController::class, 'show'])->name('usersList');

        // User Role
        // Route::resource('app_users_roles', AppUserRolesController::class);
        // Route::get('app_users_roles_list', [AppUserRolesController::class, 'show'])->name('userRoleList');

        Route::resource('comments', CommentsController::class, ['only' => ['index', 'show', 'destroy']]);
        Route::controller(CommentsController::class)->group(function () {
            Route::get('comments_list', 'show')->name('commentsList');
            Route::delete('comments-delete/{id}', 'comment_delete')->name('comments-delete');
            Route::get('comments_flag', 'index1')->name('comments_flag');
            Route::get('comments_flag_list', 'comment_flag')->name('commentsFlagsList');
            Route::post('bulk_comment_delete', 'bulkCommentDelete')->name('bulk_comment_delete');
            Route::post('bulk_commentflag_delete', 'bulkCommentflagDelete')->name('bulk_commentflag_delete');
        });
        // Comments

        // Notifications
        Route::resource('notifications', SendNotificationController::class, ['only' => ['index', 'store', 'show', 'destroy']]);
        Route::get('notifications_list', [SendNotificationController::class, 'show'])->name('notificationList');
        Route::post('bulk_delete_sendnotification', [SendNotificationController::class, 'bulkDeleteSendnotification'])->name('bulk_delete_sendnotification');

        // survey
        Route::resource('survey', SurveyController::class, ['except' => ['create', 'edit']]);
        Route::get('survey_question_list', [SurveyController::class, 'show'])->name('surveyQuestionList');
        Route::get('survey_options/{id}', [SurveyController::class, 'get_survey_option']);
        Route::get('survey_options_list', [SurveyController::class, 'survey_options_show'])->name('surveyOptionsList');
        Route::post('survey_options_store', [SurveyController::class, 'store_option'])->name('survey-options-store');
        Route::put('survey_options_edit', [SurveyController::class, 'update_option'])->name('survey-options-edit');
        Route::delete('survey_options_delete/{id}', [SurveyController::class, 'delete_option'])->name('survey-options-delete');
        Route::post('bulk_survey_delete', [SurveyController::class, 'bulkSurveyDelete'])->name('bulk_survey_delete');

        // settings
        Route::controller(SettingsController::class)->group(function () {
            Route::get('system-settings', 'indexSetting')->name('system-settings');
            Route::get('general-settings', 'indexGeneralSetting')->name('general-settings');
            Route::post('general-settings', 'storeGeneralSetting')->name('general-settings.store');
            Route::post('import-dummy-data', 'importDummyData')->name('import.dummy.data');
            Route::post('storage-link', 'createStorageLink')->name('storage.link');
            Route::post('storage-unlink', 'removeStorageLink')->name('storage.unlink');
            Route::get('panel-settings', 'indexPanelSetting')->name('panel-settings');
            Route::post('panel-settings', 'storePanelSetting')->name('panel-settings.store');
            Route::get('web-settings', 'indexWebSetting')->name('web-settings');
            Route::post('web-settings', 'storeWebSetting')->name('web-settings.store');
            Route::get('app-settings', 'indexAppSetting')->name('app-settings');
            Route::post('app-settings', 'storeAppSetting')->name('app-settings.store');
            Route::get('firebase-configuration', 'indexFirebaseSetting')->name('firebase-configuration');
            Route::post('firebase-configuration', 'storeFirebaseSetting')->name('firebase-configuration.store');
        });

        Route::resource('seo-setting', SEOController::class, ['except' => ['create', 'edit']]);
        Route::get('seo-setting-list', [SEOController::class, 'show'])->name('seoSettingList');

        Route::get('edit_profile', [HomeController::class, 'editProfile'])->name('edit-profile');
        Route::post('checkOldPass', [HomeController::class, 'checkOldPass'])->name('checkOldPass');
        Route::post('update-profile', [HomeController::class, 'update_profile'])->name('update-profile');
        // Route::get('database-backup', [HomeController::class, 'database_backup'])->name('database-backup');

        Route::get('system_update', [UpdaterController::class, 'index'])->name('system-update');
        Route::post('system_update_operation', [UpdaterController::class, 'system_update'])->name('system-update-operation');

        //social-media
        Route::resource('social-media', SocialMediaController::class, ['except' => ['create', 'edit']]);
        Route::get('social_media_list', [SocialMediaController::class, 'show'])->name('socialMediaList');
        Route::post('update_social_media_order', [SocialMediaController::class, 'update_order'])->name('update_social_media_order');

        // Staff Management Routes
        Route::resource('staff', StaffController::class);
        Route::get('staff_list', [StaffController::class, 'list'])->name('staff.list');
        Route::post('staff/change-password', [StaffController::class, 'changePassword'])->name('staff.change-password');
        Route::resource('roles', RoleController::class);
        Route::get('roles_list', [RoleController::class, 'list'])->name('roles.list');

        // Author Management Routes
        Route::resource('author', AuthorController::class);
        // Route::resource('author', AuthorController::class, ['except' => ['create', 'edit']]);
        // Route::get('author_list', [AuthorController::class, 'list'])->name('author.list');
        // rss_feeds list for feature section
        Route::get('rss_feeds_list/{category_ids}', [FeaturedSectionsController::class, 'getRssFeedsList'])->name('rss_feeds_list');
        Route::get('categories_list/{language_id}', [FeaturedSectionsController::class, 'getCategoriesList'])->name('get_categories_list');

        Route::post('create_tag', [TagController::class, 'createTag'])->name('create_tag');

        // Route::post('create_tag', [TagController::class, 'createTag'])->name('create_tag');
        Route::post('search_tags', [TagController::class, 'searchTags'])->name('search_tags');


        // eNews
        Route::resource('e-news', EnewsController::class);
        Route::post('bulkDeletEnews', [EnewsController::class,'bulkDeleteEnews'])->name('enews.bulk_delete');

        // Video short
        Route::get('video_shorts_list', [VideoShortsController::class, 'show'])->name('video_shorts.list');
        Route::resource('video_shorts', VideoShortsController::class, ['except' => ['create', 'edit']]);
        Route::post('bulkdelete', [VideoShortsController::class,'bulkVideoshortsDelete'])->name('video_shorts.bulk_delete');
        // Video short likes
        Route::get('video-shorts/{id}/likes', [VideoShortsController::class, 'likes'])->name('video_shorts.likes');
        Route::get('video-shorts/{id}/likes-list', [VideoShortsController::class, 'likesList'])->name('video_shorts.likes_list');
        Route::delete('video-shorts/likes/{id}', [VideoShortsController::class, 'deleteLike'])->name('video_shorts.likes.destroy');
        Route::post('video-shorts/likes/bulk-delete', [VideoShortsController::class, 'bulkDeleteLikes'])->name('video_shorts.likes.bulk_delete');

        // Video short comments
        Route::get('video-shorts/{id}/comments', [VideoShortsController::class, 'comments'])->name('video_shorts.comments');
        Route::get('video-shorts/{id}/comments-list', [VideoShortsController::class, 'commentsList'])->name('video_shorts.comments_list');
        Route::delete('video-shorts/comments/{id}', [VideoShortsController::class, 'deleteComment'])->name('video_shorts.comments.destroy');
        Route::post('video-shorts/comments/bulk-delete', [VideoShortsController::class, 'bulkDeleteComments'])->name('video_shorts.comments.bulk_delete');

        //Podcast
        Route::resource('podcast', PodcastController::class);
        Route::get('podcast/{podcastId}/episodes', [PodcastController::class, 'showEpisode'])->name('podcast.episodes');


        // Podcast episodes routes
        Route::post('podcast/episodes/store/{podcastId}', [PodcastController::class, 'storeEpisode'])->name('podcast.episodes.store');
        Route::delete('podcast/episodes/destroy/{podcastId}/{episodeId}', [PodcastController::class, 'destroyEpisode'])->name('podcast.episodes.destroy');
        Route::put('/podcast/episodes/update/{Id?}', [PodcastController::class, 'updateEpisode'])->name('podcast.episodes.update');
        Route::get('podcast/{podcastId}/episodes-list', [PodcastController::class, 'episodesList'])->name('podcast.episodes.list');
        Route::post('podcast/episodes/bulk-delete/{podcastId}', [PodcastController::class, 'bulkDeleteEpisodes'])->name('podcast.episodes.bulk_delete');

        Route::get('alerts/search/{query}', [AlertsController::class, 'searchCompany'])->name('alerts.search');
        Route::resource('alerts',AlertsController::class);

        // Maintenance / ops routes - protected by auth:admin + checkLogin (no longer public).
        // Full set preserved from public section, nothing removed. Use via admin session only.
        Route::get('clear', function () {
            Artisan::call('optimize:clear');
            return redirect()->back();
        });
        Route::get('feeds-crawl', function () {
            Artisan::call('feeds:crawl');
            return redirect()->back();
        });
        // INSERT RECORD through route direct to DB
        Route::get('insert-record', static function () {
            $user = Settings::create([
                'type' => 'force_update_app_mode',
                'message' => '1'
            ]);
        });
        Route::get('php-version', function () {
            return phpinfo();
        });
        Route::get('storage-link', function () {
            Artisan::call('storage:link');
            return redirect()->back();
        });
        Route::get('seeder', function () {
            Artisan::call('db:seed --class=InstallationSeeder');
            return redirect()->back();
        });
        // uncomment when new permission syn to super admin
        // Route::get('permission-seeder', function () {
        //     Artisan::call('db:seed --class=PermissionSeeder');
        //     return redirect()->back();
        // });
        Route::get('migrate-status', function () {
            Artisan::call('migrate:status');
            return Artisan::output();
        });
        Route::get('migrate', function () {
            Artisan::call('migrate');
            // Artisan::call('db:seed --class=InstallationSeeder');
            return redirect()->back();
        });
        // Route::get('migrate-rollback', function () {
        //     Artisan::call('migrate:rollback', ['--step' => 1]);
        //     return redirect()->back();
        // });
        // Route::get('notification_table', function () {
        //     Artisan::call('migrate --path=database/migrations/2026_07_29_095509_notification_module.php');
        //     return Artisan::output();
        // });
        // Route::get('user_slug_table', function () {
        //     Artisan::call('migrate --path=database/migrations/2026_07_29_161349_add_slug_to_tbl_users_table.php');
        //     return Artisan::output();
        // });
        Route::get('meta_fields_table', function () {
            Artisan::call('migrate --path=database/migrations/2026_07_30_130824_update_podcast_and_episode_table_with_meta_fields.php');
            return Artisan::output();
        });
        Route::get('podcast_dummy_seeder', function () {
            Artisan::call('db:seed --class=PodcastDummySeeder');
            return Artisan::output();
        });
        //feeds:crawl
        // Route::get('feeds_crawl_command', function () {
        //     Artisan::call('feeds:crawl');
        //     echo Artisan::output();
        // });
        Route::get('sync_tokens', function () {
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
            $result = DB::table('tbl_token')
                ->whereNull('user_id')
                ->where('updated_at', '<', now()->subMonths(2))
                ->delete();
            echo $result;
            return redirect()->back();
        });
        Route::get('schedule-run', static function () {
            Artisan::call('schedule:run');
        });
        Route::get('feed-crawl', static function () {
            Artisan::call('feed:crawl');
            Log::info("Feed crawl completed");
            return redirect()->back();
        });
        Route::get('feeds-purge', static function () {
            Artisan::call('feeds:purge');
            Log::info("Feeds purge completed");
            return redirect()->back();
        });
    });
});

/* Non-Authenticated Common Functions */
Route::group(['prefix' => 'common'], static function () {
    Route::get('/js/lang', [Controller::class, 'readLanguageFile'])->name('common.language.read');
});
