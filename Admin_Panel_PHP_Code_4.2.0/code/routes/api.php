<?php

use App\Http\Controllers\AlertsController;
use App\Http\Controllers\Api\VideoShortsApiController;
use App\Http\Controllers\Api\BookmarkLikeApiController;
use App\Http\Controllers\Api\CommentApiController;
use App\Http\Controllers\Api\ContentApiController;
use App\Http\Controllers\Api\MediaApiController;
use App\Http\Controllers\Api\NewsApiController;
use App\Http\Controllers\Api\PodcastApiController;
use App\Http\Controllers\Api\PodcastEpisodeApiController;
use App\Http\Controllers\Api\RssApiController;
use App\Http\Controllers\Api\SettingsApiController;
use App\Http\Controllers\Api\UserApiController;
use App\Http\Controllers\Api\SurveyApiController;
use App\Http\Controllers\Api\LanguageApiController;
use App\Http\Controllers\Api\MarketAlertsApiController;
use App\Http\Controllers\NotificationPreferenceApiController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// ---- Settings, languages, categories, locations, pages, notifications ----
Route::post('get_settings',                [SettingsApiController::class, 'getSettings']);
Route::post('get_pages',                   [SettingsApiController::class, 'getPages']);
Route::post('get_policy_pages',            [SettingsApiController::class, 'getPolicyPages']);
Route::post('get_location',                [SettingsApiController::class, 'getLocation']);
Route::post('get_category',                [SettingsApiController::class, 'getCategory']);
Route::post('get_subcategory_by_category', [SettingsApiController::class, 'getSubcategoryByCategory']);
Route::post('get_tag',                     [SettingsApiController::class, 'getTag']);
Route::post('get_notification',            [SettingsApiController::class, 'getNotification']);
Route::post('get_web_seo_pages',           [SettingsApiController::class, 'getWebSeoPages']);
Route::post('get_ad_space_news_details',   [SettingsApiController::class, 'getAdSpaceNewsDetails']);

// ---- Languages ----
Route::post('get_languages_list',          [LanguageApiController::class, 'getLanguagesList']);
Route::post('get_language_json_data',      [LanguageApiController::class, 'getLanguageJsonData']);

// ---- Media ----
Route::post('get_live_streaming', [MediaApiController::class, 'getLiveStreaming']);
// ---- RSS ----
Route::post('get_rss_feed',       [RssApiController::class, 'getRssFeed']);

// ---- Market alerts ----
Route::post('get_market_alerts',  [MarketAlertsApiController::class, 'getMarketAlerts']);

// ---- Auth-optional routes ----
Route::group(['middleware' => ['auth.optional']], function () {
    Route::post('set_news_view',         [ContentApiController::class, 'setNewsView']);
    Route::post('set_breaking_news_view',[ContentApiController::class, 'setBreakingNewsView']);
    Route::post('get_featured_sections', [ContentApiController::class, 'getFeaturedSections']);
    Route::post('get_breaking_news',     [ContentApiController::class, 'getBreakingNews']);

    Route::post('get_news',        [NewsApiController::class, 'getNews']);
    Route::post('get_videos', [MediaApiController::class, 'getVideos']);

    Route::post('get_comment_by_news', [CommentApiController::class, 'getCommentByNews']);

    // Author news (public)
    Route::post('get_authors_news', [NewsApiController::class, 'getAuthorsNews']);
    // Get short/reel videos
    Route::post('get_video_shorts',  [VideoShortsApiController::class, 'getVideoShorts']);
    Route::post('set_videoshort_view', [VideoShortsApiController::class, 'setVideoShortsViewCount']);

    // Podcasts (optional-auth: attaches is_followed / listening_history when a user token is present)
    Route::post('get_podcast', [PodcastApiController::class, 'getPodcast']);
    Route::post('get_episode', [PodcastEpisodeApiController::class, 'getEpisode']);
    // Route::get('alerts/search/{query}', [AlertsController::class, 'searchCompany'])->name('alerts.search');
});



// ---- Public user/device endpoints ----
Route::post('user_signup',    [UserApiController::class, 'userSignup']);
Route::post('register_token', [UserApiController::class, 'registerToken']);

Route::post('check_slug_availability', [NewsApiController::class, 'checkSlugAvailability']);

Route::post('get_short_news', [NewsApiController::class, 'getShortNews']);

