<?php

namespace App\Services;
use Illuminate\Contracts\Foundation\Application;
use Illuminate\Http\RedirectResponse;
use Illuminate\Routing\Redirector;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ResponseService
{
    /**
     * @param $permission
     * @return Application|RedirectResponse|Redirector|true
     */
    public static function noPermissionThenRedirect($permission)
    {
        if (!Auth::user()->can($permission)) {
            return redirect(route('home'))->with('error', "You Don't have enough permissions");
        }
        return true;
    }

    /**
    * If User don't have any of the permission that is specified in Array then Redirect will happen
    * @param array $permissions
    * @return RedirectResponse|true
    */
    public static function noAnyPermissionThenRedirect(array $permissions)
    {
        if (!Auth::user()->canany($permissions)) {
            return redirect()->route('home')->with('error', "You Don't have enough permissions");
        }
        return true;
    }
    /**
     * @param $permission
     *
     */
    public static function noPermissionThenSendJson($permission)
    {
        if (!Auth::user()->can($permission)) {
            self::errorResponse("You Don't have enough permissions", null, 103);
        }
        return true;
    }


     /**
     * @param string $message
     * @param $data
     * @param array $customData
     * @param $code
     * @return void
     */
    public static function successResponse(string $message = "Success", $data = null, array $customData = array(), $code = null)
    {
        response()->json(array_merge([
            'error'   => false,
            'message' => trans($message),
            'data'    => $data,
            'code'    => $code ?? config('constants.RESPONSE_CODE.SUCCESS')
        ], $customData), $code ?? config('constants.RESPONSE_CODE.SUCCESS'))->send();
        exit();
    }

    /**
     * @param string $message
     * @param $url
     * @return Application|\Illuminate\Foundation\Application|RedirectResponse|Redirector
     */
    public static function successRedirectResponse(string $message = "success", $url = null)
    {
        return isset($url) ? redirect($url)->with([
            'success' => trans($message)
        ])->send() : redirect()->back()->with([
            'success' => trans($message)
        ])->send();
    }

    /**
     *
     * @param string $message - Pass the Translatable Field
     * @param null $data
     * @param null $code
     * @param null $e
     * @return void
     */
    public static function errorResponse(string $message = 'Error Occurred', $data = null, $code = null, $e = null)
    {
        response()->json([
            'error'   => true,
            'message' => trans($message),
            'data'    => $data,
            'code'    => $code ?? config('constants.RESPONSE_CODE.EXCEPTION_ERROR'),
            // 'details' => (!empty($e) && is_object($e)) ? $e->getMessage() . ' --> ' . $e->getFile() . ' At Line : ' . $e->getLine() : ''
        ],$code ?? config('constants.RESPONSE_CODE.EXCEPTION_ERROR'))->send();
        exit();
    }

    /**
     * @param string $message
     * @param $url
     * @return Application|\Illuminate\Foundation\Application|RedirectResponse|Redirector
     */
    public static function errorRedirectResponse($url = null, string $message = 'Error Occurred')
    {
        return isset($url) ? redirect($url)->with([
            'error' => trans($message)
        ])->send() : redirect()->back()->with([
            'error' => trans($message)
        ])->send();
    }

    /**
     * @param string $message
     * @param null $data
     * @param null $code
     * @return void
     */
    public static function warningResponse(string $message = 'Error Occurred', $data = null, $code = null)
    {
        response()->json([
            'error'   => false,
            'warning' => true,
            'code'    => $code,
            'message' => trans($message),
            'data'    => $data,
        ],$code)->send();
        exit();
    }


    /**
     * @param string $message
     * @param null $data
     * @return void
     */
    public static function validationError(string $message = 'Error Occurred', $data = null)
    {
        self::errorResponse($message, $data, config('constants.RESPONSE_CODE.VALIDATION_ERROR'));
    }

    /**
     * @param string $message
     * @param null $data
     */
    public static function validationErrorRedirect($url = null, string $message = 'Error Occurred')
    {
        return (($url != null) ? redirect($url) : redirect()->back())->with([
            'error' => trans($message)
        ])->send();
    }

    /**
     * @param $e
     * @param string $logMessage
     * @param string $responseMessage
     * @param bool $jsonResponse
     * @return void
     */
    public static function logErrorResponse($e, string $logMessage = ' ', string $responseMessage = 'Error Occurred', bool $jsonResponse = true)
    {
        Log::error($logMessage . ' ' . $e->getMessage() . '---> ' . $e->getFile() . ' At Line : ' . $e->getLine());
        if ($jsonResponse && config('app.debug')) {
            self::errorResponse($responseMessage, null, null, $e);
        }
    }
    /**
     * @param $e
     * @param string $logMessage
     * @param string $responseMessage
     * @param bool $jsonResponse
     * @return void
     */
    public static function geminiLogError($e, string $logMessage = ' ', string $responseMessage = 'Error Occurred', bool $jsonResponse = true)
    {
        Log::error($logMessage . ' ' . $e . '---> ');
        // if ($jsonResponse && config('app.debug')) {
        //     self::errorResponse($responseMessage, null, null, $e);
        // }
    }


    /**
     * @param $e
     * @param string $logMessage
     * @param string $responseMessage
     * @return void
     */
    public static function logErrorRedirectResponse($e, string $logMessage = ' ', string $responseMessage = 'Error Occurred')
    {
        Log::error($logMessage . ' ' . $e->getMessage() . '---> ' . $e->getFile() . ' At Line : ' . $e->getLine());
        if (config('app.debug')) {
            self::errorRedirectResponse(null, $responseMessage);
        }

    }


     /**
     * @param string $message
     * @param null $data
     * @return void
     */
    public static function noDataFound(string $message = 'No Data Found', $data = null, $code = null)
    {
        response()->json([
            'error'   => false,
            'message' => trans($message),
            'data'    => $data,
            'code'    => $code ?? config('constants.RESPONSE_CODE.NO_DATA_FOUND'),
        ],$code ?? config('constants.RESPONSE_CODE.NO_DATA_FOUND'))->send();
        exit();
    }
}
