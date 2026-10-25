<?php

namespace App\Http\Controllers\Api;

use App\Models\Author;
use App\Models\Bookmark;
use App\Models\BreakingNewsView;
use App\Models\CommentNotification;
use App\Models\Comments;
use App\Models\CommentsFlag;
use App\Models\CommentsLike;
use App\Models\News_like;
use App\Models\News_view;
use App\Models\Settings;
use App\Models\SurveyResult;
use App\Models\Token;
use App\Models\User;
use App\Models\UserCategory;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Kreait\Firebase\Factory;

class UserApiController extends BaseApiController
{
    // -------------------------------------------------------------------------
    // Auth / profile
    // -------------------------------------------------------------------------

    public function userSignup(Request $request)
    {
        Header('Access-Control-Allow-Origin: *');
        Header('Access-Control-Allow-Headers: *');
        Header('Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE');
        try {
            $validator = Validator::make($request->all(), [
                'id_token'    => 'required|string',
                'firebase_id' => 'nullable|string|max:255',
                'name'        => 'nullable|string|max:255',
                'email'       => 'nullable|email|max:255',
                'mobile'      => ['nullable', 'string', 'regex:/^\+?[0-9]{1,15}$/'],
                'profile'     => 'nullable|string|max:255',
                'fcm_id'      => 'nullable|string|max:255',
                'type'        => 'nullable|string|max:50',
                'status'      => 'nullable|in:0,1',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            // Verify the Firebase login (ID) token and only trust the firebase_id (uid)
            // extracted from the verified token. A client-supplied firebase_id is never
            // trusted on its own; if supplied it must match the verified uid.
            $firebaseConfigPath = public_path('assets/firebase_config.json');
            $projectId          = Settings::where('type', 'firebase_project_id')->value('message');

            if (!is_file($firebaseConfigPath) || empty($projectId)) {
                return ResponseService::errorResponse(__('Firebase configuration missing'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), null);
            }

            try {
                $firebaseAuth      = (new Factory)->withServiceAccount($firebaseConfigPath)->withProjectId($projectId)->createAuth();
                $verifiedIdToken   = $firebaseAuth->verifyIdToken($request->id_token);
                $firebase_id       = $verifiedIdToken->claims()->get('sub');
            } catch (\Throwable $e) {
                ResponseService::logErrorResponse($e, 'UserApiController -> userSignup verifyIdToken');
                return ResponseService::errorResponse(__('Invalid login token'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'), $e);
            }

            if (empty($firebase_id)) {
                return ResponseService::errorResponse(__('Invalid login token'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'), null);
            }

            if ($request->filled('firebase_id') && $request->firebase_id !== $firebase_id) {
                return ResponseService::errorResponse(__('Firebase ID mismatch'), null, config('constants.RESPONSE_CODE.UNAUTHORIZED'), null);
            }

            $user = User::where('firebase_id', $firebase_id)->first();

            if (!$user) {
                $user              = new User();
                $user->firebase_id = $firebase_id;
                $user->name        = $request->name ?? '';
                $user->type        = $request->type;
                $user->email       = $request->email ?? '';
                $user->mobile      = $request->mobile ?? '';
                $user->profile     = $request->profile ?? '';
                $user->fcm_id      = $request->fcm_id ?? '';
                $user->status      = $request->status ?? 1;
                $user->date        = $this->toDateTime;
                $user->is_author   = 0;
                $user->save();

                $userData          = User::with('author')->where('id', $user->id)->first();
                $userData['is_login'] = '0';
                $userData['token'] = $user->createToken('MyApp')->plainTextToken;

                return ResponseService::successResponse('User Registered successfully', $userData);
            }

            if ($user->status == 1) {
                if ($request->fcm_id) {
                    $user->fcm_id = $request->fcm_id;
                }

                if ($request->filled('name')) {
                    $user->name = $request->name;
                }

                if ($request->filled('email')) {
                    $user->email = $request->email;
                }

                if ($request->filled('mobile')) {
                    $user->mobile = $request->mobile;
                }

                $user->save();

                $userData          = User::with('author')->where('id', $user->id)->first();
                $userData['is_login'] = '1';
                $userData['token'] = $user->createToken('MyApp')->plainTextToken;

                return ResponseService::successResponse('Successfully logged in', $userData);
            }

            return ResponseService::errorResponse('User is deactivated.', null, config('constants.RESPONSE_CODE.UNAUTHORIZED'), null);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> userSignup');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getUserById()
    {
        try {
            $user_id = Auth::user()->id;
            $res     = User::with('user_category', 'author')->where('id', $user_id)->first();

            if ($res) {
                $res['is_login'] = '0';
                return ResponseService::successResponse(__('Data fetched successfully'), $res);
            }

            return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> getUserById');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function updateProfile(Request $request)
    {
         $rules = [
            'name'    => 'nullable|string|max:255',
            'mobile'  => ['nullable', 'string', 'regex:/^\+?[0-9]{1,15}$/'],
            'email'   => 'nullable|email|max:255',
            'profile' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ];


        if (Auth::user()->is_author == 1) {
            $rules = array_merge($rules, [
                'bio'            => 'nullable|string|max:255',
                'telegram_link'  => 'nullable|url|max:255',
                'linkedin_link'  => 'nullable|url|max:255',
                'facebook_link'  => 'nullable|url|max:255',
                'whatsapp_link'  => 'nullable|url|max:255',
            ]);
        }
        
        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return ResponseService::validationError(
                $validator->errors()->first()
            );
        }

        try { 
            
            $user_id = Auth::user()->id;
            $user    = User::find($user_id);
             
            if (!$user) {
                return ResponseService::errorResponse(__('User not found'));
            }

            $user->fill([
                'name'   => $request->filled('name') ? $request->name : $user->name,
                'mobile' => $request->filled('mobile') ? $request->mobile : $user->mobile,
                'email'  => $request->filled('email') ? $request->email : $user->email,
            ]);
            if ($request->hasFile('profile')) {
                $user->profile = compressAndReplace($request->file('profile'), 'profile', $user->getRawOriginal('profile'));
            }
            $user->save();

            if(Auth::user()->is_author == 1) {
                Author::updateOrCreate(
                    ['user_id' => $user_id],
                    [
                        'bio'            => $request->bio,
                        'telegram_link'  => $request->telegram_link,
                        'linkedin_link'  => $request->linkedin_link,
                        'facebook_link'  => $request->facebook_link,
                        'whatsapp_link'  => $request->whatsapp_link,
                    ]
                );

            }elseif(Auth::user()->is_author == 0 && ($request->has('bio')||$request->has('telegram_link')
            ||$request->has('linkedin_link')||$request->has('facebook_link')
            ||$request->has('whatsapp_link'))){
                Author::updateOrCreate(
                    ['user_id' => $user_id],
                    [
                        'bio'            => $request->bio,
                        'telegram_link'  => $request->telegram_link,
                        'linkedin_link'  => $request->linkedin_link,
                        'facebook_link'  => $request->facebook_link,
                        'whatsapp_link'  => $request->whatsapp_link,
                    ]);
            }
            
            // $res = User::with('author')->where('id', $user_id)->first();
            $res = $user->load('author');
            
            return ResponseService::successResponse(__('Profile updated successfully'), $res);
        } catch (Exception $e) {
            return ResponseService::errorResponse($e->getMessage());
        }
    }

    public function deleteUser()
    {
        try {
            $user_id = Auth::user()->id;

            Bookmark::where('user_id', $user_id)->delete();
            BreakingNewsView::where('user_id', $user_id)->delete();
            Comments::where('user_id', $user_id)->delete();
            CommentsFlag::where('user_id', $user_id)->delete();
            CommentsLike::where('user_id', $user_id)->delete();
            CommentNotification::where('user_id', $user_id)->delete();
            News_like::where('user_id', $user_id)->delete();
            News_view::where('user_id', $user_id)->delete();
            SurveyResult::where('user_id', $user_id)->delete();
            UserCategory::where('user_id', $user_id)->delete();
            Author::where('user_id', $user_id)->delete();
            // delete user query always at last
            User::where('id', $user_id)->delete();
            auth()->user()->tokens()->delete();

            return ResponseService::successResponse(__('User deleted successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> deleteUser');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Token registration
    // -------------------------------------------------------------------------

    public function registerToken(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|exists:tbl_languages,code',
                'token'         => 'required|string|max:255',
                'user_id'       => 'nullable|exists:tbl_users,id',
                'latitude'      => 'nullable|numeric|between:-90,90',
                'longitude'     => 'nullable|numeric|between:-180,180',
                'platform'      => 'nullable|string|in:android,ios,web',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $language_id = $this->resolveLanguageId($request);
            $token       = $request->token;
            $latitude    = $request->latitude ?? 0;
            $longitude   = $request->longitude ?? 0;
            $userId      = $request->user_id ?? null;

            Token::updateOrCreate(
                ['token' => $token],
                [
                    'token'       => $token,
                    'user_id'     => $userId,
                    'language_id' => $language_id,
                    'latitude'    => $latitude,
                    'longitude'   => $longitude,
                    'platform'    => $request->platform,
                ]
            );

            return ResponseService::successResponse(__('Device registered successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> registerToken');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function registerDeviceToken(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'device_id'   => ['required', 'string', 'max:255'],
                'token'       => ['required'],
                'language_id' => ['nullable', 'numeric'],
                'latitude'    => ['nullable', 'numeric'],
                'longitude'   => ['nullable', 'numeric'],
                'platform'    => ['nullable', 'string', 'in:android,ios,web'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            Token::updateOrCreate(
                ['device_id' => $request->device_id],
                [
                    'token'       => $request->token,
                    'language_id' => $request->language_id ?? 0,
                    'latitude'    => $request->latitude ?? 0,
                    'longitude'   => $request->longitude ?? 0,
                    'platform'    => $request->platform,
                ]
            );

            return ResponseService::successResponse(__('Device registered successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> registerDeviceToken');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Category preference
    // -------------------------------------------------------------------------

    public function setUserCategory(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'category_id' => ['required','string'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $user_id     = Auth::user()->id;
            $category_id = $request->category_id;

            if ($category_id == '0') {
                UserCategory::where('user_id', $user_id)->delete();
            } else {
                UserCategory::updateOrCreate(
                    ['user_id' => $user_id],
                    ['category_id' => $category_id]
                );
            }

            return ResponseService::successResponse(__('Updated successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> setUserCategory');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    // -------------------------------------------------------------------------
    // Notifications
    // -------------------------------------------------------------------------

    public function getUserNotification(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'offset' => 'nullable|integer|min:0',
                'limit'  => 'nullable|integer|min:1|max:100',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $userId = Auth::user()->id;
            $offset  = $request->offset ?? 0;
            $limit   = $request->limit ?? 10;

            $query = CommentNotification::where('user_id', $userId);
            $total = $query->count();

            if ($total === 0) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'));
            }

            // $data = $res->clone()->limit($limit)->offset($offset)->orderBy('id', 'DESC')->get();
            $data = $query->orderBsy('id', 'DESC')->limit($limit)->offset($offset)->get();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'total' => $total,
                'data'  => $data,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> getUserNotification');
        }
    }

    public function deleteUserNotification(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => ['required', 'regex:/^\d+(,\d+)*$/'],
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $deleted = CommentNotification::whereIn('id', explode(',', $request->id))->where('user_id', Auth::id())->delete();
            if (!$deleted) {
                return ResponseService::errorResponse(__('Forbidden'), null, 403);
            }

            return ResponseService::successResponse(__('Notification deleted'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> deleteUserNotification');
        }
    }

    // -------------------------------------------------------------------------
    // Author
    // -------------------------------------------------------------------------

    public function becomeAuthor(Request $request)
    {
        try {
            $userId = Auth::user()->id;

            if (Auth::user()->is_author == 1) {
                return ResponseService::successResponse(__('You are already an approved author'));
            }
            $author = Author::firstOrNew(['user_id' => $userId]);

            if (!$author->exists) {
                $author->status = 'pending';
                $author->save();

                Auth::user()->ensureSlug();

                return ResponseService::successResponse('Author request sent successfully');
            }

            if ($author->status === 'pending') {
                return ResponseService::successResponse('You already have a pending author request');
            }

            if ($author->status === 'approved') {
                return ResponseService::successResponse('You are already an approved author');
            }

            // rejected
            $author->update(['status' => 'pending']);
            Auth::user()->ensureSlug();

            return ResponseService::successResponse(__('Author request resubmitted successfully'));
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> becomeAuthor');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }

    public function updateAuthorProfile(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'bio'            => 'required|string|max:255',
                'telegram_link'  => 'required|url|max:255',
                'linkedin_link'  => 'required|url|max:255',
                'facebook_link'  => 'required|url|max:255',
                'whatsapp_link'  => 'required|url|max:255',
            ]);
            if ($validator->fails()) {
                return ResponseService::validationError($validator->errors()->first());
            }

            $userId = Auth::user()->id;
            $author = Author::where('user_id', $userId)->first();

            if (!$author) {
                return ResponseService::errorResponse('Author not found');
            }

            $author->update([
                'bio'            => $request->bio,
                'telegram_link'  => $request->telegram_link,
                'linkedin_link'  => $request->linkedin_link,
                'facebook_link'  => $request->facebook_link,
                'whatsapp_link'  => $request->whatsapp_link,
            ]);

            return ResponseService::successResponse('Author profile updated successfully');
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'UserApiController -> updateAuthorProfile');
            return ResponseService::errorResponse(__('Something Went Wrong'));
        }
    }
}
