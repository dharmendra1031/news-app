<?php

namespace App\Http\Controllers;

use App\Models\Comments;
use App\Models\CommentsFlag;
use App\Services\ResponseService;
use Illuminate\Http\Request;
use Exception;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;
use App\Services\ValidationService;

class CommentsController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['comment-list', 'comment-delete']);
        try {
            return view('comments');
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, "CommentsController -> index");
        }
    }

    public function index1()
    {
        ResponseService::noAnyPermissionThenRedirect(['comment-flag-list', 'comment-flag-delete']);
        try {
            return view('comments-flag');
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('comment-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = Comments::with('user', 'news');
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                    ->orwhere('message', 'LIKE', "%{$search}%");
                    $q->orWhereHas('user', function ($q1) use ($search) {
                        $q1->where('name', 'LIKE', "%{$search}%");
                    });
                    $q->orWhereHas('news', function ($q2) use ($search) {
                        $q2->where('title', 'LIKE', "%{$search}%");
                    });
            });
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $operate = '';
            if (auth()->user()->can('comment-delete')) {
                $operate .=
                '<a data-url="' .
                url('comments', $row->id) .
                '" class="btn btn-primary me-4 text-white delete-form" data-id="' .
                $row->id .
                '" title="' .
                __('delete') .
                '">
                <span class="fa fa-trash"></span>
            </a>';
            }
            return [
                'id' => $row->id,
                'user_id' => $row->user_id,
                'name' => $row->user->name ?? '',
                'title' => $row->news->title ?? '',
                'message' => $row->message,
                'operate' => $operate,
            ];
        });
        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('comment-delete');
        try{
            // for remove sub comment data
            $sub_comment = Comments::select('id')->where('parent_id', $id)->get();
            if (!$sub_comment->isEmpty()) {
                foreach ($sub_comment as $row) {
                    Comments::find($row->id)->delete();
                }
            }
            Comments::find($id)->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "CommentsController -> destroy");
        }
    }

    public function comment_delete(string $id)
    {
        ResponseService::noPermissionThenRedirect('comment-flag-delete');
        try{
            $commentFlag = CommentsFlag::findOrFail($id);
            $commentFlag->delete();
            return ResponseService::successResponse(__('deleted_success'));
        }catch(ModelNotFoundException $e){
            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), $e);
        }catch(Exception $e){
            return ResponseService::logErrorResponse($e, "CommentsController -> comment_delete");
        }
    }

    public function comment_flag(Request $request)
    {
        ResponseService::noPermissionThenRedirect('comment-flag-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'id');
        $order = $request->input('order', 'DESC');

        $sql = CommentsFlag::with('user', 'news', 'comment');
        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                  ->orwhere('message','like',"%{$search}%")
                  ->orWhereHas('user', fn($s) => $s->where('name', 'LIKE', "%{$search}%"))
                  ->orWhereHas('news', fn($s) => $s->where('title', 'LIKE', "%{$search}%"))
                  ->orWhereHas('comment', fn($s) => $s->where('message', 'LIKE', "%{$search}%"));

            });
        }
        $total = $sql->count('id');
        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);
        $rows = $sql->get()->map(function ($row) {
            $operate = '';
            if (auth()->user()->can('comment-flag-delete')) {
                $operate .=
                '
            <a data-url="' .
                url('comments-delete/' . $row->id) .
                '" class="btn btn-primary me-4 text-white delete-form" data-id="' .
                $row->id .
                '" title="' .
                __('delete') .
                ' Comment Flag">
                <span class="fa fa-trash"></span>
            </a>';
            }
            return [
                'id' => $row->id,
                'comment_id' => $row->comment_id,
                'user_id' => $row->user_id ?? '',
                'news_id' => $row->news_id ?? '',
                'name' => $row->user->name ?? '',
                'message' => $row->message ?? '',
                'comment' => $row->comment->message ?? '',
                'title' => $row->news->title ?? '',
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

    public function bulkCommentDelete(Request $request)
    {
        ResponseService::noPermissionThenRedirect('comment-bulk-delete');
         $validator = ValidationService::bulkDeleteValidator($request,'tbl_comment');
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
        try {

            $request_ids = collect($request->request_ids)
                ->filter()
                ->unique()
                ->values();

            if ($request_ids->isEmpty()) {
                return ResponseService::errorResponse(__('No Data Found'));
            }

            $request_ids->chunk(200)->each(function ($chunkIds) {

                CommentsFlag::query()
                    ->whereIn('comment_id', $chunkIds)
                    ->toBase()
                    ->delete();
            });

            $request_ids->chunk(200)->each(function ($chunkIds) {

                Comments::query()
                    ->whereIn('id', $chunkIds)
                    ->toBase()
                    ->delete();
            });

            return ResponseService::successResponse(__('deleted_success'));

        } catch (Exception $e) {

            return ResponseService::logErrorResponse(
                $e,
                "CommentsController -> bulk_comment_delete"
            );
        }
    }

public function bulkCommentflagDelete(Request $request)
{
    ResponseService::noPermissionThenRedirect('comment-flag-delete');

    $validator = ValidationService::bulkDeleteValidator($request,'tbl_comment_flag');
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }
    try {
        $request_ids = collect($request->request_ids)
            ->filter()
            ->unique()
            ->values();

        if ($request_ids->isEmpty()) {
            return ResponseService::errorResponse(__('No Data Found'));
        }

        DB::transaction(function () use ($request_ids) {
            $request_ids->chunk(200)->each(function ($chunkIds) {
                CommentsFlag::query()
                    ->whereIn('id', $chunkIds)
                    ->delete();
            });
        });

        return ResponseService::successResponse(__('deleted_success'));

    } catch (\Throwable $e) {
        return ResponseService::errorResponse($e->getMessage());
    }
}
}
