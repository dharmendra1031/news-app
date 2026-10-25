<?php

namespace Database\Seeders;

use App\Models\Language;
use App\Models\Pages;
use App\Models\Settings;
use App\Models\WebSetting;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class InstallationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $adminExists = DB::table('admin')->where('id', 1)->exists();
        if (!$adminExists) {
            DB::table('admin')->insert([
                'id' => 1,
                'username' => 'admin',
                'password' => Hash::make('admin123'),
                'email' => 'admin@gmail.com',
                'forgot_unique_code' => '',
                'forgot_at' => '',
                'image' => 'panel/user.jpg',
                'updated_at' => now(),
                'created_at' => now(),
            ]);
        }

        $settingsData = [
            ['type' => 'app_version', 'message' => '4.2.0'],
            ['type' => 'default_language', 'message' => '1'],
            ['type' => 'system_timezone', 'message' => 'Asia/Kolkata'],
            ['type' => 'app_name', 'message' => 'News'],
            ['type' => 'primary_color', 'message' => '#E00000'],
            ['type' => 'secondary_color', 'message' => '#ba2028'],
            ['type' => 'auto_delete_expire_news_mode', 'message' => '0'],
            ['type' => 'app_logo_full', 'message' => 'panel/logo.png'],
            ['type' => 'app_logo', 'message' => 'panel/favicon.png'],
            ['type' => 'smtp_host', 'message' => 'smtp.googlemail.com'],
            ['type' => 'smtp_user', 'message' => 'SMTP User'],
            ['type' => 'smtp_password', 'message' => 'SMTP Password'],
            ['type' => 'smtp_port', 'message' => '465'],
            ['type' => 'smtp_crypto', 'message' => 'tls'],
            ['type' => 'from_name', 'message' => 'News'],
            ['type' => 'category_mode', 'message' => '1'],
            ['type' => 'subcategory_mode', 'message' => '1'],
            ['type' => 'breaking_news_mode', 'message' => '1'],
            ['type' => 'live_streaming_mode', 'message' => '1'],
            ['type' => 'comments_mode', 'message' => '1'],
            ['type' => 'weather_mode', 'message' => '0'],
            ['type' => 'location_news_mode', 'message' => '0'],
            ['type' => 'nearest_location_measure', 'message' => '1000'],
            ['type' => 'maintenance_mode', 'message' => '0'],
            ['type' => 'in_app_ads_mode', 'message' => '0'],
            ['type' => 'ads_type', 'message' => '1'],
            ['type' => 'google_rewarded_video_id', 'message' => 'google Rewarded Video Id'],
            ['type' => 'google_interstitial_id', 'message' => 'google Interstitial Id'],
            ['type' => 'google_banner_id', 'message' => 'google Banner Id'],
            ['type' => 'google_native_unit_id', 'message' => 'google Native Unit Id'],
            ['type' => 'unity_rewarded_video_id', 'message' => '1'],
            ['type' => 'unity_interstitial_id', 'message' => '1'],
            ['type' => 'unity_banner_id', 'message' => '1'],
            ['type' => 'android_game_id', 'message' => '1'],
            ['type' => 'ios_in_app_ads_mode', 'message' => '0'],
            ['type' => 'ios_ads_type', 'message' => '1'],
            ['type' => 'ios_google_rewarded_video_id', 'message' => 'google Rewarded Video Id'],
            ['type' => 'ios_google_interstitial_id', 'message' => 'google Interstitial Id'],
            ['type' => 'ios_google_banner_id', 'message' => 'google Banner Id'],
            ['type' => 'ios_google_native_unit_id', 'message' => 'google Native Unit Id'],
            ['type' => 'ios_unity_rewarded_video_id', 'message' => '1'],
            ['type' => 'ios_unity_interstitial_id', 'message' => '1'],
            ['type' => 'ios_unity_banner_id', 'message' => '1'],
            ['type' => 'ios_game_id', 'message' => '1'],
            ['type' => 'force_update_app_mode', 'message' => '0'],
            ['type' => 'android_app_version', 'message' => '1.0.0'],
            ['type' => 'ios_app_version', 'message' => '1.0.0'],
            ['type' => 'google_gemini_api_key', 'message' => ''],
            ['type' => 'google_app_open_unit_id', 'message' => 'google App Open Unit Id'],
            ['type' => 'ios_google_app_open_unit_id', 'message' => 'google App Open Unit Id'],
            ['type' => 'auth_short_video_views','message' => '0'],
            ['type' => 'ad_after_page_clicks','message' => '0'],
            ['type' => 'youtube_api_key','message' => ''],
            ['type' => 'finnhub_api_key','message' => ''],
            ['type' => 'twelvedata_api_key','message' => ''],
            ['type' => 'news_buzz_mode','message' => '1'],
            ['type' => 'podcast_mode','message' => '1'],
            ['type' => 'e_news_mode','message' => '1'],

        ];

        foreach ($settingsData as $data) {
            $existingSetting = Settings::where('type', $data['type'])->first();
            if (!$existingSetting) {
                Settings::insert($data);
            }
        }

        $languagesData = [
            [
                'id' => 1,
                'language' => 'English (US)',
                'display_name' => 'English (US)',
                'code' => 'en',
                'status' => 1,
                'isRTL' => 0,
                'image' => 'flags/en.webp',
                'app_file' => 'en_app.json',
                'web_file' => 'en_web.json',
                'panel_file' => 'en.json',
                'updated_at' => now(),
                'created_at' => now(),
            ],
        ];

        if (Language::count() === 0) {
            Language::insert($languagesData);
        }

        $pagesData = [
            [
                'title' => 'Privacy Policy',
                'slug' => 'privacy-policy',
                'meta_description' => 'Privacy Policy',
                'meta_keywords' => 'Policy',
                'is_custom' => 0,
                'page_content' => '<p style="text-align: left;">NEWS APP &amp; CONTENT POLICY</p>',
                'page_type' => 'privacy-policy',
                'language_id' => 1,
                'page_icon' => '',
                'is_termspolicy' => 0,
                'is_privacypolicy' => 1,
                'status' => 1,
                'schema_markup' => '',
                'meta_title' => '',
                'og_image' => '',
                'updated_at' => now(),
                'created_at' => now(),
            ],
            [
                'title' => 'Terms & Conditions',
                'slug' => 'terms-condition',
                'meta_description' => 'Terms & Conditions',
                'meta_keywords' => 'Terms',
                'is_custom' => 0,
                'page_content' => '<p style="text-align: left;"><strong>1. Terms Conditions</strong></p>',
                'page_type' => 'terms-condition',
                'language_id' => 1,
                'page_icon' => '',
                'is_termspolicy' => 1,
                'is_privacypolicy' => 0,
                'status' => 1,
                'schema_markup' => '',
                'meta_title' => '',
                'og_image' => '',
                'updated_at' => now(),
                'created_at' => now(),
            ],
            [
                'title' => 'Contact Us',
                'slug' => 'contact-us',
                'meta_description' => 'Contact Us',
                'meta_keywords' => 'Contact',
                'is_custom' => 0,
                'page_content' => '<p style="text-align: center;"><strong>How can we help you?</strong></p>',
                'page_type' => 'contact-us',
                'language_id' => 1,
                'page_icon' => '',
                'is_termspolicy' => 0,
                'is_privacypolicy' => 0,
                'status' => 1,
                'schema_markup' => '',
                'meta_title' => '',
                'og_image' => '',
                'updated_at' => now(),
                'created_at' => now(),
            ],
            [
                'title' => 'About Us',
                'slug' => 'about-us',
                'meta_description' => 'About Us',
                'meta_keywords' => 'About',
                'is_custom' => 0,
                'page_content' => '<p><strong>About Us:</strong></p>',
                'page_type' => 'about-us',
                'language_id' => 1,
                'page_icon' => '',
                'is_termspolicy' => 0,
                'is_privacypolicy' => 0,
                'status' => 1,
                'schema_markup' => '',
                'meta_title' => '',
                'og_image' => '',
                'updated_at' => now(),
                'created_at' => now(),
            ],


        ];

        if (Pages::count() === 0) {
            Pages::insert($pagesData);
        }

        $WebsettingsData = [
            ['type' => 'web_name', 'message' => 'News'],
            ['type' => 'light_body_color', 'message' => '#F5F5F5'],
            ['type' => 'light_hover_color', 'message' => '#122342'],
            ['type' => 'light_primary_color', 'message' => '#FF0000'],
            ['type' => 'light_secondary_color', 'message' => '#1A2E51'],
            ['type' => 'light_text_primary_color', 'message' => '#0F1F40'],
            ['type' => 'light_text_secondary_color', 'message' => '#65686D'],
            ['type' => 'light_header_logo', 'message' => 'logos/header-logo.svg'],
            ['type' => 'light_footer_logo', 'message' => 'logos/footer-logo.svg'],
            ['type' => 'light_placeholder_image', 'message' => 'logos/placeholder.png'],
            ['type' => 'dark_body_color', 'message' => '#0A1935'],
            ['type' => 'dark_hover_color', 'message' => '#15346D'],
            ['type' => 'dark_primary_color', 'message' => '#CE2B2B'],
            ['type' => 'dark_secondary_color', 'message' => '#122342'],
            ['type' => 'dark_text_primary_color', 'message' => '#ffffff'],
            ['type' => 'dark_text_secondary_color', 'message' => '#98A2B3'],
            ['type' => 'dark_header_logo', 'message' => 'logos/header-logo-dark.svg'],
            ['type' => 'dark_footer_logo', 'message' => 'logos/footer-logo-dark.svg'],
            ['type' => 'dark_placeholder_image', 'message' => 'logos/placeholder-dark.png'],
            ['type' => 'web_footer_description', 'message' => 'News Web website is an online platform that provides news and information about various topics, including current events, entertainment, politics, sports, technology, and more.'],
            ['type' => 'google_adsense', 'message' => ''],
            ['type' => 'android_app_link', 'message' => ''],
            ['type' => 'ios_app_link', 'message' => ''],
            ['type' => 'accept_cookie', 'message' => 0]
        ];

        foreach ($WebsettingsData as $data) {
            $existingWebSetting = WebSetting::where('type', $data['type'])->first();
            if (!$existingWebSetting) {
                WebSetting::insert($data);
            }
        }
    }
}
