<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\Pages;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class PagesController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['page-list', 'page-create', 'page-edit', 'page-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            return view('pages', compact('languageList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "PagesController -> index");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('page-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = Pages::with('language:id,language')->orderBy($sort, $order);
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                    ->orWhere('title', 'LIKE', "%{$search}%")
                    ->orWhere('slug', 'LIKE', "%{$search}%");
            });
        }
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('status') && $request->status != '') {
            $sql->where('status', $request->status);
        }
        if ($request->has('page_type') && $request->page_type != '') {
            $sql->where('page_type', $request->page_type);
        }
        // if ($request->policy_type != '') {
        //     $policy_type = $request->policy_type;
        //     if ($policy_type == 'terms_policy') {
        //         $sql = $sql->where('is_termspolicy', 1);
        //     }
        //     if ($policy_type == 'privacy_policy') {
        //         $sql = $sql->where('is_privacypolicy', 1);
        //     }
        // }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('page-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            if(!in_array($row->id, [1, 2, 3, 4])){
                $delete = '';
                if (auth()->user()->can('page-delete')) {
                    $delete = '<a data-url="' . url('pages', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
                }
                $readonly = false;
            } else {
                $delete = '';
                if (auth()->user()->can('page-edit')) {
                    $delete = '<a href="'.url('settings') .'/'. $row->slug .'" target="_blank" class="dropdown-item"><i class="fa fa-link mr-1 text-danger" title="' . __('generate_link') . '"></i>'.__('generate_link').'</a>';
                }
                $readonly = true;
            }
            $operate = '';
            if (auth()->user()->can('page-edit') || auth()->user()->can('page-delete')) {
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
            json_decode($row->meta_keywords);
            if (json_last_error() === JSON_ERROR_NONE) {
                $meta_keyword = json_decode($row->meta_keywords);
            } else {
                $meta_keyword = $row->meta_keywords;
            }
            return [
                'readonly' => $readonly,
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'title' => $row->title,
                'slug' => $row->slug,
                'page_type' => $row->page_type,
                'page_content' => $row->page_content,
                'schema_markup' => $row->schema_markup,
                'meta_title' => $row->meta_title,
                'meta_description' => $row->meta_description,
                'meta_keyword' => $meta_keyword,
                'status' => $row->status,
                'status1' => $row->status == '1' ? '<div class="badge badge-success">' . __('active') . '</div>' : '<div class="badge badge-danger">' . __('deactive') . '</div>',
                'image' => !empty($row->page_icon) ? '<a href="' . $row->page_icon . '" data-toggle="lightbox" data-title="Image"><img class="images_border" src="' . $row->page_icon . '" height="50" width="50"></a>' : '-',
                'og_image' => !empty($row->og_image) ? '<a href="' . $row->og_image . '" data-toggle="lightbox" data-title="Image"><img class="images_border" src="' . $row->og_image . '" height="50" width="50"></a>' : '-',
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
        ResponseService::noPermissionThenRedirect('page-create');
       try{

            $validator = Validator::make($request->all(), [
                'language' => 'required',
                'title' => 'required|string|max:255',
                'page_type' => 'required',
                'slug' => 'required|string|max:255',
                'page_content' => 'required|string'
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = $request->language;
            $page_type = $request->page_type;

            if ($page_type != 'custom') {
                $slug = $request->slug;
                $existingSlug = Pages::where('language_id', $language_id)->where('page_type', $page_type)->exists();
                if ($existingSlug) {
                    return ResponseService::validationError(__('page_already_exists'));
                }
            } else {
                $slug = generateUniqueSlug($request->slug);
                $existingSlug = Pages::where('language_id', $language_id)->where('slug', $slug)->exists();
                if ($existingSlug) {
                    return ResponseService::validationError(__('slug_already_use'));
                }
            }

            $page_icon = '';
            if ($request->hasFile('file')) {
                $page_icon = compressAndUpload($request->file('file'), 'pages');
            }
            $og_image = '';
            if ($request->hasFile('og_file')) {
                $og_image = compressAndUpload($request->file('og_file'), 'pages_og_image');
            }
            $language_id = $request->language;
            $title = $request->title;
            $meta_keyword = json_decode($request->meta_keyword, true);
            Pages::create([
                'language_id' => $language_id,
                'title' => $title,
                'page_type' => $request->page_type,
                'slug' => $slug,
                'schema_markup' => $request->schema_markup ?? '',
                'meta_title' => $request->meta_title ?? '',
                'meta_description' => $request->meta_description ?? '',
                'meta_keywords' => $meta_keyword ? get_meta_keyword($meta_keyword) : '',
                'page_content' => $request->page_content,
                'is_termspolicy' => 0,
                'is_privacypolicy' => 0,
                'status' => 1,
                'og_image' => $og_image,
                'page_icon' => $page_icon,
            ]);

            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'PagesController -> store');
        }
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('page-edit');
        try{
            $validator = Validator::make($request->all(), [
                'language' => 'required|numeric',
                'title' => 'required|string|max:255',
                'page_type' => 'required|string|max:255',
                'slug' => 'required|string|max:255',
                'page_content' => 'required|string',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $page = Pages::findOrFail($request->edit_id);

            /*
            |--------------------------------------------------------------------------
            | Slug Handling
            |--------------------------------------------------------------------------
            */

            if ($request->page_type !== 'custom') {

                $exists = Pages::where('language_id', $request->language)
                    ->where('page_type', $request->page_type)
                    ->where('id', '!=', $page->id)
                    ->exists();

                if ($exists) {
                    return ResponseService::validationError(__('page_already_exists'));
                }

                $slug = $request->slug;

            } else {

                $slug = generateUniqueSlug($request->slug);

                $exists = Pages::where('language_id', $request->language)
                    ->where('slug', $slug)
                    ->where('id', '!=', $page->id)
                    ->exists();

                if ($exists) {
                    return ResponseService::validationError(__('slug_already_use'));
                }
            }

            /*
            |--------------------------------------------------------------------------
            | File Handling
            |--------------------------------------------------------------------------
            */

            if ($request->hasFile('file')) {
                $page->page_icon = compressAndReplace(
                    $request->file('file'),
                    'pages',
                    $page->getRawOriginal('page_icon')
                );
            }

            if ($request->hasFile('og_file')) {
                $page->og_image = compressAndReplace(
                    $request->file('og_file'),
                    'pages_og_image',
                    $page->getRawOriginal('og_image')
                );
            }

            // meta keywords handling
            $metaKeyword = json_decode($request->meta_keyword, true);
            $page->update([
                'language_id'     => $request->language,
                'title'           => $request->title,
                'page_type'       => $request->page_type,
                'slug'            => $slug,
                'page_content'    => $request->page_content,
                'status'          => $request->status ?? $page->status,
                'schema_markup'   => $request->schema_markup ?? '',
                'meta_title'      => $request->meta_title ?? '',
                'meta_description'=> $request->meta_description ?? '',
                'meta_keywords'   => $metaKeyword ? get_meta_keyword($metaKeyword) : '',
            ]);

            return ResponseService::successResponse(__('updated_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'PagesController -> update');
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('page-delete');
        try{

            $page = Pages::findOrFail($id);
            $page->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'), null, 404);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, 'PagesController -> destroy');
        }
    }
}
