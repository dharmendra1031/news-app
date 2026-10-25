<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Services\BootstrapTableService;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Illuminate\Support\Facades\Validator;

class StaffController extends Controller
{
    /**
     * Display a listing of the staff members.
     */
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['staff-list', 'staff-create', 'staff-edit', 'staff-delete', 'staff-change-password']);
        try{
            
            $staff = Admin::with('roles')
            ->whereDoesntHave('roles', function($query) {
                $query->where('name', 'Admin');
            })
            ->get();
            
            $roles = Role::where('name', '!=', 'Admin')->get();
            return view('staff', compact('staff', 'roles'));
        }catch(Exception $e){
            return ResponseService::logErrorRedirectResponse($e, "StaffController -> index");
        }
    }

    /**
     * Store a newly created staff member.
     */
    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('staff-create');
        $validator = Validator::make($request->all(), [
            'username' => ['required', 'string', 'min:3', 'max:255', 'unique:admin'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:admin'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'exists:roles,id'],
            'status' => ['required', 'boolean'],
        ],[
            'username.required' => __('username_required'),
            'email.required' => __('email_required'),
            'password.required' => __('password_required'),
            'role.required' => __('role_required')
        ]);

        if ($validator->fails()) {
            return ResponseService::validationError($validator->errors()->first());
        }

        try {
            $staff = Admin::create([
                'username' => $request->username,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'status' => $request->status,
            ]);

            // Find role by ID and assign it
            $role = Role::findById($request->role, 'admin');
            $staff->assignRole($role);

            return ResponseService::successResponse(__('staff_member_created'));
        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "StaffController -> store");
        }
    }

    /**
     * Update the specified staff member.
     */
    public function update(Request $request, $id)
    {
        ResponseService::noPermissionThenRedirect('staff-edit');
        $staff = Admin::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'username' => ['required', 'string', 'min:3', 'max:255', 'unique:admin,username,' . $id],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:admin,email,' . $id],
            'role' => ['required', 'exists:roles,id'],
            'status' => ['required', 'boolean'],
        ]);

        if ($validator->fails()) {
            $response = [
                'error' => true,
                'message' => $validator->errors()->all(),
            ];
            return response()->json($response);
        }

        try {
            $staff->username = $request->username;
            $staff->email = $request->email;
            $staff->status = $request->status;

            // Update password if provided
            if ($request->filled('password')) {
                $request->validate([
                    'password' => ['required', 'string', 'min:8'],
                ]);
                $staff->password = Hash::make($request->password);
            }

            $staff->save();

            // Find role by ID and sync it
            $role = Role::findById($request->role, 'admin');
            $staff->syncRoles([$role]);

            $response = [
                'error' => false,
                'message' => __('staff_member_updated'),
            ];
            return response()->json($response);
        } catch (\Exception $e) {
            $response = [
                'error' => true,
                'message' => $e->getMessage(),
            ];
            return response()->json($response, 500);
        }
    }

    /**
     * Remove the specified staff member.
     */
    public function destroy($id)
    {
        ResponseService::noPermissionThenRedirect('staff-delete');
        try {
            $staff = Admin::findOrFail($id);

            $staff->delete();

            $response = [
                'error' => false,
                'message' => __('staff_member_deleted'),
            ];
            return response()->json($response);
        } catch (\Exception $e) {
            $response = [
                'error' => true,
                'message' => $e->getMessage(),
            ];
            return response()->json($response, 500);
        }
    }

    /**
     * Change staff member password.
     */
    public function changePassword(Request $request)
    {
        ResponseService::noPermissionThenRedirect('staff-change-password');
        $validator = Validator::make($request->all(), [
            'staff_id' => ['required', 'exists:admin,id'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        if ($validator->fails()) {
            $response = [
                'error' => true,
                'message' => $validator->errors()->all(),
            ];
            return response()->json($response);
        }

        try {
            $staff = Admin::findOrFail($request->staff_id);

            // Prevent changing admin users' passwords unless it's the current user
            if ($staff->hasRole('Admin') && $staff->id !== auth()->id()) {
                $response = [
                    'error' => true,
                    'message' => __('cannot_change_other_admin_users_passwords'),
                ];
                return response()->json($response, 403);
            }

            $staff->password = Hash::make($request->password);
            $staff->save();

            $response = [
                'error' => false,
                'message' => __('password_changed'),
            ];
            return response()->json($response);
        } catch (\Exception $e) {
            $response = [
                'error' => true,
                'message' => $e->getMessage(),
            ];
            return response()->json($response, 500);
        }
    }

    /**
     * Get staff list for datatable.
     */
    public function list(Request $request)
    {
        ResponseService::noPermissionThenRedirect('staff-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'ASC');
        $search = $request->input('search', '');

        $query = Admin::with('roles')->whereDoesntHave('roles', function ($q) {
            $q->where('name', 'Admin');
        });

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('username', 'LIKE', "%{$search}%")
                    ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if (isset($request->status)) {
            $query->where('status', $request->status);
        }

        $total = $query->count();

        $result = $query->orderBy($sort, $order)
            ->skip($offset)
            ->take($limit)
            ->get();


        $bulkData = array();
        $bulkData['total'] = $total;
        $rows = array();
        $no = 1;
        $canEdit = Auth::user()->can('staff-edit');
        $canDelete = Auth::user()->can('staff-delete');
        $canChangePassword = Auth::user()->can('staff-change-password');

        foreach ($result as $row) {
            $tempRow = $row->toArray();
            $tempRow['no'] = $no++;
            $tempRow['role_id'] = $row->roles->first() ? $row->roles->first()->id : '';
            $tempRow['role_name'] = $row->roles->first() ? $row->roles->first()->name : '';
            $tempRow['status'] = $row->status;

            $actions = [];
            if ($canEdit) {
                $actions[] = [
                    'text' => __('edit'),
                    'icon' => 'fa fa-edit text-primary',
                    'class' => 'edit-data',
                    'data-toggle' => 'modal',
                    'data-target' => '#editDataModal',
                    'data-id' => $row->id,
                ];
            }

            if ($canDelete) {
                $actions[] = [
                    'text' => __('delete'),
                    'icon' => 'fa fa-trash text-danger',
                    'class' => 'delete-form',
                    'data-url' => route('staff.destroy', $row->id),
                    'data-id' => $row->id,
                    'data-title' => __('are_you_sure'),
                ];
            }

            if($canChangePassword) {
                $actions[] = [
                    'text' => __('change_password'),
                    'icon' => 'fa fa-key text-primary',
                    'class' => 'change-password',
                    'data-id' => $row->id,
                ];
            }

            $operate = '';
            if (!empty($actions)) {
                $operate .= BootstrapTableService::dropdown(
                    'fa fa-ellipsis-v',
                    $actions,
                );
            }

            $tempRow['operate'] = $operate;
            $rows[] = $tempRow;
        }


        $bulkData['rows'] = $rows;

        return response()->json($bulkData);
    }


}
