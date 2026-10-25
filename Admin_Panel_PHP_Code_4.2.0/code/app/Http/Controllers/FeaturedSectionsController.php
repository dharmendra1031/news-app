<?php

namespace App\Http\Controllers;

use App\Models\BreakingNews;
use App\Models\Category;
use App\Models\FeaturedSections;
use App\Models\Language;
use App\Models\News;
use App\Models\RSS;
use App\Models\User;
use App\Services\FeaturedSectionCrudService;
use App\Services\ResponseService;
use Illuminate\Http\Request;
use Exception;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class FeaturedSectionsController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['featured-section-list', 'featured-section-create', 'featured-section-edit', 'featured-section-delete', 'featured-section-order-create']);
        try {
            $languageList = Language::where('status', 1)->get();
            $categoryList = [];
            if (count($languageList) == 1) {
                $language_id = $languageList[0]->id;
                $categoryList =  Category::select('id', 'category_name')->with('sub_categories')->where('language_id', $language_id)->get();
            }
            $featuredList = FeaturedSections::select('id', 'title')->where('status', 1)->orderBy('row_order', 'ASC')->get();
            return view('featured-section', compact('languageList', 'categoryList', 'featuredList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "FeaturedSectionsController -> index");
        }
    }

    public function get_feature_section_by_language(Request $request)
    {
        $language_id = $request->language_id;
        if ($language_id == 0) {
            $res = FeaturedSections::select('id', 'title')->where('status', 1)->orderBy('row_order', 'ASC')->get();
        } else {
            $res = FeaturedSections::select('id', 'title')->where('language_id', $language_id)->where('status', 1)->orderBy('row_order', 'ASC')->get();
        }
        if (!empty($res)) {
            if ($request->sortable) {
                $options = '';
                foreach ($res as $row) {
                    $options .= '<li id="' . $row->id . '">' . $row->title . '</li>';
                }
            }
        }
        return $options;
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'row_order');
        $order = $request->input('order', 'ASC');
        // $featuredSection = FeaturedSections::with('language', 'rss_feeds')->get();

        $sql = FeaturedSections::with('language', 'rss_feeds.rss_feed');

        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                    ->orwhere('title', 'LIKE', "%{$search}%")
                    ->orwhere('short_description', 'LIKE', "%{$search}%")
                    ->orwhere('news_type', 'LIKE', "%{$search}%")
                    ->orwhere('videos_type', 'LIKE', "%{$search}%")
                    ->orwhere('filter_type', 'LIKE', "%{$search}%");
            });
        }
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('status') && $request->status != '') {
            $sql->where('status', $request->status);
        }
        if ($request->has('news_type') && $request->news_type != '') {
            $sql->where('news_type', $request->news_type);
        }
        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('featured-section-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('featured-section-delete')) {
                $delete = '<a data-url="' . url('featured_sections', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
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
            json_decode($row->meta_keyword);
            if (json_last_error() === JSON_ERROR_NONE) {
                $meta_keyword = json_decode($row->meta_keyword);
            } else {
                $meta_keyword = $row->meta_keyword;
            }
            $styleApp = [
                'style_1' => ['url' => 'App_Style_1.png', 'height' => 60, 'width' => 60],
                'style_2' => ['url' => 'App_Style_2.png', 'height' => 50, 'width' => 50],
                'style_3' => ['url' => 'App_Style_3.png', 'height' => 50, 'width' => 50],
                'style_4' => ['url' => 'App_Style_4.png', 'height' => 50, 'width' => 50],
                'style_5' => ['url' => 'App_Style_5.png', 'height' => 50, 'width' => 50],
                'style_6' => ['url' => 'App_Style_6.png', 'height' => 50, 'width' => 50],
            ];

            $style_app = '';
            if (array_key_exists($row->style_app, $styleApp)) {
                $style = $styleApp[$row->style_app];
                $style_app = '<a href="' . asset('images/app_style/' . $style['url']) . '" data-toggle="lightbox" data-title="Image"><img src="' . asset('images/app_style/' . $style['url']) . '" alt="' . $style_app . '" class="" height="' . $style['height'] . '" width="' . $style['width'] . '"></a>';
            }

            $styleWeb = [
                'style_1' => ['url' => 'Web_Style_1.png', 'height' => 40, 'width' => 100],
                'style_2' => ['url' => 'Web_Style_2.png', 'height' => 40, 'width' => 100],
                'style_3' => ['url' => 'Web_Style_3.png', 'height' => 40, 'width' => 100],
                'style_4' => ['url' => 'Web_Style_4.png', 'height' => 40, 'width' => 100],
                'style_5' => ['url' => 'Web_Style_5.png', 'height' => 40, 'width' => 100],
                'style_6' => ['url' => 'Web_Style_6.png', 'height' => 40, 'width' => 100],
            ];

            $style_web = '';
            if (array_key_exists($row->style_web, $styleWeb)) {
                $style = $styleWeb[$row->style_web];
                $style_web = '<a href="' . asset('images/app_style/' . $style['url']) . '" data-toggle="lightbox" data-title="Image"><img src="' . asset('images/app_style/' . $style['url']) . '" alt="' . $style_web . '" class="" height="' . $style['height'] . '" width="' . $style['width'] . '"></a>';
            }

            $news_type_badge = [
                'news' => __('news'),
                'breaking_news' => __('breaking_news'),
                'videos' => __('videos'),
                'author_news' => __('author_news'),
                'rss_feeds_news' => __('rss_feeds_news'),
            ];

            $filter_type_badge = [
                'most_commented' => __('most_commented'),
                'recently_added' => __('recently_added'),
                'most_viewed' => __('most_viewed'),
                'most_favorite' => __('most_favorite'),
                'most_like' => __('most_like'),
                'custom' => __('custom'),
            ];

            $video_type_badge = [
                'news' => __('news'),
                'breaking_news' => __('breaking_news'),
            ];

            $rss_feeds_badge = '';
            if (count($row->rss_feeds) > 0) {
                foreach($row->rss_feeds as $rss_feed){
                    $rss_feeds_badge .= $rss_feed->rss_feed->feed_name . ', ';
                }
            }
            // Log::info('rss_feeds: '. json_encode($row->toArray()));
            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'title' => $row->title,
                'short_description' => mb_strimwidth($row->short_description, 0, 40, '...'),
                'short_description_full' => $row->short_description,
                'news_type' => $row->news_type ?? '',
                // 'news_type_badge' => str_replace('_', ' ', $row->news_type) ?? '',
                'news_type_badge' => $news_type_badge[$row->news_type] ?? '',
                'rss_feeds_badge' => $rss_feeds_badge,
                'filter_type' => $row->filter_type ?? '',
                'filter_type_badge' => $filter_type_badge[$row->filter_type] ?? '',
                'category_id' => $row->category_ids ?? '',
                'subcategory_id' => $row->subcategory_ids ?? '',
                'news_id' => $row->news_ids ?? '',
                'style_app' => $style_app,
                'style_web' => $style_web,
                'row_order' => $row->status == '1' ? '<span class="btn btn-icon btn-sm btn-warning move" alt="Move" >' . $row->row_order . '</span>' : '-',
                'is_based_on_user_choice' => $row->is_based_on_user_choice ?? '',
                'created_at' => date('d-m-Y H:i:s', strtotime($row->created_at)),
                'updated_at' => date('d-m-Y H:i:s', strtotime($row->updated_at)),
                'videos_type' => $row->videos_type ?? '',
                'video_type_badge' => $video_type_badge[$row->videos_type] ?? '',
                'status1' => $row->status == '1' ? '<div class="badge badge-success">' . __('active') . '</div>' : '<div class="badge badge-danger">' . __('deactive') . '</div>',
                'status' => $row->status,
                'style_web_edit' => $row->style_web,
                'style_app_edit' => $row->style_app,
                'slug' => $row->slug,
                'meta_keyword' => $meta_keyword,
                'schema_markup' => $row->schema_markup,
                'og_image' => !empty($row->og_image) ? '<a href="' . $row->og_image . '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' . $row->og_image . '" height="50" width="50"></a>' : '-',
                'meta_title' => $row->meta_title,
                'meta_description' => $row->meta_description,
                'user_ids' => $row->user_ids ?? '',
                'category_list' => $row->category_ids ?? '',
                'rss_feeds_news_type' => $row->rss_feeds()->pluck('rss_feed_id')->toArray() ?? '',
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function store(Request $request)
    {

        ResponseService::noPermissionThenRedirect('featured-section-create');

        $validator = Validator::make($request->all(), [
            'language_id'                     => 'required',
            'title'                           => 'required|string|max:255',
            'slug'                            => 'required|string|max:255',
            'based_on_user_choice_mode'       => 'required|in:0,1',
            'news_type'                       => 'required_if:based_on_user_choice_mode,0',
            'author_news_type'                => 'required_if:news_type,author_news',
            'news_ids'                        => 'required_if:filter_type,custom',
            'rss_feeds_news_type'             => 'required_if:news_type,rss_feeds_news',
            // 'category_ids'                    => 'required_if:filter_type,most_commented,recently_added,most_viewed,most_favorite,most_like',
            'category_ids'                    => 'required_if:news_type,videos', // ,news
            'style_app'                       => 'required|string',
            'style_web'                       => 'required|string',
        ],[
            'rss_feeds_news_type.required_if' => __('Please select rss feeds'),
            'author_news_type.required_if'    => __('Please select author news'),
            'category_ids.required_if'        => __('Please select category'),
            'news_ids.required_if'            => __('Please select news'),
        ]);

        if ($validator->fails()) {
            return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
        }

        $slug = generateUniqueSlug($request->slug);
        if (FeaturedSections::where('slug', $slug)->exists()) {
            return response()->json(['error' => true, 'message' => __('slug_already_use')]);
        }

        $response = (new FeaturedSectionCrudService())->store(
            $request->all(),
            $request->file('file'),
            $slug
        );

        return response()->json($response);
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-edit');

        $basedOnUserChoice = (int) ($request->edit_based_on_user_choice_mode ?? 1);

        // $rules = [
        //     'language_id'      => 'required',
        //     'title'            => 'required|string|max:255',
        //     'slug'             => 'required|string|max:255',
        //     'short_description'=> 'required|string',
        // ];

        // if ($basedOnUserChoice === 0) {
        //     $rules['news_type'] = 'required';
        //     if ($request->news_type !== 'rss_feeds_news' && $request->news_type !== 'author_news') {
        //         $rules['filter_type'] = 'required';
        //         if ($request->filter_type === 'custom' && $request->news_type !== 'breaking_news') {
        //             $rules['news_ids'] = 'required';
        //         }
        //     }
        // }

        // $validator = Validator::make($request->all(), $rules);
        // if ($validator->fails()) {
        //     return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
        // }

        $validator = Validator::make($request->all(), [
            'language_id'                     => 'required',
            'title'                           => 'required|string|max:255',
            'slug'                            => 'required|string|max:255',
            'edit_based_on_user_choice_mode'       => 'required|in:0,1',
            'news_type'                       => 'required_if:based_on_user_choice_mode,0',
            'author_news_type'                => 'required_if:news_type,author_news',
            'news_ids'                        => 'required_if:filter_type,custom',
            'rss_feeds_news_type'             => 'required_if:news_type,rss_feeds_news',
            // 'category_ids'                    => 'required_if:filter_type,most_commented,recently_added,most_viewed,most_favorite,most_like',
            'category_ids'                    => 'required_if:news_type,videos', //news,
            'style_app'                       => 'required|string',
            'style_web'                       => 'required|string',
        ],[
            'rss_feeds_news_type.required_if' => __('Please select rss feeds'),
            'author_news_type.required_if'    => __('Please select author news'),
            'category_ids.required_if'        => __('Please select category'),
            'news_ids.required_if'            => __('Please select news'),
        ]);
        if ($validator->fails()) {
            return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
        }

        $slugExists = FeaturedSections::where('slug', $request->slug)
            ->where('id', '!=', $request->edit_id)
            ->exists();
        if ($slugExists) {
            return response()->json(['error' => true, 'message' => __('slug_already_use')]);
        }

        $featuredSection = FeaturedSections::findOrFail($request->edit_id);
        $status          = $request->status == '1' ? 1 : 0;

        $response = (new FeaturedSectionCrudService())->update(
            $request->all(),
            $request->file('file'),
            $featuredSection,
            $request->slug,
            $status
        );

        return response()->json($response);
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('featured-section-delete');
        $feature_section = FeaturedSections::find($id);
        $feature_section->delete();
        $response = [
            'error' => false,
            'message' => __('deleted_success'),
        ];
        return response()->json($response);
    }

    public function get_categories_tree(Request $request)
    {
        $language_id = $request->language_id;
        $categories = Category::with('sub_categories')->where('language_id', $language_id)->get();

        $option = '<option value="0" disabled>' . __('select') . ' ' . __('category') . '</option>';
        foreach ($categories as $row) {
            $option .= '<option value="cat-' . $row->id . '">' . $row->category_name . '</option>';
            if (is_subcategory_enabled() == 1) {
                if ($language_id) {
                    $subcategories = $row->sub_categories->where('language_id', $language_id);
                } else {
                    $subcategories = $row->sub_categories;
                }
                foreach ($subcategories as $row1) {
                    $option .= '<option value="subcat-' . $row1->id . '">--' . $row1->subcategory_name . '</option>';
                }
            }
        }
        return $option;
    }

    public function getCustomNews(Request $request)
    {
        $languageId = $request->language_id;
        $newsType = $request->news_type;
        $option = '';
        $toDate = date('Y-m-d');
        $results = [];
        if ($newsType == 'news') {
            $results = News::where('language_id', $languageId)->where(function ($q) use ($toDate) {
                $q->where('show_till', '>=', $toDate)->orWhere('show_till', '0000-00-00');
            })->where('status', 1)
            // ->where('published_date', '<=', $toDate)
            ->where(function($q) use ($toDate) {
                $q->where(function($subq) use ($toDate) {
                    $subq->whereNotNull('published_date')
                         ->where('published_date', '<=', $toDate);
                })->orWhere(function($subq) use ($toDate) {
                    $subq->whereNull('published_date')
                         ->whereDate('created_at', '<=', $toDate);
                });
            })
            ->get();
        } elseif ($newsType == 'breaking_news') {
            // Custom picker must list ALL breaking news for the language.
            // Previously this excluded content_type='standard_post' (the default
            // type), so with only standard posts the dropdown came back empty.
            $results = BreakingNews::where('language_id', $languageId)
                                    ->orderBy('id', 'DESC')
                                    ->get();
        }elseif ($newsType == 'videos') {

                $videosType = $request->input('videos_type');

                $contentTypes = [
                    'video_upload',
                    'video_youtube',
                    'video_other'
                ];

                $newsVideoQuery = function () use ($languageId, $toDate, $contentTypes) {
                    return News::where('language_id', $languageId)
                        ->where(function ($q) use ($toDate) {
                            $q->where('show_till', '>=', $toDate)
                            ->orWhere('show_till', '0000-00-00');
                        })
                        ->where('status', 1)
                        ->where(function ($q) use ($toDate) {
                            $q->where(function ($subq) use ($toDate) {
                                $subq->whereNotNull('published_date')
                                    ->where('published_date', '<=', $toDate);
                            })->orWhere(function ($subq) use ($toDate) {
                                $subq->whereNull('published_date')
                                    ->whereDate('created_at', '<=', $toDate);
                            });
                        })
                        ->whereIn('content_type', $contentTypes);
                };

                if ($videosType == 'news') {

                    $results = $newsVideoQuery()->get();

                } elseif ($videosType == 'breaking_news') {

                    $results = BreakingNews::where('language_id', $languageId)
                        ->whereIn('content_type', $contentTypes)
                        ->get();
                } else {
                    // videos_type not chosen yet: fall back to news videos
                    // so the dropdown is not empty.
                    $results = $newsVideoQuery()->get();
                }
            }

        if (!empty($results)) {

            foreach ($results as $res) {
                $option .= '<option value="' . e($res->id) . '">' . e(Str::limit($res->title, 30)) . '</option>';
            }
        }
        return $option;
    }

    public function update_order(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-order-create');
        if ($request->row_order) {
            $row_order = explode(',', $request->row_order);
            foreach ($row_order as $key => $id) {
                FeaturedSections::where('id', $id)->update(['row_order' => $key + 1]);
            }
        }
        return redirect('featured_sections')->with('success', __('updated_success'));
    }

    // get user (author) list
    public function getAuthorList()
    {
        // $authors = User::where('is_author', 1)->get();

        // and where user has news one more than one not drafted - 0 and pluck only id and name
        // $authors is a Collection, not a Query Builder, so whereHas will not work on it.
        // We should use Eloquent query directly to get authors with news (not draft) and pluck id and name.
        $authors = User::where('is_author', 1)
            ->whereHas('news', function($query) {
                $query->where('is_draft', 0);
            })
            ->get(['id', 'name']);

        // option string
        $option = '';
        foreach ($authors as $author) {
            $option .= '<option value="' . $author->id . '">' . $author->name . '</option>';
        }
        return $option;
    }

    // get rss feeds list
    public function getRssFeedsList($category_ids)
    {
        try{
            $category_ids = array_filter(
                array_map('trim', explode(',', (string) $category_ids)),
                fn($id) => $id !== '' && is_numeric($id)
            );
            if (empty($category_ids)) {
                return '';
            }
            $rssFeeds = RSS::whereIn('category_id', $category_ids)->where('status', 1)->orderBy('feed_name')->get();
            $option = '';
            foreach ($rssFeeds as $rssFeed) {
                $option .= '<option value="' . e($rssFeed->id) . '">' . e($rssFeed->feed_name) . '</option>';
            }
            return $option;
        }catch(Exception $e){
            // responseService::errorResponse('Something went wrong', null, 500, $e);
            return '';

        }
    }

    public function getCategoriesList($language_id = null) {
        try{
            if (empty($language_id) || !is_numeric($language_id)) {
                return '';
            }
            $categoryList = Category::where('language_id', $language_id)->orderBy('category_name')->get();
            $option = '';
            foreach ($categoryList as $category) {
                $option .= '<option value="' . e($category->id) . '">' . e($category->category_name) . '</option>';
            }
            return $option;
        }catch(Exception $e){
            // response service
            responseService::errorResponse('Something went wrong', null, 500, $e);
        }
    }
}
