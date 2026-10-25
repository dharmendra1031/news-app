<?php

namespace App\Http\Controllers;

use App\Models\Language;
use App\Models\Pages;
use App\Models\Settings;
use App\Models\WebSetting;
use App\Services\ResponseService;
use dacoto\EnvSet\Facades\EnvSet;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Artisan;

class SettingsController extends Controller
{
    /**
     * Maps Settings type keys to their corresponding .env variable names.
     */
    private const ENV_KEY_MAP = [
        'app_name'      => 'APP_NAME',
    ];

    // -------------------------------------------------------------------------
    // Key lists (shared between index and store to avoid duplication)
    // -------------------------------------------------------------------------

    private function generalSettingKeys(): array
    {
        return [
            'category_mode',
            'subcategory_mode',
            'breaking_news_mode',
            'live_streaming_mode',
            'rss_feed_mode',
            'comments_mode',
            'weather_mode',
            'location_news_mode',
            'nearest_location_measure',
            'maintenance_mode',
            'mobile_login_mode',
            'country_code',
            'views_auth_mode',
            'google_gemini_api_key',
            'auth_short_video_views',
            'news_buzz_mode',
            'podcast_mode',
            'e_news_mode',
            'youtube_api_key',
            'finnhub_api_key',
            'twelvedata_api_key'
        ];
    }

    private function panelSettingKeys(): array
    {
        return [
            'system_timezone',
            'app_name',
            'auto_delete_expire_news_mode',
            'from_name',
            'primary_color',
            'secondary_color',
        ];
    }

