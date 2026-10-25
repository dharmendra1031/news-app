<?php

namespace App\Http\Controllers;

use App\Models\Author;
use App\Models\Role;
use App\Models\User;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;

class AppUserController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['user-list', 'user-edit']);
        $roleList = Role::all();
        return view('users', compact('roleList'));
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('user-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = User::where('id', '!=', 1); // id 1 for superadmin
        
        if (isset($request->status)) {
            $sql->where('status', $request->status);
        }
        if (isset($request->type)) {
            $sql->where('type', $request->type);
        }
        $total = $sql->count('id');
        $sql = $sql->search($request->search)->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $operate = '';
            if (auth()->user()->can('user-edit')) {
                $operate =
                '
            <a class="btn btn-icon  btn-primary text-white edit-data" data-id="' .
                $row->id .
                '" data-toggle="modal" data-target="#editDataModal" title="' .
                __('edit') .
                '"><em class="fa fa-edit"></em></a>';
            }

            return [
                'id' => $row->id,
                'firebase_id' => $row->firebase_id ?? '',
                'name' => $row->name ?? '',
                // 'type' => isset($row->type) && $row->type != '' ? '<em class="' . $icon[trim($row->type)] . ' fa-2x"></em>' : '<em class="' . $icon['email'] . ' fa-2x"></em>',
                'type' => $row->type,
                'email' => $row->email ? hideEmailAddress($row->email) : '',
                'mobile' => $row->mobile ? hideMobileNumber($row->mobile) : '',
                'profile' => !empty($row->profile) ? '<a href="' . $row->profile . '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' . $row->profile . '" height="50" width="50"></a>' : '-',
                'fcm_id' => $row->fcm_id ?? '',
                'status' => $row->status,
                'date' => date('d-m-Y H:i:s', strtotime($row->date)),
                // 'role_id' => $row->is_author ?? '',
                'role' => $row?->is_author,
                'created_at' => date('d-m-Y H:i:s', strtotime($row->created_at)),
                'updated_at' => date('d-m-Y H:i:s', strtotime($row->updated_at)),
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('user-edit');
        try{
            $appUser = User::findOrFail($request->edit_id);
            $appUser->status = $request->edit_status;
            $appUser->save();

            // rejecting the author
            $is_author = Author::where('user_id', $appUser->id)->first();

            if($is_author){
                $is_author->status = 'rejected';
                $is_author->save();
            }

            return ResponseService::successResponse(__('updated_success'));
        } catch (ModelNotFoundException $e) {
            return ResponseService::errorResponse(__('user_not_found'), 404);

        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "AppUserController -> update");
        }
    }
}
