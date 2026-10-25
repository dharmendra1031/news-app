<?php

namespace App\Http\Controllers;

use App\Services\ResponseService;
use Illuminate\Http\Request;
use App\Models\Podcasts;
use App\Models\PodcastEpisodes;
use App\Services\PodcastNotificationService;
use App\Services\ValidationService;
use App\Services\YoutubeVideoService;
use Exception;
use getID3;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class PodcastController extends Controller
{
    private $episodeImagePath = 'episodes_images';
    private $episodeAudioPath = 'episodes_audio';

    /**
     * Delete a stored file from the public disk.
     * Accepts raw paths or paths prefixed with 'storage/'.
     */
    private function deleteStorageFile($rawPath): void
    {
        if (empty($rawPath)) {
            return;
        }

        $path = str_starts_with($rawPath, 'storage/') ? substr($rawPath, strlen('storage/')) : $rawPath;

        if (Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['podcast-list', 'podcast-create', 'podcast-edit', 'podcast-delete']);
        return view('podcast.index');
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request)
    {
        $offset = $request->input('offset', 0);
        $limit  = $request->input('limit', 10);
        $sort   = $request->input('sort', 'id');
        $order  = $request->input('order', 'DESC');
        $search = $request->input('search');

        // withCount avoids loading every episode row just to display its count
        $query = Podcasts::with('user:id,name')->withCount('episodes');

        if ($request->filled('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', '%' . $search . '%')
                    ->orWhere('slug', 'like', '%' . $search . '%');
            });
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $total = $query->count();
        $rows  = $query->orderBy($sort, $order)
            ->skip($offset)
            ->take($limit)
            ->get();

        $rows->transform(function ($row) {
            $edit   = '';
            $delete = '';
            if (auth()->user()->can('podcast-edit')) {
                $edit = '<a href="javascript:void(0)" class="dropdown-item podcast-edit" data-id="' . $row->id . '" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            if (auth()->user()->can('podcast-delete')) {
                $delete = '<a data-url="' . route('podcast.destroy', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = ($edit === '' && $delete === '') ? '-' :
                '<div class="dropdown">
                        <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-container="body">
                            <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                        </a>
                        <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">' .
                $edit . $delete .
                '</div>
                    </div>';

            return [
                'id'           => $row->id,
                'user_name'    => optional($row->user)->name ?? '-',
                'title'        => $row->title,
                'slug'         => $row->slug,
                'description'  => $row->description,
                'image'        => $row->image,
                'draft'        => $row->draft,
                'status'       => $row->status,
                'published_at' => $row->published_at,
                'episodes'     => '<a href="' . route('podcast.episodes', $row->id) . '" class="btn btn-sm btn-success"><i class="fa fa-plus mr-1"></i>' . $row->episodes_count . '</a>',
                'operate'      => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows'  => $rows,
        ]);
    }
    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        try {
            ResponseService::noPermissionThenRedirect('podcast-create');

            $validator = Validator::make($request->all(), [
                'title'          => 'required|string|max:255',
                'slug'           => 'required|alpha_dash|unique:podcasts,slug',
                'des'            => 'nullable|string',
                'published_date' => 'nullable|date',
                'status'         => 'required|boolean',
                'image'          => 'required|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
            ]);

            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            $imagePath = null;
            if ($request->hasFile('image')) {
                $file     = $request->file('image');
                $filename = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $imagePath = $file->storeAs('podcasts', $filename, 'public');
            }

            Podcasts::create([
                'user_id'      => null,
                'title'        => $request->title,
                'slug'         => $request->slug,
                'description'  => $request->des,
                'published_at' => $request->published_date,
                'status'       => $request->status,
                'draft'        => $request->boolean('draft_switch'),
                'image'        => $imagePath,
            ]);

            return ResponseService::successResponse(__('podcast_created_successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, "PodcastController -> store");
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }


    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, $id)
    {
        try {
            ResponseService::noPermissionThenRedirect('podcast-edit');

            $validator = Validator::make($request->all(), [
                'title'          => 'required|string|max:255',
                'slug'           => 'required|alpha_dash|unique:podcasts,slug,' . $id,
                'des'            => 'nullable|string',
                'published_date' => 'nullable|date',
                'status'         => 'required|boolean',
                'image'          => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
            ]);

            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            $podcast = Podcasts::findOrFail($id);
            $imagePath = $podcast->getRawOriginal('image');

            if ($request->hasFile('image')) {
                $this->deleteStorageFile($imagePath);
                $imagePath = $request->file('image')->store('podcasts', 'public');
            }

            $podcast->update([
                'title'        => $request->title,
                'slug'         => $request->slug,
                'description'  => $request->des,
                'published_at' => $request->published_date
                    ? date('Y-m-d', strtotime($request->published_date))
                    : null,
                'status'       => $request->status,
                'draft'        => $request->boolean('draft_switch'),
                'image'        => $imagePath,
            ]);

            return ResponseService::successResponse(__('updated_success'));
        } catch (\Exception $e) {
            ResponseService::logErrorResponse($e, "PodcastController -> update");
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }

    public function destroy(Podcasts $podcast)
    {
        try {
            // Delete files of all episodes belonging to this podcast
            $episodes = PodcastEpisodes::where('podcast_id', $podcast->id)
                ->toBase()
                ->get(['image', 'audio_url', 'source_type']);

            foreach ($episodes as $episode) {
                $this->deleteStorageFile($episode->image);

                // Delete uploaded audio file only (skip remote URLs e.g. YouTube)
                if ($episode->source_type !== 'youtube_link'
                    && !filter_var($episode->audio_url, FILTER_VALIDATE_URL)) {
                    $this->deleteStorageFile($episode->audio_url);
                }
            }

            // Delete the podcast image
            $this->deleteStorageFile($podcast->getRawOriginal('image'));

            PodcastEpisodes::where('podcast_id', $podcast->id)->delete();
            $podcast->delete();

            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            ResponseService::logErrorResponse($e, "PodcastController -> destroy");
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }

    /**
     * Display the episodes list for a podcast.
     */
    public function showEpisode($podcastId)
    {
        $podcast = Podcasts::findOrFail($podcastId);
        $usedEpisodeNumbers = PodcastEpisodes::where('podcast_id', $podcast->id)
            ->pluck('episode_no')
            ->toArray();
        return view('podcast.episodes.index', compact('podcast', 'usedEpisodeNumbers'));
    }

    /**
     * Store a newly created episode in storage.
     */
    public function storeEpisode(Request $request, $podcastId, YoutubeVideoService $youtubeService)
    {
        try {
            ResponseService::noPermissionThenRedirect('podcast-episode-create');

            $validator = Validator::make($request->all(), [
                'episode_no'     => ['required','integer',
                                     Rule::unique('podcast_episodes', 'episode_no')
                                          ->where(fn ($query) => $query->where('podcast_id', $podcastId)),
                                    ],
                'title'          => 'required|string|max:255',
                'slug'           => 'required|alpha_dash|unique:podcast_episodes,slug',
                'source_type'    => 'required|in:upload,youtube_link',
                'audio_url'      => $request->source_type == 'youtube_link' ? 'required|url' : 'nullable',
                'audio_file'     => $request->source_type == 'upload' ? 'required|file|mimes:mp3,wav,m4a,ogg,aac|max:20480' : 'nullable',
                'image'          => 'required|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
                'published_date' => 'required|date',
                'description'    => 'nullable|string',
                'status'         => 'required|boolean',
                'is_draft'       => 'nullable|boolean',
            ]);

            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            $podcast = Podcasts::findOrFail($podcastId);

            $episode = new PodcastEpisodes();
            $episode->podcast_id = $podcast->id;
            $episode->episode_no = $request->episode_no;
            $episode->title = $request->title;
            $episode->slug = $request->slug;
            $episode->source_type = $request->source_type;

            if ($request->source_type === 'youtube_link') {

                $duration = $youtubeService->getDurationInSeconds($request->audio_url);

                if ($duration === null) {
                    return redirect()->back()
                        ->withErrors([
                            'audio_url' => 'Unable to fetch YouTube video duration.'
                        ])
                        ->withInput();
                }

                $episode->audio_url = $request->audio_url;
                $episode->duration_seconds = $duration;
            } else {

                if ($request->hasFile('audio_file')) {

                    $audioFile = $request->file('audio_file');

                    $getID3 = new getID3();
                    $fileInfo = $getID3->analyze($audioFile->getRealPath());

                    $episode->duration_seconds = isset($fileInfo['playtime_seconds'])
                        ? (int) round($fileInfo['playtime_seconds'])
                        : 0;

                    $episode->audio_url = 'storage/' . compressAndReplace($audioFile, $this->episodeAudioPath, null);
                }
            }

            if ($request->hasFile('image')) {
                $episode->image = 'storage/' . compressAndReplace($request->file('image'), $this->episodeImagePath, null);
            }

            $episode->published_at = date('Y-m-d', strtotime($request->published_date));
            $episode->description = $request->description ? $request->description : ' ';
            $episode->status = $request->status;
            $episode->draft = $request->boolean('is_draft');

            $episode->save();

            app(PodcastNotificationService::class)->notifyFollowers($podcast, $episode);

            return ResponseService::successResponse(__('episode_created_successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, "PodcastController -> storeEpisode");
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }


    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified episode in storage.
     */
    public function updateEpisode(Request $request, YoutubeVideoService $youtubeService)
    {
        try {
            ResponseService::noPermissionThenRedirect('podcast-edit');

            $validator = Validator::make($request->all(), [
                'podcast_id'     => 'required|exists:podcasts,id',
                'episode_id'     => 'required|exists:podcast_episodes,id',
                'episode_no'     => ['required','integer',
                                     Rule::unique('podcast_episodes', 'episode_no')
                                          ->ignore($request->episode_id)
                                          ->where(fn ($query) => $query->where('podcast_id', $request->podcast_id)),
                                    ],
                'title'          => 'required|string|max:255',
                'slug'           => 'required|alpha_dash|unique:podcast_episodes,slug,' . $request->episode_id,
                'source_type'    => 'required|in:upload,youtube_link',
                'audio_url'      => $request->source_type === 'youtube_link'
                    ? 'required|url'
                    : 'nullable',
                'audio_file'     => $request->source_type === 'upload'
                    ? 'nullable|file|mimes:mp3,wav,m4a,ogg,aac|max:20480'
                    : 'nullable',
                'image'          => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:20480',
                'published_date' => 'required|date',
                'description'    => 'nullable|string',
                'status'         => 'required|boolean',
                'is_draft'       => 'nullable|boolean',
            ]);

            if ($validator->fails()) {
                return ResponseService::errorResponse($validator->errors()->first());
            }

            // Ensure podcast exists
            Podcasts::findOrFail($request->podcast_id);

            // Ensure episode belongs to podcast
            $episode = PodcastEpisodes::where('podcast_id', $request->podcast_id)
                ->where('id', $request->episode_id)
                ->firstOrFail();

            $episode->episode_no = $request->episode_no;
            $episode->title = $request->title;
            $episode->slug = $request->slug;
            $episode->source_type = $request->source_type;

            if ($request->source_type === 'youtube_link') {

                $duration = $youtubeService->getDurationInSeconds($request->audio_url);

                if ($duration === null) {
                    return ResponseService::errorResponse('Unable to fetch YouTube video duration.');
                }

                // Delete old uploaded audio if switching to YouTube
                $this->deleteStorageFile($episode->getRawOriginal('audio_url'));

                $episode->audio_url = $request->audio_url;
                $episode->duration_seconds = $duration;
            } else {
                if ($request->hasFile('audio_file')) {
                    // Delete old uploaded audio before storing the new file
                    $this->deleteStorageFile($episode->getRawOriginal('audio_url'));

                    $audioFile = $request->file('audio_file');

                    $getID3 = new getID3();
                    $fileInfo = $getID3->analyze($audioFile->getRealPath());

                    $episode->duration_seconds = isset($fileInfo['playtime_seconds'])
                        ? (int) round($fileInfo['playtime_seconds'])
                        : 0;

                    $audioPath = $audioFile->store('podcast_episodes', 'public');
                    $episode->audio_url = 'storage/' . $audioPath;
                }
            }

            // Update image if uploaded
            if ($request->hasFile('image')) {
                // Delete the old image before storing the new one
                $this->deleteStorageFile($episode->getRawOriginal('image'));

                $imagePath = $request->file('image')->store('podcast_episodes', 'public');
                $episode->image = 'storage/' . $imagePath;
            }

            $episode->published_at = $request->published_date;
            $episode->description = $request->description ?: ' ';
            $episode->status = $request->status;
            $episode->draft = $request->boolean('is_draft');

            $episode->save();

            return ResponseService::successResponse(__('episode_updated_successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'PodcastController -> updateEpisode');
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }

    /**
     * Bulk remove episodes from storage.
     */
    public function bulkDeleteEpisodes(Request $request, $podcastId)
    {
        ResponseService::noPermissionThenRedirect('podcast-bulk-delete');

        $validator = ValidationService::bulkDeleteValidator($request, 'podcast_episodes');
        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }

        try {
            $episodes = PodcastEpisodes::query()
                ->where('podcast_id', $podcastId)
                ->whereIn('id', $request->request_ids)
                ->toBase()
                ->get(['image', 'audio_url', 'source_type']);

            // Collect related file paths of the episodes being deleted
            $files = collect($episodes)->flatMap(function ($episode) {
                $paths = [];

                if (!empty($episode->image)) {
                    $paths[] = str_starts_with($episode->image, 'storage/')
                        ? substr($episode->image, strlen('storage/'))
                        : $episode->image;
                }

                // Delete uploaded audio file only (skip remote URLs e.g. YouTube)
                if ($episode->source_type !== 'youtube_link'
                    && !empty($episode->audio_url)
                    && !filter_var($episode->audio_url, FILTER_VALIDATE_URL)) {
                    $paths[] = str_starts_with($episode->audio_url, 'storage/')
                        ? substr($episode->audio_url, strlen('storage/'))
                        : $episode->audio_url;
                }

                return $paths;
            })->filter()->unique()->values()->toArray();

            // Delete all selected episodes belonging to this podcast
            PodcastEpisodes::where('podcast_id', $podcastId)
                ->whereIn('id', $request->request_ids)
                ->delete();

            if (!empty($files)) {
                Storage::disk('public')->delete($files);
            }

            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'PodcastController -> bulkDeleteEpisodes');
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }

    /**
     * Remove the specified episode from storage.
     */
    public function destroyEpisode($podcastId, $episodeId)
    {
        ResponseService::noPermissionThenRedirect('podcast-delete');

        try {
            $episode = PodcastEpisodes::where('podcast_id', $podcastId)->findOrFail($episodeId);

            // Delete the episode image if it exists
            $this->deleteStorageFile($episode->getRawOriginal('image'));

            // Delete the episode audio file if it exists (skip remote URLs e.g. YouTube)
            if ($episode->source_type !== 'youtube_link'
                && !filter_var($episode->getRawOriginal('audio_url'), FILTER_VALIDATE_URL)) {
                $this->deleteStorageFile($episode->getRawOriginal('audio_url'));
            }

            // Delete the episode
            $episode->delete();

            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, "PodcastController -> destroyEpisode");
            return ResponseService::errorResponse(__('something_went_wrong'));
        }
    }

    /**
     * Display episodes list for a podcast.
     */
    public function episodesList(Request $request, $podcastId)
    {
        $offset = $request->input('offset', 0);
        $limit  = $request->input('limit', 10);
        $sort   = $request->input('sort', 'id');
        $order  = $request->input('order', 'DESC');
        $search = $request->input('search');

        $query = PodcastEpisodes::where('podcast_id', $podcastId);

        if ($request->filled('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', '%' . $search . '%')
                    ->orWhere('episode_no', 'like', '%' . $search . '%');
            });
        }

        $total = $query->count();
        $rows  = $query->orderBy($sort, $order)
            ->skip($offset)
            ->take($limit)
            ->get();

        $rows->transform(function ($row) {
            // ----- edit / delete buttons -----
            $edit   = '';
            $delete = '';
            if (auth()->user()->can('podcast-edit')) {
                $edit = '<a href="javascript:void(0)" class="dropdown-item episode-edit" data-id="' . $row->id . '" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            if (auth()->user()->can('podcast-delete')) {
                $delete = '<a data-url="' . route('podcast.episodes.destroy', [$row->podcast_id, $row->id]) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }

            $operate = ($edit === '' && $delete === '') ? '-' : '
                    <div class="dropdown">
                        <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-container="body">
                            <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                        </a>
                        <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' . $edit . $delete . '
                        </div>
                    </div>';

            // ----- full audio URL -----
            $audioUrl = '-';
            if (!empty($row->audio_url)) {
                // Keep absolute URLs (e.g., YouTube) as‑is; otherwise prepend the app base URL.
                $audioUrl = filter_var($row->audio_url, FILTER_VALIDATE_URL)
                    ? $row->audio_url
                    : asset($row->audio_url);
            }

                // ----- return row data -----
                return [
                    'id'            => $row->id,
                    'podcast_id' => $row->podcast_id,
                    'episode_no'    => $row->episode_no,
                    'title'         => $row->title,
                    'slug'          => $row->slug,
                    'description'   => $row->description,
                    'source_type'   => $row->source_type,
                    'audio_url'     => $audioUrl,
                    'image' => $row->image ? asset($row->image) : '',
                    'duration_seconds' => $row->duration_seconds ? gmdate("H:i:s", $row->duration_seconds) : '-',
                    'status'        => $row->status,
                    'is_draft'      => $row->draft,
                    'published_at'  => $row->published_at,
                    'operate'       => $operate,
                ];
            });

        return response()->json([
            'total' => $total,
            'rows'  => $rows,
        ]);
    }
}
