<?php

use App\Models\Settings;
use App\Models\WebSetting;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (!Settings::where('type', 'rss_feed_mode')->exists()) {
            Settings::create(['type' => 'rss_feed_mode', 'message' => '1']);
        }
        if (!Settings::where('type', 'mobile_login_mode')->exists()) {
            Settings::create(['type' => 'mobile_login_mode', 'message' => 0]);
        }
        if (!Settings::where('type', 'country_code')->exists()) {
            Settings::create(['type' => 'country_code', 'message' => 'IN']);
        }
        if (!Settings::where('type', 'shareapp_text')->exists()) {
            Settings::create(['type' => 'shareapp_text', 'message' => 'You can find our app from below url']);
        }
        if (!Settings::where('type', 'appstore_app_id')->exists()) {
            Settings::create(['type' => 'appstore_app_id', 'message' => '']);
        }
        if (!Settings::where('type', 'association_file')->exists()) {
            Settings::create(['type' => 'association_file', 'message' => '']);
        }
        if (!Settings::where('type', 'assetlinks_file')->exists()) {
            Settings::create(['type' => 'assetlinks_file', 'message' => '']);
        }
        if (!WebSetting::where('type', 'favicon_icon')->exists()) {
            WebSetting::create(['type' => 'favicon_icon', 'message' => '']);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
