<?php

namespace App\Http\Controllers\Api;

use App\Models\CommentNotification;
use App\Models\Comments;
use App\Models\CommentsFlag;
use App\Models\CommentsLike;
use App\Models\Token;
use App\Models\User;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class CommentApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Read
    // -------------------------------------------------------------------------

    public function getCommentByNews(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id'       => ['required', 'numeric', 'exists:tbl_news,id'],
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id  = Auth::check() ? Auth::user()->id : 0;
            $news_id  = $request->news_id;
            $response = $this->getCommentData('getCommentByNews', $user_id, $news_id, $request);

            return ResponseService::successResponse(__('Data fetched successfully'), $response);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'CommentApiController -> getCommentByNews');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Write
    // -------------------------------------------------------------------------

    public function setComment(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'news_id'       => ['required', 'numeric', 'exists:tbl_news,id'],
                'parent_id'     => ['nullable', 'numeric', 'exists:tbl_comment,id'],
                'message'       => 'required|string|max:1000',
                'language_code' => 'required|string|exists:tbl_languages,code',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id   = Auth::user()->id;
            $parent_id = $request->parent_id ?? 0;
            $news_id   = $request->news_id;
            $message   = $request->message;

            $comment   = Comments::create([
                'user_id'   => $user_id,
                'parent_id' => $parent_id,
                'news_id'   => $news_id,
                'message'   => $message,
                'status'    => 1,
                'date'      => $this->toDateTime,
            ]);

            $insert_id = $comment->id;

            if ($parent_id) {
                $res = Comments::find($parent_id);
                if (!empty($res)) {
                    $old_user_id = $res->user_id;
                    $language_id = $this->resolveLanguageId($request);
                    $get_name    = Auth::user()->name;

                    $fcmMsg = [
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                        'type'         => 'comment',
                        'news_id'      => $news_id,
                        'title'        => 'Reply in your comment ' . $res->message . ' by ' . $get_name,
                        'body'         => 'Reply in your comment ' . $res->message . ' by ' . $get_name,
                        'sound'        => 'default',
                    ];

                    $token = Token::where('user_id', $old_user_id)->first();
                    if (!empty($token) && $token->token) {
                        send_notification($fcmMsg, $language_id, 0, [$token->token],config('notification_types.COMMENTS'));
                    }

                    CommentNotification::create([
                        'master_id' => $insert_id,
                        'user_id'   => $old_user_id,
                        'sender_id' => $user_id,
                        'type'      => 'comment',
                        'message'   => 'Reply in your comment ' . $res->message . ' by ' . $get_name,
                        'date'      => $this->toDateTime,
                    ]);
                }
            }

            $response = $this->getCommentData('setComment', $user_id, $news_id, $request);

            return ResponseService::successResponse(__('Comment successfully'), $response);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'CommentApiController -> setComment');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function deleteComment(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'comment_id' => ['required', 'numeric'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $id      = $request->comment_id;
            $comment = Comments::find($id);

            if ($comment) {
                if ((int) $comment->user_id !== (int) Auth::id()) {
                    return ResponseService::errorResponse(__('Forbidden'), null, 403);
                }
                // Delete sub-comments first
                Comments::where('parent_id', $id)->get()->each(fn($sub) => $sub->delete());
                $comment->delete();

                return ResponseService::successResponse(__('Comment deleted!'));
            }

            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'CommentApiController -> deleteComment');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setCommentLikeDislike(Request $request)
    {
        try {
            $language_id = $this->resolveLanguageId($request);

            $validator = Validator::make($request->all(), [
                'comment_id'    => ['required', 'numeric', 'exists:tbl_comment,id'],
                'status'        => ['required', 'numeric', 'in:0,1,2'],
                'language_code' => 'required|string|exists:tbl_languages,code',
                'offset'        => 'nullable|integer|min:0',
                'limit'         => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id    = Auth::user()->id;
            $comment_id = $request->comment_id;
            $status     = $request->status;

            if ($status != '0') {
                $comment_like = CommentsLike::where('comment_id', $comment_id)->where('user_id', $user_id)->first();
                if (!empty($comment_like)) {
                    $comment_like->status = $status;
                    $comment_like->save();
                } else {
                    $comment_like = CommentsLike::create([
                        'user_id'    => $user_id,
                        'comment_id' => $comment_id,
                        'status'     => $status,
                    ]);
                }

                $insert_id = $comment_like->id;

                if ($status == '1') {
                    $res_comment = CommentsLike::find($insert_id);
                    if ($res_comment) {
                        $res_comment1 = Comments::find($res_comment->comment_id);
                        if ($res_comment1) {
                            $old_user_id = $res_comment1->user_id;
                            $token       = Token::where('user_id', $old_user_id)->first();
                            $get_name    = Auth::user()->name;

                            if (!empty($token) && $token->token) {
                                $fcmMsg = [
                                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                                    'type'         => 'comment_like',
                                    'language_id'  => $language_id,
                                    'title'        => 'Like in your comment ' . $res_comment1->message . ' by ' . $get_name,
                                    'body'         => 'Like in your comment ' . $res_comment1->message . ' by ' . $get_name,
                                    'sound'        => 'default',
                                ];
                                send_notification($fcmMsg, $language_id, 0, [$token->token],config('notification_types.COMMENTS'));
                            }

                            CommentNotification::create([
                                'master_id' => $insert_id,
                                'user_id'   => $old_user_id,
                                'sender_id' => $user_id,
                                'type'      => 'comment_like',
                                'message'   => 'Like in your comment ' . $res_comment1->message . ' by ' . $get_name,
                                'date'      => $this->toDateTime,
                            ]);
                        }
                    }
                }
            } else {
                CommentsLike::where('comment_id', $comment_id)->where('user_id', $user_id)->delete();
            }

            $res     = Comments::where('id', $comment_id)->first();
            $news_id = $res->news_id ?? 0;
            $response = $this->getCommentData('setCommentLikeDislike', $user_id, $news_id, $request);

            return ResponseService::successResponse(__('Comment like/dislike successfully'), $response);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'CommentApiController -> setCommentLikeDislike');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function setFlag(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'comment_id' => ['required', 'numeric', 'exists:tbl_comment,id'],
                'news_id'    => ['required', 'numeric', 'exists:tbl_news,id'],
                'message'    => 'required|string|max:1000',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            CommentsFlag::create([
                'comment_id' => $request->comment_id,
                'user_id'    => Auth::user()->id,
                'news_id'    => $request->news_id,
                'message'    => $request->message,
                'status'     => 1,
                'date'       => $this->toDateTime,
            ]);

            return ResponseService::successResponse(__('Flag successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'CommentApiController -> setFlag');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Private helper
    // -------------------------------------------------------------------------

    /**
     * Build and return the comment list for a given news article.
     * $from is used to select the success message.
     */
    private function getCommentData(string $from, int $user_id, int $news_id, Request $request)
    {
        $offset = $request->offset ?? 0;
        $limit  = $request->limit ?? 10;

        $res   = Comments::with('user:id,name,slug,profile,is_author')
            ->where('news_id', $news_id)
            ->where('parent_id', 0)
            ->where('status', 1);

        $total = $res->clone()->count('id');

        if (!$total) {
            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
        }

        $data = $res->clone()->orderBy('id', 'DESC')->skip($offset)->take($limit)->get();

        foreach ($data as $comment) {
            $comment_like = CommentsLike::where('comment_id', $comment->id);

            $comment->total_like    = $comment_like->clone()->where('status', 1)->count('id');
            $comment->total_dislike = $comment_like->clone()->where('status', 2)->count('id');
            $comment->like          = $comment_like->clone()->where('status', 1)->where('user_id', $user_id)->count('id');
            $comment->dislike       = $comment_like->clone()->where('status', 2)->where('user_id', $user_id)->count('id');

            $replies = Comments::with('user:id,name,slug,profile,is_author')
                ->where('news_id', $news_id)
                ->where('parent_id', $comment->id)
                ->where('status', 1)
                ->orderBy('id', 'ASC')
                ->get();

            foreach ($replies as $reply) {
                $reply_like = CommentsLike::where('comment_id', $reply->id);

                $reply->total_like    = $reply_like->clone()->where('status', 1)->count('id');
                $reply->total_dislike = $reply_like->clone()->where('status', 2)->count('id');
                $reply->like          = $reply_like->clone()->where('status', 1)->where('user_id', $user_id)->count('id');
                $reply->dislike       = $reply_like->clone()->where('status', 2)->where('user_id', $user_id)->count('id');
            }

            $comment->reply = $replies;
        }

        $message = match ($from) {
            'setComment'            => __('Comment successfully'),
            'setCommentLikeDislike' => __('updated Successfully'),
            default                 => __('Data fetched successfully'),
        };

        return ResponseService::successResponse($message, [
            'total' => $total,
            'data'  => $data,
        ]);
    }
}
