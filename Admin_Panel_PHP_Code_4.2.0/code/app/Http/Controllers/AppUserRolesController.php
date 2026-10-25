<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Role;
use App\Services\ResponseService;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\Validator;

class AppUserRolesController extends Controller
{
    public function index()
    {
        return view('app-user-role');
    }

    public function store(Request $request)
    {
        try{
            $validator = Validator::make($request->all(), [
                'role' => 'required|string|max:255|unique:tbl_user_roles,role',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            Role::create([
                'role' => $request->role,
            ]);
            return ResponseService::successResponse(__('created_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "AppUserRolesController -> store");
        }
    }

    public function show(Request $request)
    {
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        $sql = Role::orderBy($sort, $order);
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{{ $search }}%")->orwhere('role', 'LIKE', "%{$search}%");
            });
        }
        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit);
        $rows = $sql->get()->map(function ($row) {
            $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            $delete = '<a data-url="' . url('app_users_roles', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
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

            return [
                'id' => $row->id,
                'role' => $row->role,
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }
    public function update(Request $request, string $id)
    {
        $request->validate([
            'role' => 'required|string|max:255', // Adjust validation rules as needed
        ]);
        $role = Role::find($id);
        $role->role = $request->input('role');
        $role->save();
        $response = [
            'error' => false,
            'message' => __('updated_success'),
        ];
        return response()->json($response);
    }
    public function destroy(string $id)
    {
        try{
            $role = Role::findOrFail($id);
            $role->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('role_not_found'), null, config('constants.RESPONSE_CODE.NO_DATA_FOUND'), $e);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "AppUserRolesController -> destroy");
        }
    }
}
