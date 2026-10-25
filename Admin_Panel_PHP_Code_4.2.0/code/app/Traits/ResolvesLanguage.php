<?php

namespace App\Traits;

use App\Models\Language;
use App\Services\ResponseService;
use Illuminate\Http\Request;

trait ResolvesLanguage
{
    /**
     * Resolve language_id from the request.
     *
     * Accepts either:
     *   - language_code (string, e.g. 'en', 'hi', 'ar') — preferred
     *   - language_id   (numeric, backward compatible)
     *
     * If both are provided, language_code takes precedence.
     * The resolved language_id is cached in request attributes
     * to avoid repeated DB lookups within the same request lifecycle.
     *
     * Usage:
     *   $languageId = $this->resolveLanguageId($request);
     *
     * @param  Request  $request
     * @return int  The resolved language_id
     */
    protected function resolveLanguageId(Request $request): int
    {
        // Return cached result if already resolved in this request
        if ($request->attributes->has('_resolved_language_id')) {
            return $request->attributes->get('_resolved_language_id');
        }

        $language = null;

        if ($request->filled('language_code')) {
            $language = Language::where('code', $request->language_code)->first();

            if (!$language) {
                ResponseService::errorResponse(
                    'Invalid language code',
                    null,
                    config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
                    null
                );
            }
        }
        //  elseif ($request->filled('language_id')) {
        //     if (!is_numeric($request->language_id)) {
        //         ResponseService::errorResponse(
        //             'language_id must be numeric',
        //             null,
        //             config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
        //             null
        //         );
        //     }

        //     $language = Language::find($request->language_id);

        //     if (!$language) {
        //         ResponseService::errorResponse(
        //             'Invalid language id',
        //             null,
        //             config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
        //             null
        //         );
        //     }
        // }
        else {
            ResponseService::errorResponse(
                // 'language_code or language_id is required',
                'language_code is required',
                null,
                config('constants.RESPONSE_CODE.VALIDATION_ERROR'),
                null
            );
        }

        // Cache in request attributes to avoid repeated DB queries
        $request->attributes->set('_resolved_language_id', $language->id);

        // Merge language_id into request so downstream code (queries, etc.) can use it transparently
        $request->merge(['language_id' => $language->id]);

        return $language->id;
    }
}
