<?php

namespace App\Http\Controllers\Api;

use App\Models\AdSpaces;
use App\Models\Category;
use App\Models\Language;
use App\Models\Location;
use App\Models\Pages;
use App\Models\SendNotification;
use App\Models\Settings;
use App\Models\SocialMedia;
use App\Models\SubCategory;
use App\Models\Tag;
use App\Models\WebSeoPages;
use App\Models\WebSetting;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SettingsApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Global Settings
    // -------------------------------------------------------------------------

    public function getSettings()
    {
        try {
            $types = [
                'system_timezone', 'category_mode', 'subcategory_mode', 'breaking_news_mode',
                'live_streaming_mode', 'rss_feed_mode', 'comments_mode', 'weather_mode',
                'location_news_mode', 'nearest_location_measure', 'video_type_preference',
                'maintenance_mode', 'mobile_login_mode', 'country_code',
                'auto_delete_expire_news_mode', 'app_version', 'appstore_app_id',
                'shareapp_text', 'ads_type', 'in_app_ads_mode', 'ios_in_app_ads_mode',
                'ios_ads_type', 'google_rewarded_video_id', 'google_interstitial_id',
                'google_banner_id', 'google_native_unit_id', 'ios_google_rewarded_video_id',
                'ios_google_interstitial_id', 'ios_google_banner_id', 'ios_google_native_unit_id',
                'unity_rewarded_video_id', 'unity_interstitial_id', 'unity_banner_id',
                'android_game_id', 'ios_unity_rewarded_video_id', 'ios_unity_interstitial_id',
                'ios_unity_banner_id', 'ios_game_id', 'force_update_app_mode',
                'android_app_version', 'ios_app_version',
                'google_app_open_unit_id', 'ios_google_app_open_unit_id','auth_short_video_views','views_auth_mode',
                'podcast_mode', 'e_news_mode', 'news_buzz_mode','ad_after_page_clicks',
            ];

            $res = Settings::whereIn('type', $types)->pluck('message', 'type')->toArray();

            if (empty($res)) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $setting          = Settings::where('type', 'default_language')->pluck('message')->first();
            $default_lang     = $setting ?? 0;
            $language         = Language::select('id', 'language', 'code', 'status', 'isRTL', 'image', 'display_name');
            $default_language = $default_lang == 0
                ? $language->clone()->where('code', 'en')->first()
                : $language->clone()->where('id', $default_lang)->first();

            $res['default_language'] = $default_language;

            $web_setting = WebSetting::pluck('message', 'type')->toArray();
            if (!empty($web_setting)) {
                foreach (['light_header_logo', 'light_footer_logo'] as $key) {
                    $web_setting[$key] = asset('storage/' . ($web_setting[$key] ?? ''));
                }
                foreach (['light_placeholder_image', 'dark_header_logo', 'dark_footer_logo', 'dark_placeholder_image', 'favicon_icon'] as $key) {
                    $web_setting[$key] = isset($web_setting[$key]) ? asset('storage/' . $web_setting[$key]) : '';
                }
            }
            $res['web_setting']  = $web_setting;
            $res['social_media'] = SocialMedia::select('id', 'image', 'link')->get();

            return ResponseService::successResponse(__('Data fetched successfully'), $res);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getSettings');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getGeminiApiKey()
    {
        try {
            if (!Auth::check() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('You are not an author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'), null);
            }

            $key = Settings::where('type', 'google_gemini_api_key')->value('message') ?? '';

            if (empty($key)) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'google_gemini_api_key' => base64_encode($key),
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getGeminiApiKey');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Categories & Tags & Locations
    // -------------------------------------------------------------------------

    public function getCategory(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'     => 'nullable|string|max:255',
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $languageId = $this->resolveLanguageId($request);
            $offset     = $request->offset ?? 0;
            $limit      = $request->limit ?? 10;
            $orderBy    = $request->order_by ?? 'row_order';
            $sortBy     = $request->sort_by ?? 'ASC';

            $query = Category::with('sub_categories')
                ->where('language_id', $languageId)
                ->when($request->slug, fn($q) => $q->where('slug', $request->slug));

            $total = $query->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse('No Data Found', null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $categories = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $categories,
            ]);
        } catch (Exception $e) {
            return ResponseService::errorResponse($e->getMessage(), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getSubcategoryByCategory(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'category_id'   => 'required|numeric|exists:tbl_category,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $language_id = $this->resolveLanguageId($request);

            $validator = Validator::make($request->all(), [
                'category_id' => ['required', 'numeric'],
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first(), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), $validator->errors());
            }

            $res = SubCategory::with('category:id,category_name')
                ->where('language_id', $language_id)
                ->where('category_id', $request->category_id)
                ->orderBy('row_order', 'ASC')
                ->get();

            if ($res->isEmpty()) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            return ResponseService::successResponse(__('Data fetched successfully'), $res);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getSubcategoryByCategory');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getTag(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'     => 'nullable|string|max:255',
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $languageId = $this->resolveLanguageId($request);
            $offset     = $request->offset ?? 0;
            $limit      = $request->limit ?? 10;
            $orderBy    = $request->order_by ?? 'id';
            $sortBy     = $request->sort_by ?? 'DESC';

            $query = Tag::where('language_id', $languageId)
                ->when($request->filled('slug'), fn($q) => $q->where('slug', $request->slug));

            $total = $query->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $tags = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $tags,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getTag');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getLocation(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $offset  = $request->offset ?? 0;
            $limit   = $request->limit ?? 10;
            $orderBy = $request->order_by ?? 'id';
            $sortBy  = $request->sort_by ?? 'DESC';

            $total = Location::count('id');
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $data = Location::select('id', 'location_name', 'latitude', 'longitude')
                ->safeOrder($orderBy, $sortBy)
                ->skip($offset)->take($limit)
                ->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $data,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getLocation');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Pages
    // -------------------------------------------------------------------------

    public function getPages(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'     => 'nullable|string|max:255',
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $languageId = $this->resolveLanguageId($request);
            $offset     = $request->offset ?? 0;
            $limit      = $request->limit ?? 10;
            $orderBy    = $request->order_by ?? 'id';
            $sortBy     = $request->sort_by ?? 'DESC';

            $query = Pages::where('language_id', $languageId)->where('status', 1);
            if ($request->filled('slug')) {
                $query->where('slug', $request->slug);
            }

            $total = $query->clone()->count();
            if ($total == 0) {
                $defaultLangId = Settings::where('type', 'default_language')->value('message');

                $query = Pages::where('language_id', $defaultLangId)
                    ->where('status', 1);

                if ($request->filled('slug')) {
                    $query->where('slug', $request->slug);
                }

                $total = $query->count();

                $pages = $query
                    ->safeOrder($orderBy, $sortBy)
                    ->skip($offset)
                    ->take($limit)
                    ->get();

                return ResponseService::successResponse(__('Data fetched successfully'), [
                    'total' => $total,
                    'data'  => $pages,
                ]);
            }

            $pages = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $pages,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getPages');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getPolicyPages(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $languageId = $this->resolveLanguageId($request);

            $pages = Pages::select('id', 'language_id', 'title', 'page_content', 'page_type')
                ->whereIn('page_type', ['terms-condition', 'privacy-policy'])
                ->orderByRaw('CASE WHEN language_id = ? THEN 0 ELSE 1 END', [$languageId])
                ->get()
                ->groupBy('page_type');

            $terms_policy   = $pages->get('terms-condition')?->first();
            $privacy_policy = $pages->get('privacy-policy')?->first();

            if ($terms_policy || $privacy_policy) {
                return ResponseService::successResponse(__('Data fetched successfully'), [
                    'terms_policy'   => $terms_policy,
                    'privacy_policy' => $privacy_policy,
                ]);
            }

            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getPolicyPages');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Web SEO Pages & Notifications
    // -------------------------------------------------------------------------

    public function getWebSeoPages(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'type'     => 'nullable|string|max:255',
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $language_id = $this->resolveLanguageId($request);
            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;
            $orderBy     = $request->order_by ?? 'id';
            $sortBy      = $request->sort_by ?? 'DESC';

            $query = WebSeoPages::where('language_id', $language_id);
            if ($request->filled('type')) {
                $query->where('page_type', $request->type);
            }

            $total = $query->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $webSeoPages = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $webSeoPages,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getWebSeoPages');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getNotification(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'type'     => 'nullable|in:category',
                'offset'   => 'nullable|integer|min:0',
                'limit'    => 'nullable|integer|min:1|max:100',
                'order_by' => 'nullable|string',
                'sort_by'  => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $language_id = $this->resolveLanguageId($request);
            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;
            $orderBy     = $request->order_by ?? 'id';
            $sortBy      = $request->sort_by ?? 'DESC';
            $type        = $request->filled('type') ? $request->type : null;

            $query = SendNotification::with([
                'news'     => fn($q) => $q->select('id', 'title', 'slug', 'status'),
                'category:id,category_name',
            ])
                ->where('language_id', $language_id)
                ->when($type && $type === 'category', function ($query) {
                    $query->whereHas('news', fn($q) => $q->where('status', 1));
                });

            $total = $query->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $notifications = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $notifications,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getNotification');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Ad Spaces
    // -------------------------------------------------------------------------

    public function getAdSpaceNewsDetails(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'page' => 'required|in:' . implode(',', AdSpaces::getPagesForPlatform($request->platform ?? '')),
                'platform' => 'required|in:app,web',
                'featured_section_ids' => ['required_if:page,featured_section', 'regex:/^\d+(,\d+)*$/'],
            ]);
            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first(), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), null);
            }

            $languageId = $this->resolveLanguageId($request);
            $platform   = $request->platform;
            $page   = $request->page;
            $featuredSectionIds = $request->filled('featured_section_ids')
                ? array_filter(array_map('intval', explode(',', $request->featured_section_ids)))
                : [];

            $placements = AdSpaces::getPlacements($page, $platform);
            $banners = collect();

            foreach ($placements as $placement) {
                if ($page === 'featured_section') {
                    foreach ($featuredSectionIds as $fsId) {
                        $banner = AdSpaces::where('language_id', $languageId)
                            ->where('page', $page)
                            ->where('platform', $platform)
                            ->where('placement', $placement)
                            ->where('ad_featured_section_id', $fsId)
                            ->activeBanners()
                            ->inRandomOrder()
                            ->first();
                        if ($banner) {
                            $banners->push($banner);
                        }
                    }
                } else {
                    $banner = AdSpaces::where('language_id', $languageId)
                        ->where('page', $page)
                        ->where('platform', $platform)
                        ->where('placement', $placement)
                        ->activeBanners()
                        ->inRandomOrder()
                        ->first();
                    if ($banner) {
                        $banners->push($banner);
                    }
                }
            }

            if ($banners->isEmpty()) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            return ResponseService::successResponse(__('Data fetched successfully'), $banners);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getAdSpaceNewsDetails');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }
}
