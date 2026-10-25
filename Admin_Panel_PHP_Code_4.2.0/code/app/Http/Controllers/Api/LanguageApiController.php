<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\BaseApiController;
use App\Models\Language;
use App\Models\Settings;
use App\Services\ResponseService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use JsonException;

class LanguageApiController extends BaseApiController
{

    // -------------------------------------------------------------------------
    // Languages
    // -------------------------------------------------------------------------

    public function getLanguagesList(Request $request)
    {
        try {
            $languages = Language::select('id', 'language', 'code', 'status', 'isRTL', 'image', 'display_name')
                ->where('status', 1)
                ->get();

            if ($languages->isEmpty()) {
                return ResponseService::errorResponse(__('No Data Found'), null, config('constants.RESPONSE_CODE.NOT_FOUND'), null);
            }

            $defaultLangId    = Settings::where('type', 'default_language')->value('message');
            $default_language = $languages->firstWhere('id', $defaultLangId)
                ?? $languages->firstWhere('code', 'en')
                ?? $languages->first();

            return ResponseService::successResponse(__('Data fetched successfully'), [
                'default_language' => $default_language,
                'data'             => $languages,
            ]);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'SettingsApiController -> getLanguagesList');
            return ResponseService::errorResponse(__('Something Went Wrong'), null, config('constants.RESPONSE_CODE.EXCEPTION_ERROR'), $e);
        }
    }

    public function getLanguageJsonData(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'language_code' => 'required|string|max:5|exists:tbl_languages,code',
                'platform_type' => 'required|string|in:app,web',
            ]);

            if ($validator->fails()) {
                ResponseService::validationError($validator->errors()->first());
            }

            $language = Language::select('id', 'code', 'web_file', 'app_file')->where('code', $request->language_code)->firstOrFail();
            $type = $request->platform_type;

            if ($type === 'web') {
                // here need to check the base path file exists or not

                if(isset($language->web_file)){

                    $json_file_path = base_path("resources/lang/{$language->web_file}");

                    if(!file_exists($json_file_path)){
                        $json_file_path = base_path('resources/lang/en_web.json');
                    }
                }

            } else {

                if(isset($language->app_file)){

                    $json_file_path = base_path("resources/lang/{$language->app_file}");

                    if(!file_exists($json_file_path)){
                        $json_file_path = base_path('resources/lang/en_app.json');
                    }
                }
            }


            $json_string = file_get_contents($json_file_path);
            try {
                $json_data = json_decode($json_string, false, 512, JSON_THROW_ON_ERROR);
            } catch (JsonException $e) {
                ResponseService::errorResponse(__('Invalid JSON format in the language file'));
                return;
            }

            $language->file_data = $json_data;
            $data = $language->file_data;
            ResponseService::successResponse(__('Data Fetched Successfully'), $data);
        } catch (Exception $e) {
            ResponseService::logErrorResponse($e, 'API Controller -> getLanguages');
            ResponseService::errorResponse();
        }
    }
}