    private function appSettingKeys(): array
    {
        return [
            'appstore_app_id',
            'shareapp_text',
            'video_type_preference',
            'ads_type',
            'in_app_ads_mode',
            'google_rewarded_video_id',
            'google_interstitial_id',
            'google_banner_id',
            'google_native_unit_id',
            'google_app_open_unit_id',
            'ios_ads_type',
            'ios_in_app_ads_mode',
            'ios_google_rewarded_video_id',
            'ios_google_interstitial_id',
            'ios_google_banner_id',
            'ios_google_native_unit_id',
            'ios_google_app_open_unit_id',
            'unity_rewarded_video_id',
            'unity_interstitial_id',
            'unity_banner_id',
            'android_game_id',
            'ios_unity_rewarded_video_id',
            'ios_unity_interstitial_id',
            'ios_unity_banner_id',
            'ios_game_id',
            'force_update_app_mode',
            'android_app_version',
            'ios_app_version',
            'ad_after_page_clicks'
        ];
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    /**
     * Upsert a single Settings row by type.
     */
    private function upsertSetting(string $type, mixed $message): void
    {
        Settings::updateOrCreate(['type' => $type], ['message' => $message]);
    }

    /**
     * Delete the old stored logo (if any) and save the new one for a given
     * Settings type key.
     */
    private function updateLogoFile(string $settingType, UploadedFile $file): void
    {
        $setting = Settings::ofType($settingType)->firstOrNew(['type' => $settingType]);

        if ($setting->exists && $setting->getRawOriginal('message')) {
            Storage::disk('public')->delete($setting->getRawOriginal('message'));
        }

        $setting->message = $file->store('logos', 'public');
        $setting->save();
    }

    // -------------------------------------------------------------------------
    // Pages / public view
    // -------------------------------------------------------------------------

    public function view_data(Request $request)
    {
        try {
            $defaultLanguageId = Settings::ofType('default_language')->value('message');

            $languageData = $defaultLanguageId
                ? Language::find($defaultLanguageId)
                : Language::where('code', 'en')->first();

            $type    = $request->type;
            $get_data = null;

            if ($languageData) {
                $get_data = Pages::where('language_id', $languageData->id)
                    ->where('status', 1)
                    ->where('page_type', $type)
                    ->first();
            }

            if (empty($get_data)) {
                $get_data = Pages::where('page_type', $type)->first();
            }

            return view('settings', compact('get_data'));
        } catch (Exception $e) {
            return ResponseService::logErrorRedirectResponse($e, 'SettingsController -> view_data');
        }
    }

    // -------------------------------------------------------------------------
    // System Setting (hub page)
    // -------------------------------------------------------------------------

    public function indexSetting()
    {
        ResponseService::noAnyPermissionThenRedirect([
            'general-settings',
            'panel-settings',
            'web-settings',
            'app-settings',
            'language-list',
            'language-create',
            'language-edit',
            'language-delete',
            'seo-list',
            'seo-create',
            'seo-edit',
            'seo-delete',
            'firebase-configuration',
            'social-media-list',
            'social-media-create',
            'social-media-edit',
            'social-media-delete',
            'system-update',
        ]);
        return view('system-setting');
    }

    // -------------------------------------------------------------------------
    // General Settings
    // -------------------------------------------------------------------------

    public function indexGeneralSetting()
    {
        ResponseService::noAnyPermissionThenRedirect(['general-settings']);

        $setting = Settings::ofTypes($this->generalSettingKeys())->get()->pluck('message', 'type');

        // Mask the Gemini API key in demo/production mode
        $setting['google_gemini_api_key'] = config('app.mode') == 'true'
            ? '********'
            : $setting['google_gemini_api_key'];

        $setting['android_app_link'] = WebSetting::ofType('android_app_link')->value('message');
        $setting['ios_app_link']     = WebSetting::ofType('ios_app_link')->value('message');

        return view('general-setting', compact('setting'));
    }

    public function storeGeneralSetting(Request $request)
    {
        $validator = Validator::make($request->all(), []);

        if ($validator->fails()) {
            return ResponseService::errorRedirectResponse('general-settings', $validator->errors()->first());
        }

        ResponseService::noPermissionThenRedirect('general-settings');

        foreach ($this->generalSettingKeys() as $type) {
            $this->upsertSetting($type, $request->input($type));
        }

        if ($request->has('google_gemini_api_key')) {
            EnvSet::setKey('GOOGLE_GEMINI_API_KEY', base64_encode($request->google_gemini_api_key));
            EnvSet::save();
        }

        foreach (['android_app_link', 'ios_app_link'] as $type) {
            $setting          = WebSetting::firstOrNew(['type' => $type]);
            $setting->message = $request->input($type);
            $setting->save();
        }

        return redirect('general-settings')->with('success', __('updated_success'));
    }

    // -------------------------------------------------------------------------
    // Panel Settings
    // -------------------------------------------------------------------------

    public function indexPanelSetting()
    {
        ResponseService::noAnyPermissionThenRedirect(['panel-settings']);

        $indexKeys = array_merge($this->panelSettingKeys(), ['app_logo_full', 'app_logo']);
        $setting   = Settings::ofTypes($indexKeys)->get()->pluck('message', 'type');

        return view('panel-setting', compact('setting'));
    }

    public function storePanelSetting(Request $request)
    {
        ResponseService::noPermissionThenRedirect('panel-settings');

        // Handle logo uploads
        if ($request->hasFile('file1') && $request->file('file1')->isValid()) {
            $this->updateLogoFile('app_logo_full', $request->file('file1'));
        }
        if ($request->hasFile('file') && $request->file('file')->isValid()) {
            $this->updateLogoFile('app_logo', $request->file('file'));
        }

        foreach ($this->panelSettingKeys() as $type) {
            $message = $request->input($type);

            // Sync specific keys to .env
            if (isset(self::ENV_KEY_MAP[$type])) {
                EnvSet::setKey(self::ENV_KEY_MAP[$type], $message);
                EnvSet::save();
            }

            // Timezone gets its own .env key and may need to be appended
            if ($type === 'system_timezone') {
                $envKey = 'APP_TIMEZONE';
                if (!EnvSet::keyExists($envKey)) {
                    File::append(base_path('.env'), "{$envKey}={$message}\n");
                } else {
                    EnvSet::setKey($envKey, $message);
                    EnvSet::save();
                }
            }

            if ($message) {
                $this->upsertSetting($type, $message);
            }
        }

        return redirect('panel-settings')->with('success', __('updated_success'));
    }

    // -------------------------------------------------------------------------
    // Web Settings
    // -------------------------------------------------------------------------

    public function indexWebSetting()
    {
        ResponseService::noAnyPermissionThenRedirect(['web-settings']);
        $setting = getWebSetting();
        return view('web-setting', compact('setting'));
    }

    public function storeWebSetting(Request $request)
    {
        ResponseService::noPermissionThenRedirect('web-settings');
        $validator = Validator::make($request->all(), [
            'google_adsense' => ['nullable', 'url:https', 'active_url'],
        ]);

        if ($validator->fails()) {
            return ResponseService::errorRedirectResponse('web-settings', $validator->errors()->first());
        }
        $textTypes = [
            'web_name',
            'accept_cookie',
            'web_footer_description',
            'google_adsense',
            'light_body_color',
            'light_hover_color',
            'light_primary_color',
            'light_secondary_color',
            'light_text_primary_color',
            'light_text_secondary_color',
            'dark_body_color',
            'dark_hover_color',
            'dark_primary_color',
            'dark_secondary_color',
            'dark_text_primary_color',
            'dark_text_secondary_color',
        ];

        $fileTypes = [
            'light_header_logo',
            'light_footer_logo',
            'light_placeholder_image',
            'dark_header_logo',
            'dark_footer_logo',
            'dark_placeholder_image',
            'favicon_icon',
        ];

        foreach ($fileTypes as $fileType) {
            if ($request->hasFile($fileType)) {
                $file = $request->file($fileType);
                if ($file->isValid()) {
                    $setting              = WebSetting::firstOrNew(['type' => $fileType]);
                    $previousFileName     = $setting->getRawOriginal('message');
                    if ($previousFileName) {
                        Storage::disk('public')->delete($previousFileName);
                    }
                    $setting->message = $file->store('logos', 'public');
                    $setting->save();
                }
            }
        }

        foreach ($textTypes as $type) {
            $setting          = WebSetting::firstOrNew(['type' => $type]);
            $setting->message = $request->input($type);
            $setting->save();
        }

        return redirect('web-settings')->with('success', __('updated_success'));
    }

    // -------------------------------------------------------------------------
    // App Settings
    // -------------------------------------------------------------------------

    public function indexAppSetting()
    {
        ResponseService::noAnyPermissionThenRedirect(['app-settings']);
        $setting = Settings::ofTypes($this->appSettingKeys())->get()->pluck('message', 'type');
        return view('app-setting', compact('setting'));
    }

    public function storeAppSetting(Request $request)
    {
        ResponseService::noPermissionThenRedirect('app-settings');

        $validator = Validator::make($request->all(), [
            'android_app_version' => ['required', 'regex:/^[0-9]+(\.[0-9]+)*$/'],
            'ios_app_version'     => ['required', 'regex:/^[0-9]+(\.[0-9]+)*$/'],
            'ads_file'            => 'nullable|file|mimes:txt',
        ], [
            'android_app_version.regex' => 'Android app version must be in format like 1.0.0 (numbers and dots only)',
            'ios_app_version.regex'     => 'iOS app version must be in format like 1.0.0 (numbers and dots only)',
        ]);

        if ($validator->fails()) {
            return ResponseService::errorRedirectResponse('app-settings', $validator->errors()->first());
        }

        foreach ($this->appSettingKeys() as $type) {
            $this->upsertSetting($type, $request->input($type));
        }

        if ($request->hasFile('ads_file')) {
            $filename            = 'app-ads.txt';
            $fileContents        = File::get($request->file('ads_file'));
            $publicWellKnownPath = public_path('.well-known');
            $baseWellKnownPath   = base_path('.well-known');

            if (!File::exists($publicWellKnownPath)) {
                File::makeDirectory($publicWellKnownPath, 0755, true);
            }
            if (!File::exists($baseWellKnownPath)) {
                File::makeDirectory($baseWellKnownPath, 0755, true);
            }

            File::put(public_path($filename), $fileContents);
            File::put(base_path($filename), $fileContents);
        }

        return redirect('app-settings')->with('success', __('updated_success'));
    }

    // -------------------------------------------------------------------------
    // Firebase Settings
    // -------------------------------------------------------------------------

    public function indexFirebaseSetting()
    {
        ResponseService::noAnyPermissionThenRedirect(['firebase-configuration']);

        $is_file    = (int) file_exists(public_path('assets/firebase_config.json'));
        $project_id = Settings::ofType('firebase_project_id')->first();

        return view('firebase-configuration', compact('is_file', 'project_id'));
    }

    public function storeFirebaseSetting(Request $request)
    {
        ResponseService::noPermissionThenRedirect('firebase-configuration');

        $validator = Validator::make($request->all(), [
            'project_id' => ['required', 'string', 'max:255'],
            'file'       => ['required', 'file', 'mimetypes:application/json'],
        ]);

        if ($validator->fails()) {
            return redirect('firebase-configuration')->with('error', $validator->errors()->first());
        }

        $oldFile = public_path('assets/firebase_config.json');
        if (file_exists($oldFile)) {
            unlink($oldFile);
        }

        if ($request->hasFile('file')) {
            $file     = $request->file('file');
            $filename = 'firebase_config.' . $file->getClientOriginalExtension();
            $file->move(public_path('assets/'), $filename);
        }

        Settings::updateOrCreate(['type' => 'firebase_project_id'], ['message' => $request->project_id]);

        return redirect('firebase-configuration')->with('success', __('updated_success'));
    }

    // -------------------------------------------------------------------------
    // Utility actions
    // -------------------------------------------------------------------------

    public function importDummyData()
    {
        try {
            Artisan::call('db:seed', ['--class' => 'DummyDataSeeder', '--force' => true]);
            return response()->json(['success' => true]);
        } catch (Exception $e) {
            Log::error($e->getMessage());
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function createStorageLink()
    {
        try {
            if (!file_exists(public_path('storage'))) {
                Artisan::call('storage:link');
            }
            return response()->json(['success' => true]);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function removeStorageLink()
    {
        try {
            if (file_exists(public_path('storage'))) {
                File::delete(public_path('storage'));
            }
            return response()->json(['success' => true]);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
