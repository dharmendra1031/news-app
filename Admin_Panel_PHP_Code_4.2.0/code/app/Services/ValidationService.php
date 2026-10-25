<?php

namespace App\Services;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ValidationService
{
    public static function bulkDeleteValidator(Request $request, string $table)
    {
        return Validator::make(
            $request->all(),
            [
                'request_ids'   => 'required|array',
                'request_ids.*' => "integer|exists:{$table},id",
            ],
            [
                'request_ids.required'  => __('please_select_at_least_one_item'),
                'request_ids.array'     => __('invalid_request_data'),
                'request_ids.*.integer' => __('invalid_id'),
                'request_ids.*.exists'  => __('record_not_found'),
            ]
        );
    }
}