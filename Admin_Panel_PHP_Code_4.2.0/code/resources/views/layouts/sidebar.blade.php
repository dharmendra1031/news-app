<!-- Main Sidebar Container -->
@php
    $currentUrl = url()->current();
@endphp

<aside class="main-sidebar sidebar-dark-primary elevation-4">
    <!-- Brand Logo -->
    <a href="{{ url('home') }}" class="brand-link">
        <img src="{{ url(Storage::url($setting['app_logo'])) }}" alt="Logo" class="brand-image" style="opacity:.8">
        <span
            class="brand-text text-bold">{{ isset($setting['app_name']) ? $setting['app_name'] : env('APP_NAME') }}</span>
    </a>

    <!-- Sidebar -->
    <div class="sidebar">

        <!-- Sidebar Menu -->
        <nav class="mt-2">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu"
                data-accordion="false">
                <li class="nav-item">
                    <a href="{{ url('home') }}" class="nav-link  {{ $currentUrl == url('home') ? 'active' : '' }}">
                        <i class="nav-icon fas fa-tachometer-alt"></i>
                        <p>{{ __('dashboard') }}</p>
                    </a>
                </li>
                {{-- @canany(['category-list', 'category-create', 'category-edit', 'category-delete', 'sub-category-list', 'sub-category-create', 'sub-category-edit', 'sub-category-delete', 'sub-category-order-create', 'tag-list', 'tag-create', 'tag-edit', 'tag-delete', 'news-list', 'news-create', 'news-edit', 'news-delete', 'news-edit-description', 'news-clone', 'news-delete', 'news-bulk-delete', 'breaking-news-list', 'breaking-news-create', 'breaking-news-edit', 'breaking-news-delete', 'breaking-news-bulk-delete', 'live-streaming-list', 'live-streaming-create', 'live-streaming-edit', 'live-streaming-delete', 'rss-list', 'rss-create', 'rss-edit', 'rss-delete', 'rss-bulk-delete']) --}}
                <div class="sidebar-new-title">
                    {{ __('news_management') }}
                </div>
                @if (getSettingMode('category_mode') == 1)
                    @canany(['category-list', 'category-create', 'category-edit', 'category-delete'])
                        <li class="nav-item">
                            <a href="{{ url('category') }}"
                                class="nav-link  {{ $currentUrl == url('category') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-cube"></i>
                                <p>{{ __('category') }}</p>
                            </a>
                        </li>
                    @endcanany
                @endif
                @if (getSettingMode('subcategory_mode') == 1)
                    @canany(['sub-category-list', 'sub-category-create', 'sub-category-edit', 'sub-category-delete',
                        'sub-category-order-create'])
                        <li class="nav-item">
                            <a href="{{ url('sub_category') }}"
                                class="nav-link  {{ $currentUrl == url('sub_category') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-cubes"></i>
                                <p>{{ __('subcategory') }}</p>
                            </a>
                        </li>
                    @endcanany
                @endif
                @canany(['tag-list', 'tag-create', 'tag-edit', 'tag-delete'])
                    <li class="nav-item">
                        <a href="{{ url('tag') }}" class="nav-link {{ $currentUrl == url('tag') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-tag"></i>
                            <p>{{ __('tag') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['news-list', 'news-create', 'news-edit', 'news-delete', 'news-edit-description', 'news-clone',
                    'news-bulk-delete'])
                    <li class="nav-item">
                        <a href="{{ url('news') }}" class="nav-link {{ $currentUrl == url('news') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-newspaper"></i>
                            <p>{{ __('news') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['newsbuzz-list', 'newsbuzz-create', 'newsbuzz-edit', 'newsbuzz-delete'])
                    <li class="nav-item">
                        <a href="{{ route('video_shorts.index') }}"
                            class="nav-link {{ request()->routeIs('video_shorts.*') ? 'active' : '' }}">

                            <i class="nav-icon fas fa-play-circle"></i>

                            <p>{{ __('news_buzz') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['podcast-list', 'podcast-create', 'podcast-edit', 'podcast-delete', 'podcast-bulk-delete'])
                    <li class="nav-item">
                        <a href="{{ route('podcast.index') }}"
                            class="nav-link {{ request()->routeIs('podcast.index') ? 'active' : '' }}">

                            <i class="nav-icon fas fa-podcast"></i>

                            <p>{{ __('podcast') }}</p>
                        </a>
                    </li>
                @endcanany

                @canany(['enews-list', 'enews-create', 'enews-edit', 'enews-delete'])
                    <li class="nav-item">
                        <a href="{{ route('e-news.index') }}"
                            class="nav-link {{ $currentUrl == route('e-news.index') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-envelope"></i>
                            <p>{{ __('e_news') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['breaking-news-list', 'breaking-news-create', 'breaking-news-edit', 'breaking-news-delete',
                    'breaking-news-bulk-delete'])
                    <li class="nav-item">
                        <a href="{{ url('breaking_news') }}"
                            class="nav-link {{ $currentUrl == url('breaking_news') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-newspaper"></i>
                            <p>{{ __('breaking_news') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['live-streaming-list', 'live-streaming-create', 'live-streaming-edit',
                    'live-streaming-delete'])
                    <li class="nav-item">
                        <a href="{{ url('live_streaming') }}"
                            class="nav-link {{ $currentUrl == url('live_streaming') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-stream"></i>
                            <p>{{ __('live_streaming') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['rss-list', 'rss-create', 'rss-edit', 'rss-delete', 'rss-bulk-delete'])
                    {{-- rss feeds sources --}}
                    <li class="nav-item">
                        <a href="{{ url('rss') }}" class="nav-link {{ $currentUrl == url('rss') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-rss"></i>
                            <p>{{ __('rss_sources') }}</p>
                        </a>
                    </li>
                    {{-- new li for rss feeds --}}
                    {{-- <li class="nav-item">
                        <a href="{{ url('rss_feeds') }}" class="nav-link {{ $currentUrl == url('rss_feeds') ? 'active' : '' }}">
                            <i class="nav-icon fas fa-database"></i>
                            <p>{{ __('rss_feeds') }}</p>
                        </a>
                    </li> --}}
                @endcanany
                {{-- @endcanany --}}
                @canany(['alerts-list', 'alerts-create', 'alerts-edit', 'alerts-delete'])
                    <li class="nav-item">
                        <a href="{{ route('alerts.index') }}"
                            class="nav-link {{ request()->routeIs('alerts.index') ? 'active' : '' }}">

                            <i class="nav-icon fas fa-bell "></i>

                            <p>{{ __('alerts') }}</p>
                        </a>
                    </li>
                @endcanany
                @canany(['featured-section-list', 'featured-section-create', 'featured-section-edit',
                    'featured-section-delete', 'ad-space-list', 'ad-space-create', 'ad-space-edit', 'ad-space-delete'])
                    <div class="sidebar-new-title">
                        {{ __('home_screen_management') }}
                    </div>

                    @canany(['featured-section-list', 'featured-section-create', 'featured-section-edit',
                        'featured-section-delete'])
                        <li class="nav-item">
                            <a href="{{ url('featured_sections') }}"
                                class="nav-link {{ $currentUrl == url('featured_sections') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-layer-group"></i>
                                <p>{{ __('featured_section') }}</p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['ad-space-list', 'ad-space-create', 'ad-space-edit', 'ad-space-delete'])
                        <li class="nav-item">
                            <a href="{{ url('ad_spaces') }}"
                                class="nav-link {{ $currentUrl == url('ad_spaces') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-ad"></i>
                                <p> {{ __('ad_spaces') }} </p>
                            </a>
                        </li>
                    @endcanany
                @endcanany

                @canany(['user-list', 'user-edit', 'comment-list', 'comment-delete', 'comment-bulk-delete',
                    'comment-flag-list', 'comment-flag-delete', 'notification-list', 'notification-create',
                    'notification-delete', 'survey-list', 'survey-create', 'survey-edit', 'survey-view', 'survey-delete',
                    'survey-bulk-delete'])
                    <div class="sidebar-new-title">
                        {{ __('user_management') }}
                    </div>

                    @canany(['user-list', 'user-edit'])
                        <li class="nav-item">
                            <a href="{{ url('app_users') }}"
                                class="nav-link {{ $currentUrl == url('app_users') ? 'active' : '' }}">
                                <i class="fas fa-user nav-icon"></i>
                                <p>{{ __('user') }}</p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['author-list', 'author-edit'])
                        <li class="nav-item">
                            <a href="{{ route('author.index') }}"
                                class="nav-link {{ $currentUrl == route('author.index') ? 'active' : '' }}">
                                <i class="fas fa-user-tie nav-icon"></i>
                                <p>{{ __('author') }}</p>
                            </a>
                        </li>
                    @endcanany
                    {{-- <li class="nav-item">
                    <a href="{{ url('app_users_roles') }}" class="nav-link {{ $currentUrl == url('app_users_roles') ? 'active' : '' }}">
                        <i class="fas fa-user-tie nav-icon"></i>
                        <p>{{ __('user_role') }}</p>
                    </a>
                </li> --}}
                    @canany(['comment-list', 'comment-delete', 'comment-bulk-delete'])
                        <li class="nav-item">
                            <a href="{{ url('comments') }}"
                                class="nav-link {{ $currentUrl == url('comments') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-comments"></i>
                                <p> {{ __('comment') }} </p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['comment-flag-list', 'comment-flag-delete'])
                        <li class="nav-item">
                            <a href="{{ route('comments_flag') }}"
                                class="nav-link {{ $currentUrl == url('comments_flag') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-flag"></i>
                                <p> {{ __('comment_flag') }} </p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['notification-list', 'notification-create', 'notification-delete'])
                        <li class="nav-item">
                            <a href="{{ url('notifications') }}"
                                class="nav-link {{ $currentUrl == url('notifications') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-bullhorn"></i>
                                <p> {{ __('send_notification') }} </p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['survey-list', 'survey-create', 'survey-edit', 'survey-view', 'survey-delete',
                        'survey-bulk-delete'])
                        <li class="nav-item">
                            <a href="{{ url('survey') }}" class="nav-link {{ $currentUrl == url('survey') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-poll-h"></i>
                                <p> {{ __('survey') }} </p>
                            </a>
                        </li>
                    @endcanany
                @endcanany

                @canany(['location-list', 'location-create', 'location-edit', 'location-delete', 'page-list',
                    'page-create', 'page-edit', 'page-delete'])
                    <div class="sidebar-new-title">
                        {{ __('others') }}
                    </div>
                    @canany(['location-list', 'location-create', 'location-edit', 'location-delete'])
                        <li class="nav-item">
                            <a href="{{ url('location') }}"
                                class="nav-link  {{ $currentUrl == url('location') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-map-marker"></i>
                                <p>{{ __('location') }}</p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['page-list', 'page-create', 'page-edit', 'page-delete'])
                        <li class="nav-item">
                            <a href="{{ url('pages') }}"
                                class="nav-link  {{ $currentUrl == url('pages') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-file"></i>
                                <p>{{ __('pages') }}</p>
                            </a>
                        </li>
                    @endcanany
                @endcanany

                @canany(['role-list', 'role-create', 'role-edit', 'role-view', 'role-delete', 'staff-list',
                    'staff-create', 'staff-edit', 'staff-change-password', 'staff-delete'])
                    <div class="sidebar-new-title">
                        {{ __('staff_management') }}
                    </div>
                    @canany(['role-list', 'role-create', 'role-edit', 'role-view', 'role-delete'])
                        <li class="nav-item">
                            <a href="{{ route('roles.index') }}"
                                class="nav-link {{ request()->is('roles*') ? 'active' : '' }}">
                                <i class="fas fa-user-cog"></i>
                                <p>{{ __('roles') }}</p>
                            </a>
                        </li>
                    @endcanany
                    @canany(['staff-list', 'staff-create', 'staff-edit', 'staff-change-password', 'staff-delete'])
                        <li class="nav-item">
                            <a href="{{ url('staff') }}"
                                class="nav-link  {{ $currentUrl == url('staff') ? 'active' : '' }}">
                                <i class="fas fa-user-cog"></i>
                                <p>{{ __('staff_management') }}</p>
                            </a>
                        </li>
                    @endcanany
                @endcanany

                @canany(['general-settings', 'panel-settings', 'web-settings', 'app-settings', 'language-list',
                    'language-create', 'language-edit', 'language-delete', 'seo-list', 'seo-create', 'seo-edit',
                    'seo-delete', 'firebase-configuration', 'social-media-list', 'social-media-create', 'social-media-edit',
                    'social-media-delete', 'system-update'])
                    <div class="sidebar-new-title">
                        {{ __('system_configuration') }}
                    </div>

                    @canany(['general-settings', 'panel-settings', 'web-settings', 'app-settings', 'language-list',
                        'language-create', 'language-edit', 'language-delete', 'seo-list', 'seo-create', 'seo-edit',
                        'seo-delete', 'firebase-configuration', 'social-media-list', 'social-media-create', 'social-media-edit',
                        'social-media-delete', 'system-update'])
                        <li class="nav-item">
                            <a href="{{ url('system-settings') }}"
                                class="nav-link  {{ $currentUrl == url('system-settings') ? 'active' : '' }}">
                                <i class="nav-icon fas fa-cogs"></i>
                                <p>{{ __('system_setting') }}</p>
                            </a>
                        </li>
                    @endcanany
                @endcanany
            </ul>
        </nav>
        <!-- /.sidebar-menu -->
    </div>
    <!-- /.sidebar -->
</aside>
@section('script')
    <script type="text/javascript">
        // Add this script to open the dropdown
        document.addEventListener('DOMContentLoaded', function() {
            var menuOpenElement = document.querySelector('.nav-item.has-treeview.menu-open > ul');
            if (menuOpenElement) {
                menuOpenElement.style.display = 'block';
            }
        });
    </script>
@endsection
