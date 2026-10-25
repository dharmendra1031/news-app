<?php

namespace App\Http\Controllers\Api;

use App\Models\Author;
use App\Models\Podcasts;
use App\Models\PodcastEpisodes;
use App\Models\EpisodeBookmarks;
use App\Models\EpisodePlayHistory;
use App\Models\PodcastFollow;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use App\Services\PodcastNotificationService;
use App\Services\ResponseService;
use App\Services\YoutubeVideoService;
use Exception;
use getID3;

class PodcastEpisodeApiController extends BaseApiController
{

    private $episodeImagePath = 'episodes_images';
    private $episodeAudioPath = 'episodes_audio';


    // -------------------------------------------------------------------------
    // Single resource detail (public / optional-auth)
    // -------------------------------------------------------------------------

    protected function getEpisode(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'is_author_check' => 'required|in:1,0',
                'id'           => 'nullable|integer|exists:podcast_episodes,id',
                'podcast_slug' => 'required|string|exists:podcasts,slug',
                'type'         => 'required|string|in:all,bookmark,history,draft',
                'search'       => 'nullable|string|max:255',
                'limit'        => 'nullable|integer|min:1|max:100',
                'offset'       => 'nullable|integer|min:0',
                'order_column' => 'nullable|string',
                'order_by'     => 'nullable|string|in:asc,desc,ASC,DESC',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            if (!$request->filled('podcast_slug')) {
                return ResponseService::validationError(__('podcast_slug_is_required'));
            }

            $type = $request->get('type', 'all');

            if (in_array($type, ['history', 'bookmark']) && !Auth::user()) {
                return ResponseService::errorResponse(__('login_required_to_view_this_list'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $limit  = $request->has('limit') ? (int) $request->limit : 10;
            $offset = $request->has('offset') ? (int) $request->offset : 0;

            $filterEpisodes = function ($q) use ($request, $type) {

               $q->when($request->filled('type'), function ($q2) use ($request) {
                        if ($request->type === 'draft') {
                            $q2->where('draft', 1);
                        } elseif ($request->type === 'all') {
                            $q2->where('draft', 0);
                            if($request->is_author_check == 0){
                              $q2->where('status',1);
                            }
                        }
                    })
                    // ->where('draft', 0)
                    // ->where('status', 1)
                    ->where(function ($q2) use ($request) {
                        // if the user_id == Auth::id() than no date check
                        if ($request->is_author_check === 1 || $request->is_author_check === '1') {
                            return;
                        }
                        if ($request->is_author_check === 0 || $request->is_author_check === '0') {
                            $q2->whereNull('published_at')->orWhere('published_at', '<=', now());
                        }
                    })
                    ->when($request->filled('id'), function ($q2) use ($request) {
                        $q2->where('id', $request->id);
                    })
                    ->when($request->filled('search'), function ($q2) use ($request) {
                        $q2->search($request->search);
                    })
                    ->when($type === 'history', function ($q2) {
                        $q2->whereHas('playHistory', function ($q3) {
                            $q3->where('user_id', Auth::id());
                        });
                    })
                    ->when($type === 'bookmark', function ($q2) {
                        $q2->whereHas('bookmarks', function ($q3) {
                            $q3->where('user_id', Auth::id());
                        });
                    });
            };

            $podcast = Podcasts::with([
                'user:id,name,slug,profile,is_author',
                'author:user_id,bio',
                'episodes' => function ($q) use ($filterEpisodes, $request, $limit, $offset) {
                    $filterEpisodes($q);

                    $orderBy = $request->order_column;
                    $sortBy  = $request->order_by ?? 'ASC';

                    $q->safeOrder($orderBy, $sortBy)->skip($offset)->take($limit);
                },
            ])
                ->where('slug', $request->podcast_slug)->first();

            if ($podcast) {
                $podcast->is_followed = Auth::user()
                    ? PodcastFollow::where('user_id', Auth::id())->where('podcast_id', $podcast->id)->exists()
                    : false;
                
            }

            // $totalQuery = PodcastEpisodes::where('podcast_id', $podcast->id);
            // $filterEpisodes($totalQuery);
            // $total = $totalQuery->count();

            // if ($total == 0) {
            //     return ResponseService::successResponse(
            //         __('No data found')
            //     );
            // }

            return ResponseService::successResponse(__('episodes_fetched_successfully'), $podcast);
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
    // Bookmark / listening history (auth required)
    // -------------------------------------------------------------------------

    protected function toggleBookmarkEpisode(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'episode_id' => 'required|integer|exists:podcast_episodes,id',
                'status'     => 'required|in:0,1',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $episodeId = $request->episode_id;
            $status    = $request->status;

            if ($status == '1') {
                $exists = EpisodeBookmarks::where('episode_id', $episodeId)->where('user_id', Auth::id())->count('id');
                if ($exists) {
                    return ResponseService::errorResponse(__('already_bookmarked'), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'), null);
                }

                EpisodeBookmarks::create([
                    'episode_id'  => $episodeId,
                    'user_id'     => Auth::id(),
                    'followed_at' => now(),
                ]);

                return ResponseService::successResponse(__('episode_bookmarked_successfully'));
            }

            EpisodeBookmarks::where('episode_id', $episodeId)->where('user_id', Auth::id())->delete();

            return ResponseService::successResponse(__('episode_bookmark_removed_successfully'));
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

    protected function updateListeningHistory(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'episode_id'       => 'required|integer|exists:podcast_episodes,id',
                'listened_seconds' => 'required|integer|min:0',
                'completed'        => 'nullable|boolean',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $history = EpisodePlayHistory::updateOrCreate(
                [
                    'episode_id' => $request->episode_id,
                    'user_id'    => Auth::id(),
                ],
                [
                    'listened_seconds' => $request->listened_seconds,
                    'completed'        => $request->boolean('completed'),
                ]
            );

            return ResponseService::successResponse(__('listening_history_updated_successfully'), $history);
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
    // Author-only episode CRUD
    // -------------------------------------------------------------------------

    /**
     * Create or update an episode of the author's own podcast.
     * action_type: 1 = create, 2 = update.
     */
    protected function saveEpisode(Request $request, YoutubeVideoService $youtubeService)
    {
        try {
            if (!Auth::user() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('you_are_not_an_approved_author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $isUpdate = $request->input('action_type') == 2;
            $checkAutoApprove = Author::where('user_id', Auth::id())->first();

            // Determine the podcast scope for the episode_no uniqueness check
            if ($isUpdate) {
                $episodeForScope = PodcastEpisodes::find($request->episode_id);
                $podcastId = $episodeForScope ? $episodeForScope->podcast_id : null;
            } else {
                $podcastId = $request->podcast_id;
            }

            $validator = Validator::make($request->all(), [
                'action_type'    => 'required|integer|in:1,2',
                'episode_id'     => 'required_if:action_type,2|integer|exists:podcast_episodes,id',
                'podcast_id'     => 'required_if:action_type,1|integer|exists:podcasts,id',
                'episode_no'     => [
                    'required',
                    'integer',
                    Rule::unique('podcast_episodes', 'episode_no')
                        ->where('podcast_id', $podcastId)
                        ->ignore($isUpdate ? $request->episode_id : null),
                ],
                'title'          => 'required|string|max:255',
                'slug'           => ['required', 'alpha_dash', Rule::unique('podcast_episodes', 'slug')->ignore($request->episode_id)],
                'source_type'    => 'required|in:upload,youtube_link',
                'audio_url'      => $request->source_type == 'youtube_link' ? 'required|url' : 'nullable',
                'audio_file'     => (!$isUpdate && $request->source_type == 'upload')
                    ? 'required|file|mimes:mp3,wav,m4a,ogg,aac|max:20480'
                    : 'nullable|file|mimes:mp3,wav,m4a,ogg,aac|max:20480',
                'image'          => ($isUpdate ? 'nullable' : 'required') . '|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
                'published_date' => 'required|date',
                'description'    => 'nullable|string',
                'is_draft'       => 'nullable|boolean',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            if ($isUpdate) {
                $episode = PodcastEpisodes::where('id', $request->episode_id)
                    ->whereHas('podcast', function ($q) {
                        $q->where('user_id', Auth::id());
                    })
                    ->first();

                if (!$episode) {
                    return ResponseService::errorResponse(__('episode_not_found_or_not_yours'), null, config('constants.RESPONSE_CODE.EMPTY_DATA'));
                }
            } else {
                $podcast = Podcasts::where('id', $request->podcast_id)->where('user_id', Auth::id())->first();

                if (!$podcast) {
                    return ResponseService::errorResponse(__('podcast_not_found_or_not_yours'), null, config('constants.RESPONSE_CODE.EMPTY_DATA'));
                }

                $episode = new PodcastEpisodes();
                $episode->podcast_id = $podcast->id;
            }

            $episode->episode_no = $request->episode_no;
            $episode->title = $request->title;
            $episode->slug = $request->slug;
            $episode->source_type = $request->source_type;

            if ($request->source_type === 'youtube_link') {

                $duration = $youtubeService->getDurationInSeconds($request->audio_url);

                if ($duration === null) {
                    return ResponseService::errorResponse(__('unable_to_fetch_youtube_video_duration'), null, config('constants.RESPONSE_CODE.VALIDATION_ERROR'));
                }

                // Remove old uploaded audio if switching to YouTube (no-op on create - no audio_url yet)
                $rawAudio = $episode->getRawOriginal('audio_url');
                if (!empty($rawAudio) && str_starts_with($rawAudio, 'storage/')) {
                    $oldAudioPath = substr($rawAudio, strlen('storage/'));

                    if (Storage::disk('public')->exists($oldAudioPath)) {
                        Storage::disk('public')->delete($oldAudioPath);
                    }
                }

                $episode->audio_url = $request->audio_url;
                $episode->duration_seconds = $duration;
            } else {

                if ($request->hasFile('audio_file')) {

                    $rawAudio = $episode->getRawOriginal('audio_url');
                    $oldAudioPath = (!empty($rawAudio) && str_starts_with($rawAudio, 'storage/'))
                        ? substr($rawAudio, strlen('storage/'))
                        : null;

                    $audioFile = $request->file('audio_file');

                    $getID3 = new getID3();
                    $fileInfo = $getID3->analyze($audioFile->getRealPath());

                    $episode->duration_seconds = isset($fileInfo['playtime_seconds'])
                        ? (int) round($fileInfo['playtime_seconds'])
                        : 0;

                    $episode->audio_url = 'storage/' . compressAndReplace($audioFile, $this->episodeAudioPath, $oldAudioPath);
                }
            }

            // Update image if uploaded (no-op on create until the file below is stored)
            if ($request->hasFile('image')) {

                $oldImagePath = !empty($episode->getRawOriginal('image')) ? str_replace('storage/', '', $episode->getRawOriginal('image')) : null;

                $episode->image = 'storage/' . compressAndReplace($request->file('image'), $this->episodeImagePath, $oldImagePath);
            }

            $episode->published_at = date('Y-m-d', strtotime($request->published_date));
            $episode->description = $request->description ?: ' ';
            $episode->status = $checkAutoApprove && $checkAutoApprove->auto_approve ? 1 : 0;
            $episode->draft = $request->boolean('is_draft');

            $episode->save();

            if (!$isUpdate && $episode->status == 1) {
                app(PodcastNotificationService::class)->notifyFollowers($episode->podcast, $episode);
            }

            return ResponseService::successResponse(
                $isUpdate ? __('episode_updated_successfully') : __('episode_created_successfully'),
                $episode
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

    protected function deleteEpisode(Request $request)
    {
        try {
            if (!Auth::user() || Auth::user()->is_author != 1) {
                return ResponseService::errorResponse(__('you_are_not_an_approved_author'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'));
            }

            $validator = Validator::make($request->all(), [
                'episode_id' => 'required|integer|exists:podcast_episodes,id',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $episode = PodcastEpisodes::where('id', $request->episode_id)
                ->whereHas('podcast', function ($q) {
                    $q->where('user_id', Auth::id());
                })
                ->first();

            if (!$episode) {
                return ResponseService::errorResponse(__('episode_not_found_or_not_yours'), null, config('constants.RESPONSE_CODE.EMPTY_DATA'));
            }

            // Delete the episode image if it exists
            $rawImage = $episode->getRawOriginal('image');
            if (!empty($rawImage)) {
                $path = str_starts_with($rawImage, 'storage/') ? substr($rawImage, strlen('storage/')) : $rawImage;
                if (Storage::disk('public')->exists($path)) {
                    Storage::disk('public')->delete($path);
                }
            }

            // Delete the episode audio file if it exists (skip remote URLs e.g. YouTube)
            if ($episode->source_type !== 'youtube_link') {
                $rawAudio = $episode->getRawOriginal('audio_url');
                if (!empty($rawAudio) && !filter_var($rawAudio, FILTER_VALIDATE_URL)) {
                    $path = str_starts_with($rawAudio, 'storage/') ? substr($rawAudio, strlen('storage/')) : $rawAudio;
                    if (Storage::disk('public')->exists($path)) {
                        Storage::disk('public')->delete($path);
                    }
                }
            }

            $episode->delete();

            return ResponseService::successResponse(__('episode_deleted_successfully'));
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


    protected function myEpisodes(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type'         => 'required|string|in:bookmark,history',
            'search'       => 'nullable|string|max:255',
            'limit'        => 'nullable|integer|min:1|max:100',
            'offset'       => 'nullable|integer|min:0',
            'order_column' => 'nullable|string',
            'order_by'     => 'nullable|string|in:asc,desc,ASC,DESC',
        ]);

        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }
        try {

            $type   = $request->get('type', 'bookmark');
            $limit  = $request->has('limit') ? (int) $request->limit : 10;
            $offset = $request->has('offset') ? (int) $request->offset : 0;

            $filterEpisodes = function ($q) use ($request) {
                $q->where('draft', 0)
                    ->where('status', 1)
                    ->where(function ($q2) {
                        $q2->whereNull('published_at')->orWhere('published_at', '<=', now());
                    })
                    ->when($request->filled('search'), function ($q2) use ($request) {
                        $q2->search($request->search);
                    });
            };

            $model = $type === 'history' ? EpisodePlayHistory::class : EpisodeBookmarks::class;

            $records = $model::where('user_id', Auth::id())
                ->whereHas('episode', $filterEpisodes)
                ->with(['episode.podcast:id,slug']);

            $total = $records->count();

            if ($total == 0) {
                return ResponseService::successResponse(
                    __('No data found')
                );
            }

            $records = $records->safeOrder($request->order_column, $request->order_by ?? 'DESC')
                ->skip($offset)
                ->take($limit)
                ->get();

            $episodes = $records->pluck('episode')->filter()->values();

            return ResponseService::successResponse(__('episodes_retrieved_successfully'),
            [
                'episodes' => $episodes,
                'total'    => $total,
            ]);

        } catch (Exception $e) {
            ResponseService::logErrorResponse($e);
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }
}
