<?php

namespace App\Http\Controllers;

use App\Models\VideoShort;
use App\Models\VideoShortLike;
use App\Models\VideoShortComment;
use Exception;
use Illuminate\Http\Request;
use App\Services\ResponseService;
use App\Services\BootstrapTableService;
use App\Models\Language;
use App\Models\Category;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Services\ValidationService;
use App\Http\Requests\StoreVideoShortRequest;
use App\Http\Requests\UpdateVideoShortRequest;
use Illuminate\Support\Facades\Log;

class VideoShortsController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect
        (['newsbuzz-list',
          'newsbuzz-create',
          'newsbuzz-edit',
          'newsbuzz-bulk-delete',
          ]);
        $languageList = Language::where('status', 1)->get();
        $categoryList = [];
        if (count($languageList) == 1) {
            $language_id = $languageList[0]->id;
            $categoryList = Category::select('id', 'category_name')->where('language_id', $language_id)->get();

        }
        return view('videoshorts.index', compact('languageList', 'categoryList'));
    }

    /**
     * Datatable JSON feed for the listing.
     */
    public function show(Request $request)
    {
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        $search = $request->input('search');

        $query = VideoShort::with(['language', 'category']);

        // Search
        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'LIKE', "%$search%")
                    ->orWhere('video_url', 'LIKE', "%$search%");
            });
        }

        // Filters
        if ($request->filled('language_id') && $request->language_id != 0) {
            $query->where('language_id', $request->language_id);
        }

        if ($request->filled('category_id') && $request->category_id != 0) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->status !== null && $request->status !== '') {
            $query->where('status', $request->status);
        }

        $total = $query->count();

        $rows = $query->orderBy($sort, $order)
            ->skip($offset)
            ->take($limit)
            ->get();

        $rows->transform(function ($row) {


            $edit = '';
            if (auth()->user()->can('newsbuzz-edit')) {
                $edit = '<a href="javascript:void(0)" class="dropdown-item videoshorts-edit" data-id="' . $row->id . '" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('newsbuzz-delete')) {
                $delete = '<a data-url="' . route('video_shorts.destroy', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                    '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-container="body">
                                <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                            </a>
                            <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' .
                    $edit .

                    $delete .

                    '
                            </div>
                        </div>';
            }

            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language_name' => optional($row->language)->language,
                'category_id' => $row->category_id,
                'category_name' => optional($row->category)->category_name,
                'title' => $row->title,
                'slug' => $row->slug,
                'video_url' => $row->video_type === 'youtubelink'
                ? trim($row->getRawOriginal('video_url'))
                : $row->video_url,
                'video_type' => $row->video_type,
                'status' => $row->status,
                'date' => $row->published_date,
                'show_till' => $row->show_till,
                'description' => $row->description,
                'views_count' => $row->views_count,
                'shares_count' => $row->shares_count,
                'likes_count'    => $row->likes()->count(),
                'comments_count' => $row->comments()->count(),
                'likes_url'      => route('video_shorts.likes', $row->id),
                'comments_url'   => route('video_shorts.comments', $row->id),
                'operate' => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);

    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreVideoShortRequest $request)
    {
        $videoPath = null;
        if ($request->video_type == "youtubelink") {
            $videoPath = str_replace('/shorts/', '/embed/', $request->youtube_url);
        } else {
            if ($request->hasFile('video_file')) {
                $file = $request->file('video_file');
                $filename = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $videoPath = $file->storeAs('video_shorts', $filename, 'public');
            }
        }


        VideoShort::create([
            'language_id' => $request->language,
            'category_id' => $request->category_id,
            'title' => $request->title,
            'slug' => $request->slug,
            'video_type' => $request->video_type,
            'video_url' => $videoPath,
            'description' => $request->des,
            'published_date' => $request->published_date,
            'status' => $request->status ?? 0,
            'views_count' => 0,
            'shares_count' => 0,
        ]);

        return ResponseService::successResponse(__('created_success'));
    }

    /**
     * Display the specified resource.
     */


    /**
     * Show the form for editing the specified resource.
     */
    public function edit(VideoShort $videoShort)
    {
        //
    }

    public function update(UpdateVideoShortRequest $request)
    {

    $videoShort = VideoShort::findOrFail($request->edit_id);

    try {

        $slug = generateUniqueSlug($request->slug);

        $existingSlug = VideoShort::where('slug', $slug)
            ->where('id', '!=', $videoShort->id)
            ->exists();

        if ($existingSlug) {
            throw new \Exception(__('slug_already_use'));
        }

        $videoPath = $videoShort->getRawOriginal('video_url');
        
        if($request->video_type == "youtubelink"){
            $videoPath = $request->youtube_url;
        }else{
            if ($request->hasFile('video_file')) {
            $file      = $request->file('video_file');
            $filename  = time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
            $videoPath = $file->storeAs('video_shorts', $filename, 'public');
        }
        }

        $videoShort->update([
            'language_id'    => $request->language,
            'category_id'    => $request->category_id,
            'title'          => $request->title,
            'slug'           => $slug,
            'video_type'     => $request->video_type,
            'video_url'      => $videoPath,
            'description'    => $request->des,
            'published_date' => $request->published_date,
            'status'         => $request->status ?? 0,
        ]);

        return ResponseService::successResponse(__('updated_success'));

    } catch (\Exception $e) {
        return ResponseService::errorResponse($e->getMessage());
    }
}
    /**
     * Remove the specified resource from storage.
     */
    public function destroy(VideoShort $videoShort)
    {
        try {

            if ($videoShort->video_url && Storage::disk('public')->exists($videoShort->video_url)) {
                Storage::disk('public')->delete($videoShort->video_url);
            }


            $videoShort->delete();

            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {

            return ResponseService::errorResponse($e->getMessage());
        }
    }
    public function bulkVideoshortsDelete(Request $request)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-bulk-delete');

        $validator = ValidationService::bulkDeleteValidator($request, 'video_shorts');

        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }
        try {
            collect($request->request_ids)
                ->chunk(200)
                ->each(function ($chunkIds) {
                    // Get all video paths in one query
                    $videos = VideoShort::query()
                        ->whereIn('id', $chunkIds)
                        ->toBase()
                        ->pluck('video_url')
                        ->filter()
                        ->unique()
                        ->values()
                        ->toArray();

                    // Delete all videos from storage
                    if (!empty($videos)) {
                        Storage::disk('public')->delete($videos);
                    }

                    // Delete all rows in one query
                    VideoShort::whereIn('id', $chunkIds)->delete();
                });

            return ResponseService::successResponse(__('deleted_success'));

        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "VideoShortsController -> bulk_videoshorts_delete");
        }
    }
    public function likes($id)
    {
        // ResponseService::noPermissionThenRedirect('newsbuzz-list');
        $videoShort = VideoShort::with(['language', 'category'])->findOrFail($id);
        return view('videoshorts.likes', compact('videoShort'));
    }

    public function comments($id)
    {
        // ResponseService::noPermissionThenRedirect('newsbuzz-list');
        $videoShort = VideoShort::with(['language', 'category'])->findOrFail($id);
        return view('videoshorts.comments', compact('videoShort'));
    }

    public function likesList(Request $request, $id)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-list');
        $offset = $request->input('offset', 0);
        $limit  = $request->input('limit', 10);
        $sort   = $request->input('sort', 'id');
        $order  = $request->input('order', 'DESC');
        $search = $request->input('search');

        $query = VideoShortLike::with('user')->where('video_shorts_id', $id);

        if (!empty($search)) {
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'LIKE', "%$search%");
            });
        }

        $total = $query->count();

        $rows = $query->orderBy($sort, $order)->skip($offset)->take($limit)->get();

        $rows->transform(function ($row) {
            $operate = '-';
            if (auth()->user()->can('newsbuzz-delete')) {
                $operate = BootstrapTableService::singleDeleteButton(
                    route('video_shorts.likes.destroy', $row->id),
                    $row->id
                );
            }

            return [
                'id'         => $row->id,
                'user_name'  => optional($row->user)->name ?? __('unknown'),
                'like'       => $row->like
                    ? '<span class="badge badge-success">' . __('true') . '</span>'
                    : '-',
                'dislike'    => $row->dislike
                    ? '<span class="badge badge-danger">' . __('true') . '</span>'
                    : '-',
                // 'created_at' => $row->created_at ? $row->created_at->format('d M Y, h:i A') : '-',
                'operate'    => $operate,
            ];
        });

        return response()->json(['total' => $total, 'rows' => $rows]);
    }

    public function commentsList(Request $request, $id)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-list');
        $offset = $request->input('offset', 0);
        $limit  = $request->input('limit', 10);
        $sort   = $request->input('sort', 'id');
        $order  = $request->input('order', 'DESC');
        $search = $request->input('search');

        $query = VideoShortComment::with('user')->where('video_shorts_id', $id);

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('comment', 'LIKE', "%$search%")
                  ->orWhereHas('user', function ($u) use ($search) {
                      $u->where('name', 'LIKE', "%$search%");
                  });
            });
        }

        $total = $query->count();

        $rows = $query->orderBy($sort, $order)->skip($offset)->take($limit)->get();

        $rows->transform(function ($row) {
            $operate = '-';
            if (auth()->user()->can('newsbuzz-delete')) {
                $operate = BootstrapTableService::singleDeleteButton(
                    route('video_shorts.comments.destroy', $row->id),
                    $row->id
                );
            }

            return [
                'id'         => $row->id,
                'user_name'  => optional($row->user)->name ?? '-',
                'comment'    => e($row->comment),
                // 'created_at' => $row->created_at ? $row->created_at->format('d M Y, h:i A') : '-',
                'operate'    => $operate,
            ];
        });

        return response()->json(['total' => $total, 'rows' => $rows]);
    }

    public function deleteLike($id)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-delete');
        try {
            VideoShortLike::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function deleteComment($id)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-delete');
        try {
            VideoShortComment::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function bulkDeleteLikes(Request $request)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-delete');
        $validator = ValidationService::bulkDeleteValidator($request, 'video_shorts_likes');

        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }
        try {
            $existingIds = VideoShortLike::whereIn('id', $request->request_ids)->pluck('id')->toArray();
            if (!empty($existingIds)) {
                VideoShortLike::whereIn('id', $existingIds)->delete();
            }
            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function bulkDeleteComments(Request $request)
    {
        ResponseService::noPermissionThenRedirect('newsbuzz-delete');

        $validator = ValidationService::bulkDeleteValidator($request, 'video_shorts_comments');

        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }
        try {

            $existingIds = VideoShortComment::whereIn('id', $request->request_ids)->pluck('id')->toArray();
            if (!empty($existingIds)) {
                VideoShortComment::whereIn('id', $existingIds)->delete();
            }
            return ResponseService::successResponse(__('deleted_success'));
        } catch (\Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }
}
