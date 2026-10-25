@extends('layouts.main')

@section('title')
    {{ __('dashboard') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('dashboard') }}</h1>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('news') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-green-new">
                                <i class="fas fa-newspaper text-green-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('news') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countNews }}
                                    </span>
                                </div>
                                <!-- Active / Inactive -->
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeNews ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveNews ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Categories -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('category') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-red-new">
                                <i class="fas fa-cube text-red-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('categories') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countCategory }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Users -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('app_users') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-sky-new">
                                <i class="fas fa-user text-sky-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('users') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countUsers }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeUsers ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveUsers ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Ad Spaces (already in desired format) -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('ad_spaces') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-orange-new">
                                <i class="fas fa-ad text-orange-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('ad_spaces') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countAdSpace }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeAdSpaces ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveAdSpaces ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
                <!-- Podcasts -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('podcast') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-sky-new">
                                <i class="fas fa-podcast text-sky-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('podcasts') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countPodcasts }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activePodcasts ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactivPodcasts ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
                <!-- news_buzz -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('video_shorts') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-pink-new">
                                <i class="fas fa-play-circle text-pink-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('news_buzz') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countNewsBuzz }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeNewsBuzz ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveNewsBuzz ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- eNews -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('e-news') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-green-new">
                                <i class="fas fa-envelope text-green-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('eNews') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countEnews }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeEnews ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveEnews ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Breaking News -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('breaking_news') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-orange-new">
                                <i class="fas fa-newspaper text-orange-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('breaking_news') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countBreakingNews }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- RSS Sources -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('rss') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-purple-new">
                                <i class="fas fa-rss text-purple-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('rss_sources') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countRssSource }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeRssSources ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveRssSources ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Featured Sections -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('featured_sections') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-blue-new">
                                <i class="fas fa-layer-group text-blue-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('featured_sections') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countFeatredSection }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeFeaturedSections ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveFeaturedSections ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Pages -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('pages') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-purple-new">
                                <i class="fas fa-file text-purple-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('pages') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $countPages }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activePages ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactivePages ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>

                <!-- Languages -->
                <div class="col-md-3 col-sm-6 col-12">
                    <a href="{{ url('language') }}" class="text-dark d-block h-100">
                        <div class="info-box">
                            <span class="info-box-icon bg-blue-new">
                                <i class="fas fa-language text-blue-new"></i>
                            </span>
                            <div class="info-box-content">
                                <div class="d-flex justify-content-between align-items-center w-100">
                                    <span class="info-box-text mb-0">{{ __('languages') }}</span>
                                    <span class="info-box-number counter mb-0"
                                        style="font-size: 1.25rem; font-weight: 550;">
                                        {{ $totalLanguage }}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center flex-wrap"
                                    style="font-size: 1rem; font-weight: 400; gap:8px;">
                                    <span class="d-flex align-items-center">
                                        <span class="bg-success rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $activeLanguages ?? '-' }}
                                    </span>
                                    <span class="d-flex align-items-center">
                                        <span class="bg-danger rounded-circle mr-1"
                                            style="width:10px;height:10px;"></span>
                                        {{ $inactiveLanguages ?? '-' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
            </div>
            <div class="row mb-3">
                <div class="col-md-5 col-sm-12 mb-3 mb-md-0">
                    <div class="card h-100">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('category_wise_news') }}</h3>
                        </div>
                        <div class="card-body d-flex flex-column justify-content-center align-items-center p-3">
                            <div id="category_chart" class="w-100">
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-7 col-sm-12">
                    <div class="card h-100 language-news-card">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('language_wise_news') }}</h3>
                        </div>
                        <div id="news_language_chart" class="language-news-chart">
                        </div>
                    </div>
                </div>
            </div>
            <div class="row mb-3">
                  <div class="col-md-7 col-sm-12 mb-3 mb-md-0">
                    <div class="card h-100">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('latest_category') }}</h3>
                        </div>
                        @if (count($recent_categories) == 0)
                            <div class=" px-4">
                                <div class="row">
                                    <div class="col-md-12  d-flex justify-content-center">
                                        <div class="empty-state" data-height="400" style="height: 400px;">
                                            <div class="empty-state-icon bg-primary">
                                                <i class="fas fa-question text-white "></i>
                                            </div>
                                            <h2>{{ __('could_not_find_data') }}</h2>
                                            <p class="lead">{{ __('make_alteast_entry') }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @else
                            <div class="card-body mt-3">
                                <div class="row">
                                    @foreach ($recent_categories as $row)
                                        <div class="col-md-3 col-sm-6 col-6 mb-3 text-center">
                                            @if ($row->image)
                                                <img src="{{ $row->image }}" alt="category"
                                                    class="d-block mx-auto"
                                                    style="height: 100px;width:100px;border-radius:5px;">
                                            @endif
                                            <a href="{{ url('category') }}" class="users-list-name mt-2 d-block">{{ $row->category_name }}</a>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                            <div class="card-footer text-center">
                                <a href="{{ url('category') }}"
                                    class="text-dark">{{ __('view_all') . ' ' . __('category') }}</a>
                            </div>
                        @endif
                    </div>
                </div>
                <div class="col-md-5 col-sm-12">
                    <div id="RNews-main" class="h-100 card">
                        <div class="card-header d-flex justify-content-between align-items-center flex-wrap">
                            <h3 class="card-title mb-0 flex-grow-1">{{ __('most_viewed_news') }}</h3>
                            <div class="tab-filter">
                                <button class="btn btn-sm btn-filter" data-filter="daily">{{ __('daily') }}</button>
                                <button class="btn btn-sm btn-filter" data-filter="weekly">{{ __('weekly') }}</button>
                                <button class="btn btn-sm btn-filter active"
                                    data-filter="monthly">{{ __('monthly') }}</button>
                            </div>
                        </div>
                        <div class="card-body p-0">
                            @if (count($monthly_news_view) == 0)
                                <div class="px-4">
                                    <div class="row">
                                        <div class="col-md-12 d-flex justify-content-center">
                                            <div class="empty-state" data-height="400" style="height: 400px;">
                                                <div class="empty-state-icon bg-primary">
                                                    <i class="fas fa-question text-white"></i>
                                                </div>
                                                <h2>{{ __('could_not_find_data') }}</h2>
                                                <p class="lead">{{ __('make_alteast_entry') }}</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            @else
                                <div id="news-items-container">
                                    <!-- Monthly news items (visible by default) -->
                                    <div id="monthly-news-container">
                                        @foreach ($monthly_news_view as $item)
                                            <div class="news-card">
                                                <img src="{{ $item->image ? $item->image : asset('images/favicon.png') }}"
                                                    class="news-card-image" alt="{{ $item->title }}"
                                                    onerror="this.onerror=null; this.src='{{ asset('images/favicon.png') }}';">
                                                <div class="news-card-content">
                                                    <div class="news-card-views">
                                                        <i class="fas fa-eye mr-1"></i> {{ $item->viewcount }}
                                                    </div>
                                                    <h6 class="news-card-title">{{ $item->title }}</h6>
                                                </div>
                                            </div>
                                        @endforeach
                                    </div>

                                    <!-- Weekly news items (hidden by default) -->
                                    <div id="weekly-news-container" style="display: none;">
                                        @if (count($weekly_news_view) == 0)
                                            <div class="px-4">
                                                <div class="row">
                                                    <div class="col-md-12 d-flex justify-content-center">
                                                        <div class="empty-state" data-height="400"
                                                            style="height: 400px;">
                                                            <div class="empty-state-icon bg-primary">
                                                                <i class="fas fa-question text-white"></i>
                                                            </div>
                                                            <h2>{{ __('could_not_find_data') }}</h2>
                                                            <p class="lead">{{ __('make_alteast_entry') }}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        @else
                                            @foreach ($weekly_news_view as $item)
                                                <div class="news-card">
                                                    <img src="{{ $item->image ? $item->image : asset('images/favicon.png') }}"
                                                        class="news-card-image" alt="{{ $item->title }}"
                                                        onerror="this.onerror=null; this.src='{{ asset('images/favicon.png') }}';">
                                                    <div class="news-card-content">
                                                        <div class="news-card-views">
                                                            <i class="fas fa-eye mr-1"></i> {{ $item->viewcount }}
                                                        </div>
                                                        <h6 class="news-card-title">{{ $item->title }}</h6>
                                                    </div>
                                                </div>
                                            @endforeach
                                        @endif
                                    </div>

                                    <!-- Daily news items (hidden by default) -->
                                    <div id="daily-news-container" style="display: none;">
                                        @if (count($daily_news_view) == 0)
                                            <div class="px-4">
                                                <div class="row">
                                                    <div class="col-md-12 d-flex justify-content-center">
                                                        <div class="empty-state" data-height="400"
                                                            style="height: 400px;">
                                                            <div class="empty-state-icon bg-primary">
                                                                <i class="fas fa-question text-white"></i>
                                                            </div>
                                                            <h2>{{ __('could_not_find_data') }}</h2>
                                                            <p class="lead">{{ __('make_alteast_entry') }}</p>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        @else
                                            @foreach ($daily_news_view as $item)
                                                <div class="news-card">
                                                    <img src="{{ $item->image ? $item->image : asset('images/favicon.png') }}"
                                                        class="news-card-image" alt="{{ $item->title }}"
                                                        onerror="this.onerror=null; this.src='{{ asset('images/favicon.png') }}';">
                                                    <div class="news-card-content">
                                                        <div class="news-card-views">
                                                            <i class="fas fa-eye mr-1"></i> {{ $item->viewcount }}
                                                        </div>
                                                        <h6 class="news-card-title">{{ $item->title }}</h6>
                                                    </div>
                                                </div>
                                            @endforeach
                                        @endif
                                    </div>
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
            <div class="row mb-3">
                <div class="col-md-6 col-sm-12 mb-3 mb-md-0">
                    <div class="card h-100 survey-card">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('language_wise_survey') }}</h3>
                        </div>
                        @if (count($surveys_per_language) > 0)
                            <div id="chart" class="survey-chart">
                            </div>
                            <div class="survey-chart-label">{{ __('survey_question') }}</div>
                        @else
                            <div class="px-4">
                                <div class="row">
                                    <div class="col-md-12 d-flex justify-content-center">
                                        <div class="empty-state" style="height: 400px;">
                                            <div class="empty-state-icon bg-primary">
                                                <i class="fas fa-question text-white"></i>
                                            </div>
                                            <h2>{{ __('could_not_find_data') }}</h2>
                                            <p class="lead">{{ __('make_alteast_entry') }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @endif
                    </div>
                </div>
                <div class="col-md-6 col-sm-12 d-flex">
                    <div class="card h-100 w-100 dash-equal-card">
                        <div class="card-header dash-card-header">
                            <h3 class="card-title dash-card-title">{{ __('latest_comment_in_news') }}</h3>
                        </div>
                        @if (count($recent_comments) == 0)
                            <div class=" px-4">
                                <div class="row">

                                    <div class="col-md-12 d-flex justify-content-center">
                                        <div class="empty-state" data-height="400" style="height: 400px;">
                                            <div class="empty-state-icon bg-primary">
                                                <i class="fas fa-question text-white "></i>
                                            </div>
                                            <h2>{{ __('could_not_find_data') }}</h2>
                                            <p class="lead">{{ __('make_alteast_entry') }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @else
                            <div class="card-body p-0 d-flex flex-column">
                                <div class="dash-comments">
                                    @foreach ($recent_comments as $row)
                                        @php
                                            $commentAuthor = $row?->user?->name ?: __('unknown');
                                            $commentAvatar =
                                                !empty($row?->user?->profile) && $row->user->profile !== ''
                                                    ? $row->user->profile
                                                    : asset('images/favicon.png');
                                            $commentNewsTitle = $row?->news?->title ?? null;
                                        @endphp
                                        <div class="dash-comment">
                                            <img class="dash-comment-avatar"
                                                src="{{ $commentAvatar }}"
                                                alt="{{ $commentAuthor }}"
                                                loading="lazy"
                                                onerror="this.onerror=null; this.src='{{ asset('images/favicon.png') }}';" />
                                            <div class="dash-comment-body">
                                                <div class="dash-comment-meta">
                                                    <strong class="dash-comment-author">{{ $commentAuthor }}</strong>
                                                    <span class="dash-comment-time">{{ $row->date }}</span>
                                                </div>
                                                <p class="dash-comment-text mb-1"
                                                    title="{{ $row->message }}">{{ Str::limit(trim($row->message), 100) }}</p>
                                                @if ($commentNewsTitle)
                                                    <a href="{{ url('comments') }}"
                                                        class="dash-comment-article">{{ Str::limit($commentNewsTitle, 70) }}</a>
                                                @endif
                                            </div>
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                            <div class="card-footer text-center dash-card-footer">
                                <a href="{{ url('comments') }}"
                                    class="text-dark">{{ __('view_all') . ' ' . __('comments') }}</a>
                            </div>
                        @endif
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection


@section('js')
    <!-- ChartJS -->
    <script src="{{ url('assets/plugins/chart.js/Chart.min.js') }}"></script>

    <!-- jQuery Knob Chart -->
    <script src="{{ url('assets/plugins/jquery-knob/jquery.knob.min.js') }}"></script>
    <script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>

    <script>
        // Most Viewed News Tabs
        $(document).ready(function() {
            // Define CSS for the new design
            const styleElement = document.createElement('style');
            styleElement.textContent = `
                .tab-filter {
                    display: flex;
                    background: white;
                    border-radius: 6px;
                    padding: 2px;
                }
                .btn-filter {
                    border-radius: 4px;
                    margin: 0 2px;
                    border: none;
                    font-size: 14px;
                    padding: 4px 10px;
                    color: #6c757d;
                    background: white;
                }
                .btn-filter.active {
                    background: var(--primary-color);
                    color: white;
                }
                #news-items-container {
                    display: flex;
                    flex-direction: column;
                    gap: 15px;
                    padding: 15px;
                }

                .news-card {
                    display: flex;
                    align-items: stretch;
                    height: 120px;
                    border-radius: 8px;
                    background: #fff;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
                    padding: 0;
                    overflow: hidden;
                    margin-bottom: 10px;
                }

                .news-card-image,
                .news-card-image-placeholder {
                    width: 120px;
                    height: 100%;
                    object-fit: cover;
                    border-radius: 5px;
                }

                .news-card-content {
                    flex: 1;
                    padding: 6px 9px;
                    display: flex;
                    flex-direction: column;
                }

                .news-card-views {
                    display: inline-flex;
                    align-items: center;
                    background: var(--primary-color);
                    color: white;
                    border-radius: 4px;
                    padding: 3px 10px;
                    font-size: 14px;
                    margin-bottom: 8px;
                    width: max-content;
                }

                .news-card-title {
                    font-size: 16px;
                    margin: 0;
                    line-height: 1.4;
                    color: #101828;
                    font-weight: 500;
                }
            `;
            document.head.appendChild(styleElement);

            // Make sure monthly tab is active by default
            $('#monthly-news-container').show();
            $('#weekly-news-container, #daily-news-container').hide();

            // Add click event to tabs for direct HTML containers
            $('.btn-filter').on('click', function() {
                $('.btn-filter').removeClass('active');
                $(this).addClass('active');

                const filter = $(this).data('filter');

                // Hide all containers
                $('#monthly-news-container, #weekly-news-container, #daily-news-container').hide();

                // Show the selected container
                switch (filter) {
                    case 'monthly':
                        $('#monthly-news-container').show();
                        break;
                    case 'weekly':
                        $('#weekly-news-container').show();
                        break;
                    case 'daily':
                        $('#daily-news-container').show();
                        break;
                }
            });
        });
    </script>
@endsection

@section('script')
    <script type="text/javascript">
        $(".counter").each(function() {
            $(this).prop("Counter", 0).animate({
                Counter: $(this).text(),
            }, {
                duration: 1600,
                easing: "swing",
                step: function(now) {
                    $(this).text(Math.ceil(now));
                },
            });
        });

        // Is the UI in dark mode? (mirrors the FOUC script / layout.js)
        var isDark = false;
        try {
            isDark = localStorage.getItem('ta.darkMode') === '1';
        } catch (e) {}

        // Brand accent from admin settings (matches Body[data-theme=tailadmin] --ta-brand)
        @php
            $_dsb_setting = getSetting();
            $_dsb_primary = isset($_dsb_setting['primary_color']) ? $_dsb_setting['primary_color'] : '#465FFF';
        @endphp
        var brandColor = '{{ $_dsb_primary }}';

        // Extracting data from PHP to JavaScript
        var newsData = [];
        @foreach ($news_per_category as $row)
            newsData.push({
                category: '{{ $row['category'] }}',
                newsCount: {{ $row['news'] }}
            });
        @endforeach
        var chartValueColor = isDark ? '#F9FAFB' : '#101828';
        var chartLegendColor = isDark ? '#98A2B3' : '#344054';
        var chartTextColor = isDark ? '#98A2B3' : '#667085';

        // Monochromatic step-down system derived from the primary brand color:
        // segment 1 = 100% solid, then 75% / 55% / 35% / 20% lightness steps.
        function mixColor(hex, weight) {
            var c = hex.replace('#', '');
            if (c.length === 3) c = c.split('').map(function (x) { return x + x; }).join('');
            var r = parseInt(c.substr(0, 2), 16);
            var g = parseInt(c.substr(2, 2), 16);
            var b = parseInt(c.substr(4, 2), 16);
            var mix = function (val) { return Math.round((255 - val) * weight + val); };
            var rr = mix(r).toString(16).padStart(2, '0');
            var gg = mix(g).toString(16).padStart(2, '0');
            var bb = mix(b).toString(16).padStart(2, '0');
            return '#' + rr + gg + bb;
        }
        // ultra-light brand-tinted grid lines (5-8% toward white) for light mode
        var chartGridLight = mixColor(brandColor, 0.94);

        // Distinct legacy stat-tile colors (matches the bg-*-new/text-*-new
        // palette used by the info-box icons) instead of primary monotones
        var categoryColors = ['#2563eb', '#22c55e', '#f87171', '#38bdf8', '#f472b6',
                              '#818cf8', '#a78bfa', '#64748b', '#fbbf24', '#22d3ee'];

        // ApexCharts data format - TailAdmin Donut Chart with Legend (chart-45)
        var apexChartData = {
            chart: {
                type: 'donut',
                height: 420,
                toolbar: {
                    show: false
                },
                fontFamily: 'Outfit, sans-serif'
            },
                series: newsData.map(item => item.newsCount),
            labels: newsData.map(item => item.category),
            colors: categoryColors,
            plotOptions: {
                pie: {
                    donut: {
                        size: '70%',
                        background: 'transparent',
                        labels: {
                            show: true,
                            name: {
                                show: true,
                                fontSize: '13px',
                                fontWeight: 400,
                                color: chartTextColor,
                                offsetY: 20
                            },
                            value: {
                                show: true,
                                fontSize: '28px',
                                fontWeight: 700,
                                color: chartValueColor,
                                offsetY: -16,
                                formatter: function (val) {
                                    return val;
                                }
                            },
                            total: {
                                show: true,
                                label: '{{ __('total') }} {{ __('news') }}',
                                fontSize: '13px',
                                fontWeight: 400,
                                color: chartTextColor,
                                formatter: function (w) {
                                    return w.globals.seriesTotals.reduce(function (a, b) {
                                        return a + b;
                                    }, 0);
                                }
                            }
                        }
                    }
                }
            },
            dataLabels: {
                enabled: false
            },
            stroke: {
                show: false,
                width: 0
            },
            legend: {
                show: true,
                showForSingleSeries: false,
                showForNullSeries: true,
                showForZeroSeries: true,
                position: 'bottom',
                horizontalAlign: 'center',
                markers: {
                    shape: 'circle',
                    size: 6,
                    offsetX: -2,
                    strokeWidth: 0
                },
                itemMargin: {
                    horizontal: 10,
                    vertical: 4
                },
                labels: {
                    colors: chartLegendColor
                },
                fontSize: '13px'
            },
            tooltip: {
                enabled: false
            },
            responsive: [{
                breakpoint: 768,
                options: {
                    chart: {
                        height: 260
                    }
                }
            }]
        };

        var categoryDonutChart = null;
        if (newsData.length > 0) {
            // Create an ApexCharts instance
            var chart = new ApexCharts(document.getElementById('category_chart'), apexChartData);
            categoryDonutChart = chart;
            // Render the chart
            chart.render();
            // Update donut center/legend colors on theme switch so white text doesn't stay on white bg
            document.addEventListener('ta:theme-changed', function (e) {
                if (!categoryDonutChart || !categoryDonutChart.updateOptions) return;
                var dark = e.detail === 'dark';
                categoryDonutChart.updateOptions({
                    plotOptions: {
                        pie: {
                            donut: {
                                labels: {
                                    name: { color: dark ? '#98A2B3' : '#667085' },
                                    value: { color: dark ? '#F9FAFB' : '#101828' },
                                    total: { color: dark ? '#98A2B3' : '#667085' }
                                }
                            }
                        }
                    },
                    legend: { labels: { colors: dark ? '#98A2B3' : '#344054' } }
                });
            });
        } else {
            $('#category_chart').html(
                '<div class="empty-state" style="height: 420px;">' +
                '<div class="empty-state-icon bg-primary"><i class="fas fa-question text-white"></i></div>' +
                '<h2>{{ __('could_not_find_data') }}</h2>' +
                '<p class="lead">{{ __('make_alteast_entry') }}</p>' +
                '</div>'
            );
        }
        // TailAdmin "Bar Chart 1" (chartOne) style
        var options = {
            series: [{
                name: '{{ __('news_count') }}',
                data: [
                    @foreach ($news_per_language as $row)
                        {{ $row['news'] }},
                    @endforeach
                ]
            }],
            noData: {
                text: 'No data available to display chart',
                align: 'center',
                verticalAlign: 'middle',
                offsetX: 0,
                offsetY: 0,
                style: {
                    color: undefined,
                    fontSize: '14px',
                    fontFamily: undefined
                }
            },
            colors: ['#2563eb', '#22c55e', '#f87171', '#38bdf8', '#f472b6',
                     '#818cf8', '#a78bfa', '#64748b', '#fbbf24', '#22d3ee'],
            chart: {
                fontFamily: 'Outfit, sans-serif',
                type: 'bar',
                // 440 fills the card to match the sibling category card
                // (420 donut + 32 body padding - 12 own bottom padding),
                // so no empty slack sits above the chart.
                height: 440,
                toolbar: {
                    show: false
                }
            },
            plotOptions: {
                bar: {
                    horizontal: false,
                    columnWidth: '60',
                    borderRadius: 5,
                    borderRadiusApplication: 'end',
                    distributed: true
                }
            },
            dataLabels: {
                enabled: false
            },
            stroke: {
                show: true,
                width: 4,
                colors: ['transparent']
            },
            xaxis: {
                categories: [
                    @foreach ($news_per_language as $row)
                        '{{ $row['language'] }}',
                    @endforeach
                ],
                axisBorder: {
                    show: false
                },
                axisTicks: {
                    show: false
                },
                labels: {
                    style: {
                        colors: isDark ? '#98a2b3' : '#667085',
                        fontSize: '12px',
                        fontWeight: 500
                    }
                }
            },
            yaxis: {
                title: false,
                labels: {
                    style: {
                        colors: isDark ? '#98a2b3' : '#667085'
                    }
                }
            },
            legend: {
                show: true,
                position: 'top',
                horizontalAlign: 'left',
                fontFamily: 'Outfit',
                markers: {
                    radius: 99
                },
                labels: {
                    colors: isDark ? '#98a2b3' : '#344054'
                }
            },
            grid: {
                yaxis: {
                    lines: {
                        show: true
                    }
                },
                borderColor: isDark ? '#1d2939' : chartGridLight,
                strokeDashArray: 0,
                padding: {
                    top: -12,
                    right: 0,
                    bottom: 0,
                    left: 0
                }
            },
            fill: {
                opacity: 1
            },
            tooltip: {
                x: {
                    show: false
                },
                y: {
                    formatter: function(val) {
                        return val;
                    }
                }
            },
            responsive: [{
                breakpoint: 480,
                options: {
                    chart: {
                        height: 320
                    },
                    xaxis: {
                        labels: {
                            style: {
                                fontSize: '10px'
                            }
                        }
                    }
                }
            }]
        };
        var newsLangChart = new ApexCharts(document.querySelector("#news_language_chart"), options);
        newsLangChart.render();

        // Re-theme the language-wise news bar chart when dark mode is toggled
        // (layout.js fires 'ta:theme-changed' after every toggle) so the grid
        // lines and axis/legend numbers stay visible in both modes.
        document.addEventListener('ta:theme-changed', function (e) {
            var dark = e.detail === 'dark';
            var axisColor = dark ? '#98a2b3' : '#667085';
            var legendColor = dark ? '#98a2b3' : '#344054';
            var gridColor = dark ? '#1d2939' : chartGridLight;
            var languageChartColors = ['#2563eb', '#22c55e', '#f87171', '#38bdf8', '#f472b6',
                                       '#818cf8', '#a78bfa', '#64748b', '#fbbf24', '#22d3ee'];
            newsLangChart.updateOptions({
                colors: languageChartColors,
                xaxis: {
                    labels: {
                        style: {
                            colors: axisColor,
                            fontSize: '12px',
                            fontWeight: 500
                        }
                    }
                },
                yaxis: {
                    labels: {
                        style: {
                            colors: axisColor
                        }
                    }
                },
                legend: {
                    labels: {
                        colors: legendColor
                    }
                },
                grid: {
                    yaxis: {
                        lines: {
                            show: true
                        }
                    },
                    borderColor: gridColor,
                    strokeDashArray: 0
                }
            }, false, true);
        });
        // Multi-color palette for the distributed survey bars.
        var customColors = ['#2563eb', '#22c55e', '#f87171', '#38bdf8', '#f472b6',
                            '#818cf8', '#a78bfa', '#64748b', '#fbbf24', '#22d3ee'];
        var surveysData = [
            @foreach ($surveys_per_language as $row)
                {
                    language: '{{ $row['language'] }}',
                    surveys: {{ $row['surveys'] }}
                },
            @endforeach
        ];

        // console.log(surveysData);

        // need to add condition when there is no data then show the message "No data found"

        var seriesData = surveysData.map(function(item) {
            return item.surveys;
        });
        var categoriesData = surveysData.map(function(item) {
            return item.language;
        });
        var options = {
            series: [{
                name: '{{ __('questions') }}',
                data: seriesData,
            }],
            noData: {
                text: 'No data available to display chart', // The message to show
                align: 'center', // Horizontal alignment: 'left', 'center', or 'right'
                verticalAlign: 'middle', // Vertical alignment: 'top', 'middle', or 'bottom'
                offsetX: 0, // X-offset for the text
                offsetY: 0, // Y-offset for the text
                style: {
                    color: undefined, // Text color
                    fontSize: '14px', // Font size
                    fontFamily: undefined // Font family
                }
            },
            chart: {
                type: 'bar',
                height: 400,
                toolbar: {
                    show: false // This hides the entire toolbar
                }
            },
            grid: {
                show: false,
            },
            plotOptions: {
                bar: {
                    distributed: true,
                    borderRadius: 4,
                    horizontal: true,
                    barHeight: 60,
                }
            },
            dataLabels: {
                enabled: false,
                textAnchor: 'start',
                style: {
                    colors: isDark ? ['#98A2B3'] : ['#475467'],
                    fontWeight: 600,
                    fontSize: '12px'
                },
                formatter: function(val, opt) {
                    return val
                },
                offsetX: 6,
                dropShadow: {
                    enabled: false
                }
            },
            xaxis: {
                categories: categoriesData,
                labels: {
                    style: {
                        colors: isDark ? '#98a2b3' : '#667085',
                        fontSize: '12px',
                        fontWeight: 500,
                    },
                },
            },
            yaxis: {
                labels: {
                    style: {
                        colors: isDark ? '#98a2b3' : '#667085',
                    },
                },
            },
            legend: {
                show: false,
            },
            colors: customColors,
            fill: {
                opacity: 1,
            },
            stroke: {
                show: false,
            },
            tooltip: {
                y: {
                    formatter: function(val) {
                        return val;
                    }
                }
            }
        };
        var monthlyChart = null;
        var chartElement = document.querySelector("#chart");
        if (chartElement) {
            monthlyChart = new ApexCharts(chartElement, options);
            monthlyChart.render();
        }
        document.addEventListener('ta:theme-changed', function (e) {
            if (!monthlyChart || !monthlyChart.updateOptions) return;
            var dark = e.detail === 'dark';
            var surveyChartColors = ['#2563eb', '#22c55e', '#f87171', '#38bdf8', '#f472b6',
                                     '#818cf8', '#a78bfa', '#64748b', '#fbbf24', '#22d3ee'];
            monthlyChart.updateOptions({
                colors: surveyChartColors,
                dataLabels: { style: { colors: dark ? ['#98A2B3'] : ['#475467'] } },
                xaxis: { labels: { style: { colors: dark ? '#98a2b3' : '#667085' } } },
                yaxis: { labels: { style: { colors: dark ? '#98a2b3' : '#667085' } } }
            });
        });
    </script>
@endsection
