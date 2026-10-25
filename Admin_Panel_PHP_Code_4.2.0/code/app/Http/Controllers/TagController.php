<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\News;
use App\Models\Tag;
use App\Services\ResponseService;
use Illuminate\Http\Request;
use Exception;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use App\Services\ValidationService;

class TagController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['tag-list', 'tag-create', 'tag-edit', 'tag-delete']);
        try {
            $languageList = Language::where('status', 1)->get();
            return view('tag', compact('languageList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "TagController -> index");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('tag-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        $sql = Tag::with('language');

        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")->orwhere('tag_name', 'LIKE', "%{$search}%")->orwhere('slug','LIKE',"%{$search}%");
            });
        }
        $total = $sql->count();
        $sql = $sql->orderBy($sort, $order)->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            $delete = '';
            if (auth()->user()->can('tag-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            if (auth()->user()->can('tag-delete')) {
                $delete = '<a data-url="' . url('tag', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '" data-title="' . __('are_you_sure') . '" data-text="' . __('deleting_a_tag_it_will_breaks_relations_to_news_without_additional_confirmation') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }
            if ($edit == '' && $delete == '') {
                $operate = '-';
            }
            else{
                $operate =
                '<div class="dropdown">
                            <a href="javascript:void(0) role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
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
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'tag_name' => $row->tag_name,
                'slug' => $row->slug,
                'schema_markup' => $row->schema_markup,
                'meta_title' => $row->meta_title,
                'meta_keyword' => $meta_keyword,
                'description' => $row->meta_description,
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
        try {
            ResponseService::noPermissionThenRedirect('tag-create');
            $request->validate([
                'language' => 'required',
                'name' => 'required|string|max:255',
                'slug' => 'required|string|max:255',
            ]);

            $slug = generateUniqueSlug($request->slug);
            $existingSlug = Tag::where('slug', $slug)->exists();
            if ($existingSlug) {
                return ResponseService::errorResponse(__('slug_already_use'));
            }
            $ogImage = '';
            if ($request->hasFile('file')) {
                $ogImage = compressAndUpload($request->file('file'), 'tag_og_image');
            }
            $meta_keyword = json_decode($request->meta_keyword, true);
            
            Tag::create([
                'language_id' => $request->language,
                'tag_name' => $request->name,
                'slug' => $slug,
                'schema_markup' => $request->schema_markup ?? '',
                'meta_title' => $request->meta_title ?? '',
                'meta_description' => $request->meta_description ?? '',
                'meta_keyword' => $meta_keyword ? get_meta_keyword($meta_keyword) : '',
                'og_image' => $ogImage,
            ]);
            
            return ResponseService::successResponse(__('created_success'));
        }catch (Exception $e) {
            return ResponseService::logErrorResponse($e, 'TagController -> store');
        }
    }

    public function update(Request $request)
    {
        try {
            ResponseService::noPermissionThenRedirect('tag-edit');
            $request->validate([
                'language' => 'required',
                'name' => 'required|string|max:255',
                'slug' => 'required|string|max:255',
            ]);
            $slug = generateUniqueSlug($request->slug);
            $existingSlug = Tag::where('slug', $slug)
                ->where('id', '!=', $request->edit_id)
                ->exists();
            if ($existingSlug) {
                return ResponseService::errorResponse(__('slug_already_use'));
            }
            
            $tag = Tag::find($request->edit_id);
            $ogImage = '';
            if ($request->hasFile('file')) {
                $ogImage = compressAndReplace($request->file('file'), 'tag_og_image', $tag->getRawOriginal('og_image'));
            }
            $meta_keyword = json_decode($request->meta_keyword, true);
            
            $tag->update([
                'language_id' => $request->language,
                'tag_name' => $request->name,
                'slug' => $slug,
                'schema_markup' => $request->schema_markup ?? '',
                'meta_title' => $request->meta_title ?? '',
                'meta_description' => $request->meta_description ?? '',
                'meta_keyword' => $meta_keyword ? get_meta_keyword($meta_keyword) : '',
                'og_image' => $request->hasFile('file') ? $ogImage : $tag->getRawOriginal('og_image'),
            ]);

            return ResponseService::successResponse(__('updated_success'));
        } catch (Exception $e){
            return ResponseService::logErrorResponse($e, 'TagController -> update');
        }
    }

    public function destroy(string $id)
    {
        try{

            ResponseService::noPermissionThenRedirect('tag-delete');
            News::whereRaw('FIND_IN_SET(?, tag_id)', [$id])
            ->get()
            ->each(function ($news) use ($id) {
                $tagIds = explode(',', $news->tag_id); // Split the tag_ids into an array
                $tagIds = array_diff($tagIds, [$id]); // Remove the specified tag ID
                $news->tag_id = implode(',', $tagIds); // Join the remaining tag_ids back into a comma-separated list
                $news->save(); // Save the updated news item
            });

            Tag::find($id)->delete();

            return ResponseService::successResponse(__('deleted_success'));

        }catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "TagController -> destroy");
        }
    }

    public function get_tag_by_language(Request $request)
    {
        try {
            $language_id = $request->language_id;
            $res = Tag::where('language_id', $language_id)->get();
            // $option = '<option value="">'.__('select') . ' ' . __('tag').'</option>';
            $option = '';
            if (!empty($res)) {
                foreach ($res as $value) {
                    $option .= '<option value="' . $value['id'] . '" data-text="' . $value['tag_name'] . '">' . $value['tag_name'] . '</option>';
                }
            }
            return $option;
        } catch (Exception $e) {
            // ResponseService::logErrorResponse($e, "TagController -> get_tag_by_language");
            return '';
        }
    }

    /**
     * Search tags by name with debouncing support
     * Returns matching tags for autocomplete
     */
    public function searchTags(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_id' => 'required|exists:tbl_languages,id',
                'search' => 'nullable|string|max:255',
            ]);

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $languageId = $request->language_id;
            $search = $request->input('search', '');

            $query = Tag::where('language_id', $languageId);

            if (!empty($search)) {
                $query->where('tag_name', 'LIKE', "%{$search}%");
            }

            $tags = $query->orderBy('tag_name', 'ASC')
                ->limit(20)
                ->get(['id', 'tag_name']);

            $results = $tags->map(function ($tag) {
                return [
                    'id' => $tag->id,
                    'text' => $tag->tag_name,
                ];
            });

            return response()->json([
                'error' => false,
                'results' => $results,
            ]);

        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "TagController -> searchTags");
        }
    }

    /**
     * Create tag or return existing tag
     * If tag exists, returns it; otherwise creates new tag
     */
    public function createTag(Request $request)
    {
        try {

            $tagName = trim($request->tag_name);
            $languageId = $request->language_id;
            $slug = generateUniqueSlug($tagName);

            // Check if tag exists by slug and language
            $existingTag = Tag::where('language_id', $languageId)
                ->where('slug', $slug)
                ->first();

            if ($existingTag) {
                return ResponseService::successResponse('Tag already exists', [
                    'id' => $existingTag->id,
                    'tag_name' => $existingTag->tag_name,
                    'text' => $existingTag->tag_name,
                ]);
            }

            // Create new tag
            $tag = Tag::create([
                'tag_name' => $tagName,
                'slug' => $slug,
                'language_id' => $languageId,
            ]);

            return ResponseService::successResponse('Tag created successfully', [
                'id' => $tag->id,
                'tag_name' => $tag->tag_name,
                'text' => $tag->tag_name,
            ]);

        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "TagController -> createTag");
        }
    }
    public function tagBulkDelete(request $request){
        ResponseService::noPermissionThenRedirect('tag-delete');
        
        $validator = ValidationService::bulkDeleteValidator($request, 'tbl_tag');

            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {
        $request_ids = $request->request_ids;

    /*
    |--------------------------------------------------------------------------
    | Update news tag_ids
    |--------------------------------------------------------------------------
    */

    $removeIds = array_flip($request_ids);

    News::where(function ($query) use ($request_ids) {

        foreach ($request_ids as $id) {
            $query->orWhereRaw('FIND_IN_SET(?, tag_id)', [$id]);
        }

    })
    ->select('id', 'tag_id')
    ->chunkById(500, function ($newsItems) use ($removeIds) {

        foreach ($newsItems as $news) {

            $filtered = [];

            foreach (explode(',', $news->tag_id) as $tagId) {

                if (!isset($removeIds[$tagId])) {
                    $filtered[] = $tagId;
                }
            }

            $news->tag_id = implode(',', $filtered);

            $news->save();
        }
    });

    /*
    |--------------------------------------------------------------------------
    | Collect images before delete
    |--------------------------------------------------------------------------
    */

    $images = Tag::query()
        ->whereIn('id', $request_ids)
        ->toBase()
        ->pluck('og_image')
        ->filter()
        ->values()
        ->toArray();

    /*
    |--------------------------------------------------------------------------
    | Delete all tags in single query
    |--------------------------------------------------------------------------
    */

    Tag::query()
        ->whereIn('id', $request_ids)
        ->toBase()
        ->delete();

    /*
    |--------------------------------------------------------------------------
    | Delete images from storage
    |--------------------------------------------------------------------------
    */

    if (!empty($images)) {
        Storage::disk('public')->delete($images);
    }

    return ResponseService::successResponse(__('deleted_success'));

} catch (Exception $e) {

    return ResponseService::logErrorResponse(
        $e,
        "TagController -> tag_bulk_delete"
    );
}
    }
}
