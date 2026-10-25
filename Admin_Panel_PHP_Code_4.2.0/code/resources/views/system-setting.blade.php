@extends('layouts.main')

@section('title')
    {{ __('system_setting') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('system_setting') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('general-settings')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-1">
                    <a href="{{ url('general-settings') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-cogs icon_font_size "></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('general_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('panel-settings')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-1">
                    <a href="{{ url('panel-settings') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-cogs icon_font_size "></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('panel_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('web-settings')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-2">
                    <a href="{{ url('web-settings') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-tv icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('web_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('app-settings')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ url('app-settings') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-tablet-alt icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('app_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('language-list')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ url('language') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-language icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('language_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('seo-list')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ url('seo-setting') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-chart-bar icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('seo_setting') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('social-media-list')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ url('social-media') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-network-wired icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('social_media') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('firebase-configuration')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ url('firebase-configuration') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-cog icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('firebase_configuration') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan

                @can('system-update')
                <div class="col-lg-3 col-md-4 col-sm-12 mb-3">
                    <a href="{{ route('system-update') }}" class="card setting_active_tab" style="text-decoration: none;">
                        <div class="content d-flex h-100">
                            <div class="row mx-2 ">
                                <div class="provider_a test">
                                    <i class="fas fa-upload icon_font_size"></i>
                                </div>
                            </div>
                        </div>
                        <div class="card-body">
                            <h5 class="title">{{ __('system_update') }}</h5>
                            <div class="title">{{ __('go_to_settings') }} <i class="fas fa-arrow-right mt-2 arrow_icon"></i>
                            </div>
                        </div>
                    </a>
                </div>
                @endcan
            </div>
        </div>
    </section>
@endsection
