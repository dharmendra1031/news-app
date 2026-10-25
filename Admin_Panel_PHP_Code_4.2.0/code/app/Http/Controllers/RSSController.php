<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Language;
use App\Models\FeedItem;
use App\Models\RSS;
use App\Models\Tag;
use App\Services\ResponseService;
use App\Services\TagService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use App\Services\ValidationService;
use App\Jobs\ProcessFeedSource;

class RSSController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['rss-list', 'rss-create', 'rss-edit', 'rss-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            $categoryList = [];
            $tagList = [];
            if (count($languageList) == 1) {
                $language_id = $languageList[0]->id;
                $categoryList = Category::select('id', 'category_name')->where('language_id', $language_id)->get();
                $tagList = Tag::where('language_id', $language_id)->get();
            }
            return view('rss', compact('languageList', 'categoryList', 'tagList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "RSSController -> index");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('rss-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = RSS::with('language:id,language', 'category:id,category_name', 'sub_category:id,subcategory_name');
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->orWhere('id', 'LIKE', "%{$search}%")->orWhere('feed_name', 'LIKE', "%{$search}%")->orWhere('feed_url', 'LIKE', "%{$search}%");
            });
        }
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('category_id') && $request->category_id) {
            $sql->where('category_id', $request->category_id);
        }
        if ($request->has('subcategory_id') && $request->subcategory_id) {
            $sql->where('subcategory_id', $request->subcategory_id);
        }
        if (isset($request->status)) {
            $sql->where('status', $request->status);
        }
        $total = $sql->count();
        $sql = $sql->orderBy($sort, $order)->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('rss-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('rss-delete')) {
                $delete = '<a data-url="' . url('rss', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
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

            if (isset($row->tag_id) && !empty($row->tag_id)) {
                $tagNames = Tag::whereIn('id', explode(',', $row->tag_id))
                    ->distinct()
                    ->pluck('tag_name')
                    ->implode(',');
                $row->tag_name = $tagNames;
                $row->tag_id = !empty($res2) ? $res2[0]->tag_id : $row->tag_id;
            }

            $status = [
                0 => '<span class="badge badge-danger">' . __('deactive') . '</span>',
                1 => '<span class="badge badge-success">' . __('active') . '</span>',
            ];

                    // --- CRAWL BUTTON WITH 10-MINUTE COOLDOWN ---
            $crawlFeed = '';
            $now = \Carbon\Carbon::now();

            // Build the button HTML - hidden by default when on cooldown
            $buttonHtml = '<a href="' . url('rss/' . $row->id . '/crawlfeed') . '" class="btn btn-sm btn-info crawl-feed-btn" data-id="' . $row->id . '" title="' . __('crawl_feed') . '" style="display:none;"><i class="fa fa-sync-alt"></i></a>';

            if (!empty($row->last_fetched_at)) {
                $lastFetched = \Carbon\Carbon::parse($row->last_fetched_at);
                $cooldownEnds = $lastFetched->copy()->addMinutes(10);

                if ($now->lessThan($cooldownEnds)) {
                    $remainingSeconds = $now->diffInSeconds($cooldownEnds, false);
                    $remainingMin = max(1, ceil($remainingSeconds / 60));
                    // Show label + HIDDEN button (inline style)
                    $crawlFeed = '<span class="badge badge-success crawled-label" data-cooldown-ends="' . $cooldownEnds->timestamp . '" data-cooldown-iso="' . $cooldownEnds->toIso8601String() . '">' . __('crawl_again_in') . ' ' . $remainingMin . ' ' . __('min') . '</span>' . $buttonHtml;
                }
            }

            if (empty($crawlFeed)) {
                // No cooldown - show button only, no inline style needed
                $crawlFeed = '<a href="' . url('rss/' . $row->id . '/crawlfeed') . '" class="btn btn-sm btn-info crawl-feed-btn" data-id="' . $row->id . '" title="' . __('crawl_feed') . '"><i class="fa fa-sync-alt"></i></a>';
            }
            // --- END CRAWL BUTTON LOGIC ---
            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language_name' => $row->language->language ?? '',
                'category_id' => $row->category_id,
                'category_name' => $row->category->category_name ?? '',
                'subcategory_id' => $row->subcategory_id ?? '',
                'subcategory_name' => $row->sub_category->subcategory_name ?? '',
                'tag_id' => $row->tag_id ?? '',
                'tag_name' => $row->tag_name ?? '',
                'feed_name' => $row->feed_name,
                'feed_url' => $row->feed_url,
                'status' => $row->status ?? '',
                'created_at' => date('d-m-Y H:i:s', strtotime($row->created_at)) ?? '',
                'updated_at' => date('d-m-Y H:i:s', strtotime($row->updated_at)) ?? '',
                'status_badge' => $status[$row->status],
                'crawled_feeds_counts' => $row?->feedItem()?->count() ?? 0,
                'crawled_feeds_counts_url' => url('rss/' . $row->id . '/feed-items'),
                'operate' => $operate,
                'crawl_feed' => $crawlFeed,
                'row_fetched_at' => !empty($row->last_fetched_at) ? \Carbon\Carbon::parse($row->last_fetched_at)->format('d M Y, h:i A') : '-'
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('rss-create');
        try{
            $validator = Validator::make($request->all(), [
               'language' => 'required|integer',
               'feed_name' => 'required|string|max:255',
               'feed_url' => 'required|url',
               'category_id' => 'required_if:is_category_enabled,1|integer'
            ]);
            if ($validator->fails()) {
               return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
            }

            $tagIds = TagService::resolveTagIds($request->tag_id, $request->language);

            RSS::create([
                'language_id'    => $request->language,
                'category_id'    => $request->category_id ?? 0,
                'subcategory_id' => $request->subcategory_id ?? 0,
                'tag_id'         => implode(',', $tagIds),
                'feed_name'      => $request->feed_name,
                'feed_url'       => $request->feed_url,
                'status'         => 1,
            ]);

            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "RSSController -> store");
        }
    }

    public function update(Request $request, RSS $news)
    {
        ResponseService::noPermissionThenRedirect('rss-edit');
        try{
            $validator = Validator::make($request->all(), [
               'language' => 'required|integer',
               'feed_name' => 'required|string',
               'feed_url' => 'required|url',
               'category_id' => 'required_if:is_category_enabled,1|integer'
           ]);
           if ($validator->fails()) {
               return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
           }

            $tagIds = TagService::resolveTagIds($request->tag_id, $request->language);

            RSS::findOrFail($request->edit_id)->update([
                'language_id'    => $request->language,
                'category_id'    => $request->category_id ?? 0,
                'subcategory_id' => $request->subcategory_id ?? 0,
                'tag_id'         => implode(',', $tagIds),
                'feed_name'      => $request->feed_name,
                'feed_url'       => $request->feed_url,
                'status'         => $request->status,
            ]);

            return ResponseService::successResponse(__('updated_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "RSSController -> update");
        }
    }

    public function destroy($id)
    {
        ResponseService::noPermissionThenRedirect('rss-delete');
        try{
            RSS::find($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "RSSController -> destroy");
        }
    }

    public function feedItems($id)
    {
        ResponseService::noAnyPermissionThenRedirect(['rss-list']);
        try {
            $rss = RSS::with('language:id,language', 'category:id,category_name')->findOrFail($id);
            return view('rss_feed_items', compact('rss'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "RSSController -> feedItems");
        }
    }

    public function feedItemsList(Request $request, $id)
    {
        ResponseService::noPermissionThenRedirect('rss-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = FeedItem::where('rss_source_id', $id);

        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->orWhere('title', 'LIKE', "%{$search}%")
                  ->orWhere('author', 'LIKE', "%{$search}%")
                  ->orWhere('url', 'LIKE', "%{$search}%");
            });
        }

        $total = $sql->count();
        $sql = $sql->orderBy($sort, $order)->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $delete = '';
            if (auth()->user()->can('rss-delete')) {
                $delete = '<a data-url="' . url('feed-items', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            $operate = '-';
            if ($delete != '') {
                $operate =
                '<div class="dropdown">
                    <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                    </a>
                    <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">'
                    . $delete .
                    '</div>
                </div>';
            }

            return [
                'id' => $row->id,
                'title' => $row->title,
                'url' => $row->url,
                'image_url' => $row->image_url,
                'author' => $row->author ?? '-',
                'description' => $row->description,
                'published_at' => $row->published_at_human ?? '-',
                'fetched_at' => $row->fetched_at ? $row->fetched_at->format('d M Y, h:i A') : '-',
                'operate' => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function deleteFeedItem($id)
    {
        ResponseService::noPermissionThenRedirect('rss-delete');
        try {
            FeedItem::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "RSSController -> deleteFeedItem");
        }
    }

    public function bulkDeleteFeedItems(Request $request)
    {
        ResponseService::noPermissionThenRedirect('rss-delete');
         $validator = ValidationService::bulkDeleteValidator($request,'feed_items');
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {
            $existingIds = FeedItem::whereIn('id', $request->request_ids)
                ->pluck('id')
                ->toArray();

            if (!empty($existingIds)) {
                FeedItem::whereIn('id', $existingIds)->delete();
            }

            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "RSSController -> bulkDeleteFeedItems");
        }
    }

    public function bulkDeleteRss(Request $request)
    {
        ResponseService::noPermissionThenRedirect('rss-bulk-delete');
        $validator = ValidationService::bulkDeleteValidator($request,'tbl_rss');
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {
            // Get only existing IDs from database
            $existingIds = RSS::whereIn('id', $request->request_ids)
                ->pluck('id')
                ->toArray();

            if (!empty($existingIds)) {
                RSS::whereIn('id', $existingIds)->delete();
            }

            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "RSSController -> bulk_delete");
        }
    }

   public function crawlFeed($id)
    {
        ResponseService::noPermissionThenRedirect('rss-list');

        try {
            $rss = RSS::findOrFail($id);

            // Detect stale pending jobs — indicates the queue worker is not running
            $queueWorkerRunning = !DB::table('jobs')
                ->whereNull('reserved_at')
                ->where('available_at', '<', now()->subMinutes(2)->timestamp)
                ->exists();


            if (!$queueWorkerRunning) {
                return ResponseService::errorResponse(
                    __('queue_worker_not_running')
                );
            }

            $rss->last_fetched_at = now();
            $rss->save();

            ProcessFeedSource::dispatch($rss);

            return ResponseService::successResponse(__('crawl_feed_success'));

        } catch (\Exception $e) {
            return ResponseService::logErrorResponse($e, "RSSController -> crawlFeed");
        }
    }
}
