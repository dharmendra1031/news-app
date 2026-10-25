<!DOCTYPE html>
@php
    use App\Models\Language;
    use App\Models\Settings;

    $setting = Settings::where('type', 'app_logo')->first();
    $appLogoPath = optional($setting)->message;

    // Get current locale from session or fall back to app default
    $currentLang = session('locale') ?? app()->getLocale();

    // Get the language from DB or fallback to null
    $language = Language::where('code', $currentLang)->first();

    // Determine if it's an RTL language
    $isRTL = optional($language)->isRTL == 1;
@endphp

<html lang="{{ $currentLang }}">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="icon" type="image/x-icon" href="{{ url(Storage::url($appLogoPath)) }}" />

    <title>@yield('title') || {{ config('app.name') }}</title>
    <meta name="csrf-token" content="{{ csrf_token() }}" />
    @include('layouts.header_script')
    @yield('css')

    @php
        $setting = getSetting();
        $primary_color = isset($setting['primary_color']) ? $setting['primary_color'] : '#1B2D51';
        $secondary_color = isset($setting['secondary_color']) ? $setting['secondary_color'] : '#EE2934';
    @endphp

    <style>
        :root {
            --primary-color: <?php echo $primary_color; ?>;
            --secondary-color: <?php echo $secondary_color; ?>;
        }
    </style>

    <script>
        // FOUC-free dark mode: apply before paint (set on <html> immediately, and on <body> as soon as it exists)
        (function() {
            try {
                if (localStorage.getItem('ta.darkMode') === '1') {
                    document.documentElement.setAttribute('data-theme-mode', 'dark');
                    // body may not exist yet in <head>; set as soon as it is parsed
                    if (document.body) {
                        document.body.setAttribute('data-theme-mode', 'dark');
                    } else {
                        document.addEventListener('DOMContentLoaded', function() {
                            try {
                                if (localStorage.getItem('ta.darkMode') === '1') {
                                    document.body.setAttribute('data-theme-mode', 'dark');
                                }
                            } catch (e) {}
                        });
                    }
                }
            } catch (e) {}
        })();
    </script>

</head>

<body class="hold-transition sidebar-mini layout-fixed" data-theme="tailadmin" data-panel-auto-height="false" data-login-register-auto-height="false" style="height: auto;">
    <div class="wrapper">
        @include('layouts.header')

        @include('layouts.sidebar')

        <div class="content-wrapper">
            @yield('content')
        </div>

    </div>

    @include('layouts.footer_script')

    @yield('js')
    @yield('script')
</body>

</html>
