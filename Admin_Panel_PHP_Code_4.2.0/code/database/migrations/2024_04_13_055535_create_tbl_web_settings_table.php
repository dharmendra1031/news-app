<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_web_settings', function (Blueprint $table) {
            $table->id();
            $table->string('type')->nullable();
            $table->string('message')->nullable();
            $table->timestamps();
        });

        DB::table('tbl_web_settings')->insert([
            ['type' => 'web_name', 'message' => 'News', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_body_color', 'message' => '#f5f5f5', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_hover_color', 'message' => '#122342', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_primary_color', 'message' => '#ee2934', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_secondary_color', 'message' => '#1a2e51', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_text_primary_color', 'message' => '#0f1f40', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_text_secondary_color', 'message' => '#65686d', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_header_logo', 'message' => 'logos/header-logo.svg', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_footer_logo', 'message' => 'logos/footer-logo.svg', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'light_placeholder_image', 'message' => 'logos/placeholder.png', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_body_color', 'message' => '#0a1935', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_hover_color', 'message' => '#15346d', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_primary_color', 'message' => '#ce2b2b', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_secondary_color', 'message' => '#122342', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_text_primary_color', 'message' => '#ffffff', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_text_secondary_color', 'message' => '#98a2b3', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_header_logo', 'message' => 'logos/header-logo-dark.svg', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_footer_logo', 'message' => 'logos/footer-logo-dark.svg', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'dark_placeholder_image', 'message' => 'logos/placeholder-dark.png', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'favicon_icon', 'message' => 'logos/favicon-icon.png', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'web_footer_description', 'message' => 'News Web website is an online platform that provides news and information about various topics, including current events, entertainment, politics, sports, technology, and more.', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'google_adsense', 'message' => '', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'android_app_link', 'message' => '', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'ios_app_link', 'message' => '', 'updated_at' => now(), 'created_at' => now()],
            ['type' => 'accept_cookie', 'message' => 0, 'updated_at' => now(), 'created_at' => now()]
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_web_settings');
    }
};
