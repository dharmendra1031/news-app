<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\SocialMedia;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class SocialMediaController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['social-media-list', 'social-media-create', 'social-media-edit', 'social-media-delete']);
        try {
            $socialList = SocialMedia::orderBy('row_order', 'ASC')->get();
            return view('social-media', compact('socialList'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "SocialMediaController -> index");
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('social-media-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'row_order');
        $order = $request->input('order', 'ASC');

        $sql = SocialMedia::orderBy($sort, $order);        
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")->orwhere('link', 'LIKE', "%{$search}%");
            });
        }
        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('social-media-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }
            $delete = '';
            if (auth()->user()->can('social-media-delete')) {
                $delete = '<a data-url="' . url('social-media', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
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
            return [
                'id' => $row->id,
                'link' => $row->link,
                'image' => $row->image ? '<a href="' . $row->image . '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' . $row->image . '" height="50" width="50"></a>' : '-',
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
        ResponseService::noPermissionThenRedirect('social-media-create');
        try{
            $validator = Validator::make($request->all(), [
                'link' => 'required|url|max:255',
                'file' => 'required',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
            SocialMedia::create([
                'link' => $request->link,
                'image' => $request->hasFile('file') ? compressAndUpload($request->file('file'), 'social_media') : '',
                'row_order' => 0,
            ]);
            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SocialMediaController -> store");
        }

    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('social-media-edit');
        try{
            $validator = Validator::make($request->all(), [
                'link' => 'required|max:255',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $socialMedia = SocialMedia::findOrFail($request->edit_id);
            $socialMedia->update([
                'link' => $request->link,
                'image' => $request->hasFile('file') ? compressAndReplace($request->file('file'), 'social_media', $socialMedia->getRawOriginal('image')) : $socialMedia->getRawOriginal('image')
            ]);
            return ResponseService::successResponse(__('updated_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SocialMediaController -> update");
        }
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('social-media-delete');
        try{
            SocialMedia::findOrFail($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "SocialMediaController -> destroy");
        }
    }

    public function update_order(Request $request)
    {
        if ($request->row_order) {
            $row_order = explode(',', $request->row_order);
            foreach ($row_order as $key => $id) {
                SocialMedia::where('id', $id)->update(['row_order' => $key + 1]);
            }
        }
        return redirect('social-media')->with('success', __('updated_success'));
    }
}
