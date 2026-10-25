<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\WebSeoPages;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class SEOController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['seo-list', 'seo-create', 'seo-edit', 'seo-delete']);
        try{

            $languageList = Language::where('status', 1)->get();
            $options = ['home', 'video_news', 'all_breaking_news', 'live_streaming_news', 'rss_feeds', 'e_news', 'news_buzz', 'podcast', 'alerts'];
            return view('seo-setting', compact('languageList', 'options'));
        }catch(Exception $e){
            return ResponseService::logErrorRedirectResponse($e, "SEOController -> index");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('seo-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = WebSeoPages::with('language')->orderBy($sort, $order);
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")->orwhere('page_type', 'LIKE', "%{$search}%");
            });
        }
        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('seo-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('seo-delete')) {
                $delete = '<a data-url="' . url('seo-setting', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
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
            return [
                'id' => $row->id,
                'language_id' => $row->language_id ?? '',
                'language_name' => $row->language ? $row->language->language : '',
                'page_type' => $row->page_type,
                'page_type_badge' => page_type($row->page_type),
                'meta_keyword' => $meta_keyword,
                'meta_title' => $row->meta_title,
                'schema_markup' => $row->schema_markup,
                'meta_description' => $row->meta_description,
                'og_image' => !empty($row->og_image) ? '<a href="' . $row->og_image . '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' . $row->og_image . '" height="50" width="50"></a>' : '-',
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
        ResponseService::noPermissionThenRedirect('seo-create');
        try{

            $validator = Validator::make($request->all(), [
                'language' => 'required|numeric',
                'page_type' => 'required|string|max:255',
                'meta_keyword' => 'required',
                'meta_title' => 'required|string|max:255',
                'meta_description' => 'required|string|max:255',
                'og_image' => 'required|image|mimes:jpeg,png,jpg,gif,svg,webp|max:2048',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $meta_keyword = json_decode($request->meta_keyword, true);
            WebSeoPages::create([
                'language_id' => $request->language,
                'meta_title' => $request->meta_title ?? null,
                'schema_markup' => $request->schema_markup ?? null,
                'meta_description' => $request->meta_description ?? null,
                'meta_keyword' => $meta_keyword ? get_meta_keyword($meta_keyword) : null,
                'page_type' => $request->page_type,
                'og_image' => $request->hasFile('og_image') ?? compressAndUpload($request->file('og_image'), 'web_seo_pages')
            ]);

        return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SEOController -> store");
        }
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('seo-edit');
        try{

            $validator = Validator::make($request->all(), [
                'language' => 'required|numeric',
                'page_type' => 'required|string|max:255',
                'meta_keyword' => 'required',
                'meta_title' => 'required|string|max:255',
                'meta_description' => 'required|string|max:255',
                'og_image' => 'required|image|mimes:jpeg,png,jpg,gif,svg,webp|max:2048',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $meta_keyword = json_decode($request->meta_keyword, true);

            $res = WebSeoPages::findOrFail($request->edit_id);

            $og_image = $res->getRawOriginal('og_image');
            if($request->hasFile('og_image')){
                $og_image = compressAndReplace($request->file('og_image'), 'web_seo_pages', $res->getRawOriginal('og_image'));
            }

            $res->update([
                'language_id' => $request->language,
                'page_type' => $request->page_type,
                'meta_title' => $request->meta_title ?? null,
                'schema_markup' => $request->schema_markup ?? null,
                'meta_description' => $request->meta_description ?? null,
                'meta_keyword' => $meta_keyword ? get_meta_keyword($meta_keyword) : null,
                'og_image' => $og_image,
            ]);

            return ResponseService::successResponse(__('updated_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), $e);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SEOController -> update");
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('seo-delete');
        try{
            $seo = WebSeoPages::findOrFail($id);
            $seo->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), $e);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SEOController -> destroy");
        }
    }
}
