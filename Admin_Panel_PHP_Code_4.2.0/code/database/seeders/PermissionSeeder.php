<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use App\Models\Admin;

class PermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Reset cached roles and permissions

        $permissions = [
            // News Management
            // Category permissions
            'category-list',
            'category-create',
            'category-edit',
            'category-delete',
            'category-order-create',

            // Sub Category permissions
            'sub-category-list',
            'sub-category-create',
            'sub-category-edit',
            'sub-category-delete',
            'sub-category-order-create',

            // Tag permissions
            'tag-list',
            'tag-create',
            'tag-edit',
            'tag-delete',

            // News permissions
            'news-list',
            'news-create',
            'news-edit',
            'news-edit-description',
            'news-clone',
            'news-delete',
            'news-bulk-delete',

            // Breaking News permissions
            'breaking-news-list',
            'breaking-news-create',
            'breaking-news-edit',
            'breaking-news-delete',
            'breaking-news-bulk-delete',

            // Live Streaming permissions
            'live-streaming-list',
            'live-streaming-create',
            'live-streaming-edit',
            'live-streaming-delete',

            // RSS Feed permissions
            'rss-list',
            'rss-create',
            'rss-edit',
            'rss-delete',
            'rss-bulk-delete',

            // Home Screen Management
            // Featured Section permissions
            'featured-section-list',
            'featured-section-create',
            'featured-section-edit',
            'featured-section-delete',
            'featured-section-order-create',

            // Ad Space permissions
            'ad-space-list',
            'ad-space-create',
            'ad-space-edit',
            'ad-space-delete',

            // User Management
            // User permissions
            'user-list',
            'user-edit',

            // Comment permissions
            'comment-list',
            'comment-delete',
            'comment-bulk-delete',

            // Comment Flag permissions
            'comment-flag-list',
            'comment-flag-delete',

            // Notification permissions
            'notification-list',
            'notification-create',
            'notification-delete',

            // Survey permissions
            'survey-list',
            'survey-create',
            'survey-edit',
            'survey-view',
            'survey-delete',
            'survey-bulk-delete',

            // Others
            // Location permissions
            'location-list',
            'location-create',
            'location-edit',
            'location-delete',

            // Pages permissions
            'page-list',
            'page-create',
            'page-edit',
            'page-delete',

            //Staff Management
            'staff-list',
            'staff-create',
            'staff-edit',
            'staff-change-password',
            'staff-delete',

            //Role Management
            'role-list',
            'role-create',
            'role-edit',
            'role-view',
            'role-delete',

            // System Setting permissions
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

            // author module
            'author-list',
            'author-edit',

            // eNews module
            'enews-list',
            'enews-create',
            'enews-edit',
            'enews-delete',

            // Video Shorts permissions
            'newsbuzz-list',
            'newsbuzz-create',
            'newsbuzz-edit',
            'newsbuzz-delete',
            'newsbuzz-bulk-delete',

            //Podcasts persmissions
            'podcast-list',
            'podcast-create',
            'podcast-edit',
            'podcast-delete',
            'podcast-bulk-delete',

            //Alerts permissions
            'alerts-list',
            'alerts-create',
            'alerts-edit',
            'alerts-delete',

            //Podcast episode permissions (appended at end to keep existing ids stable)
            'podcast-episode-list',
            'podcast-episode-create',
            'podcast-episode-edit',
            'podcast-episode-delete',
            'podcast-episode-bulk-delete',
        ];

        // Create permissions in the database with admin guard
        foreach ($permissions as $key => $permission) {
            Permission::updateOrCreate(['id'=> $key + 1],[
                'name' => $permission,
                'guard_name' => 'admin'
            ]);
        }

        // Create admin role with admin guard and assign all permissions
        $AdminRole = Role::updateOrCreate(['id'=> 1],[
            'name' => 'Admin',
            'guard_name' => 'admin'
        ]);
        $AdminRole->givePermissionTo(Permission::all());

        // Find the first admin and assign admin role
        $firstAdmin = Admin::first();
        if ($firstAdmin) {
            $firstAdmin->assignRole($AdminRole);
        }
    }
}
