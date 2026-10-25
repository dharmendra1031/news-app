<?php

namespace App\Http\Controllers\Api;

use App\Models\Bookmark;
use App\Models\News;
use App\Models\News_image;
use App\Models\News_like;
use App\Services\ReadTimeService;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BookmarkLikeApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Bookmarks
    // -------------------------------------------------------------------------

    public function getBookmark(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = $this->resolveLanguageId($request);
            $user_id     = Auth::user()->id;
            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;

            $news = DB::table('tbl_bookmark as b')
                ->select(
                    'b.*',
                    'n.category_id', 'c.category_name',
                    'n.subcategory_id', 'n.language_id',
                    'n.title', 'n.slug', 'n.date', 'n.published_date',
                    'n.show_till', 'n.is_comment', 'n.tag_id',
                    'n.content_type', 'n.content_value', 'n.image', 'n.description'
                )
                ->join('tbl_news as n', 'b.news_id', '=', 'n.id')
                ->join('tbl_category as c', 'c.id', '=', 'n.category_id')
                ->where(function ($query) {
                    $query->where('n.show_till', '>=', $this->toDate)->orWhere('n.show_till', '0000-00-00');
                })
                ->where('b.user_id', $user_id)
                ->where('n.status', 1)
                ->where(function ($q) {
                    $q->where(function ($subq) {
                        $subq->whereNotNull('n.published_date')
                            ->where('n.published_date', '<=', $this->toDate);
                    })->orWhere(function ($subq) {
                        $subq->whereNull('n.published_date')
                            ->whereDate('n.created_at', '<=', $this->toDate);
                    });
                })
                ->where('n.language_id', $language_id);

            $total = $news->clone()->count();

            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'));
            }

            $data = $news->clone()->limit($limit)->offset($offset)->orderBy('id', 'DESC')->get();

            foreach ($data as $item) {
                $item = $this->getNewsData($item, $item->news_id);

                $image = (($item->image) && strpos($item->image, 'news/') === false)
                    ? 'news/' . $item->image
                    : $item->image;

                $item->image = ($item->image) && Storage::disk('public')->exists($image)
                    ? url(Storage::url($image))
                    : '';

                if ($item->content_type == 'video_upload') {
                    $item->content_value = $this->resolveNewsVideoUrl($item->content_value);
                }

                $item->image_data = News_image::where('news_id', $item->news_id)->get();
                $item->read_time = ReadTimeService::estimate($item->description);
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $data,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'BookmarkLikeApiController -> getBookmark');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setBookmark(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id' => ['required', 'numeric', 'exists:tbl_news,id'],
                'status'  => ['required', 'numeric', 'in:0,1'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id = Auth::user()->id;
            $news_id = $request->news_id;
            $status  = $request->status;

            if ($status == '1') {
                $exists = Bookmark::where('user_id', $user_id)->where('news_id', $news_id)->count('id');
                if ($exists) {
                    return ResponseService::errorResponse(__('Already bookmark'), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), null);
                }
                Bookmark::create(['user_id' => $user_id, 'news_id' => $news_id]);

                return ResponseService::successResponse(__('Bookmark successfully'));
            }

            Bookmark::where('user_id', $user_id)->where('news_id', $news_id)->delete();

            return ResponseService::successResponse(__('Bookmark removed successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'BookmarkLikeApiController -> setBookmark');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Likes
    // -------------------------------------------------------------------------

    public function getLike(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = $this->resolveLanguageId($request);
            $user_id     = Auth::user()->id;
            $offset      = $request->offset ?? 0;
            $limit       = $request->limit ?? 10;

            $news = DB::table('tbl_news_like as l')
                ->select(
                    'l.*',
                    'n.category_id', 'c.category_name',
                    'n.title', 'n.slug', 'n.date', 'n.published_date',
                    'n.show_till', 'n.tag_id', 'n.content_type', 'n.content_value',
                    'n.image', 'n.description'
                )
                ->join('tbl_news as n', 'n.id', '=', 'l.news_id')
                ->join('tbl_category as c', 'c.id', '=', 'n.category_id')
                ->where(function ($query) {
                    $query->where('n.show_till', '>=', $this->toDate)->orWhere('n.show_till', '0000-00-00');
                })
                ->where('l.user_id', $user_id)
                ->where('l.status', 1)
                ->where(function ($q) {
                    $q->where(function ($subq) {
                        $subq->whereNotNull('n.published_date')
                            ->where('n.published_date', '<=', $this->toDate);
                    })->orWhere(function ($subq) {
                        $subq->whereNull('n.published_date')
                            ->whereDate('n.created_at', '<=', $this->toDate);
                    });
                })
                ->where('n.language_id', $language_id);

            $total = $news->clone()->count();

            if ($total == 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $data = $news->clone()->limit($limit)->offset($offset)->orderBy('l.id', 'DESC')->get();

            foreach ($data as $item) {
                $item = $this->getNewsData($item, $item->news_id);
                $item->image_data = News_image::where('news_id', $item->news_id)->get();

                $image = (($item->image) && strpos($item->image, 'news/') === false)
                    ? 'news/' . $item->image
                    : $item->image;

                $item->image = ($item->image) && Storage::disk('public')->exists($image)
                    ? url(Storage::url($image))
                    : '';
            }

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $data,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'BookmarkLikeApiController -> getLike');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setLikeDislike(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id' => ['required', 'numeric', 'exists:tbl_news,id'],
                'status'  => ['required', 'numeric', 'in:0,1,2'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id = Auth::user()->id;
            $news_id = $request->news_id;
            $status  = $request->status;

            if ($status != '0') {
                $news_like = News_like::where('news_id', $news_id)->where('user_id', $user_id)->first();
                if ($news_like) {
                    $news_like->status = $status;
                    $news_like->save();
                } else {
                    News_like::create([
                        'status'  => $status,
                        'user_id' => $user_id,
                        'news_id' => $news_id,
                    ]);
                }
            } else {
                News_like::where('news_id', $news_id)->where('user_id', $user_id)->delete();
            }

            $news = News::with('category', 'images')->where('id', $news_id)->first();
            $total_like = News_like::where('news_id', $news_id)
                ->where('status', 1)
                ->count();
            $news['total_like'] = $total_like ?? 0;

            return ResponseService::successResponse(__('Updated successfully!'), $news);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'BookmarkLikeApiController -> setLikeDislike');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }
}
