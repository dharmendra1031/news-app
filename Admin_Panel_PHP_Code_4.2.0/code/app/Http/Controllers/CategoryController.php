<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Language;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['category-list', 'category-create', 'category-edit', 'category-delete', 'category-order-create']);
        try {
            $languageList = Language::where('status', 1)->get();
            $categoryList = Category::select('id', 'category_name')->orderBy('row_order', 'ASC')->get();
            return view('category', compact('languageList', 'categoryList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "CategoryController -> index");
        }
    }

    public function get_category_by_language(Request $request)
    {
        try {
            $language_id = $request->language_id;

            $query = Category::select('id', 'category_name');

            if ($language_id == 0 && $request->sortable) {
                $res = $query->get();
            } else {
                $res = $query->where('language_id', $language_id)->orderBy('row_order', 'ASC')->get();
            }

            if ($request->sortable) {
                return $res->map(fn($row) => '<li id="' . $row->id . '">' . $row->category_name . '</li>')->implode('');
            }

            $options = '<option value="">' . __('select') . ' ' . __('category') . '</option>';
            $options .= $res->map(fn($row) => '<option value="' . $row->id . '">' . $row->category_name . '</option>')->implode('');
            return $options;
        } catch (Exception $e) {
            return '';
            // ResponseService::logErrorResponse($e, 'CategoryController@get_category_by_language');
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('category-list');
        try {
            $offset = $request->input('offset', 0);
            $limit  = $request->input('limit', 10);
            $sort   = $request->input('sort', 'row_order');
            $order  = $request->input('order', 'ASC');

            $query = Category::with('language')->withCount('news');

            // language_id null than fetch all

            if ($request->filled('language_id')) {
                $query->where('language_id', $request->language_id);
            }

            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('id', 'LIKE', "%{$search}%")->orWhere('category_name', 'LIKE', "%{$search}%")->orwhere('slug','LIKE',"%{$search}%");
                });
            }

            $total = $query->count();
            $rows  = $query->orderBy($sort, $order)->skip($offset)->take($limit)->get()->map(function ($row) {
                $edit   = auth()->user()->can('category-edit')
                    ? '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>'
                    : '';

                $delete = auth()->user()->can('category-delete')
                    ? '<a data-url="' . url('category', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '" data-title="' . __('are_you_sure') . '" data-text="' . __('deleting_a_category_subcategory_or_tag_automatically_deletes_related_news_without_additional_confirmation') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>'
                    : '';

                $operate = ($edit === '' && $delete === '')
                    ? '-'
                    : '<div class="dropdown">
                            <a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                <button class="btn btn-primary btn-sm px-3 operatebtn"><i class="fas fa-ellipsis-v"></i></button>
                            </a>
                            <div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">
                            ' . $edit . $delete . '
                            </div>
                        </div>';

                $decoded      = json_decode($row->meta_keyword);
                $meta_keyword = json_last_error() === JSON_ERROR_NONE ? $decoded : $row->meta_keyword;

                return [
                    'id'           => $row->id,
                    'language_id'  => $row->language_id ?? '',
                    'language_name'=> $row->language?->language ?? '',
                    'category_name'=> $row->category_name,
                    'slug'         => $row->slug,
                    'meta_keyword' => $meta_keyword,
                    'schema_markup'=> $row->schema_markup,
                    'description'  => $row->meta_description,
                    'meta_title'   => $row->meta_title,
                    'news_count'   => $row->news_count,
                    'image'        => $row->image,
                    'row_order'    => $row->row_order,
                    'operate'      => $operate,
                ];
            });

            return response()->json(['total' => $total, 'rows' => $rows]);
        } catch (Exception $e) {
            return response()->json(['error' => true, 'message' => $e->getMessage()]);
        }
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('category-create');
        try {
            $validator = Validator::make($request->all(), [
                'language' => ['required', 'numeric'],
                'name'     => ['required', 'max:255'],
                'slug'     => ['required', 'max:255'],
                'file'     => ['required'],
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => true, 'message' => $validator->errors()->all()]);
            }

            $slug = generateUniqueSlug($request->slug);

            if (Category::where('slug', $slug)->exists()) {
                return response()->json(['error' => true, 'message' => __('slug_already_use')]);
            }

            $meta_keyword = json_decode($request->meta_keyword, true);

            Category::create([
                'language_id'      => $request->language,
                'category_name'    => $request->name,
                'slug'             => $slug,
                'image'            => $request->hasFile('file') ? compressAndUpload($request->file('file'), 'category') : '',
                'schema_markup'    => $request->schema_markup ?? '',
                'meta_title'       => $request->meta_title ?? '',
                'meta_description' => $request->meta_description ?? '',
                'meta_keyword'     => $meta_keyword ? get_meta_keyword($meta_keyword) : '',
            ]);

            // return response()->json(['error' => false, 'message' => __('created_success')]);
            return ResponseService::successResponse(__('created_success'));
        } catch (Exception $e) {
            // return response()->json(['error' => true, 'message' => $e->getMessage()]);
            // log error
            return ResponseService::logErrorResponse($e, 'CategoryController -> store');
        }
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('category-edit');
        try {
            $validator = Validator::make($request->all(), [
                'language' => ['required', 'numeric'],
                'name'     => ['required', 'max:255'],
                'slug'     => ['required', 'max:255'],
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => true, 'message' => $validator->errors()->all()]);
            }

            $slug = generateUniqueSlug($request->slug);

            if (Category::where('slug', $slug)->where('id', '!=', $request->edit_id)->exists()) {
                return response()->json(['error' => true, 'message' => __('slug_already_use')]);
            }

            $category = Category::findOrFail($request->edit_id);

            $meta_keyword = json_decode($request->meta_keyword, true);

            $category->fill([
                'language_id'      => $request->language,
                'category_name'    => $request->name,
                'slug'             => $slug,
                'schema_markup'    => $request->schema_markup ?? '',
                'meta_title'       => $request->meta_title ?? '',
                'meta_description' => $request->meta_description ?? '',
                'meta_keyword'     => $meta_keyword ? get_meta_keyword($meta_keyword) : '',
            ]);

            if ($request->hasFile('file')) {
                $category->image = compressAndReplace($request->file('file'), 'category', $category->getRawOriginal('image'));
            }

            $category->save();

            // return response()->json(['error' => false, 'message' => __('updated_success')]);
            return ResponseService::successResponse(__('updated_success'));
        } catch (Exception $e) {
            // log error
            return ResponseService::logErrorResponse($e, 'CategoryController -> update');
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('category-delete');
        try {
            Category::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        } catch (Exception $e) {
            // log error
            return ResponseService::logErrorResponse($e, 'CategoryController -> destroy');
        }
    }

    public function update_order(Request $request)
    {
        ResponseService::noPermissionThenRedirect('category-order-create');
        try {
            if ($request->row_order) {
                foreach (explode(',', $request->row_order) as $key => $id) {
                    Category::where('id', $id)->update(['row_order' => $key + 1]);
                }
            }
            return redirect('category')->with('success', __('updated_success'));
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }
}
