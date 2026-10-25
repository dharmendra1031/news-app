<?php

namespace App\Http\Controllers\Api;

use App\Models\BreakingNewsView;
use App\Models\LiveStreaming;
use App\Models\News;
use App\Models\News_like;
use App\Models\News_view;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use App\Models\Tag;
class MediaApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Live Streaming
    // -------------------------------------------------------------------------

    public function getLiveStreaming(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'          => 'nullable|string|max:255',
                'order_by'      => 'nullable|string',
                'sort_by'       => 'nullable|string|in:asc,desc,ASC,DESC',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);
            $offset     = $request->offset ?? 0;
            $limit      = $request->limit ?? 10;
            $orderBy    = $request->order_by ?? 'id';
            $sortBy     = $request->sort_by ?? 'DESC';
            $slug       = $request->filled('slug') ? $request->slug : null;

            $query = LiveStreaming::where('language_id', $languageId);
            if ($slug) {
                $query->search($slug);
            }

            $total = $query->clone()->count();
            if ($total == 0) {
                return ResponseService::errorResponse(
                    'No Data Found', null,
                    config('constants.RESPONSE_CODE.NOT_FOUND'), null
                );
            }

            $liveStreaming = $query->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit)->get();
            $liveStreaming->map(function ($item) {
                $item->slug = $this->generateSlugFromTitle($item->title);
                return $item;
            });

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $liveStreaming->values(),
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'MediaApiController -> getLiveStreaming');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Videos (news + breaking news + live streaming combined)
    // -------------------------------------------------------------------------

    public function getVideos(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'slug'          => 'nullable|string',
                'source_type'   => 'nullable|string|in:news,breaking_news,live_streaming',
                'category_slug' => 'nullable|string',
                'latitude'      => 'nullable|numeric',
                'longitude'     => 'nullable|numeric',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = $this->resolveLanguageId($request);
            $slug        = $request->slug ?? null;
            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;
            $latitude    = $request->latitude ?? 0;
            $longitude   = $request->longitude ?? 0;
            $user_id     = Auth::check() ? Auth::user()->id : 0;
            $source_type = $request->source_type ?? null;

            // --- News videos query ---
            $res = DB::table('tbl_news')
                ->selectRaw(
                    'tbl_news.*, tbl_category.category_name, tbl_category.slug as category_slug,
                     tbl_location.latitude, tbl_location.longitude, "news" as source_type,
                     SQRT(POW(111.2 * (tbl_location.latitude - ?), 2) + POW(111.2 * (? - tbl_location.longitude) * COS(tbl_location.latitude / 57.3), 2)) AS distance',
                    [$latitude, $longitude]
                )
                ->leftJoin('tbl_category', 'tbl_news.category_id', '=', 'tbl_category.id')
                ->leftJoin('tbl_subcategory', 'tbl_news.subcategory_id', '=', 'tbl_subcategory.id')
                ->leftJoin('tbl_location', 'tbl_news.location_id', '=', 'tbl_location.id')
                ->where(function ($q1) {
                    $q1->where(function ($subq) {
                        $subq->whereNotNull('tbl_news.published_date')
                            ->where('tbl_news.published_date', '<=', $this->toDate);
                    })->orWhere(function ($subq) {
                        $subq->whereNull('tbl_news.published_date')
                            ->whereDate('tbl_news.created_at', '<=', $this->toDate);
                    });
                })
                ->where('tbl_news.status', 1)
                ->where('tbl_news.language_id', $language_id)
                ->where(function ($q1) {
                    $q1->where('tbl_news.show_till', '>=', $this->toDate)
                        ->orWhere('tbl_news.show_till', '0000-00-00');
                })
                ->whereIn('content_type', ['video_upload', 'video_youtube', 'video_other']);

            if ($slug) {
                $res->where('tbl_news.slug', $slug);
            }
            if ($request->category_slug) {
                $res->where('tbl_category.slug', $request->category_slug);
            }

            if ($latitude && $longitude) {
                $res->orderByRaw('CASE WHEN distance IS NULL THEN 1 ELSE 0 END, distance ASC')
                    ->where(function ($q2) {
                        $q2->having(DB::raw('distance <' . $this->nearest_location_measure . ' OR tbl_news.location_id=. 0'));
                    });
            } else {
                $res->orderBy('tbl_news.id', 'DESC');
            }

            // --- Source-type specific: news only ---
            if ($source_type === 'news') {
                $total = $res->clone()->count('tbl_news.id');
                if ($total) {
                    $data = $res->clone()->limit($limit)->offset($offset)->get();
                    foreach ($data as $item) {
                        $this->processNewsVideoItem($item, $user_id);
                    }
                    return ResponseService::successResponse(__('Data fetched successfully'), ['total' => $total, 'data' => $data]);
                }
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            // --- Breaking news videos ---
            $includeBreakingNews  = !$request->has('category_slug');
            $totalBreakingNews    = 0;
            $breakingNewsData     = collect([]);

            if ($includeBreakingNews) {
                $breakingNews = DB::table('tbl_breaking_news')
                    ->select('tbl_breaking_news.*', DB::raw('"breaking_news" as source_type'))
                    ->where('tbl_breaking_news.language_id', $language_id)
                    ->whereIn('tbl_breaking_news.content_type', ['video_upload', 'video_youtube', 'video_other']);

                if ($slug) {
                    $breakingNews->where('tbl_breaking_news.slug', $slug);
                }

                if ($source_type === 'breaking_news') {
                    $total = $breakingNews->clone()->count('tbl_breaking_news.id');
                    if ($total) {
                        $data = $breakingNews->clone()->orderBy('tbl_breaking_news.id', 'DESC')
                            ->limit($limit)->offset($offset)->get();
                        foreach ($data as $item) {
                            $this->processBreakingNewsVideoItem($item);
                        }
                        return ResponseService::successResponse(__('Data fetched successfully'), ['total' => $total, 'data' => $data]);
                    }
                    return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
                }

                $totalBreakingNews = $breakingNews->clone()->count('tbl_breaking_news.id');
                $breakingNewsData  = $breakingNews->clone()->orderBy('tbl_breaking_news.id', 'DESC')->get();
            }

            // --- Live streaming ---
            $includeLiveStreaming = !$request->has('category_slug');
            $totalLiveStreaming   = 0;
            $liveStreamingData   = collect([]);

            if ($includeLiveStreaming) {
                $liveStreaming = LiveStreaming::withCommonFields()->where('language_id', $language_id);

                if ($source_type === 'live_streaming') {
                    $total = $liveStreaming->clone()->count('tbl_live_streaming.id');
                    if ($total) {
                        $data = $liveStreaming->clone()->orderBy('tbl_live_streaming.id', 'DESC')
                            ->limit($limit)->offset($offset)->get();
                        foreach ($data as $item) {
                            $item->slug        = $this->generateSlugFromTitle($item->title);
                            $item->like        = 0;
                            $item->total_like  = 0;
                            $item->total_views = 0;
                        }
                        if ($slug) {
                            $data  = $data->filter(fn($item) => $item->slug === $slug)->values();
                            $total = $data->count();
                            if ($total === 0) {
                                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
                            }
                        }
                        return ResponseService::successResponse(__('Data fetched successfully'), ['total' => $total, 'data' => $data]);
                    }
                    return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
                }

                $totalLiveStreaming = $liveStreaming->clone()->count('tbl_live_streaming.id');
                $liveStreamingData  = $liveStreaming->clone()->orderBy('tbl_live_streaming.id', 'DESC')->get();

                foreach ($liveStreamingData as $item) {
                    $item->slug = $this->generateSlugFromTitle($item->title);
                }

                if ($slug) {
                    $liveStreamingData  = $liveStreamingData->filter(fn($item) => $item->slug === $slug)->values();
                    $totalLiveStreaming  = $liveStreamingData->count();
                }
            }

            // --- Combined ---
            $totalNews = $res->clone()->count('tbl_news.id');
            $total     = $totalNews + $totalBreakingNews + $totalLiveStreaming;

            if (!$total) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $allData = $res->clone()->get()
                ->concat($breakingNewsData)
                ->concat($liveStreamingData)
                ->sortByDesc('id')
                ->values()
                ->slice($offset, $limit)
                ->values();

            foreach ($allData as $item) {
                if ($item->source_type === 'news') {
                    $this->processNewsVideoItem($item, $user_id);
                } elseif ($item->source_type === 'breaking_news') {
                    $this->processBreakingNewsVideoItem($item);
                } elseif ($item->source_type === 'live_streaming') {
                    $item->category_name = null;
                    $item->category_slug = null;
                    $item->like          = 0;
                    $item->total_like    = 0;
                    $item->total_views   = 0;
                }
            }
            // Collect all unique tag IDs from comma-separated tag_id values
            $tagIds = $allData
                ->pluck('tag_id')
                ->filter()
                ->flatMap(function ($tagIds) {
                    return array_map('trim', explode(',', $tagIds));
                })
                ->filter()
                ->unique()
                ->values();

            // Fetch all tags in a single query
            $tags = Tag::whereIn('id', $tagIds)
                ->pluck('tag_name', 'id');

            // Add comma-separated tag names to each item
            $allData->transform(function ($item) use ($tags) {
                if (empty($item->tag_id)) {
                    $item->tag_name = null;
                    return $item;
                }

                $item->tag_name = collect(explode(',', $item->tag_id))
                    ->map(fn($id) => trim($id))
                    ->filter()
                    ->map(fn($id) => $tags[$id] ?? null)
                    ->filter()
                    ->implode(', ');

                return $item;
            });
            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $allData,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'MediaApiController -> getVideos');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Private item processors
    // -------------------------------------------------------------------------

    private function processNewsVideoItem($item, int $user_id): void
    {
        if (!empty($item->image) && strpos($item->image, 'news/') === false) {
            $item->image = 'news/' . $item->image;
        }
        if(!empty($item->image)){
            $item->image = url(Storage::url($item->image));
        }

        if ($item->content_type == 'video_upload') {
            $cv = $item->content_value;
            if (!empty($cv) && strpos($cv, 'news_video/') === false) {
                $cv = 'news_video/' . $cv;
            }
            $item->content_value = $item->content_value ? url(Storage::url($cv)) : '';
        }

        $news_like        = News_like::where('news_id', $item->id);
        $item->like       = $news_like->clone()->where('status', 1)->where('user_id', $user_id)->count('id');
        $item->total_like = $news_like->clone()->where('status', 1)->count('id');
        $item->total_views = News_view::where('news_id', $item->id)->count('id');
    }

    private function processBreakingNewsVideoItem($item): void
    {
        if (!empty($item->image) && strpos($item->image, 'breaking_news/') === false) {
            $item->image = 'breaking_news/' . $item->image;
        }
        $item->image = url(Storage::url($item->image));

        if ($item->content_type == 'video_upload') {
            $cv = $item->content_value;
            if (!empty($cv) && strpos($cv, 'breaking_news_video/') === false) {
                $cv = 'breaking_news_video/' . $cv;
            }
            $item->content_value = $item->content_value ? url(Storage::url($cv)) : '';
        }

        $item->category_name = null;
        $item->category_slug = null;
        $item->like          = 0;
        $item->total_like    = 0;
        $item->total_views   = BreakingNewsView::where('breaking_news_id', $item->id)->count('id');
    }
}
