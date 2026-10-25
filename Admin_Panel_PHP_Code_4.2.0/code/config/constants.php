<?php


// $SYSTEM_VERSION = "1.0.0";
return [
    'RESPONSE_CODE'    => [
        'VALIDATION_ERROR'    => 400,
        'EXCEPTION_ERROR'     => 500,
        'SUCCESS'             => 200,
        'NOT_FOUND'           => 404,
        'NOT_VERIFIED'        => 403,
        'UNAUTHORIZED'        => 401,
        'NOT_AUTHORIZED'      => 403,
        'INVALID_JSON_CONTENT' => 422,
        'NO_DATA_FOUND'       => 204,
        'EMPTY_DATA'       => 501,
    ],
    'CACHE'            => [
        'LANGUAGE' => 'languages',
        'SETTINGS' => 'settings'
    ],
    'PAGINATION' => [
        'PER_PAGE' => 10,
        'SIX_PER_PAGE' => 6
    ],

    'JOB_CHUNK_SIZE' => [
        'SYNC_PROJECT_DEPENDENCIES' => 10
    ],
];
