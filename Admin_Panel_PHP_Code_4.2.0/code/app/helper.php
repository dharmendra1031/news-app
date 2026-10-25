<?php

use App\Models\Language;
use App\Models\Location;
use App\Models\Settings;
use App\Models\NotificationPreference;
use App\Models\NotificationType;
use App\Models\Token;
use App\Models\WebSetting;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Laravel\Facades\Image;
use Illuminate\Support\Str;

if (!function_exists('get_meta_keyword')) {
    function get_meta_keyword($meta_keyword)
    {
        $meta_keyword1 = '';
        if ($meta_keyword) {
            $meta_keyword1 = implode(
                ',',
                array_map(function ($tag) {
                    return $tag['value'];
                }, $meta_keyword),
            );
        }
        return $meta_keyword1;
    }
}

/** Generate Slugs Functions */
if (!function_exists('generateUniqueSlug')) {
    function generateUniqueSlug($title, $originalSlug = null, $exceptId = null) {
        if (!$originalSlug) {
            $originalSlug = Str::slug($title);
        } else {
            $originalSlug = Str::slug($originalSlug);
        }

        if(empty($originalSlug)){
            $originalSlug = "slug";
        }
        return $originalSlug;
    }
}


if (!function_exists('customSlug')) {
    function customSlug($string, $separator = '-')
    {
        // Normalize the string
        $normalizedString = mb_strtolower(trim($string), 'UTF-8');
        // Check if the string contains only ASCII characters
        if (preg_match('/^[\x00-\x7F]*$/', $normalizedString)) {
            $slug = preg_replace('/[^a-z0-9]+/', $separator, $normalizedString);
        } else {
            // slug with remove special characters
            // $slug = preg_replace('/[^\p{L}\p{N}\s]+/u', '', $string);
            // $slug = preg_replace('/\s+/', $separator, $slug);

            //slug with all language
            // $slug = preg_replace('/[^\p{Gujarati}0-9]+/u', '', $normalizedString);

            //remove space from string
            $slug = preg_replace('/\s+/', $separator, $string);
        }
        return $slug;
    }
}

if (!function_exists('getSetting')) {
    function getSetting($type = '')
    {
        $settingList = [];
        if ($type == '') {
            $setting = Settings::get();
        } else {
            $setting = Settings::where('type', $type)->get();
        }
        foreach ($setting as $row) {
            $settingList[$row->type] = $row->message;
        }
        return $settingList;
    }
}

if (!function_exists('getSettingMode')) {
    function getSettingMode($type)
    {
        return Settings::where('type', $type)->pluck('message')->first();
    }
}

