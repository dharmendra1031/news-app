<?php

namespace App\Http\Controllers;

use App\Models\Author;
use App\Models\Token;
use App\Models\User;
use App\Services\BootstrapTableService;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Validator;

class AuthorController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        try{
            ResponseService::noPermissionThenRedirect('author-list');
            return view('author.index');
        }catch(Exception $e){
            return ResponseService::logErrorRedirectResponse($e, "AuthorController -> index");
        }
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Request $request, string $id)
    {
        //
        ResponseService::noPermissionThenRedirect('author-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');
        $status = $request->input('status', '');

        $sql = Author::orderBy($sort, $order);

        $sql = $sql->with('user');

        if(!empty($status)){
            $sql = $sql->where('status', $status);
        }

        if (!empty($request->search)) {
            $sql = $sql->search($request->search);
        }

        $total = $sql->count();
        $sql = $sql->skip($offset)->take($limit);

        $result = $sql->get();
        $bulkData = array();
        $bulkData['total'] = $total;
        $rows = array();
        $no = 1;
        foreach ($result as $row) {
            $tempRow = $row->toArray();
            $tempRow['user']['email'] = hideEmailAddress( $row->user?->email ?? '');
            $tempRow['no'] = $no++;
            $tempRow['user_name'] = $row?->user?->name;
            // $tempRow['status'] = __($row->status);

            $operate = '';
            if (Auth::user()->can('author-edit')) {
                $operate .= BootstrapTableService::editButton(
                    route('author.update', $row->id),
                    true, // modal
                    '#editDataModal', // data-target
                    null,
                    null, // id
                    'fa fa-edit', // iconClass
                    null, // onClick
                    $row->id, // dataId
                    // $row->user_id // data-user-id
                );
            }



            $tempRow['operate'] = $operate;
            $rows[] = $tempRow;
        }



        $bulkData['rows'] = $rows;
        return response()->json($bulkData);

    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {

        ResponseService::noPermissionThenRedirect('author-edit');

        try {

            $validator = Validator::make($request->all(), [
                'author_status' => 'required|in:pending,approved,rejected',
            ]);

            if ($validator->fails()) {
                    return ResponseService::validationError($validator->errors()->first());
            }

            $author = Author::findOrFail($id);

            // dd($author->status);
            if($author->status != $request->author_status) {
                // dd($request->author_status);
                if($request->author_status == 'approved'){
                    $user = User::findOrFail($author->user_id);
                    $user->is_author = 1;
                    $user->save();
                    $user->ensureSlug();

                    $tokens = Token::where('user_id', $user->id)->first();
                    // notification
                    if($tokens?->language_id){

                        $fcmMsg = [
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                            'title' => 'Your author request has been approved',
                            'body' => 'Your author request has been approved',
                            'author_id' => $id,
                            'language_id' => $tokens->language_id ?? 1,
                            'type' => 'author_approved',
                        ];
                        send_notification($fcmMsg, $tokens->language_id, 0, [$tokens->token]);
                    }
                }elseif($request->author_status == 'rejected'){

                    $user = User::findOrFail($author->user_id);
                    $user->is_author = 0;
                    $user->save();

                    $tokens = Token::where('user_id', $user->id)->first();

                    // notification
                    if($tokens?->language_id){

                        $fcmMsg = [
                            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                            'title' => 'Your author request has been rejected',
                            'body' => 'Your author request has been rejected',
                            'author_id' => $id,
                            'language_id' => $tokens?->language_id,
                            'type' => 'author_rejected',
                        ];
                        send_notification($fcmMsg, $tokens?->language_id, 0, [$tokens->token]);
                    }
                }
            }
            if($request->author_status == 'pending'){
                $user = User::findOrFail($author->user_id);
                $user->is_author = 0;
                $user->save();
            }
            $author->status = $request->author_status;
            $author->auto_approve = $request->auto_approve;
            $author->save();
            return ResponseService::successResponse(__('author_status_updated'));

        } catch (Exception $e) {
            return ResponseService::logErrorResponse($e, "AuthorController -> update");
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
