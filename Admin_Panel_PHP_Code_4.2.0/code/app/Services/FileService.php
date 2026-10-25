<?php

namespace App\Services;

use Illuminate\Support\Facades\File;

class FileService
{
    /**
     * @param $requestFile
     * @param $code
     * @return string
     */
    public static function uploadLanguageFile($requestFile, $code) {

        $filename = $code . '.' . $requestFile->getClientOriginalExtension();
        if (file_exists(base_path('resources/lang/') . $filename)) {
            File::delete(base_path('resources/lang/') . $filename);
        }
        $requestFile->move(base_path('resources/lang/'), $filename);
        return $filename;
    }

     /**
     * @param $file
     * @return bool
     */
    public static function deleteLanguageFile($file) {
        if (file_exists(base_path('resources/lang/') . $file)) {
            return File::delete(base_path('resources/lang/') . $file);
        }
        return true;
    }
}
