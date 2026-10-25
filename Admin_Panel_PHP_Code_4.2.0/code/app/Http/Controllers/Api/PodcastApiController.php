<?php

namespace App\Http\Controllers\Api;

use App\Models\Author;
use App\Models\Podcasts;
use App\Models\PodcastFollow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use App\Services\ResponseService;
use Exception;

class PodcastApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Single resource detail (public / optional-auth)
    // -------------------------------------------------------------------------

    protected function getPodcast(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'type'         => 'required|string|in:all,history,bookmark',
                'slug'         => 'nullable|string|exists:podcasts,slug',
                'user_id'      => 'nullable|integer|exists:tbl_users,id',
                'search'       => 'nullable|string|max:255',
                'limit'        => 'nullable|integer|min:1|max:100',
                'order_column' => 'nullable|string',
                'order_by'     => 'nullable|string|in:asc,desc,ASC,DESC',
                'offset'       => 'nullable|integer|min:0',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $type = $request->get('type', 'all');

            if (in_array($type, ['history', 'bookmark']) && !Auth::user()) {
                return ResponseService::errorResponse(__('login_required_to_view_this_list'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $limit  = $request->has('limit') ? (int) $request->limit : 10;
            $offset = $request->has('offset') ? (int) $request->offset : 0;

            $query = Podcasts::with([
                'user:id,name,slug,profile,is_author',
                // 'episodes',
                'author:user_id,bio',
            ])
                ->whereHas('episodes', function ($q){
                    $q->where('status','1');
                })
                ->where('draft', 0)
                ->where('status', 1)
                // ->where(function ($q) {
                //     $q->whereNull('published_at')->orWhere('published_at', '<=', now());
                // })
                ->when($request->filled('slug'), function ($q) use ($request) {
                    $q->where('slug', $request->slug);
                })
                ->when($request->filled('user_id'), function ($q) use ($request) {
                    $q->where('user_id', $request->user_id);
                })
                ->when($request->filled('search'), function ($q) use ($request) {
                    $q->search($request->search);
                })
                ->when($type === 'history', function ($q) {
                    $q->whereHas('episodes.playHistory', function ($q) {
                        $q->where('user_id', Auth::id());
                    });
                })
                ->when($type === 'bookmark', function ($q) {
                    $q->whereHas('episodes.bookmarks', function ($q) {
                        $q->where('user_id', Auth::id());
                    });
                });

            $total = $query->count();

            if ($total == 0) {
                return ResponseService::successResponse(
                    __('No data found'),
                    [
                        'total' => 0,
                        'data'  => [],
                    ]
                );
            }

            $orderBy = $request->order_column;
            $sortBy  = $request->order_by ?? 'DESC';

            $data = $query->safeOrder($orderBy, $sortBy)
                ->skip($offset)
                ->take($limit)
                ->get();

            $followedIds = Auth::user()
                ? PodcastFollow::where('user_id', Auth::id())->whereIn('podcast_id', $data->pluck('id'))->pluck('podcast_id')->all()
                : [];

            $data->each(function ($podcast) use ($followedIds) {
            $podcast->is_followed = in_array($podcast->id, $followedIds);
        });

            return ResponseService::successResponse(
                __('podcasts_fetched_successfully'),
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

    // -------------------------------------------------------------------------
    // Follow (auth required)
    // -------------------------------------------------------------------------

    protected function toggleFollowPodcast(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'podcast_id' => 'required|integer|exists:podcasts,id',
                'status'     => 'required|in:0,1',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $podcastId = $request->podcast_id;
            $status    = $request->status;


            // need to checkthe request user is not the author/owner of podcast than not allowed to follow its own podcast
            $podcast = Podcasts::find($podcastId);


            if ($podcast->user_id == Auth::id()) {
                return ResponseService::errorResponse(__('you_cannot_follow_your_own_podcast'), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), null);
            }


            if ($status == '1') {
                $exists = PodcastFollow::where('podcast_id', $podcastId)->where('user_id', Auth::id())->count('id');
                if ($exists) {
                    return ResponseService::errorResponse(__('already_following'), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), null);
                }

                PodcastFollow::create([
                    'podcast_id'  => $podcastId,
                    'user_id'     => Auth::id(),
                    'followed_at' => now(),
                ]);

                return ResponseService::successResponse(__('podcast_followed_successfully'));
            }

            PodcastFollow::where('podcast_id', $podcastId)->where('user_id', Auth::id())->delete();

            return ResponseService::successResponse(__('podcast_unfollowed_successfully'));
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

    // -------------------------------------------------------------------------
    // Author-only podcast CRUD
    // -------------------------------------------------------------------------

    /**
     * Create or update the author's own podcast.
     * action_type: 1 = create, 2 = update.
     */
    protected function savePodcast(Request $request)
    {
        try {
            // dd(Auth::user());
            // author table auto_approve not true
            if (!Auth::user() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('you_are_not_an_author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $isUpdate = $request->input('action_type') == 2;

            $validator = Validator::make($request->all(), [
                'action_type'    => 'required|integer|in:1,2',
                'id'             => 'required_if:action_type,2|integer|exists:podcasts,id',
                'title'          => 'required|string|max:255',
                'slug'           => ['required', 'alpha_dash', Rule::unique('podcasts', 'slug')->ignore($request->id)],
                'description'    => 'nullable|string',
                'published_date' => 'nullable|date',
                'image'          => ($isUpdate ? 'nullable' : 'required') . '|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
                'draft'          => 'nullable|boolean',
                'meta_title'       => 'nullable|string',
                'meta_description' => 'nullable|string',
                'meta_keyword'     => 'nullable|string',
                'schema_markup'    => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            if ($isUpdate) {
                $podcast = Podcasts::where('id', $request->id)->where('user_id', Auth::id())->first();

                if (!$podcast) {
                    return ResponseService::errorResponse(__('podcast_not_found_or_not_yours'), null, config('constants.RESPONSE_CODE.EMPTY_DATA'));
                }
            } else {
                $podcast = new Podcasts();
                $podcast->user_id = Auth::id();
            }

            $checkAutoApprove = Author::where('user_id', Auth::id())->first();

            $podcast->title = $request->title;
            $podcast->slug = $request->slug;
            $podcast->description = $request->description;
            $podcast->published_at = $request->published_date ? date('Y-m-d', strtotime($request->published_date)) : null;
            $podcast->status = $checkAutoApprove && $checkAutoApprove->auto_approve ? 1 : 0;
            $podcast->draft = $request->boolean('draft');
            $podcast->meta_title = $request->meta_title ?? null;
            $podcast->meta_description = $request->meta_description ?? null;
            $podcast->meta_keyword = $request->meta_keyword ?? null;
            $podcast->schema_markup = $request->schema_markup ?? null;

            if ($request->hasFile('image')) {
                if (!empty($podcast->image)) {
                    $oldImagePath = 'public/' . str_replace('storage/', '', $podcast->image);
                    if (Storage::exists($oldImagePath)) {
                        Storage::delete($oldImagePath);
                    }
                }

                $path = $request->file('image')->store('podcasts', 'public');
                $podcast->image = $path;
            }

            $podcast->save();

            return ResponseService::successResponse(
                $isUpdate ? __('podcast_updated_successfully') : __('podcast_created_successfully'),
                $podcast
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

    protected function deletePodcast(Request $request)
    {
        try {
            if (!Auth::user() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('you_are_not_an_approved_author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $validator = Validator::make($request->all(), [
                'id' => 'required|integer|exists:podcasts,id',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $podcast = Podcasts::where('id', $request->id)->where('user_id', Auth::id())->first();

            if (!$podcast) {
                return ResponseService::errorResponse(__('podcast_not_found_or_not_yours'), null, config('constants.RESPONSE_CODE.EMPTY_DATA'));
            }

            if (!empty($podcast->image)) {
                $imagePath = 'public/' . str_replace('storage/', '', $podcast->image);
                if (Storage::exists($imagePath)) {
                    Storage::delete($imagePath);
                }
            }

            $podcast->delete();

            return ResponseService::successResponse(__('podcast_deleted_successfully'));
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

    protected function myPodcasts(Request $request)
    {
        try {
            if (!Auth::user() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('you_are_not_an_approved_author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $validator = Validator::make($request->all(), [
                'podcast_slug' => 'nullable|string|exists:podcasts,slug',
                'type'         => 'required|string|in:all,draft',
                'search'       => 'nullable|string',
                'limit'        => 'nullable|integer|min:1|max:100',
                'offset'       => 'nullable|integer|min:0',
                'order_column' => 'nullable|string',
                'order_by'     => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $limit  = $request->has('limit') ? (int) $request->limit : 10;
            $offset = $request->has('offset') ? (int) $request->offset : 0;

            $query = Podcasts::where('user_id', Auth::id())
                ->when($request->filled('type'), function ($query) use ($request) {
                    if ($request->type === 'draft') {
                        $query->where('draft', 1);
                    } elseif ($request->type === 'all') {
                        $query->where('draft', 0);
                    }
                })
                ->when($request->has('podcast_slug'), function ($query) use ($request) {
                    $query->where('slug', $request->input('podcast_slug'));
                })
                ->when($request->filled('search'), function ($query) use ($request) {
                    $query->search($request->search);
                });

            $total = $query->count();

            if ($total == 0) {
                return ResponseService::successResponse(
                    __('No data found'),
                    [
                        'total' => 0,
                        'data'  => [],
                    ]
                );
            }

            $orderBy = $request->order_column;
            $sortBy  = $request->order_by ?? 'DESC';

            $data = $query->safeOrder($orderBy, $sortBy)
                ->skip($offset)
                ->take($limit)
                ->get();
              $data->each(function ($podcast) {
                 $podcast->usedepisodenumbers = $podcast->episodes()->pluck('episode_no')->all();
              });
             
            return ResponseService::successResponse(
                __('podcasts_fetched_successfully'),
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
}