if (!function_exists('getWebSetting')) {
    function getWebSetting($type = '')
    {
        $settingList = [];
        if ($type == '') {
            $setting = WebSetting::get();
        } else {
            $setting = WebSetting::where('type', $type)->get();
        }
        foreach ($setting as $row) {
            $settingList[$row->type] = $row->message;
        }
        return $settingList;
    }
}
if (!function_exists('send_notification')) {

    function send_notification($fcmMsg, $language_id, $location_id, $devicetoken = [], $notification_type = '')
    {
        // -----------------------------------------
        // 1. Device Token Selection (unchanged)
        // -----------------------------------------

        $languageCode = getCodeFromLanguageId($language_id);
        if (empty($devicetoken)) {

            if ($location_id != 0) {
                $filteredTokens = [];

                $location = Location::find($location_id);
                $news_lat = $location->latitude;
                $news_long = $location->longitude;

                $devicetoken = Token::where('language_id', $language_id)->get();
                $maxDistance = Settings::where('type', 'nearest_location_measure')->value('message');

                foreach ($devicetoken as $value) {
                    $device_lat = $value->latitude;
                    $device_long = $value->longitude;

                    if (!empty($device_lat)) {
                        $distance = calculateDistance($news_lat, $news_long, $device_lat, $device_long);

                        if ($distance < $maxDistance) {
                            $filteredTokens[] = $value->token;
                        }
                    }
                }

                $registrationIDs_chunks = array_chunk($filteredTokens, 500);

            } else {
                $tokens = Token::where('language_id', $language_id)->pluck('token')->toArray();
                $registrationIDs_chunks = array_chunk($tokens, 500);
            }

        } else {
            $registrationIDs_chunks = array_chunk($devicetoken, 500);
        }



        // -----------------------------------------
        // 2. Call FCM v1 (using CURL) — CLEAN
        // -----------------------------------------

        $firebase_config = public_path('assets/firebase_config.json');

        if (!file_exists($firebase_config)) {
            Log::error("Firebase config missing");
            return false;
        }

        // Hardcoded for testing
        // $registrationIDs = [
        //     // 'eibdP4ZVQ7O_BYJa6x1yBa:APA91bFwlQdMe2OnelFQ7sxFY2zp4CrPcg_1VRGfxvbbZsGVdN8F3LoT6UTSSfdbZ52XBrDstbW1E7rKggsdMK79qCBlJW69drR39Xcq8cDsIirS2fUAHTs'
        //     'fvn4I5jTRGOuncCyFEZpCG:APA91bHOn9UplXvzVtOSnqoz9Wd2HT-dEPVFlXkPmriviRVcc_FM-M6DdoFykFFlbq4qKACi4cvOOJC-axJAPNV_k5QFVBR5w-WI6MX0u8Ax-lB19hyiLg8'
        // ];

        // ----------------------------------------------------
        // NOTIFICATION PREFERENCE FILTER
        // ----------------------------------------------------
        if ($notification_type) {
            $typeId = NotificationType::where('key', $notification_type)->value('id');

            if (!$typeId) {
                Log::warning("send_notification: unknown notification_type '{$notification_type}', skipping preference filter");
            } else {
                $allTokens = array_merge(...$registrationIDs_chunks);
                $tokenUserMap = Token::whereIn('token', $allTokens)
                    ->pluck('user_id', 'token')
                    ->filter()
                    ->toArray();
                $disabledUserIds = NotificationPreference::whereIn('user_id', array_values($tokenUserMap))
                    ->where('notification_type_id', $typeId)
                    ->where('status', false)
                    ->pluck('user_id')
                    ->toArray();
                // dd($tokenUserMap);
                $filteredTokens = [];
                foreach ($tokenUserMap as $token => $uid) {
                    if (!in_array($uid, $disabledUserIds)) {
                        $filteredTokens[] = $token;
                    }
                }
                $registrationIDs_chunks = array_chunk($filteredTokens, 500);
            }
        }

        // dd($registrationIDs_chunks);
        // Loop through real device token chunks
        foreach ($registrationIDs_chunks as $registrationIDs) {
            sendFcmNotification(
                $registrationIDs,
                $fcmMsg['title'],
                $fcmMsg['body'],
                // 'default',
                $fcmMsg['type'] ?? 'default',
                $language_id,
                [
                    // 'news_id' => $fcmMsg['news_id'] ?? null,
                    // 'location_id' => $fcmMsg['location_id'] ?? null,
                    ...$fcmMsg,
                    'language_code' => $languageCode,
                ],
            );
        }
    }
}

