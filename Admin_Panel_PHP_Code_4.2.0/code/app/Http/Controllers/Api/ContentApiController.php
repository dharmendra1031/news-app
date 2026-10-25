<?php

namespace App\Http\Controllers\Api;

use App\Models\AdSpaces;
use App\Models\BreakingNews;
use App\Models\BreakingNewsView;
use App\Models\Enews;
use App\Models\Category;
use App\Models\FeaturedSections;
use App\Models\FeedItem;
use App\Models\News_view;
use App\Models\RSS;
use App\Models\Settings;
use App\Models\Tag;
use App\Services\FeaturedSectionService;
use App\Services\ReadTimeService;
use App\Services\ResponseService;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ContentApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Breaking News
    // -------------------------------------------------------------------------

    public function getBreakingNews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'          => 'nullable|string|max:255',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);

            $data = BreakingNews::where('language_id', $languageId)
                ->withCount('breaking_news_view as total_views');

            if ($request->slug) {
                $data->where('slug', $request->slug);
            }

            $total = $data->clone()->count('id');
            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;
            $breakingNews = $data->clone()->skip($offset)->take($limit)->safeOrder('id', 'DESC')->get();

            foreach ($breakingNews as $item) {
                $item->read_time = ReadTimeService::estimate($item->description);
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $breakingNews,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> getBreakingNews');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Views
    // -------------------------------------------------------------------------

    public function setBreakingNewsView(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'breaking_news_id' => ['required', 'numeric'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $breaking_news_id = $request->breaking_news_id;
            $views_auth_mode  = Settings::where('type', 'views_auth_mode')->value('message') ?? '1';
            $user_id          = auth()->check() ? auth()->id() : null;

            if ($views_auth_mode == '1' && !$user_id) {
                return ResponseService::errorResponse(__('Authentication required to view this news.'), null, config('constants.RESPONSE_CODE.NOT_AUTHORIZED'), null);
            }

            if ($user_id) {
                $alreadyViewed = BreakingNewsView::where('user_id', $user_id)
                    ->where('breaking_news_id', $breaking_news_id)
                    ->exists();

                if ($alreadyViewed) {
                    return ResponseService::errorResponse(__('Breaking News already viewed by this user'), null, config('constants.RESPONSE_CODE.SUCCESS'), null);
                }
            }

            BreakingNewsView::create([
                'user_id'         => $user_id,
                'breaking_news_id' => $breaking_news_id,
            ]);

            return ResponseService::successResponse(__('Breaking News view added successfully.'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> setBreakingNewsView');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setNewsView(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id' => ['required', 'numeric'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $news_id         = $request->news_id;
            $views_auth_mode = Settings::where('type', 'views_auth_mode')->value('message') ?? '1';
            $user_id         = auth()->check() ? auth()->id() : null;

            if ($views_auth_mode == '1' && !$user_id) {
                return ResponseService::errorResponse(__('Authentication required to view this news.'), null, config('constants.RESPONSE_CODE.NOT_AUTHORIZED'), null);
            }

            if ($user_id) {
                $alreadyViewed = News_view::where('user_id', $user_id)->where('news_id', $news_id)->exists();
                if ($alreadyViewed) {
                    return ResponseService::errorResponse(__('News already viewed by this user'), null, config('constants.RESPONSE_CODE.SUCCESS'), null);
                }
            }

            News_view::create([
                'user_id' => $user_id,
                'news_id' => $news_id,
            ]);

            return ResponseService::successResponse(__('News view added successfully.'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> setNewsView');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Featured Sections
    // -------------------------------------------------------------------------

    public function getFeaturedSections(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'platform'        => ['required', 'string', 'in:app,web'],
                'language_code'   => 'required|string|exists:tbl_languages,code',
                'section_id'      => 'nullable|numeric|exists:tbl_featured_sections,id',
                'slug'            => 'nullable|string|max:255',
                'news_type'       => 'nullable|string|in:news,breaking_news,videos,author_news,rss_feeds_news',
                'style_web'       => 'nullable|string|in:style_1,style_2,style_3,style_4,style_5,style_6',
                'latitude'        => 'nullable|numeric|between:-90,90',
                'longitude'       => 'nullable|numeric|between:-180,180',
                'offset'          => 'nullable|integer|min:0',
                'limit'           => 'nullable|integer|min:1|max:100',
                'section_offset'  => 'nullable|integer|min:0',
                'section_limit'   => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);
            $news_type  = $request->news_type ?? '';
            $style_web  = $request->style_web ?? '';
            $latitude   = (float) ($request->latitude ?? 0);
            $longitude  = (float) ($request->longitude ?? 0);
            $platform   = $request->platform;

            $service = new FeaturedSectionService($this->toDate, $this->nearest_location_measure);

            $res = FeaturedSections::where('language_id', $languageId)->where('status', 1);

            if ($request->section_id) {
                $res = $res->where('id', $request->section_id);
            } elseif ($request->slug) {
                $res = $res->where('slug', $request->slug);
            } elseif (!empty($news_type) && !empty($style_web)) {
                $res = $res->where('news_type', $news_type)->where('style_web', $style_web);
            }

            $total = $res->clone()->count('id');
            if (!$total) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $data = $res->clone()
                ->orderBy('row_order', 'ASC')
                ->offset($request->section_offset ?? 0)
                ->take($request->section_limit ?? 10)
                ->get();

            foreach ($data as $key => $row) {

                $offset = (int) ($request->offset ?? 0);
                $limit  = (int) ($request->limit ?? 10);

                $result_count = 0;
                $results      = collect();

                if (in_array($row->news_type, ['news', 'videos'])) {
                    [$result_count, $results] = $service->resolveNewsResults($row, $languageId, $latitude, $longitude, $offset, $limit);
                } elseif ($row->news_type === 'breaking_news') {
                    [$result_count, $results] = $service->resolveBreakingNewsResults($row, $languageId, $offset, $limit);
                } elseif ($row->is_based_on_user_choice == '1') {
                    [$result_count, $results] = $service->resolveUserChoiceResults($languageId, $latitude, $longitude, $offset, $limit);
                } elseif ($row->news_type === 'rss_feeds_news') {
                    [$result_count, $results] = $service->resolveRssFeedsResults($row, $languageId, $offset, $limit);
                } elseif ($row->news_type === 'author_news') {
                    [$result_count, $results] = $service->resolveAuthorNewsResults($row, $languageId, $offset, $limit);

                    foreach ($results as $row2) {
                        if (!empty($row2->image)) {
                            $imagePath = (strpos($row2->image, 'news/') === false)
                                ? 'news/' . $row2->image
                                : $row2->image;

                            $row2->image = url(Storage::url($imagePath));
                        }

                        $row2->read_time = ReadTimeService::estimate($row2->description ?? null);
                    }
                }

                foreach ($results as $row2) {
                    if ($row->news_type === 'news' || $row->is_based_on_user_choice == '1') {
                        $row2 = $service->formatNewsItem($row2, fn($r, $id) => $this->getNewsData($r, $id));
                    } elseif ($row->news_type === 'breaking_news') {
                        $row2 = $service->formatBreakingNewsItem($row2);
                    } elseif ($row->news_type === 'videos') {
                        if ($row->videos_type === 'news') {
                            $row2 = $service->formatVideoNewsItem($row2, fn($r, $id) => $this->getNewsData($r, $id));
                        } elseif ($row->videos_type === 'breaking_news') {
                            $row2 = $service->formatBreakingNewsItem($row2);
                        }
                    } elseif ($row->news_type === 'rss_feeds_news') {
                        $row2 = $service->formatRssFeedItem($row2);
                    }
                }

                $data[$key]->news_type     = $data[$key]->is_based_on_user_choice == '1' ? 'user_choice' : $data[$key]->news_type;
                $content                   = $data[$key]->is_based_on_user_choice == '1' ? 'news' : $data[$key]->news_type;
                $content_total             = $data[$key]->is_based_on_user_choice == '1' ? 'news_total' : $data[$key]->news_type . '_total';
                $data[$key]->$content_total = $result_count;
                $data[$key]->$content       = $results;

                $ad_space = AdSpaces::where('ad_featured_section_id', $data[$key]->id)
                    ->where('status', 1)
                    ->where('platform', $platform)
                    ->inRandomOrder()
                    ->first();
                if (!empty($ad_space)) {
                    $row->ad_spaces = $ad_space;
                }
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $data,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> getFeaturedSections');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // E-News
    // -------------------------------------------------------------------------

    public function getENews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'per_page'      => 'nullable|integer|min:1|max:100',
                'order_by'      => 'nullable|string',
                'sort_by'       => 'nullable|string|in:asc,desc,ASC,DESC',
                'search'        => 'nullable|string|max:255',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);
            $perPage    = $request->per_page ?? 10;
            $orderBy    = $request->order_by ?? 'id';
            $sortBy     = $request->sort_by ?? 'DESC';
            $search     = $request->search ?? '';

            $eNews = Enews::where('language_id', $languageId)
                ->search($search, $languageId)
                ->safeOrder($orderBy, $sortBy)
                ->paginate($perPage);

            return ResponseService::successResponse('E news fetched successfully', $eNews);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> getENews');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }

    // -------------------------------------------------------------------------
    // Feed Items
    // -------------------------------------------------------------------------

    public function getFeedItems(Request $request)
    {
        try {
            $languageId = $this->resolveLanguageId($request);

            $validator = Validator::make($request->all(), [
                'language_code'  => 'required|string|exists:tbl_languages,code',
                'per_page'       => 'nullable|integer|min:1|max:100',
                'category_ids'   => 'nullable|string|exists:tbl_category,id',
                'sub_category_ids' => 'nullable|string|exists:tbl_subcategory,id',
                'source_ids'     => 'nullable|string|exists:tbl_rss,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $perPage   = $request->per_page ?? 10;
            $freshness = Carbon::now()->subDays(7);

            $categoryIds = $request->category_ids
                ? array_values(array_filter(array_map('intval', explode(',', $request->category_ids))))
                : null;
            $subCategoryIds = $request->sub_category_ids
                ? array_values(array_filter(array_map('intval', explode(',', $request->sub_category_ids))))
                : null;
            $sourceIds = $request->source_ids
                ? array_values(array_filter(array_map('intval', explode(',', $request->source_ids))))
                : null;

            if ($categoryIds) {
                $categoryIds = Category::whereIn('id', $categoryIds)->pluck('id')->toArray();
            }
            if ($subCategoryIds) {
                $subCategoryIds = Category::whereIn('id', $subCategoryIds)->pluck('id')->toArray();
            }
            if ($sourceIds) {
                $sourceIds = RSS::whereIn('id', $sourceIds)->where('status', 1)->pluck('id')->toArray();
            }

            $feedItems = FeedItem::selectedColumns()->with([
                'source:id,language_id,category_id,subcategory_id,tag_id,feed_name,feed_url',
                'source.category:id,slug,category_name',
                'source.sub_category:id,slug,subcategory_name',
            ])
                ->whereHas('source', function ($query) use ($languageId, $categoryIds, $subCategoryIds) {
                    $query->where('language_id', $languageId)
                        ->when($categoryIds, fn($q) => $q->whereIn('category_id', $categoryIds))
                        ->when($subCategoryIds, fn($q) => $q->whereIn('subcategory_id', $subCategoryIds));
                    // status 1 of rss sources
                    $query->where('status', 1);
                })
                ->when($sourceIds, fn($query) => $query->whereIn('rss_source_id', $sourceIds))
                ->where('published_at', '>=', $freshness)
                ->whereNotNull('published_at')
                ->orderBy('published_at', 'DESC')
                ->inRandomOrder()
                ->paginate($perPage);

            foreach ($feedItems as $item) {
                if (isset($item->source->tag_id) && $item->source->tag_id != '') {
                    $tagIds = explode(',', $item->source->tag_id);
                    $item->source->tag = Tag::select('id', 'tag_name', 'slug')->whereIn('id', $tagIds)->get();
                } else {
                    $item->source->tag = [];
                }
            }

            return ResponseService::successResponse('RSS feeds fetched successfully', $feedItems);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'ContentApiController -> getFeedItems');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }
}
