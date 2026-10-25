<?php

namespace App\Http\Controllers\Api;

use App\Models\Author;
use App\Models\Category;
use App\Models\News;
use App\Models\News_image;
use App\Models\SubCategory;
use App\Models\Tag;
use App\Models\User;
use App\Services\ReadTimeService;
use App\Services\ResponseService;
use Carbon\Carbon;
use Exception;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class NewsApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Slug
    // -------------------------------------------------------------------------

    public function checkSlugAvailability(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'slug'    => 'required|string|max:255',
                'news_id' => 'nullable|numeric|exists:tbl_news,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $slug_en   = generateUniqueSlug($request->slug);
            $checkSlug = News::where('slug', $slug_en)->where('id', '!=', $request->news_id)->first();

            if (!empty($checkSlug)) {
                return ResponseService::errorResponse(
                    __('The slug is already in use. Please choose another.'),
                    $slug_en,
                    config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
                    null
                );
            }

            return ResponseService::successResponse(__('This slug can be used.'), ['slug' => $slug_en]);
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> checkSlugAvailability');
        }
    }

    // -------------------------------------------------------------------------
    // News CRUD
    // -------------------------------------------------------------------------

    public function deleteNewsImages(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|numeric|exists:tbl_news_image,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $image = News_image::with('news:id,user_id')->find($request->id);
            if (!$image) {
                return ResponseService::errorResponse(__('Image not found'), null, 403);
            }
            if (!$image->news || (int) $image->news->user_id !== (int) Auth::id()) {
                return ResponseService::errorResponse(__('Forbidden'), null, 403);
            }
            Storage::disk('public')->delete($image->getRawOriginal('other_image'));
            $image->delete();

            return ResponseService::successResponse(__('Image deleted!'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> deleteNewsImages');
        }
    }

    public function deleteNews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|numeric|exists:tbl_news,id',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $news = News::find($request->id);
            if (!$news) {
                return ResponseService::errorResponse('News not found', null, 403);
            }
            if ((int) $news->user_id !== (int) Auth::id()) {
                return ResponseService::errorResponse(__('Forbidden'), null, 403);
            }

            // Delete uploaded video file
            if ($news->content_type === 'video_upload' && !empty($news->content_value)) {
                if (Storage::disk('public')->exists($news->content_value)) {
                    Storage::disk('public')->delete($news->content_value);
                }
            }

            // Delete main image
            $imagePath = $news->getRawOriginal('image');
            if (!empty($imagePath) && Storage::disk('public')->exists($imagePath)) {
                Storage::disk('public')->delete($imagePath);
            }

            // Delete gallery images
            News_image::where('news_id', $news->id)->get()->each(function ($row) {
                $otherImage = $row->getRawOriginal('other_image');
                if (!empty($otherImage) && Storage::disk('public')->exists($otherImage)) {
                    Storage::disk('public')->delete($otherImage);
                }
                $row->delete();
            });

            $news->delete();

            return ResponseService::successResponse(__('News deleted!'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'NewsApiController -> deleteNews');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setNews(Request $request)
    {
        try {
            if ($request->is_draft == 1) {
                $validator = Validator::make($request->all(), [
                    'action_type'    => 'required',
                    'news_id'        => 'required_if:action_type,2',
                    'title'          => 'required|string|max:255',
                    'slug'           => 'required|string|max:255',
                    'published_date' => 'nullable',
                    'is_draft'       => 'required|boolean',
                    'language_code'  => 'required|string|exists:tbl_languages,code',
                    'content_type'           => 'nullable|string|in:standard_post,video_youtube,video_other,video_upload',
                    'category_id'            => 'nullable|numeric|exists:tbl_category,id',
                    'subcategory_id'         => 'nullable|numeric|exists:tbl_subcategory,id',
                    'location_id'            => 'nullable|numeric|exists:tbl_location,id',
                    'tag_id'                 => 'nullable|string|max:255',
                    'show_till'              => 'nullable|date',
                    'meta_title'             => 'nullable|string|max:255',
                    'meta_keyword'           => 'nullable|string|max:255',
                    'meta_description'       => 'nullable|string|max:500',
                    'summarized_description' => 'nullable|string',
                    'is_short_news'          => 'nullable|boolean',
                ]);
            } else {
                $validator = Validator::make($request->all(), [
                    'action_type'    => 'required',
                    'news_id'        => 'required_if:action_type,2',
                    'title'          => 'required|string|max:255',
                    'slug'           => 'required|string|max:255',
                    'published_date' => 'nullable',
                    'description'    => 'nullable',
                    'is_draft'       => 'required|boolean',
                    'language_code'  => 'required|string|exists:tbl_languages,code',
                    'content_type'           => 'nullable|string|in:standard_post,video_youtube,video_other,video_upload',
                    'category_id'            => 'nullable|numeric|exists:tbl_category,id',
                    'subcategory_id'         => 'nullable|numeric|exists:tbl_subcategory,id',
                    'location_id'            => 'nullable|numeric|exists:tbl_location,id',
                    'tag_id'                 => 'nullable|string|max:255',
                    'show_till'              => 'nullable|date',
                    'meta_title'             => 'nullable|string|max:255',
                    'meta_keyword'           => 'nullable|string|max:255',
                    'meta_description'       => 'nullable|string|max:500',
                    'summarized_description' => 'nullable|string',
                    'is_short_news'          => 'nullable|boolean',
                ]);
            }

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            if (Auth::user()->is_author == 1) {
                if ($request->action_type == '2') {
                    return $this->updateNews($request);
                }
                return $this->createNews($request);
            }

            return ResponseService::errorResponse(__('You do not have permission to manage news'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> setNews');
        }
    }

    public function createNews(Request $request)
    {
        try {
            $languageId = $this->resolveLanguageId($request);

            if (Auth::user()->is_author == 0) {
                return ResponseService::errorResponse('You do not have permission to create news.');
            }

            $slug          = generateUniqueSlug($request->slug);
            $existingSlug  = News::where('slug', $slug)->exists();
            if ($existingSlug) {
                return ResponseService::errorResponse(
                    'The slug is already in use. Please choose another.',
                    null,
                    config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
                    null
                );
            }

            $news         = new News();
            $content_type = $request->content_type;

            if ($content_type === 'standard_post') {
                $content_value = '';
            } elseif (in_array($content_type, ['video_youtube', 'video_other'])) {
                $content_value = $request->input('content_data');
            } elseif ($content_type === 'video_upload') {
                $file = $request->file('content_data');
                $content_value = ($request->hasFile('content_data') && $file->isValid())
                    ? $request->file('content_data')->store('news_video', 'public')
                    : '';
            } else {
                $content_value = '';
            }
            if ($request->hasFile('image')) {
                $news->image = compressAndUpload($request->file('image'), 'news');
            }
            $author = Author::where('user_id', Auth::user()->id)->first();

            $news->language_id           = $languageId;
            $news->category_id           = $request->category_id ?? 0;
            $news->subcategory_id        = $request->subcategory_id ?? 0;
            $news->tag_id                = $request->tag_id ?? '';
            $news->title                 = $request->title;
            $news->slug                  = $slug;
            $news->date                  = $this->toDateTime;
            $news->published_date        = $request->published_date ?? null;
            $news->description           = $request->description ?? null;
            $news->summarized_description = $request->summarized_description ?? null;
            $news->content_type          = $content_type;
            $news->content_value         = $content_value;
            $news->user_id               = Auth::user()->id;
            $news->show_till             = $request->show_till ?? '';
            $news->location_id           = $request->location_id ?? 0;
            $news->meta_title            = $request->meta_title ?? '';
            $news->meta_keyword          = $request->meta_keyword ?? '';
            $news->meta_description      = $request->meta_description ?? '';
            $news->admin_id              = 0;
            $news->status                = ($author && $author->auto_approve) ? 1 : 0;
            $news->is_draft              = $request->is_draft ?? 0;
            $news->is_short_news         = $request->is_short_news ?? 0;
            $news->save();

            if ($request->file('ofile')) {
                foreach ($request->file('ofile') as $file) {
                    News_image::create([
                        'news_id'     => $news->id,
                        'other_image' => compressAndUpload($file, 'news'),
                    ]);
                }
            }

            return ResponseService::successResponse(__('News added Successfully'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> createNews');
        }
    }

    public function updateNews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id'        => 'required|numeric|exists:tbl_news,id',
                'slug'           => 'nullable|string|max:255',
                'title'          => 'nullable|string|max:255',
                'category_id'            => 'nullable|numeric|exists:tbl_category,id',
                'subcategory_id'         => 'nullable|numeric|exists:tbl_subcategory,id',
                'location_id'            => 'nullable|numeric|exists:tbl_location,id',
                'tag_id'                 => 'nullable|string|max:255',
                'show_till'              => 'nullable|date',
                'published_date'         => 'nullable|date',
                'description'            => 'nullable|string',
                'summarized_description' => 'nullable|string',
                'meta_title'             => 'nullable|string|max:255',
                'meta_keyword'           => 'nullable|string|max:255',
                'meta_description'       => 'nullable|string|max:500',
                'is_draft'               => 'nullable|boolean',
                'is_short_news'          => 'nullable|boolean',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);
            $news       = News::find($request->news_id);

            if (!$news) {
                return ResponseService::errorResponse(
                    __('No Data Found'),
                    null,
                    config('constants.RESPONSE_CODE.NO_DATA_FOUND')
                );
            }

            if ($news->user_id !== Auth::id()) {
                return ResponseService::errorResponse(
                    __('You do not have permission to manage this news.'),
                    null,
                    config('constants.RESPONSE_CODE.NOT_AUTHORIZED')
                );
            }

            $author = Author::where('user_id', Auth::id())->first();

            if ($request->filled('slug')) {
                $slug      = generateUniqueSlug($request->slug);
                $slugExists = News::where('slug', $slug)->where('id', '!=', $news->id)->exists();
                if ($slugExists) {
                    return ResponseService::errorResponse(
                        'The slug is already in use. Please choose another.',
                        null,
                        config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
                        null
                    );
                }
                $news->slug = $slug;
            }

            $data = $request->only([
                'category_id', 'subcategory_id', 'tag_id', 'title',
                'description', 'summarized_description', 'meta_description',
                'meta_title', 'meta_keyword', 'published_date', 'show_till',
                'location_id', 'is_draft', 'is_short_news',
            ]);

            $data['subcategory_id'] = $request->subcategory_id ?? 0;
            $data['language_id']    = $languageId;
            $data['user_id']        = Auth::id();
            $data['date']           = now();

            $isDraft = $request->has('is_draft') ? (bool) $request->is_draft : (bool) $news->is_draft;
            if (!$isDraft && $author?->auto_approve) {
                $data['status'] = 1;
            }

            if ($request->hasFile('image')) {
                $news->image = compressAndReplace(
                    $request->file('image'),
                    'news',
                    $news->getRawOriginal('image')
                );
            }

            $news->update($data);

            if ($request->hasFile('ofile')) {
                foreach ($request->file('ofile') as $file) {
                    News_image::create([
                        'news_id'     => $news->id,
                        'other_image' => compressAndUpload($file, 'news'),
                    ]);
                }
            }

            return ResponseService::successResponse(__('News Updated Successfully'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> updateNews');
        }
    }

    // -------------------------------------------------------------------------
    // getNews — main listing with filters, location distance, tag-union query
    // -------------------------------------------------------------------------

    public function getNews(Request $request)
    {
        try {
            $request['get_user_news'] = $request->get_user_news ?? 0;

            $validator = Validator::make($request->all(), [
                'get_user_news'     => ['required', 'numeric'],
                'language_code'     => 'nullable|string|exists:tbl_languages,code',
                'id'                => 'nullable|numeric|exists:tbl_news,id',
                'slug'              => 'nullable|string|max:255',
                'category_id'       => ['nullable', 'regex:/^\d+(,\d+)*$/'],
                'subcategory_id'    => 'nullable|numeric|exists:tbl_subcategory,id',
                'category_slug'     => 'nullable|string|max:255',
                'subcategory_slug'  => 'nullable|string|max:255',
                'tag_id'            => ['nullable', 'regex:/^\d+(,\d+)*$/'],
                'tag_slug'          => 'nullable|string|max:255',
                'search'            => 'nullable|string|max:255',
                'date'              => 'nullable|date',
                'last_n_days'       => 'nullable|integer|min:1',
                'year'              => 'nullable|integer|min:1970|max:2100',
                'merge_tag'         => 'nullable|in:0,1',
                'is_comment'        => 'nullable|in:0,1',
                'offset'            => 'nullable|integer|min:0',
                'limit'             => 'nullable|integer|min:1|max:100',
                'latitude'          => 'nullable|numeric|between:-90,90',
                'longitude'         => 'nullable|numeric|between:-180,180',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = 0;
            if ($request->get_user_news == 0) {
                $language_id = $this->resolveLanguageId($request);
            }

            $user_id   = Auth::check() ? Auth::user()->id : 0;
            $offset    = $request->offset ?? 0;
            $limit     = $request->limit ?? 10;
            $latitude  = $request->latitude ?? 0;
            $longitude = $request->longitude ?? 0;

            $news = News::with(
                'category:id,category_name,slug',
                'sub_category:id,subcategory_name',
                'location:id,location_name,latitude,longitude',
                'images',
                'user:id,name,profile,is_author,slug',
                'author:user_id,bio'
            )->where('is_draft', 0);

            if ($request->get_user_news == 1) {
                $news->where('user_id', $user_id)->where('user_id', '!=', 0);
            } else {
                $news->where('language_id', $language_id)
                    ->where(function ($q) {
                        $q->where('show_till', '>=', $this->toDate)
                            ->orWhere('show_till', '0000-00-00')
                            ->orWhere('show_till', null);
                    })
                    ->where('status', 1)
                    ->where(function ($q) {
                        $q->where(function ($subq) {
                            $subq->whereNotNull('published_date')
                                ->where('published_date', '<=', $this->toDate);
                        })->orWhere(function ($subq) {
                            $subq->whereNull('published_date')
                                ->whereDate('tbl_news.created_at', '<=', $this->toDate);
                        });
                    });
            }

            // Apply individual filters
            $news = $this->applyNewsFilters($news, $request);

            // Merge-tag union query — returns early if union is used
            if (
                ($request->category_id || $request->subcategory_id)
                && $request->has('merge_tag')
                && $request->merge_tag == 1
                ) {
                $result = $this->applyTagUnionQuery($news, $request, $language_id, (float) $latitude, (float) $longitude, $offset, $limit);
                if ($result !== null) {
                    return $result;
                }
            }

            // Standard path (no union)
            $news->select('tbl_news.*');

            if (isset($request->latitude) && isset($request->longitude)) {
                $news->join('tbl_location', 'tbl_news.location_id', '=', 'tbl_location.id', 'left')
                    ->selectRaw('SQRT(POW(111.2 * (tbl_location.latitude - ?), 2) + POW(111.2 * (? - tbl_location.longitude) * COS(RADIANS(tbl_location.latitude) / 57.3), 2)) AS distance', [$latitude, $longitude])
                    ->where(function ($q1) {
                        $q1->having(DB::raw('distance <' . (int) $this->nearest_location_measure . ' OR tbl_news.location_id=. 0'));
                    })
                    ->orderByRaw('CASE WHEN distance IS NULL THEN 1 ELSE 0 END')
                    ->orderBy('distance', 'ASC')
                    ->orderBy('tbl_news.id', 'DESC');
            } else {
                $news->reorder('tbl_news.id', 'DESC');
            }

            $total = $news->clone()->count();

            if ($total) {
                $res = $news->clone()->skip($offset)->take($limit)->get();
                $res->each(function ($item) {
                    $this->getNewsData($item, $item->id);
                    if ($item->content_type == 'video_upload') {
                        $item->content_value = $this->resolveNewsVideoUrl($item->content_value);
                    }
                    $item->read_time = ReadTimeService::estimate($item->description);
                });

                return ResponseService::successResponse(__('Data fetched successfully'), [
                    'total' => $total,
                    'data'  => $res,
                ]);
            }

            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'NewsApiController -> getNews');
        }
    }

    /**
     * Apply all optional filter clauses to the news query builder.
     */
    private function applyNewsFilters(Builder $query, Request $request): Builder
    {
        if ($request->id) {
            $query->where('id', $request->id);
        }
        if ($request->slug) {
            $query->where('slug', $request->slug);
        }
        if ($request->category_id) {
            $query->whereIn('category_id', explode(',', $request->category_id));
        }
        if ($request->category_slug) {
            $catId = Category::select('id')->where('slug', $request->category_slug)->pluck('id')->first();
            $query->where('category_id', $catId);
        }
        if ($request->subcategory_id) {
            $query->where('subcategory_id', $request->subcategory_id);
        }
        if ($request->subcategory_slug) {
            $subId = SubCategory::select('id')->where('slug', $request->subcategory_slug)->pluck('id')->first();
            $query->where('subcategory_id', $subId);
        }
        if ($request->tag_id) {
            $tagIds = explode(',', $request->tag_id);
            $query->where(function ($q) use ($tagIds) {
                foreach ($tagIds as $tagId) {
                    $q->orWhereRaw('FIND_IN_SET(?, tag_id)', [$tagId]);
                }
            });
        }
        if ($request->tag_slug) {
            $tagId = Tag::select('id')->where('slug', $request->tag_slug)->pluck('id')->first();
            $query->whereRaw('FIND_IN_SET(?, tag_id)', [$tagId]);
        }
        if ($request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('tbl_news.title', 'LIKE', "%{$search}%");
            });
        }
        if ($request->date) {
            $query->where(function ($q) use ($request) {
                $q->where(function ($subq) use ($request) {
                    $subq->whereNotNull('published_date')->whereDate('published_date', $request->date);
                })->orWhere(function ($subq) use ($request) {
                    $subq->whereNull('published_date')->whereDate('tbl_news.created_at', $request->date);
                });
            });
        }
        if ($request->last_n_days && is_numeric($request->last_n_days)) {
            $startDate = Carbon::now()->subDays($request->last_n_days)->startOfDay();
            $query->where(function ($q) use ($startDate) {
                $q->where(function ($subq) use ($startDate) {
                    $subq->whereNotNull('published_date')->whereDate('published_date', '>=', $startDate);
                })->orWhere(function ($subq) use ($startDate) {
                    $subq->whereNull('published_date')->whereDate('tbl_news.created_at', '>=', $startDate);
                });
            });
        }
        if ($request->year && is_numeric($request->year)) {
            $query->where(function ($q) use ($request) {
                $q->where(function ($subq) use ($request) {
                    $subq->whereNotNull('published_date')->whereYear('published_date', $request->year);
                })->orWhere(function ($subq) use ($request) {
                    $subq->whereNull('published_date')->whereYear('tbl_news.created_at', $request->year);
                });
            });
        }
        if($request->get_user_news == 0){
            // Ensure show_till not expired
          $query->where(function ($q) {
            $q->where('show_till', '>=', $this->toDate)->orWhere('show_till', '0000-00-00');
        });
        }

        if ($request->has('is_comment') && $request->is_comment != '') {
            $query->where('is_comment', $request->is_comment);
        }

        return $query;
    }

    /**
     * Build and execute a UNION query that merges category/subcategory news with tag-related news.
     * Returns a JsonResponse on success, or null if no tag IDs were found (fall through to standard query).
     */
    private function applyTagUnionQuery(
        Builder $originalNews,
        Request $request,
        int $languageId,
        float $latitude,
        float $longitude,
        int $offset,
        int $limit
    ) {
        $originalQuery = $originalNews->clone();

        $tagIds = $originalNews->clone()
            ->select('tag_id')
            ->whereNotNull('tag_id')
            ->where('tag_id', '!=', '')
            ->pluck('tag_id')
            ->toArray();

        $uniqueTagIds = [];
        foreach ($tagIds as $tagIdList) {
            if (!empty($tagIdList)) {
                foreach (explode(',', $tagIdList) as $tagId) {
                    if (!empty($tagId) && !in_array($tagId, $uniqueTagIds)) {
                        $uniqueTagIds[] = $tagId;
                    }
                }
            }
        }

        if (empty($uniqueTagIds)) {
            return null;
        }

        $originalNewsIds  = $originalQuery->pluck('tbl_news.id')->toArray();
        $tagRelatedQuery  = News::with(
            'category:id,category_name,slug',
            'sub_category:id,subcategory_name',
            'location:id,location_name,latitude,longitude',
            'images'
        )
            ->where('language_id', $languageId)
            ->where(function ($q) {
                $q->where('show_till', '>=', $this->toDate)->orWhere('show_till', '0000-00-00');
            })
            ->where('status', 1)
            ->where('published_date', '<=', $this->toDate)
            ->where(function ($query) use ($uniqueTagIds) {
                foreach ($uniqueTagIds as $tagId) {
                    $query->orWhereRaw('FIND_IN_SET(?, tag_id)', [$tagId]);
                }
            });

        if (!empty($originalNewsIds)) {
            $tagRelatedQuery->whereNotIn('id', $originalNewsIds);
        }

        if ($latitude && $longitude) {
            $originalQuery->orderByRaw('CASE WHEN distance IS NULL THEN 1 ELSE 0 END, distance DESC');
            $tagRelatedQuery->orderByRaw('CASE WHEN distance IS NULL THEN 1 ELSE 0 END, distance DESC');
        } else {
            $originalQuery->orderBy('id', 'DESC');
            $tagRelatedQuery->orderBy('id', 'DESC');
        }

        $unionQuery = $originalQuery->union($tagRelatedQuery);

        $news = DB::table(DB::raw("({$unionQuery->toSql()}) as news_union"))
            ->mergeBindings($unionQuery->getQuery())
            ->select('*');

        if ($latitude && $longitude) {
            $news->orderByRaw('CASE WHEN distance IS NULL THEN 1 ELSE 0 END, distance DESC');
        } else {
            $news->reorder('id', 'DESC');
        }

        $total = $news->count();
        if (!$total) {
            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NO_DATA_FOUND'), null);
        }

        $res = $news->skip($offset)->take($limit)->get();
        $res->each(function ($item) {
            $this->getNewsData($item, $item->id);
            $item->image = $this->resolveNewsImageUrl($item->image);
            if ($item->content_type == 'video_upload') {
                $item->content_value = $this->resolveNewsVideoUrl($item->content_value);
            }
            $item->read_time = ReadTimeService::estimate($item->description);
        });

        return ResponseService::successResponse(__('Data fetched successfully'), [
            'total' => $total,
            'data'  => $res,
        ]);
    }

    // -------------------------------------------------------------------------
    // Author news
    // -------------------------------------------------------------------------

    public function getAuthorsNews(Request $request)
    {
        // either user_id req or user_slug
        $validator = Validator::make($request->all(), [
            'user_id' => 'required_without:user_slug|nullable|exists:tbl_users,id',
            'user_slug' => 'required_without:user_id|nullable|exists:tbl_users,slug',
        ]);
        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }

        try {
            $author_id = $request->user_id;

            if ($request->filled('user_slug')) {
                $author_id = User::where('slug', $request->user_slug)->value('id');
            }
            $user = User::where(['id' => $author_id, 'is_author' => 1])->first();
            if (!$user) {
                return ResponseService::errorResponse(__('Author not found'), null, 404);
            }

            $author = Author::where(['user_id' => $author_id, 'status' => 'approved'])->first();
            // if (!$author) {
            //     return ResponseService::errorResponse(__('Author not found'), null, 404);
            // }

            $userData           = $user->only(['id', 'name', 'slug', 'profile', 'is_author']);
            $userData['author'] = $author ? $author->only(['bio']) : [];

            $news = News::with(
                'category:id,category_name,slug',
                'sub_category:id,subcategory_name',
                'location:id,location_name,latitude,longitude',
                'images',
                'author:user_id,bio',
                'comments'
            )
                ->withCount('newsview')
                ->where('user_id', $author_id)
                ->where('is_draft', 0)
                ->where('status', 1)
                ->paginate(config('constants.PAGINATION.SIX_PER_PAGE'));

            foreach ($news as $item) {
                if (isset($item->tag_id) && $item->tag_id != '') {
                    $item->tag_name = Tag::whereIn('id', explode(',', $item->tag_id))->distinct()->pluck('tag_name')->implode(',');
                }
                $item->read_time = ReadTimeService::estimate($item->description);
            }

            return ResponseService::successResponse(__('data fetched successfully'), [
                'user' => $userData,
                'news' => $news,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'NewsApiController -> getAuthorsNews');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }

    public function getUserDraftedNews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'author_id' => 'required|numeric',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user = User::where(['id' => $request->author_id, 'is_author' => 1])->first();
            if (!$user) {
                return ResponseService::errorResponse('Author not found');
            }

            $news = News::with(
                'category:id,category_name,slug',
                'sub_category:id,subcategory_name',
                'location:id,location_name,latitude,longitude',
                'images'
            )
                ->where('user_id', $request->author_id)
                ->where('is_draft', 1)
                ->paginate(config('constants.PAGINATION.SIX_PER_PAGE'));

            foreach ($news as $item) {
                if (isset($item->tag_id) && $item->tag_id != '') {
                    $item->tag_name = Tag::whereIn('id', explode(',', $item->tag_id))->distinct()->pluck('tag_name')->implode(',');
                }
                $item->read_time = ReadTimeService::estimate($item->description);
            }

            return ResponseService::successResponse('Author news fetched successfully', ['news' => $news]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'NewsApiController -> getUserDraftedNews');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }

    // -------------------------------------------------------------------------
    // Tag management
    // -------------------------------------------------------------------------

    public function createTag(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'tag_name'      => 'required|string',
                'language_code' => 'required|string|exists:tbl_languages,code',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $this->resolveLanguageId($request);

            if (Auth::user()->is_author != 1) {
                return ResponseService::errorResponse('You are not allowed to create tag', null, 403);
            }

            $slug     = generateUniqueSlug($request->tag_name);
            $tagCheck = Tag::where(['language_id' => $languageId, 'slug' => $slug])->first();

            if ($tagCheck) {
                return ResponseService::successResponse('Tag already exists', $tagCheck);
            }

            $tag = Tag::create([
                'tag_name'    => $request->tag_name,
                'slug'        => $slug,
                'language_id' => $languageId,
            ]);

            return ResponseService::successResponse('Tag created successfully', $tag);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'NewsApiController -> createTag');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }

    public function getShortNews(Request $request) {
        try{
            $language_id = $this->resolveLanguageId($request);
            $validator = Validator::make($request->all(), [
                 'language_code' => 'required|string|exists:tbl_languages,code',
                'per_page' => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            // query in news model check where equal to is_short_news = 1 get those paginated
            $query = News::with(
                'category:id,category_name,slug',
                'sub_category:id,subcategory_name',
                'location:id,location_name,latitude,longitude',
                'images',
                'author:user_id,bio',
                'comments'
            )->where('language_id', $language_id)->where('is_short_news', 1)
            ->where('is_draft', 0)->where('status', 1);

            $count = $query->clone()->count();


            $shortNews = $query->orderBy('id', 'DESC')->limit(20)->get();

            // getting tags
            $shortNews->each(function ($item) {
                if (isset($item->tag_id) && $item->tag_id != '') {
                    $item->tag_name = Tag::whereIn('id', explode(',', $item->tag_id))->distinct()->pluck('tag_name')->implode(',');

                }

                $item->read_time = ReadTimeService::estimate($item->description);
            });

            if($count == 0){
                // message no data found
                return ResponseService::errorResponse(__('No Short News Found'), ['news' => $shortNews], 200);
            }

            return ResponseService::successResponse(__('data fetched successfully'), ['news' => $shortNews]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'NewsApiController -> createTag');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }
}