if (!function_exists('sendFcmNotification')) {

    function sendFcmNotification(array $registrationIDs, string|null $title = '', string|null $message = '', string $type = "default", int $language_id = 1, array $data = []): string|array|bool {

        try {
            $project_id = Settings::where('type', 'firebase_project_id')->first();
            // $project_id = 'visionverse-9d4de';
            $project_id = $project_id?->message ?? null;

            if (empty($project_id)) {
                Log::error("Firebase project ID is not set");
                return ['error' => true, 'message' => 'Firebase project ID is not set'];
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";

            $access_token = getAccessToken();

            if (empty($access_token['data'])) {
                Log::error("FCM access token missing");
                return ['error' => true, 'message' => 'Failed to get FCM access token'];
            }

            $payloadData = [
                "title" => $title,
                "body"  => $message,
                "language_id" => $language_id,
                "type" => $type,
                ...$data
            ];

            $payloadData = array_map(function ($value) {
                return is_scalar($value) ? (string)$value : json_encode($value);
            }, $payloadData);


            foreach ($registrationIDs as $registrationID) {

                if (empty($registrationID)) {
                    Log::warning("Skipping empty token");
                    continue;
                }

                $data = [
                    "message" => [
                        "token" => $registrationID,
                        "notification" => [
                            "title" => $title,
                            "body"  => $message,
                        ],
                        "data" => $payloadData,
                        "android" => ["priority" => "high"],
                        "apns" => [
                            "headers" => ["apns-priority" => "10"],
                            "payload" => [
                                "aps" => [
                                    "alert" => [
                                        "title" => $title,
                                        "body"  => $message,
                                    ],
                                    "sound" => "default"
                                ]
                            ]
                        ]
                    ]
                ];

                $jsonBody = json_encode($data);

                $headers = [
                    'Authorization: Bearer ' . $access_token['data'],
                    'Content-Type: application/json',
                ];

                $ch = curl_init();
                curl_setopt_array($ch, [
                    CURLOPT_URL            => $url,
                    CURLOPT_POST           => true,
                    CURLOPT_HTTPHEADER     => $headers,
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_SSL_VERIFYHOST => 2,
                    CURLOPT_SSL_VERIFYPEER => true,
                    CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_1_1,
                    CURLOPT_POSTFIELDS     => $jsonBody,
                ]);

                $result   = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

                // Log::info("Helper line: 311 FCM Response Code: $httpCode");
                // Log::info("Helper line: 312 FCM Response: $result");

                // ----------------------------------------------------
                // DEAD TOKEN CLEANUP
                // ----------------------------------------------------
                if ($httpCode != 200 && $result) {

                    $errorResponse = json_decode($result, true);

                    if (!empty($errorResponse['error']['status'])) {

                        $status = $errorResponse['error']['status'];

                        if (in_array($status, ['UNREGISTERED', 'INVALID_ARGUMENT', 'NOT_FOUND'])) {

                            Log::warning("Removing dead FCM token: $registrationID (Reason: $status)");

                            Token::where('token', $registrationID)->delete();
                        }
                    }
                }

                if ($result === false) {
                    Log::error("Curl failed: " . curl_error($ch));
                }

                // curl_close($ch);
            }

            return ['error' => false, 'message' => "Success"];

        } catch (Exception $e) {
            Log::error("FCM error: " . $e->getMessage());
            return false;
        }
    }
}

/** END OF Generate Slugs Functions */
if (!function_exists('getAccessToken')) {

    function getAccessToken() {
        try {
            $file_path = public_path('assets/firebase_config.json');

            if (!file_exists($file_path)) {
                return ['error' => true, 'message' => 'FCM Service File not found'];
            }

            $client = new Google\Client();
            $client->setAuthConfig($file_path);
            $client->setScopes(['https://www.googleapis.com/auth/firebase.messaging']);

            return [
                'error'   => false,
                'message' => 'Access Token generated successfully',
                'data'    => $client->fetchAccessTokenWithAssertion()['access_token']
            ];

        } catch (Exception $e) {
            throw new RuntimeException($e);
        }
    }
}

if (!function_exists('page_type')) {
    function page_type($type)
    {
        $values = [
            'home' => __('home'),
            'video_news' => __('video_news'),
            'all_breaking_news' => __('all_breaking_news'),
            'live_streaming_news' => __('live_streaming_news'),
            'rss_feeds' => __('rss_feeds'),
            'e_news' => __('e_news'),
            'news_buzz' => __('news_buzz'),
            'podcast' => __('podcast'),
            'alerts' => __('alerts'),
        ];
        return $values[$type] ?? '';
    }
}

if (!function_exists('is_category_enabled')) {
    function is_category_enabled()
    {
        return Settings::where('type', 'category_mode')->pluck('message')->first();
    }
}

if (!function_exists('is_subcategory_enabled')) {
    function is_subcategory_enabled()
    {
        return Settings::where('type', 'subcategory_mode')->pluck('message')->first();
    }
}

if (!function_exists('is_breaking_news_enabled')) {
    function is_breaking_news_enabled()
    {
        $setting = Settings::where('type', 'breaking_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_auto_news_expire_news_enabled')) {
    function is_auto_news_expire_news_enabled()
    {
        $setting = Settings::where('type', 'auto_delete_expire_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_live_streaming_enabled')) {
    function is_live_streaming_enabled()
    {
        $setting = Settings::where('type', 'live_streaming_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('is_location_news_enabled')) {
    function is_location_news_enabled()
    {
        $setting = Settings::where('type', 'location_news_mode')->pluck('message')->first();
        return $setting ? $setting : 0;
    }
}

if (!function_exists('getTimezoneOptions')) {
    function getTimezoneOptions()
    {
        $list = DateTimeZone::listAbbreviations();
        $idents = DateTimeZone::listIdentifiers();
        $data = $offset = $added = [];
        foreach ($list as $info) {
            foreach ($info as $zone) {
                if (!empty($zone['timezone_id']) && !in_array($zone['timezone_id'], $added) && in_array($zone['timezone_id'], $idents)) {
                    $z = new DateTimeZone($zone['timezone_id']);
                    $c = new DateTime(); // Replace $n = '' with $n = null
                    $c->setTimezone($z);
                    $zone['time'] = $c->format('H:i a');
                    $offset[] = $zone['offset'] = $z->getOffset($c);
                    $data[] = $zone;
                    $added[] = $zone['timezone_id'];
                }
            }
        }
        array_multisort($offset, SORT_ASC, $data);
        $options = [];
        foreach ($data as $row) {
            $options[] = [
                'time' => $row['time'],
                'offset' => formatOffset($row['offset']),
                'timezone_id' => $row['timezone_id'],
            ];
        }
        return $options;
    }
}

if (!function_exists('formatOffset')) {
    function formatOffset($offset)
    {
        $hours = floor($offset / 3600);
        $minutes = abs(($offset % 3600) / 60);
        return sprintf('%+d:%02d', $hours, $minutes);
    }
}

if (!function_exists('generateRandomString')) {
    function generateRandomString($length = 10)
    {
        return substr(str_shuffle(str_repeat($x = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ceil($length / strlen($x)))), 1, $length);
    }
}

if (!function_exists('is_email_setting')) {
    function is_email_setting()
    {
        $builder = new Settings(); // Create an instance of the Settings model
        $email_setting = new \stdClass(); // Create a new stdClass object to store email settings
        // Retrieve and set individual email settings
        $email_setting->SMTPHost = $builder->where('type', 'smtp_host')->first()->message;
        $email_setting->SMTPUser = $builder->where('type', 'smtp_user')->first()->message;
        $email_setting->SMTPPass = $builder->where('type', 'smtp_password')->first()->message;
        $email_setting->SMTPPort = $builder->where('type', 'smtp_port')->first()->message;
        $email_setting->SMTPCrypto = $builder->where('type', 'smtp_crypto')->first()->message;
        $email_setting->fromName = $builder->where('type', 'from_name')->first()->message;
        $email_setting->mailType = 'html';
        return $email_setting;
    }
}

if (!function_exists('createSlug')) {
    function createSlug($text)
    {
        // // Convert the title to lowercase and replace spaces with hyphens
        $slug = str_replace(' ', '-', strtolower($text));
        // Remove special characters
        $slug = preg_replace('/[^A-Za-z0-9\-]/', '', $slug);
        return $slug . '-' . rand(1, 100);
    }
}

if (!function_exists('get_language')) {
    function get_language($status = '')
    {
        if ($status) {
            return Language::where('status', $status)->get();
        } else {
            return Language::get();
        }
    }
}

if (!function_exists('get_default_language')) {
    function get_default_language()
    {
        $language = '';
        $setting = getSetting('default_language');
        if (!empty($setting)) {
            $language = Language::where('id', $setting['default_language'])->first();
        }
        return $language;
    }
}

if (!function_exists('calculateDistance')) {
    function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        // Convert degrees to radians
        $lat1 = deg2rad($lat1);
        $lon1 = deg2rad($lon1);
        $lat2 = deg2rad($lat2);
        $lon2 = deg2rad($lon2);
        // Radius of the Earth in kilometers
        $earthRadius = 6371; // You can also use 3959 for miles
        // Haversine formula
        $dlat = $lat2 - $lat1;
        $dlon = $lon2 - $lon1;
        $a = sin($dlat / 2) * sin($dlat / 2) + cos($lat1) * cos($lat2) * sin($dlon / 2) * sin($dlon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }
}

//hideEmailAddress
if (!function_exists('hideEmailAddress')) {
    function hideEmailAddress($email)
    {
        $demo_mode = env('DEMO_MODE');
        if ($demo_mode == true && $email != '') {
            return '******@gmail.com';
        } else {
            return $email;
        }
    }
}

//hideMobileNumber
if (!function_exists('hideMobileNumber')) {
    function hideMobileNumber($mobile)
    {
        $demo_mode = env('DEMO_MODE');
        if ($demo_mode == true && $mobile != '') {
            return '***********';
        } else {
            return $mobile;
        }
    }
}
if (!function_exists('compressAndUpload')) {
function compressAndUpload($requestFile, $folder, $quality = 75) {
    $extension = strtolower($requestFile->getClientOriginalExtension());
    $mime = $requestFile->getMimeType();
    $file_name = uniqid() . '.' . $extension;

    try {
        if ($extension === 'svg' || $mime === 'image/svg+xml') {
            return $requestFile->storeAs($folder, $file_name, 'public');
        }

        if ($extension === 'gif' || $mime === 'image/gif') {
            return $requestFile->storeAs($folder, $file_name, 'public');
        }

        $image = Image::read($requestFile);

        switch ($extension) {
            case 'jpg':
            case 'png':
            case 'jpeg':
                $encoded = $image->toJpeg($quality);
                break;
            case 'webp':
                $encoded = $image->toWebp($quality);
                break;
            default:
                return $requestFile->storeAs($folder, $file_name, 'public');
        }

        Storage::disk('public')->put("$folder/$file_name", $encoded->toString());

    } catch (\Exception $e) {
        return $requestFile->storeAs($folder, $file_name, 'public');
    }

    return "$folder/$file_name";
}
}

if (!function_exists('compressAndReplace')) {
function compressAndReplace($requestFile, $folder, $deleteRawOriginalImage) {
    if (!empty($deleteRawOriginalImage) && Storage::disk('public')->exists($deleteRawOriginalImage)) {
        Storage::disk('public')->delete($deleteRawOriginalImage);
    }
    return compressAndUpload($requestFile, $folder);
}
}
if(!function_exists('getCodeFromLanguageId')) {
    function getCodeFromLanguageId(int $language_id): string
    {
        $code = Language::find($language_id)?->code;
        // other wise default language from DB table
        if (!$code) {
            $defaultCode = Settings::where('type', 'default_language')->first()->message;
            $code = $defaultCode;
        }

        return $code;
    }
}