// ---- Authenticated routes ----
Route::group(['middleware' => ['auth:sanctum', 'sanitize']], function () {

    // News
    Route::post('delete_news_images', [NewsApiController::class, 'deleteNewsImages']);
    Route::post('delete_news',        [NewsApiController::class, 'deleteNews']);
    Route::post('set_news',           [NewsApiController::class, 'setNews']);
    Route::post('get_user_drafted_news', [NewsApiController::class, 'getUserDraftedNews']);
    Route::post('create_tag',         [NewsApiController::class, 'createTag']);

    // Survey / Questions
    Route::post('get_question_result', [SurveyApiController::class, 'getQuestionResult']);
    Route::post('set_question_result', [SurveyApiController::class, 'setQuestionResult']);
    Route::post('get_question',        [SurveyApiController::class, 'getQuestion']);

    // Bookmarks & Likes
    Route::post('get_bookmark',    [BookmarkLikeApiController::class, 'getBookmark']);
    Route::post('set_bookmark',    [BookmarkLikeApiController::class, 'setBookmark']);
    Route::post('get_like',        [BookmarkLikeApiController::class, 'getLike']);
    Route::post('set_like_dislike',[BookmarkLikeApiController::class, 'setLikeDislike']);

    // Comments
    Route::post('set_flag',                [CommentApiController::class, 'setFlag']);
    Route::post('set_comment_like_dislike',[CommentApiController::class, 'setCommentLikeDislike']);
    Route::post('delete_comment',          [CommentApiController::class, 'deleteComment']);
    Route::post('set_comment',             [CommentApiController::class, 'setComment']);

    // User
    Route::post('get_gemini_api_key', [SettingsApiController::class, 'getGeminiApiKey']);
    Route::post('delete_user_notification', [UserApiController::class, 'deleteUserNotification']);
    Route::post('get_user_notification',    [UserApiController::class, 'getUserNotification']);
    Route::post('set_user_category',        [UserApiController::class, 'setUserCategory']);
    Route::post('delete_user',              [UserApiController::class, 'deleteUser']);
    Route::post('update_profile',           [UserApiController::class, 'updateProfile']);
    Route::post('get_user_by_id',           [UserApiController::class, 'getUserById']);
    Route::post('become_author',            [UserApiController::class, 'becomeAuthor']);
    Route::post('update_author_profile',    [UserApiController::class, 'updateAuthorProfile']);

    // ---- Videoshorts ----
    Route::post('set_videoshort_like_dislike', [VideoShortsApiController::class, 'setVideoshortLikeDislike']);
    Route::post('set_videoshort_comment', [VideoShortsApiController::class, 'setVideoShortsComment']);

    // Notification Preferences
    Route::post('get_notification_preference', [NotificationPreferenceApiController::class, 'getPreference']);
    Route::post('set_notification_preference', [NotificationPreferenceApiController::class, 'updatePreference']);

    // ---- Podcasts (auth required) ----
    Route::post('follow_podcast', [PodcastApiController::class, 'toggleFollowPodcast']);
    Route::post('bookmark_episode', [PodcastEpisodeApiController::class, 'toggleBookmarkEpisode']);
    Route::post('update_episode_listening_history', [PodcastEpisodeApiController::class, 'updateListeningHistory']);

    // Author (own podcast/episode) CRUD
    Route::post('my_podcasts', [PodcastApiController::class, 'myPodcasts']);
    Route::post('my_episodes', [PodcastEpisodeApiController::class, 'myEpisodes']);
    Route::post('save_podcast', [PodcastApiController::class, 'savePodcast']);
    Route::post('save_episode', [PodcastEpisodeApiController::class, 'saveEpisode']);
    Route::post('delete_podcast', [PodcastApiController::class, 'deletePodcast']);
    Route::post('delete_episode', [PodcastEpisodeApiController::class, 'deleteEpisode']);
});

// ---- Videoshorts public share count ----
Route::post('set_videoshort_shares', [VideoShortsApiController::class, 'setVideoShortShareCount']);

// ---- Videoshorts public get comments----
Route::post('get_videoshort_comment', [VideoShortsApiController::class, 'getVideoShortsComment']);

// ---- E-News ----
Route::post('get_e_news', [ContentApiController::class, 'getENews']);
// ---- Feed items from RSS source ----
Route::post('get_feed_items', [ContentApiController::class, 'getFeedItems']);
