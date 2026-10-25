<?php

namespace App\Http\Controllers\Api;

use App\Models\Language;
use App\Models\Category;
use App\Models\VideoShortComment;
use App\Models\VideoShortLike;
use App\Models\VideoShort;
use App\Models\UserCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;
use App\Services\ResponseService;
use Exception;
use Illuminate\Support\Facades\DB;

class VideoShortsApiController extends BaseApiController
{
     
    protected function getVideoShorts(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'category_id' => 'nullable|integer|exists:tbl_category,id',
                'limit'       => 'nullable|integer|min:1|max:100',
                'offset'      => 'nullable|integer|min:0',
                'slug'        => 'nullable|string|exists:video_shorts,slug',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            // Resolve the language for this request after validation.
            $languageId = $this->resolveLanguageId($request);

            // 2. Bound pagination limits strictly between 10 and 100
            $limit = $request->has('limit') ? (int)$request->limit : 10;
            $offset = $request->has('offset') ? (int)$request->offset : 0;


            $excludedFields = [
                    // 'language_id',
                    // 'category_id',
                    // 'status',
            ];
            $columns = array_diff(
                Schema::getColumnListing('video_shorts'),
                $excludedFields
            );

            $user   = Auth::user();
            $userId = $user?->id;

            $query = VideoShort::select($columns)
                ->withCount(['comments' => function ($q) {
                    $q->where('status', 1);
                }])
                ->withCount(['likes as total_like_count' => function ($q) {
                    $q->where('like', 1);
                }])
                ->where('language_id', $languageId)
                ->where('status', 1);

            // Branch A: language-scoped request -> language + preferred categories.
            // Branch B: no language_code -> fully random across everything.

            // user id than only
            if($userId){

                $preferredIds = $this->preferredCategoryIds($userId, $languageId);
                if (!empty($preferredIds)) {
                    $preferredQuery = (clone $query)->whereIn('category_id', $preferredIds);

                    // Empty-preference fallback: only narrow to preferred
                    // categories if that actually yields rows; otherwise
                    // stay language-only so the feed is never empty.
                    if ($preferredQuery->count() > 0) {
                        $query = $preferredQuery;
                    }
                }
            }


            if($request->slug) {
                $query->where('slug', $request->slug);
            }

            $total = $query->count();

            if ($total == 0) {
                // No results for the slug/preference filter — fall back to
                // any active video shorts in the requested language. We keep
                // the language scope so callers always get language-specific
                // results (or an empty set), never cross-language rows.
                $query = VideoShort::select($columns)
                    ->withCount(['comments' => function ($q) {
                        $q->where('status', 1);
                    }])
                    ->withCount(['likes as total_like_count' => function ($q) {
                        $q->where('like', 1);
                    }])
                    ->where('language_id', $languageId)
                    ->where('status', 1);
                $total = $query->count();
            }

            if ($total == 0) {
                return ResponseService::successResponse(
                    __('No data found'),
                    [
                        'total' => $total,
                        'data'  => [],
                    ]
                );
            }

            $data = $query->inRandomOrder()
                ->skip($offset)
                ->take($limit)
                ->get();

            $data->transform(function ($videoShort) use ($userId) {

                // Attach per-user like / dislike status
                $reaction = $userId
                    ? VideoShortLike::where('video_shorts_id', $videoShort->id)
                          ->where('user_id', $userId)
                          ->first()
                    : null;

                $videoShort->is_liked    = (bool) ($reaction?->like ?? false);
                $videoShort->is_disliked = (bool) ($reaction?->dislike ?? false);

                return $videoShort;
            });

            return ResponseService::successResponse(
                __('data fetched successfully'),
                [
                    'total' => $total,
                    'data'  => $data,
                ]
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }

    /**
     * Resolve a user's preferred category IDs.
     *
     * tbl_users_category stores one row per user with a comma-separated
     * category_id list. category_id == '0' (or no row) means "no preference".
     */
    private function preferredCategoryIds(?int $userId, ?int $languageId = null): array
    {
        if (!$userId) {
            return [];
        }

        $stored = UserCategory::where('user_id', $userId)->value('category_id');

        if ($stored === null || $stored === '' || (string) $stored === '0') {
            return [];
        }

        $ids = array_values(array_filter(array_map(
            'intval',
            array_map('trim', explode(',', (string) $stored))
        )));

        if (empty($ids) || !$languageId) {
            return $ids;
        }

        // tbl_users_category stores category IDs across all languages, but
        // each tbl_category row is language-scoped. Narrow to categories that
        // actually belong to the requested language so the feed query never
        // mixes languages via preferences.
        return Category::whereIn('id', $ids)
            ->where('language_id', $languageId)
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->values()
            ->all();
    }

    protected function setVideoshortLikeDislike(Request $request)
    {
        try {

            $validator = Validator::make($request->all(), [
                'video_shorts_id' => 'required|integer|exists:video_shorts,id',
                'action'          => 'required|string|in:like,dislike',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $videoId = $request->video_shorts_id;
            $action = $request->action;
            $oppositeAction = ($action === 'like') ? 'dislike' : 'like';

            $user = Auth::guard('sanctum')->user();

            $userId = $user->id;
            $reaction = VideoShortLike::firstOrNew([
                'video_shorts_id' => $videoId,
                'user_id'         => $userId,
            ]);

            $message = '';

            if ($reaction->$action) {
                $reaction->$action = false;
                $message = ($action === 'like') ? __('like_removed_successfully') : __('dislike_removed_successfully');
            } else {
                $reaction->$action = true;
                $message = ($action === 'like') ? __('video_liked_successfully') : __('video_disliked_successfully');

                if ($reaction->$oppositeAction) {
                    $reaction->$oppositeAction = false;
                }
            }

            if (!$reaction->like && !$reaction->dislike) {
                if ($reaction->exists) {
                    $reaction->delete();
                }
            } else {
                $reaction->save();
            }

            return ResponseService::successResponse(
                $message,
                [
                    'is_liked'    => (bool)$reaction->like,
                    'is_disliked' => (bool)$reaction->dislike,
                ]
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }

    protected function setVideoShortsComment(Request $request)
    {
        try {
            // 1. Validate the payload inputs
            $validator = Validator::make($request->all(), [
                'video_shorts_id' => 'required|integer|exists:video_shorts,id',
                'comment'         => 'required|string|max:1000',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user = Auth::guard('sanctum')->user();
            if (!$user) {
                return ResponseService::errorResponse(__('unauthorized_please_login_to_count_your_view'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }
            $userId = $user ? $user->id : 0;

            $comment = VideoShortComment::create([
                'video_shorts_id' => $request->video_shorts_id,
                'user_id'         => $userId,
                'comment'         => $request->comment,
            ]);

            return ResponseService::successResponse(
                __('comment_posted_successfully'),
                $comment
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }

    protected function getVideoShortsComment(request $request)
    {
        try {

            $validator = Validator::make($request->all(), [
                'video_shorts_id' => 'required|integer|exists:video_shorts,id',
                'limit' => 'nullable|integer|min:1|max:100',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $limit   = $request->limit ?? 10;

            $query = VideoShortComment::with('user:id,name,slug,profile,is_author')->where('video_shorts_id', $request->video_shorts_id)
                ->where('status', 1);

            $total = $query->count();

            if ($total === 0) {
                return ResponseService::errorResponse(
                    __('no_comments_found'),
                    null,
                    config('constants.RESPONSE_CODE.SUCCESS')
                );
            }

            $comments = $query->paginate($limit);

            return ResponseService::successResponse(
                __('comments_fetched_successfully'),
                [
                    'total' => $total,
                    'data'  => $comments,
                ]
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }
    protected function setVideoShortShareCount(request $request)
    {
        try {
            // 1. Validate that the video short exists
            $validator = Validator::make($request->all(), [
                'video_shorts_id' => 'required|integer|exists:video_shorts,id',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $videoId = $request->video_shorts_id;

            // 2. Perform an optimized database update statement directly
            $updated = VideoShort::where('id', $videoId)->increment('shares_count');

            if (!$updated) {
                return ResponseService::errorResponse(
                    __('video_short_not_found'),
                    null,
                    config('constants.RESPONSE_CODE.EMPTY_DATA')
                );
            }

            // 3. Return only the requested fields
            return ResponseService::successResponse(
                __('share_count_incremented_successfully'),
                [
                    'video_shorts_id' => (int)$videoId,
                    'incremented'     => true
                ]
            );
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }
    protected function setVideoShortsViewCount(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'video_shorts_id' => 'required|integer|exists:video_shorts,id',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            // If the admin has enabled "auth-only views" mode, reject unauthenticated requests
            $authModeEnabled = (bool) getSettingMode('auth_short_video_views');

            if ($authModeEnabled) {
                $user = Auth::user();
                if (!$user) {
                    // return ResponseService::errorResponse(
                    //     __('unauthorized_please_login_to_count_your_view'),
                    //     null,
                    //     config('constants.RESPONSE_CODE.UNAUTHORIZED') ?? 401
                    // );
                    return ResponseService::successResponse(__('unauthorized_please_login_to_count_your_view'));
                }
            }

            $videoId = $request->video_shorts_id;

            $updated = VideoShort::where('id', $videoId)->increment('views_count');

            if (!$updated) {
                return ResponseService::errorResponse(
                    __('video_short_not_found'),
                    null,
                    config('constants.RESPONSE_CODE.EMPTY_DATA')
                );
            }

            return ResponseService::successResponse(
                __('view_count_incremented_successfully'),
                [
                    'video_shorts_id' => (int) $videoId,
                    'incremented'     => true,
                ]
            );

        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(
                __('Something Went Wrong'),
                null,
                config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
                $e
            );
        }
    }
}
