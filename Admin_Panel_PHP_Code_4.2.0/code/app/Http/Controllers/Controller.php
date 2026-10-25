<?php

namespace App\Http\Controllers;

use App\Services\ResponseService;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use Throwable;

class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    public function readLanguageFile() {
        try {
            //    https://medium.com/@serhii.matrunchyk/using-laravel-localization-with-javascript-and-vuejs-23064d0c210e
            header('Content-Type: text/javascript');
            // $labels = Cache::remember('lang.js', 3600, static function () {
            $lang = app()->getLocale();

            $code = Session::get('language_code') ?? "en";
            $files = resource_path('lang/' . $code . '.json');

            echo('window.languageLabels = ' . File::get($files));
            // http_response_code(200); // deprecated
            exit();
        } catch (Throwable $th) {
            ResponseService::errorResponse($th);
        }
    }
}
