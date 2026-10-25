<nav class="main-header navbar navbar-expand navbar-white navbar-light" role="navigation" aria-label="Main navigation">
    <style>
        /* Fix: language badge must stay centered inside its 40px circle.
           Bootstrap's d-md-inline (display:inline !important) would break
           the flex centering and collapse width/height, causing the text
           to sit at the top edge as in the screenshot. Force flex here. */
        .main-header .current_language {
            display: inline-flex !important;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            box-sizing: border-box;
            vertical-align: middle;
            line-height: 1;
            text-align: center;
        }

        /* TailAdmin-style user menu */
        .user-menu-dropdown .user-menu-toggle {
            padding: 0.35rem 0.5rem;
            border-radius: 9999px;
            gap: 0.5rem;
            text-decoration: none;
            color: inherit;
        }
        .user-menu-dropdown .user-menu-toggle:hover {
            background: var(--ta-hover, rgba(0,0,0,0.04));
        }
        .user-avatar-wrap {
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .user-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            object-fit: cover;
        }
        .user-avatar-placeholder {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: #e5e7eb;
            color: #374151;
            font-weight: 600;
            font-size: 14px;
        }
        .user-name {
            font-size: 14px;
            font-weight: 500;
            color: var(--ta-text-primary, #344054);
            line-height: 1;
        }
        .user-chevron {
            font-size: 10px;
            color: var(--ta-text-secondary, #667085);
            margin-left: 0.15rem;
        }

        /* Dark mode */
        html[data-theme-mode='dark'] .user-menu-dropdown .user-menu-toggle:hover,
        body[data-theme-mode='dark'] .user-menu-dropdown .user-menu-toggle:hover {
            background: var(--ta-hover, rgba(255,255,255,0.06));
        }
        html[data-theme-mode='dark'] .user-name,
        body[data-theme-mode='dark'] .user-name {
            color: var(--ta-text-primary, #f9fafb);
        }
        html[data-theme-mode='dark'] .user-chevron,
        body[data-theme-mode='dark'] .user-chevron {
            color: var(--ta-text-secondary, #98a2b3);
        }

        /* Responsive: tablet and below */
        @media (max-width: 768px) {
            .main-header .nav-link {
                padding: 0.5rem 0.5rem !important;
                min-height: 44px;
                display: inline-flex;
                align-items: center;
            }

            .main-header .user-avatar {
                max-width: 28px;
                max-height: 28px;
            }

            .main-header .navbar-nav.user-menu-right {
                flex-wrap: nowrap;
            }

            .main-header .user-menu .dropdown-toggle {
                max-width: 140px;
            }

            .main-header .user-menu .user-name {
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }

            .main-header .scrollable-menu {
                max-height: 60vh;
                overflow-y: auto;
            }
        }

        /* Responsive: small phones */
        @media (max-width: 425px) {
            .main-header .nav-link {
                padding: 0.4rem 0.5rem !important;
            }

            .main-header .user-avatar {
                max-width: 24px;
                max-height: 24px;
            }

            .main-header .user-menu .dropdown-toggle {
                max-width: 120px;
            }

            .main-header .version-badge {
                padding: 4px 6px !important;
                font-size: 0.7rem;
            }
        }

        /* Responsive: extra small */
        @media (max-width: 320px) {
            .main-header .nav-link {
                padding: 0.35rem 0.4rem !important;
            }

            .main-header .user-avatar {
                max-width: 20px;
                max-height: 20px;
            }

            .main-header .user-menu .dropdown-toggle .user-name {
                display: none;
            }

            .main-header .version-badge {
                display: none !important;
            }
        }
    </style>

    <!-- Left navbar links -->
    <ul class="navbar-nav align-items-center flex-nowrap">
        <li class="nav-item">
            <a class="nav-link" data-action="toggle-sidebar" href="javascript:void(0)" role="button"
                aria-label="Toggle menu">
                <i class="fas fa-bars" aria-hidden="true"></i>
            </a>
        </li>
        <li class="nav-item ml-2">
            <span class="badge version-badge"
                style="border-radius: var(--ta-radius-lg, 8px)!important; padding: 8px; color: {{ $setting['primary_color'] }}; border: 1px solid {{ $setting['primary_color'] }}">{{ $setting['app_version'] }}</span>
        </li>
        @if (env('DEMO_MODE'))
            <li class="nav-item ml-2 demo-mode-badge">
                <span class="badge badge-danger" style="border-radius: var(--ta-radius-lg, 8px)!important; padding: 8px">Demo mode</span>
            </li>
        @endif
    </ul>

    <!-- Right navbar links -->
    <ul class="navbar-nav ml-auto align-items-center flex-nowrap user-menu-right">
        <li class="nav-item">
            <a class="nav-link header-icon-btn theme-toggle-circle" href="javascript:void(0)" data-action="toggle-dark-mode"
                role="button" aria-label="Toggle dark mode" title="Toggle dark mode">
                <i class="fas fa-moon" aria-hidden="true"></i>
            </a>
        </li>
        <li class="nav-item dropdown user-menu">
            <div class="d-flex align-items-center flex-nowrap">
                <div class="dropdown language-picker">
                    <a href="javascript:void(0)" class="nav-link dropdown-toggle language-picker-btn"
                        data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"
                        id="languageDropdownToggle" title="{{ __('language') }}">
                        <span class="language-code">
                            {{ empty(session('language_name')) ? 'EN' : Str::upper(Str::limit(session('language_name'), 2, '')) }}
                        </span>
                        <i class="fas fa-language" aria-hidden="true"></i>
                    </a>
                    <div class="dropdown-menu dropdown-menu-lg dropdown-menu-right" id="languageDropdown"
                        aria-labelledby="languageDropdownToggle">
                        <div class="scrollable-menu">
                            @foreach (get_language(1) as $key => $language)
                                <a class="dropdown-item" href="{{ url('set-language') . '/' . $language->code }}">
                                    {{ $language->language }}
                                </a>
                            @endforeach
                        </div>
                    </div>
                </div>

                <div class="dropdown navbar_dropdown user-menu-dropdown">
                    <a href="javascript:void(0)" class="nav-link dropdown-toggle user-menu-toggle d-flex align-items-center"
                        data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <span class="user-avatar-wrap">
                            @if (Auth::user()->image)
                                <img src="{{ url(Storage::url(Auth::user()->image)) }}"
                                    class="user-avatar" alt="{{ Auth::user()->username }}">
                            @else
                                <span class="user-avatar-placeholder">{{ strtoupper(substr(Auth::user()->username, 0, 1)) }}</span>
                            @endif
                        </span>
                        <span class="user-name">{{ Auth::user()->username }}</span>
                        <i class="fas fa-chevron-down user-chevron" aria-hidden="true"></i>
                    </a>
                    <div class="dropdown-menu dropdown-menu-lg dropdown-menu-right">
                        <a href="{{ route('edit-profile') }}" class="dropdown-item">
                            <em class="fas fa-user mr-2" aria-hidden="true"></em>
                            <span>{{ __('edit') . ' ' . __('profile') }}</span>
                        </a>
                        <div class="dropdown-divider" role="separator"></div>
                        <a href="{{ url('logout') }}" class="dropdown-item">
                            <em class="fas fa-power-off mr-2" aria-hidden="true"></em>
                            <span>{{ __('logout') }}</span>
                        </a>
                    </div>
                </div>
            </div>
        </li>
    </ul>
</nav>
<!-- /.navbar -->