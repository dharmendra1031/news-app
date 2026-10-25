<?php

namespace App\Http\Controllers;

use App\Models\Category;
use App\Models\Language;
use App\Models\SubCategory;
use App\Services\ResponseService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Exception;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class SubCategoryController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['sub-category-list', 'sub-category-create', 'sub-category-edit', 'sub-category-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            $categoryList = [];
            if (count($languageList) == 1) {
                $language_id = $languageList[0]->id;
                $categoryList = Category::select('id', 'category_name')->where('language_id', $language_id)->get();
            }
            $subcategoryList = SubCategory::select('id', 'subcategory_name')->orderBy('row_order', 'ASC')->get();
            return view('subcategory', compact('languageList', 'categoryList', 'subcategoryList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "SubCategoryController -> index");
        }
    }

    public function get_subcategory_by_category(Request $request)
    {
        try {
            $res = SubCategory::select('id', 'subcategory_name');
            if ($request->has('category_id')) {
                $res = $res->where('category_id', $request->category_id);
            }
            $res = $res->orderBy('row_order', 'ASC')->get();
            if (!empty($res)) {
                if ($request->sortable) {
                    $options = '';
                    foreach ($res as $row) {
                        $options .= '<li id="' . $row->id . '">' . $row->subcategory_name . '</li>';
                    }
                } else {
                    $options = '<option value="">' . __('select') . ' ' . __('subcategory') . '</option>';
                    foreach ($res as $row) {
                        $options .= '<option value="' . $row->id . '">' . $row->subcategory_name . '</option>';
                    }
                }
            }
            return $options;
        }catch(Exception $e){
            // return ResponseService::logErrorResponse($e, "SubCategoryController -> get_subcategory_by_category");
            return '';
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('sub-category-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'row_order');
        $order = $request->input('order', 'ASC');

        $sql = SubCategory::with(['category', 'language']);
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")->orwhere('subcategory_name', 'LIKE', "%{$search}%");
            });
        }
        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('category_id') && $request->category_id) {
            $sql = $sql->where('category_id', $request->category_id);
        }
        $total = $sql->count();
        $sql = $sql->orderBy($sort, $order)->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            $delete = '';

            // Check if the user has the permission to edit sub-category
            if (auth()->user()->can('sub-category-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '">
                            <i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '
                        </a>';
            }

            // Check if the user has the permission to delete sub-category
            if (auth()->user()->can('sub-category-delete')) {
                $delete = '<a data-url="' . url('sub_category', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '" data-title="' . __('are_you_sure') . '" data-text="' . __('deleting_a_subcategory_it_will_breaks_relations_to_news_without_additional_confirmation') . '">
                              <i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }

            // Check if both edit and delete are empty
            if ($edit == '' && $delete == '') {
                $operate = '-'; // No permissions, set operate to empty
            } else {
                // If any permission exists, generate the dropdown
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

            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'category_id' => $row->category_id,
                'category_name' => $row->category->category_name ?? '',
                'subcategory_name' => $row->subcategory_name,
                'slug' => $row->slug,
                'row_order' => '<span class="btn btn-icon btn-sm btn-warning move" alt="Move" >' . $row->row_order . '</span>',
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
        try {
            ResponseService::noPermissionThenRedirect('sub-category-create');
            $validator = Validator::make($request->all(), [
                'language' => 'required|numeric',
                'category' => 'required|numeric',
                'name' => 'required|max:255',
                'slug' => 'required|max:255',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $slug = generateUniqueSlug($request->slug);
            $existingSlug = SubCategory::where('slug', $slug)->exists();
            if ($existingSlug) {
                return ResponseService::validationError(__('slug_already_use'));
            }

            SubCategory::create([
                'language_id' => $request->language,
                'category_id' => $request->category,
                'subcategory_name' => $request->name,
                'slug' => $slug,
            ]);
            return ResponseService::successResponse(__('created_success'));
        }catch (Exception $e){
            return ResponseService::logErrorResponse($e, 'SubCategoryController -> store');
        }
    }

    public function update(Request $request)
    {
        try {
            ResponseService::noPermissionThenRedirect('sub-category-edit');
            $validator = Validator::make($request->all(), [
                'language' => 'required|numeric',
                'category' => 'required|numeric',
                'name'     => 'required|max:255',
                'slug'     => 'required|max:255',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            $slug = generateUniqueSlug($request->slug);
            $existingSlug = SubCategory::where('slug', $slug)
                ->where('id', '!=', $request->edit_id)
                ->exists();
            if ($existingSlug) {
                return ResponseService::validationError(__('slug_already_use'));
            }
            SubCategory::where('id', $request->edit_id)->update([
                'language_id' => $request->language,
                'category_id' => $request->category,
                'subcategory_name' => $request->name,
                'slug' => $slug,
            ]);
            return ResponseService::successResponse(__('updated_success'));
        }catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'SubCategoryController -> update');
        }
    }

    public function destroy(string $id)
    {
        try{
            ResponseService::noPermissionThenRedirect('sub-category-delete');
            SubCategory::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'));
        }catch (Exception $e){
            return ResponseService::logErrorResponse($e, 'SubCategoryController -> destroy');
        }
        
    }

    public function update_order(Request $request)
    {
        try{
            ResponseService::noPermissionThenRedirect('sub-category-order-create');
            if ($request->row_order) {
                $row_order = explode(',', $request->row_order);
                foreach ($row_order as $key => $id) {
                    SubCategory::where('id', $id)->update(['row_order' => $key + 1]);
                }
            }
        
            return ResponseService::successRedirectResponse(__('updated_success'), 'sub_category');
        }catch (Exception $e){
            return ResponseService::logErrorResponse($e, 'SubCategoryController -> update_order');
        }
    }
}
