@extends('layouts.main')

@section('title')
    {{ __('featured_section') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('featured_section') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i
                                class="nav-icon fas fa-layer-group mr-1"></i>{{ __('featured_section') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('featured-section-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('featured_section') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('featured_section') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('featured_sections.store') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <label class="required">{{ __('language') }}</label>
                                            <select id="language_id" name="language_id" class="form-control" required>
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                                @if (count($languageList) >= 1)
                                                    @foreach ($languageList as $item)
                                                        <option value="{{ $item->id }}" data-name="{{ $item->language }}">
                                                            {{ $item->language }}
                                                        </option>
                                                    @endforeach
                                                @endif
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('title') }}</label>
                                            <input id="title" name="title" required placeholder="{{ __('title') }}"
                                                type="text" class="form-control" data-slug-table="tbl_featured_sections"
                                                data-slug-target="#slug">
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('slug') }}</label><span
                                                class="">({{__('english_only')}})</span>
                                            <input id="slug" name="slug" required placeholder="{{ __('slug') }}" type="text"
                                                class="form-control">
                                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                        </div>
                                        <div class="form-group">
                                            <x-schema-markup-field />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('display_news_based_user_preference') }}</label>
                                            <div>
                                                <input type="checkbox" id="is_based_on_user_choice"
                                                    name="is_based_on_user_choice" class="status-switch">
                                                <input type="hidden" id="based_on_user_choice_mode"
                                                    class="based_on_user_choice_mode" name="based_on_user_choice_mode"
                                                    value="0">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div id="filter_section">
                                            <div class="form-group">
                                                <label class="required">{{ __('news_type') }}</label>
                                                <select id="news_type" name="news_type" class="form-control news_type"
                                                    required>
                                                    <option value="">{{ __('select') . ' ' . __('news_type') }}
                                                    </option>
                                                    <option value="news">{{ __('news') }}</option>
                                                    @if (is_breaking_news_enabled() == 1)
                                                        <option value="breaking_news">{{ __('breaking_news') }}</option>
                                                    @endif
                                                    <option value="videos">{{ __('videos') }}</option>
                                                    <option value="author_news">{{ __('author_news') }}</option>
                                                    <option value="rss_feeds_news">{{ __('rss_feeds_news') }}</option>
                                                </select>
                                            </div>
                                            <div class="form-group" id="videos_option" style="display: none">
                                                <label class="required">{{ __('which_videos_want_show') }}</label>
                                                <select id="videos_type" name="videos_type" class="form-control">
                                                    <option value=""> {{ __('select_option') }}</option>
                                                    <option value="news">{{ __('news') }}</option>
                                                    @if (is_breaking_news_enabled() == 1)
                                                        <option value="breaking_news">{{ __('breaking_news') }}</option>
                                                    @endif
                                                </select>
                                            </div>
                                            <div class="form-group" id="filter_type_section">
                                                <label class="required">{{ __('type_of_filter') }}</label>
                                                <select id="filter_type" name="filter_type" class="form-control filter_type"
                                                    required>
                                                    <option value="">{{ __('select_option') }}</option>
                                                    <option value="most_commented" class="most_commented">
                                                        {{ __('most_commented') }}
                                                    </option>
                                                    <option value="recently_added">{{ __('recently_added') }}</option>
                                                    <option value="most_viewed">{{ __('most_viewed') }}</option>
                                                    <option value="most_favorite" class="most_favorite">
                                                        {{ __('most_favorite') }}
                                                    </option>
                                                    <option value="most_like" class="most_like">{{ __('most_like') }}
                                                    </option>
                                                    <option value="custom">{{ __('custom') }}</option>
                                                </select>
                                            </div>
                                            {{-- author news select --}}
                                            <div class="form-group" id="author_news_type_section" style="display: none;">
                                                <label class="required">{{ __('authors') }}</label>
                                                <select id="author_news_type" name="author_news_type[]" multiple="multiple"
                                                    class="form-control author_news_type">

                                                </select>
                                            </div>

                                            @if (is_category_enabled() == 1)
                                                <div id="filter_news" class="form-group">
                                                    <label class="required">{{ __('category') }}</label>
                                                    <select id="category_ids" name="category_ids[]" class="form-control"
                                                        style="width:100%" multiple="multiple" required>
                                                        <option value="0" disabled>
                                                            {{ __('select') . ' ' . __('category') }}
                                                        </option>
                                                        @foreach ($categoryList as $row)
                                                            <option value="cat-{{ $row->id }}">{{ $row->category_name }}</option>
                                                            @if (is_subcategory_enabled() == 1)
                                                                @foreach ($row->sub_categories as $row1)
                                                                    <option value="subcat-{{ $row1->id }}">--{{ $row1->subcategory_name }}
                                                                    </option>
                                                                @endforeach
                                                            @endif
                                                        @endforeach
                                                    </select>
                                                </div>
                                                <div id="filter_category_list" class="form-group" style="display: none;">
                                                    <label class="required">{{ __('category') }}</label>
                                                    <select id="category_list" name="category_list[]" class="form-control"
                                                        style="width:100%" multiple="multiple">
                                                        <option value="0" disabled>
                                                            {{ __('select') . ' ' . __('category') }}
                                                        </option>
                                                    </select>
                                                </div>

                                                {{-- rss_feeds_news select --}}
                                                <div class="form-group" id="rss_feeds_news_section"
                                                    style="display: none;">
                                                    <label class="required">{{ __('rss_feeds') }}</label>
                                                    <i class="fa fa-question-circle"
                                                        data-content="{{__('please_select_1_or_2_rss_feeds_only')}}"></i>
                                                    <select id="rss_feeds_news_type" name="rss_feeds_news_type[]"
                                                        class="form-control rss_feeds_news_type" style="width: 100%"
                                                        multiple="multiple">
                                                        <option value="">{{ __('select') . ' ' . __('rss_feeds') }}</option>
                                                    </select>
                                                </div>
                                            @endif
                                            <div class="form-group" id="custom" style="display: none">
                                                <label class="required">{{ __('news') }}</label>
                                                <select id="news_ids" name="news_ids[]" class=" form-control"
                                                    multiple="multiple">
                                                </select>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('meta_description') }}</label>
                                            <textarea id="meta_description" name="meta_description" class="form-control"
                                                oninput="getWordCount('meta_description','meta_description_count','12.9px arial')"></textarea>
                                            <h6 id="meta_description_count">0</h6>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label>{{ __('meta_keywords') }}</label>
                                            <input id="meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                                name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('meta_title') }}</label>
                                            <input type="text" name="meta_title" class="form-control" id="meta_title"
                                                oninput="getWordCount('meta_title','meta_title_count','19.9px arial')"
                                                placeholder="{{ __('meta_title') }}">
                                            <h6 id="meta_title_count">0</h6>
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('og_image') }} </label>
                                            <input name="file" type="file" class="filepond">
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group row">
                                            <div class="col-md-12 col-sm-12">
                                                <label class="required">{{ __('select_style_for_app_section') }}</label>
                                            </div>
                                        </div>
                                        <div class="form-group row">
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_1" required
                                                        class="form-control" />
                                                    <img src="images/app_style/App_Style_1.png" alt="style_1"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_2" />
                                                    <img src="images/app_style/App_Style_2.png" alt="style_2"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_3" />
                                                    <img src="images/app_style/App_Style_3.png" alt="style_3"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_4" />
                                                    <img src="images/app_style/App_Style_4.png" alt="style_4"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_5" />
                                                    <img src="images/app_style/App_Style_5.png" alt="style_5"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img">
                                                    <input type="radio" name="style_app" value="style_6" />
                                                    <img src="images/app_style/App_Style_6.png" alt="style_6"
                                                        class="style_image">
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group row">
                                            <div class="col-md-12 col-sm-12">
                                                <label class="required">{{ __('select_style_for_web_section') }}</label>
                                            </div>
                                        </div>
                                        <br>
                                        <div class="form-group row">
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_1"
                                                        class="form-control" required />
                                                    <img src="images/app_style/Web_Style_1.png" alt="style_1"
                                                        class="style_image" style="display:block; margin-bottom:16px;">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_2" />
                                                    <img src="images/app_style/Web_Style_2.png" alt="style_2"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_3" />
                                                    <img src="images/app_style/Web_Style_3.png" alt="style_3"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_4" />
                                                    <img src="images/app_style/Web_Style_4.png" alt="style_4"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_5" />
                                                    <img src="images/app_style/Web_Style_5.png" alt="style_5"
                                                        class="style_image">
                                                </label>
                                            </div>
                                            <div class="col-md-2 col-sm-2">
                                                <label class="radio-img-web">
                                                    <input type="radio" name="style_web" value="style_6" />
                                                    <img src="images/app_style/Web_Style_6.png" alt="style_6"
                                                        class="style_image">
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer d-flex justify-content-end">
                                <button type="button" class="btn btn-outline-primary" id="generate_meta_fields">
                                    <i class="fas fa-magic"></i> {{ __('generate') }}
                                </button>
                                <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            @can('featured-section-list')
                <div class="row">
                    <div class="col-lg-9 col-md-12 col-sm-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('featured_section') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    <div class="toolbar-filter">
                                        <select id="filter_language_id" class="form-control">
                                            <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_status" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_news_type" class="form-control">
                                           <option value="">{{ __('select') . ' ' . __('news_type') }}
                                           </option>
                                           <option value="news">{{ __('news') }}</option>
                                            @if (is_breaking_news_enabled() == 1)
                                                <option value="breaking_news">{{ __('breaking_news') }}</option>
                                            @endif
                                            <option value="videos">{{ __('videos') }}</option>
                                            <option value="author_news">{{ __('author_news') }}</option>
                                            <option value="rss_feeds_news">{{ __('rss_feeds_news') }}</option>
                                        </select>
                                    </div>

                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table" 
                                    data-url="{{ route('featuredSectionList') }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="row_order"
                                    data-sort-order="asc" data-query-params="featuredSectionQueryParams">
                                    <thead>
                                        <tr>
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            
                                            <th scope="col" data-field="language">{{ __('language') }}</th>
                                            <th scope="col" data-field="title" data-sortable="false">{{ __('title') }}
                                            </th>
                                            <th scope="col" data-field="slug" data-sortable="false" data-visible="false">{{ __('slug') }}
                                            </th>
                                            <th scope="col" data-field="news_type_badge">{{ __('news_type') }}</th>
                                            <th scope="col" data-field="rss_feeds_badge">{{ __('rss_feeds') }}</th>
                                            <th scope="col" data-field="video_type_badge">{{ __('video_type') }}</th>
                                            <th scope="col" data-field="filter_type_badge">{{ __('type_of_filter') }}</th>
                                            <th scope="col" data-field="style_app">{{ __('app_style') }}</th>
                                            <th scope="col" data-field="style_web">{{ __('web_style') }}</th>
                                            <th scope="col" data-field="status1">{{ __('status') }}</th>
                                            <th scope="col" data-field="short_description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('short_description') }}
                                            </th>
                                            <th scope="col" data-field="schema_markup" data-visible="false">
                                                {{ __('schema_markup') }}
                                            </th>
                                            <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_keywords') }}
                                            </th>
                                            <th scope="col" data-field="og_image" data-visible="true">
                                                {{ __('og_image') }}
                                            </th>
                                            <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_title') }}
                                            </th>
                                            <th scope="col" data-field="meta_description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_description') }}
                                            </th>
                                            <th scope="col" data-field="row_order" data-sortable="true">
                                                {{ __('row_order') }}
                                            </th>
                                            <th scope="col" data-field="created_at" data-visible="false">
                                                {{ __('created_at') }}
                                            </th>
                                            @canany(['featured-section-edit', 'featured-section-delete'])
                                                <th scope="col" data-field="operate" data-events="featuredSectionEvents">
                                                    {{ __('operate') }}
                                                </th>
                                            @endcanany
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
            @endcan
                @can('featured-section-order-create')
                        <div class="col-lg-3 col-md-12 col-sm-12">
                            <div class="card card-secondary">
                                <div class="card-header">
                                    <h3 class="card-title">{{ __('featured_section') . ' ' . __('order') }}</h3>
                                </div>
                                <form id="order_form" action="{{ route('update_featured_sections_order') }}" method="post"
                                    onsubmit="return saveOrder()">
                                    @csrf
                                    <div class="card-body">
                                        <div class="form-group col-md-12 col-sm-12">
                                            <select id="order_language_id" class="form-control">
                                                <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                                @foreach ($languageList as $item)
                                                    <option value="{{ $item->id }}">{{ $item->language }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="col-md-12 col-sm-12">
                                            <input id="row_order" name="row_order" type="hidden">
                                            <ol id="sortable-row">
                                                @foreach ($featuredList as $row)
                                                    <li id="{{ $row->id }}">{{ $row->title }}</li>
                                                @endforeach
                                            </ol>
                                        </div>
                                    </div>
                                    <div class="card-footer">
                                        <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                @endcan
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('featured_section') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('featured_sections') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="edit_language_id" name="language_id" class="form-control language_id"
                                            required>
                                            <option disabled>{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $item)
                                                <option value="{{ $item->id }}">{{ $item->language }}
                                                </option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('title') }}</label>
                                        <input id="edit_title" name="title" type="text" required class="form-control"
                                            data-slug-table="tbl_featured_sections" data-slug-target="#edit_slug"
                                            data-slug-id="#edit_id">
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('slug') }}</label><span
                                            class="">({{__('english_only')}})</span>
                                        <input id="edit_slug" name="slug" type="text" required class="form-control">
                                        <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                    </div>
                                    <div class="form-group">
                                        <x-schema-markup-field id="edit_schema_markup" />
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('display_news_based_user_preference') }}</label>
                                        <div>
                                            <input type="checkbox" id="edit_is_based_on_user_choice"
                                                name="edit_is_based_on_user_choice" class="status-switch editInModel">
                                            <input type="hidden" id="edit_based_on_user_choice_mode"
                                                class="edit_based_on_user_choice_mode" name="edit_based_on_user_choice_mode"
                                                value="0">
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div id="edit_filter_section">
                                        <div class="form-group">
                                            <label class="required">{{ __('news_type') }}</label>
                                            <select id="edit_news_type" name="news_type" class="form-control" required>
                                                <option value="news">{{ __('news') }}</option>
                                                @if (is_breaking_news_enabled() == 1)
                                                    <option value="breaking_news">{{ __('breaking_news') }}</option>
                                                @endif
                                                <option value="videos">{{ __('videos') }}</option>
                                                <option value="author_news">{{ __('author_news') }}</option>
                                                <option value="rss_feeds_news">{{ __('rss_feeds_news') }}</option>
                                            </select>
                                        </div>
                                        <div id="edit_author_news_type_section" class="form-group">

                                            <label class="required"> {{ __('authors') }}</label>
                                            <select id="edit_author_news_type" name="author_news_type[]" multiple="multiple"
                                                class="form-control" multiple="multiple">
                                            </select>

                                        </div>
                                        <div id="edit_videos_option" class="form-group">
                                            <label>{{ __('which_videos_want_show') }}</label>
                                            <select id="edit_videos_type" name="videos_type" class="form-control">
                                                <option value="">{{ __('select') }}</option>
                                                <option value="news">{{ __('news') }}</option>
                                                @if (is_breaking_news_enabled() == 1)
                                                    <option value="breaking_news">{{ __('breaking_news') }}</option>
                                                @endif
                                            </select>
                                        </div>
                                        <div class="form-group" id="edit_filter_type_section">
                                            <label class="required">{{ __('type_of_filter') }}</label>
                                            <select id="edit_filter_type" name="filter_type"
                                                class="form-control filter_type" required>
                                                <option value="">{{ __('select_option') }}</option>
                                                <option value="most_commented" class="most_commented">
                                                    {{ __('most_commented') }}
                                                </option>
                                                <option value="recently_added">{{ __('recently_added') }}</option>
                                                <option value="most_viewed">{{ __('most_viewed') }}</option>
                                                <option value="most_favorite" class="most_favorite">
                                                    {{ __('most_favorite') }}
                                                </option>
                                                <option value="most_like" class="most_like">{{ __('most_like') }}
                                                </option>
                                                <option value="custom">{{ __('custom') }}</option>
                                            </select>
                                        </div>
                                        <div class="form-group" id="edit_filter_news_section">
                                            @if (is_category_enabled() == 1)
                                                <div id="edit_filter_news" class="form-group">
                                                    <label class="required">{{ __('category') }}</label>
                                                    <select id="edit_category_ids" name="category_ids[]" class="form-control"
                                                        multiple="multiple" required>
                                                    </select>
                                                </div>
                                                <div id="edit_filter_category_list" class="form-group" style="display: none;">
                                                    <label class="required">{{ __('category List') }}</label>
                                                    <select id="edit_category_list" name="category_list[]" class="form-control"
                                                        style="width:100%" multiple="multiple" required>
                                                        <option value="0" disabled>
                                                            {{ __('select') . ' ' . __('category') }}
                                                        </option>
                                                    </select>
                                                </div>

                                                {{-- rss_feeds_news select --}}
                                                <div class="form-group" id="edit_rss_feeds_news_section" style="display: none;">
                                                    <label class="required">{{ __('rss_feeds') }}</label>
                                                    <i class="fa fa-question-circle"
                                                        data-content="{{__('please_select_1_or_2_rss_feeds_only')}}"></i>
                                                    <select id="edit_rss_feeds_news_type" name="rss_feeds_news_type[]"
                                                        class="form-control rss_feeds_news_type" style="width: 100%"
                                                        multiple="multiple" required>
                                                        <option value="">{{ __('select') . ' ' . __('rss_feeds') }}</option>
                                                    </select>
                                                </div>
                                            @endif
                                            <div id="edit_custom" class="form-group">
                                                <label class="required"> {{ __('news') }}</label>
                                                <select id="edit_news_ids" name="news_ids[]" class="form-control"
                                                    multiple="multiple" required>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_description') }}</label>
                                        <textarea id="edit_meta_description" name="meta_description" class="form-control"
                                            oninput="getWordCount('edit_meta_description','edit_meta_description_count','12.9px arial')"></textarea>
                                        <h6 id="edit_meta_description_count">0</h6>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>{{ __('meta_keywords') }}</label>
                                        <input id="edit_meta_tags" class="w-100" type="text" name="meta_keyword"
                                            style="border-radius: 0.25rem"
                                            placeholder="{{ __('press_enter_add_keywords') }}">
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_title') }}</label>
                                        <input id="edit_meta_title" name="meta_title" type="text"
                                            oninput="getWordCount('edit_meta_title','edit_meta_title_count','19.9px arial')"
                                            placeholder="{{ __('meta_title') }}" class="form-control">
                                        <h6 id="edit_meta_title_count">0</h6>
                                    </div>
                                    <div class="form-group">
                                        <div class="form-group">
                                            <label>{{ __('og_image') }} </label>
                                            <input name="file" type="file" class="filepond">
                                            <div id="edit_image_preview_container" class="mt-2" style="">
                                                <label class="d-block small text-muted">{{ __('current_og_image') }}</label>
                                                <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="form-group row">
                                <div class="col-md-6 row">
                                    <div class="col-lg-12">
                                        <label class="required">{{ __('select_style_for_app_section') }}</label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_1" required />
                                            <img src="images/app_style/App_Style_1.png" alt="style_1" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_2" />
                                            <img src="images/app_style/App_Style_2.png" alt="style_2" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_3" />
                                            <img src="images/app_style/App_Style_3.png" alt="style_3" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_4" />
                                            <img src="images/app_style/App_Style_4.png" alt="style_4" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_5" />
                                            <img src="images/app_style/App_Style_5.png" alt="style_5" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img">
                                            <input type="radio" name="style_app" value="style_6" />
                                            <img src="images/app_style/App_Style_6.png" alt="style_6" class="style_image">
                                        </label>
                                    </div>
                                </div>
                                <div class="col-md-6 row">
                                    <div class="col-lg-12">
                                        <label class="required"> {{ __('select_style_for_web_section') }}</label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_1" required />
                                            <img src="images/app_style/Web_Style_1.png" alt="style_1" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_2" />
                                            <img src="images/app_style/Web_Style_2.png" alt="style_2" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_3" />
                                            <img src="images/app_style/Web_Style_3.png" alt="style_3" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_4" />
                                            <img src="images/app_style/Web_Style_4.png" alt="style_4" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_5" />
                                            <img src="images/app_style/Web_Style_5.png" alt="style_5" class="style_image">
                                        </label>
                                    </div>
                                    <div class="col-md-2">
                                        <label class="radio-img edit-radio-img-web">
                                            <input type="radio" name="style_web" value="style_6" />
                                            <img src="images/app_style/Web_Style_6.png" alt="style_6" class="style_image">
                                        </label>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-6 col-sm-6 col-xs-12">
                                <label class="control-label"> {{ __('status') }}</label>
                                <div id="status1" class="btn-group">
                                    <label class="btn btn-success" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input class="mr-1" type="radio" name="status" value="1">{{ __('active') }}
                                    </label>
                                    <label class="btn btn-danger" data-toggle-class="btn-primary"
                                        data-toggle-passive-class="btn-default">
                                        <input class="mr-1" type="radio" name="status" value="0">{{ __('deactive') }}
                                    </label>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                            <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('script')
    {{-- Slug generation is handled globally by slug-helper.js via data-slug-* attributes --}}
    <script type="text/javascript">

    </script>

    <script type="text/javascript">
        $("#filter_language_id").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_status").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_news_type").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });

    </script>

    <script type="text/javascript">
        function saveOrder() {
            var selectedLanguage = new Array();
            $('ol#sortable-row li').each(function () {
                selectedLanguage.push($(this).attr("id"));
            });
            document.getElementById("row_order").value = selectedLanguage;
        }

        $('#order_language_id').on('change', function (e) {
            var language_id = $('#order_language_id').val();
            var url = '{{ route('get_feature_section_by_language') }}';
            var data = {
                language_id: language_id,
                sortable: 1
            };
            fetchList(url, data, '#sortable-row');
        });

        $(function () {
            $("#sortable-row").sortable();

            $('.videos').hide();

            // Ensure RSS feeds section is hidden on page load
            $('#rss_feeds_news_section').hide();

            // NOTE: width:'100%' is required on every multi-select. Without it,
            // selects initialised while hidden (#custom, #filter_category_list,
            // #rss_feeds_news_section) render as raw native listboxes (see bug
            // screenshot) because Select2 cannot resolve their width.
            $('#category_ids').select2({
                placeholder: '{{ __('select') . ' ' . __('category') }}',
                width: '100%'
            });
            $('#author_news_type').select2({
                placeholder: '{{ __('select') . ' ' . __('author_news') }}',
                width: '100%'
            });
            $('#news_ids').select2({
                placeholder: '{{ __('select') . ' ' . __('news') }}',
                width: '100%'
            });

            $('#category_list').select2({
                placeholder: '{{ __('select') . ' ' . __('category') }}',
                width: '100%',
                maximumSelectionLength: 3
            });
            // Initialize RSS feeds Select2 (works even when parent is hidden)
            $('#rss_feeds_news_type').select2({
                placeholder: '{{ __('select') . ' ' . __('rss_feeds') }}',
                width: '100%',
                maximumSelectionLength: 3
            });
            // Ensure RSS feeds section stays hidden after Select2 initialization
            $('#rss_feeds_news_section').hide();
            $('#edit_category_ids').select2({
                placeholder: '{{ __('select') . ' ' . __('category') }}',
                width: '100%'
            });
            $('#edit_news_ids').select2({
                placeholder: '{{ __('select') . ' ' . __('news') }}',
                width: '100%'
            });

            $('#edit_author_news_type').select2({
                placeholder: '{{ __('select') . ' ' . __('author_news') }}',
                width: '100%'
            });
            $('#edit_category_list').select2({
                placeholder: '{{ __('select') . ' ' . __('category') }}',
                width: '100%',
                maximumSelectionLength: 3
            });
            $('#edit_rss_feeds_news_type').select2({
                placeholder: '{{ __('select') . ' ' . __('rss_feeds') }}',
                width: '100%',
                maximumSelectionLength: 3
            });

            // When a hidden section is revealed, nudge Select2 to recalc width
            // (fixes collapsed/incorrect rendering after .show()).
            function refreshVisibleSelect2() {
                $('#filter_news:visible #category_ids, #custom:visible #news_ids, #filter_category_list:visible #category_list, #rss_feeds_news_section:visible #rss_feeds_news_type, #edit_filter_news:visible #edit_category_ids, #edit_custom:visible #edit_news_ids, #edit_filter_category_list:visible #edit_category_list, #edit_rss_feeds_news_section:visible #edit_rss_feeds_news_type').each(function () {
                    $(this).trigger('change.select2');
                });
            }
            window.refreshVisibleSelect2 = refreshVisibleSelect2;

            var elems = Array.prototype.slice.call(
                document.querySelectorAll(".status-switch")
            );
            elems.forEach(function (elem) {
                var switchery = new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
            });
        });
    </script>

    <script type="text/javascript">

        // =====================================================================
        // AJAX helper functions
        // =====================================================================

        /**
         * Generic GET/POST helper – loads HTML into a selector.
         */
        function fetchCategoriesList(url, data, selector, callback) {
            $.ajax({
                url: url, type: 'GET', data: data,
                success: function (result) {
                    $(selector).html(result);
                    $(selector).trigger('change.select2');
                    if (typeof callback === 'function') callback(result);
                },
                error: function () {
                    $(selector).html('');
                    if (typeof callback === 'function') callback('');
                }
            });
        }
       // fetching rss feeds based on category ids for create form
       function fetchRssFeedsList(url, selector) {
            var $select = $(selector);

            // Store current selection BEFORE replacing HTML
            var currentSelection = $select.val() || [];

            $.ajax({
                url: url,
                type: 'GET',
                success: function(result) {
                    $select.html(result);

                    // Get available options after new HTML is loaded
                    var availableOptions = [];
                    $select.find('option').each(function() {
                        var val = $(this).val();
                        if (val && val !== '') availableOptions.push(val);
                    });

                    // Preserve feeds that still exist, remove those that don't
                    var feedsToPreserve = currentSelection.filter(function(feedId) {
                        return availableOptions.indexOf(feedId) !== -1;
                    });

                    if (feedsToPreserve.length) {
                        $select.val(feedsToPreserve).trigger('change');
                    } else {
                        $select.val(null).trigger('change');
                    }
                },
                error: function() {
                    $select.html('');
                    $select.val(null).trigger('change');
                }
            });
        }

        // Similar to fetchRssFeedsList but for edit form 
        function fetchEditRssFeedsList(url, selector, preSelectedFeeds) {
            var $select = $(selector);

            // Store current selection BEFORE replacing HTML
            var currentSelection = $select.val() || [];

            $.ajax({
                url: url,
                type: 'GET',
                success: function(result) {
                    $select.html(result);

                    // Get available options after new HTML is loaded
                    var availableOptions = [];
                    $select.find('option').each(function() {
                        var val = $(this).val();
                        if (val && val !== '') availableOptions.push(val);
                    });

                    var feedsToSelect = [];

                    // Priority 1: Pre-selected feeds from row data (initial modal open)
                    if (preSelectedFeeds && preSelectedFeeds.length) {
                        var arr = Array.isArray(preSelectedFeeds) 
                            ? preSelectedFeeds 
                            : String(preSelectedFeeds).split(',');
                        
                        feedsToSelect = arr
                            .map(function(v) { return String(v).trim(); })
                            .filter(function(v) { 
                                return v !== '' && availableOptions.indexOf(v) !== -1; 
                            });
                    }
                    // Priority 2: Preserve current selection (user adds/removes categories)
                    else if (currentSelection.length) {
                        feedsToSelect = currentSelection.filter(function(v) {
                            return availableOptions.indexOf(v) !== -1;
                        });
                    }

                    if (feedsToSelect.length) {
                        $select.val(feedsToSelect).trigger('change');
                    } else {
                        $select.val(null).trigger('change');
                    }
                },
                error: function() {
                    $select.html('');
                    $select.val(null).trigger('change');
                }
            });
        }

        /** Fetch author <option> list (create form). */
        function fetchAuthorList(url, data, selector) {
            $.ajax({
                url: url, type: 'GET', data: data,
                success: function (result) { $(selector).html(result); },
                error: function () { $(selector).html(''); }
            });
        }

        /**
         * Fetch author list for edit form, optionally pre-selecting values.
         * @param {string|string[]|null} selectedValues  Comma-separated IDs or array.
         */
        function fetchEditAuthorList(url, data, selector, selectedValues) {
            $.ajax({
                url: url, type: 'GET', data: data,
                success: function (result) {
                    $(selector).html(result);
                    if (!selectedValues) return;
                    var arr = Array.isArray(selectedValues)
                        ? selectedValues
                        : String(selectedValues).split(',');
                    arr = arr
                        .map(function (v) { return String(v).trim(); })
                        .filter(function (v) { return v !== ''; });
                    if (arr.length) $(selector).val(arr).trigger('change');
                }
            });
        }

        function fetchEditCategoryList(url, data, selector, selectedValues) {
            $.ajax({
                url: url, type: 'GET', data: data,
                success: function (result) {
                    $(selector).html(result);
                    if (!selectedValues) return;
                    var arr = Array.isArray(selectedValues)
                        ? selectedValues
                        : String(selectedValues).split(',');
                    arr = arr
                        .map(function (v) { return String(v).trim(); })
                        .filter(function (v) { return v !== '' && v !== '0'; });
                    if (arr.length) $(selector).val(arr).trigger('change');
                }
            });
        }




        /** Return valid (non-null, non-empty, non-zero) category IDs from a select. */
        function getValidCategoryIds(selector) {
            return ($(selector).val() || []).filter(function (id) {
                return id !== null && id !== undefined && id !== '' && id !== '0';
            });
        }

        // =====================================================================
        // CREATE FORM — #language_id change
        // =====================================================================

        $(document).on('change', '#language_id', function () {
            var languageId = $(this).val();
            // Guard: bail out when language_id is empty (e.g., after form reset via
            // formElement.find("select").val('').trigger("change")).
            // Without this guard, fetchCategoriesList is called with an empty languageId,
            // producing a malformed URL like /get_categories_list/ that returns a full HTML
            // page. jQuery then evaluates the <script> tags it finds, re-declaring all top-
            // level const/let variables in custom.js and throwing a SyntaxError.
            if (!languageId) return;
            var newsType = $('#news_type').val();

            // Always reset category_list + rss feeds when language changes
            $('#category_list').val(null);
            $('#rss_feeds_news_type').html('<option value="">{{ __('select') . ' ' . __('rss_feeds') }}</option>');

            if (newsType !== 'rss_feeds_news') {
                // Regular category tree (create form)
                fetchList('{{ route('get_categories_tree') }}', { language_id: languageId }, '#category_ids');
            }

            // Fetch flat category list for RSS section and reinitialise Select2
            var categoriesUrl = '{{ route('get_categories_list', ['language_id' => ':language_id']) }}'.replace(':language_id', languageId);
            fetchCategoriesList(categoriesUrl, null, '#category_list', function () {
                var $cat = $('#category_list');
                var $rss = $('#rss_feeds_news_type');
                // if ($cat.hasClass('select2-hidden-accessible')) $cat.select2('destroy');
                // if ($rss.hasClass('select2-hidden-accessible')) $rss.select2('destroy');
                // $cat.select2({ placeholder: '{{ __('select') . ' ' . __('category') }}', allowClear: true, width: '100%', maximumSelectionLength: 3 });
                // $rss.select2({ placeholder: '{{ __('select') . ' ' . __('rss_feeds') }}', allowClear: true, width: '100%', maximumSelectionLength: 3 });
            });
        });

        // =====================================================================
        // CREATE FORM — #news_type change  (single consolidated handler)
        // =====================================================================
        // TODO:
        // $(document).on('change', '#videos_type', function () {

        // });
        $(document).on('change', '#news_type', function () {
            var newsType = $(this).val();
            // --- Reset all dependent fields first ---
            // $('#category_ids, #news_ids, #author_news_type, #rss_feeds_news_type, #category_list')
            $('#category_ids, #news_ids, #author_news_type, #rss_feeds_news_type, #category_list')
                .val('').trigger('change');
            $('#videos_type').val('').trigger('change');
             $('#filter_type').val('').trigger('change');
            // --- videos_option visibility ---
            if (newsType === 'videos') {

                $('#videos_type').prop('required', true);
                $('#videos_option').show();
            } else {
                $('#videos_type').prop('required', false);
                $('#videos_option').hide();
            }

            // --- filter options for breaking_news ---
            if (newsType === 'breaking_news') {
                $('#filter_news').hide();
                $('.most_commented, .most_like, .most_favorite').hide();
            } else {
                $('.most_commented, .most_like, .most_favorite').show();
            }

            // --- section visibility: author_news ---
            if (newsType === 'author_news') {
                // category_ids value null when author_news
                // $('#category_ids').val(null).trigger('change');
                $('#author_news_type_section').show();
                $('#filter_type_section').hide();
                $('#filter_news').hide();
                $('#rss_feeds_news_section').hide();
                $('#filter_category_list').hide();
                fetchAuthorList('{{ route('get_author_list') }}', null, '#author_news_type');

                // --- section visibility: rss_feeds_news ---
            } else if (newsType === 'rss_feeds_news') {
                $('#author_news_type_section').hide();
                $('#filter_type_section').hide();
                $('#filter_news').hide();
                $('#rss_feeds_news_section').show();
                $('#filter_category_list').show();
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();

                // Lazy-load RSS categories if empty (news_type picked before
                // language, or list cleared by a previous reset).
                var rssLanguageId = $('#language_id').val();
                var hasRssCategories = $('#category_list option').filter(function () {
                    var v = $(this).val();
                    return v && v !== '' && v !== '0';
                }).length > 0;
                if (rssLanguageId && !hasRssCategories) {
                    var rssCategoriesUrl = '{{ route('get_categories_list', ['language_id' => ':language_id']) }}'.replace(':language_id', rssLanguageId);
                    fetchCategoriesList(rssCategoriesUrl, null, '#category_list');
                }

                // --- section visibility: everything else (news, videos, breaking_news) ---
            } else {
                $('#author_news_type_section').hide();
                $('#filter_type_section').show();
                $('#rss_feeds_news_section').hide();
                $('#filter_category_list').hide();
                if (newsType !== 'breaking_news') {
                    $('#filter_news').show();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            }

        });

        // =====================================================================
        // CREATE FORM — #filter_type change
        // =====================================================================

        $(document).on('change', '#filter_type', function () {
            var filterType = $(this).val();
            var newsType = $('#news_type').val();
            var videosType = $('#videos_type').val();
            var languageId = $('#language_id').val();

            if (filterType === 'custom') {
                $('#custom').show();
                $('#filter_news').hide();
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
                if (!languageId) {
                    $('#news_ids').html('');
                    return;
                }
                // For videos, videos_type must be chosen first, else backend
                // returns an empty list ("no news to select").
                if (newsType === 'videos' && !videosType) {
                    $('#news_ids').html('');
                    return;
                }
                fetchList('{{ route('get_custom_news') }}', { language_id: languageId, news_type: newsType, videos_type: videosType }, '#news_ids');
            } else {
                $('#custom').hide();
                if (newsType === 'news' || newsType === 'videos') {
                    $('#filter_news').show();
                } else {
                    $('#filter_news').hide();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            }
        });

        // =====================================================================
        // CREATE FORM — #videos_type change
        // =====================================================================

        $(document).on('change', '#videos_type', function () {
            let videos = $(this).val();
            let newsType = $('#news_type').val();
            let videosType = $('#videos_type').val();
            let languageId = $('#language_id').val();
            // Only load custom news when visible/selected. Previously this fired
            // on every change (even reset to '') and wiped #news_ids with ''.
            if ($('#filter_type').val() === 'custom' && newsType === 'videos' && videosType && languageId) {
                if (!$('#custom').is(':visible')) {
                    $('#custom').show();
                    $('#filter_news').hide();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
                fetchList('{{ route('get_custom_news') }}', { language_id: languageId, news_type: newsType, videos_type: videosType }, '#news_ids');
            }

            if (videos === 'breaking_news') {
                $('.most_commented, .most_like, .most_favorite').hide();
            } else {
                $('.most_commented, .most_like, .most_favorite').show();
            }
        });

        // =====================================================================
        // CREATE FORM — #category_list change (RSS feeds)
        // =====================================================================

        $(document).on('change', '#category_list', function () {
            if ($('#news_type').val() !== 'rss_feeds_news') return;

            var validIds = getValidCategoryIds('#category_list');
            if (!validIds.length) {
                $('#rss_feeds_news_type').html('<option value="">{{ __("select") . " " . __("rss_feeds") }}</option>')
                    .val(null).trigger('change');
                return;
            }

            var url = '{{ route("rss_feeds_list", ["category_ids" => ":category_ids"]) }}'
                .replace(':category_ids', validIds.join(','));

            fetchRssFeedsList(url, '#rss_feeds_news_type');
        });

        // =====================================================================
        // CREATE FORM — user choice toggle (switchery)
        // =====================================================================

        var is_based_on_user_choice = document.querySelector('#is_based_on_user_choice');
        is_based_on_user_choice.onchange = function () {
            if (this.checked) {
                $('#based_on_user_choice_mode').val(1);
                $('#news_type, #filter_type').prop('required', false);
                $('#filter_section').hide();
            } else {
                $('#based_on_user_choice_mode').val(0);
                $('#news_type, #filter_type').prop('required', true);
                $('#filter_section').show();
            }
        };

        // =====================================================================
        // EDIT FORM — user choice toggle (switchery)
        // =====================================================================

        var edit_is_based_on_user_choice = document.querySelector('#edit_is_based_on_user_choice');
        edit_is_based_on_user_choice.onchange = function () {
            if (this.checked) {
                $('#edit_based_on_user_choice_mode').val(1);
                $('#edit_filter_section').hide();
                $('#edit_news_type, #edit_author_news_type, #edit_videos_type, #edit_filter_type, #edit_category_ids, #edit_news_ids, #edit_category_list, #edit_rss_feeds_news_type')
                    .val('').trigger('change');
                // Explicitly clear RSS feeds via Select2 API
                if ($('#edit_rss_feeds_news_type').hasClass('select2-hidden-accessible')) {
                    $('#edit_rss_feeds_news_type').select2('val', '');
                }
                // console.log('edit_based_on_user_choice_mode set to 1');
            } else {
                $('#edit_based_on_user_choice_mode').val(0);
                $('#edit_filter_section').show();
            }
        };

        // =====================================================================
        // EDIT FORM — #edit_videos_type change
        // =====================================================================

        $(document).on('change', '#edit_videos_type', function () {
            var videosType = $(this).val();
            var newsType = $('#edit_news_type').val();
            var languageId = $('#edit_language_id').val();
            if ($('#edit_filter_type').val() === 'custom' && newsType === 'videos' && videosType && languageId) {
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
                $.ajax({
                    url: '{{ route('get_custom_news') }}',
                    type: 'POST',
                    data: { language_id: languageId, news_type: newsType, videos_type: videosType },
                    beforeSend: function () { $('#edit_news_ids').html('{{ __('please_wait') }}...'); },
                    success: function (result) {
                        $('#edit_news_ids').html(result);
                        $('#edit_news_ids').trigger('change.select2');
                    },
                    error: function (err) { console.error(err); }
                });
            }
            if (videosType === 'breaking_news') {
                $('.most_commented, .most_like, .most_favorite').hide();
            } else {
                $('.most_commented, .most_like, .most_favorite').show();
            }
        });

        // =====================================================================
        // EDIT FORM — #edit_language_id change
        // =====================================================================

        $(document).on('change', '#edit_language_id', function (e, row_language_id, row_category_id, row_subcategory_id,
            row_news_id, row_filter_type, row_news_type, row_user_ids, row_category_list, row_rss_feeds_news_type, row_videos_type) {

            var languageId = $(this).val();
            // Guard: bail out when language_id is empty to prevent malformed route URLs.
            if (!languageId) return;

            // #edit_category_list is loaded by the #edit_news_type handler (rss_feeds_news
            // branch). A parallel fetch here would race the same selector and could wipe
            // the preselected categories.

            // Fetch categories tree then cascade news_type / filter_type
            $.ajax({
                url: '{{ route('get_categories_tree') }}',
                type: 'POST',
                data: { language_id: languageId },
                beforeSend: function () { $('#edit_category_ids').html('{{ __('please_wait') }}...'); },
                success: function (result) {
                    $('#edit_category_ids').html(result);
                    $('#edit_category_ids').trigger('change.select2');
                    $('#edit_filter_type').val(row_filter_type).trigger('change', [row_filter_type, row_news_id]);
                    $('#edit_news_type').val(row_news_type).trigger('change', [row_filter_type, row_news_id, row_category_id, row_subcategory_id, row_user_ids, row_category_list, row_rss_feeds_news_type, row_videos_type]);

                    // Set edit_filter_type AFTER edit_news_type has finished
                    setTimeout(function() {
                        $('#edit_filter_type').val(row_filter_type).trigger('change', [row_filter_type, row_news_id]);
                    }, 50);
                },
                error: function (err) { console.error(err); }
            });
        });

        // =====================================================================
        // EDIT FORM — #edit_news_type change  (single consolidated handler)
        // =====================================================================

        $(document).on('change', '#edit_news_type', function (e, row_filter_type, row_news_id, row_category_id,
            row_subcategory_id, row_user_ids, row_category_list, row_rss_feeds_news_type, row_videos_type) {

            var newsType = $(this).val();
            var languageId = $('#edit_language_id').val();
            $('#edit_category_ids, #edit_news_ids, #edit_author_news_type, #edit_rss_feeds_news_type, #edit_category_list')
                .val('').trigger('change');
            $('#edit_videos_type').val('').trigger('change');
             $('#edit_filter_type').val('').trigger('change');
            // --- videos_option visibility ---
            // Restore saved videos_type AFTER reset (modal cascade wipes it).
            if (newsType === 'videos') {
                $('#edit_videos_type').prop('required', true);
                $('#edit_videos_option').show();
                if (row_videos_type) {
                    $('#edit_videos_type').val(row_videos_type);
                }
            } else {
                $('#edit_videos_type').prop('required', false);
                $('#edit_videos_option').hide();
            }

            // --- section visibility ---
            if (newsType === 'author_news') {
                $('#edit_author_news_type_section').show();
                $('#edit_filter_type_section, #edit_filter_news, #edit_filter_news_section').hide();
                $('#edit_rss_feeds_news_section, #edit_filter_category_list').hide();
                fetchEditAuthorList('{{ route('get_author_list') }}', null, '#edit_author_news_type', row_user_ids);

            } else if (newsType === 'rss_feeds_news') {
                $('#edit_author_news_type_section').hide();
                $('#edit_filter_type_section, #edit_filter_news').hide();
                // #edit_filter_category_list / #edit_rss_feeds_news_section are nested inside
                // #edit_filter_news_section; the parent must be revealed too or the
                // children stay invisible inside a display:none wrapper.
                $('#edit_filter_news_section').show();
                $('#edit_filter_category_list, #edit_rss_feeds_news_section').show();
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();

                if (languageId) {
                    var catUrl = '{{ route('get_categories_list', ['language_id' => ':language_id']) }}'.replace(':language_id', languageId);
                    // Stash the saved RSS selection on #edit_category_list so its change
                    // handler can preselect them after the RSS list arrives. Set even when
                    // row_category_list is empty so a later manual category pick still
                    // restores the saved RSS feeds.
                    $('#edit_category_list').data('pending-rss-feeds', row_rss_feeds_news_type || null);
                    fetchEditCategoryList(catUrl, null, '#edit_category_list', row_category_list || null);
                }

            } else {
                $('#edit_author_news_type_section').hide();
                $('#edit_rss_feeds_news_section, #edit_filter_category_list').hide();
                // Keep the shared wrapper visible for news / videos / breaking_news.
                $('#edit_filter_news_section').show();
                $('#edit_filter_type_section').show();
                if (newsType !== 'breaking_news') {
                    $('#edit_filter_news').show();
                } else {
                    $('#edit_filter_news').hide();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            }

            // --- breaking_news hides engagement filters ---
            if (newsType === 'breaking_news') {
                $('.most_commented, .most_like, .most_favorite').hide();
            } else {
                $('.most_commented, .most_like, .most_favorite').show();
            }

            // --- restore custom news selection ---
            // NOTE: options load async via #edit_filter_type; only toggle here.
            if (row_filter_type === 'custom') {
                $('#edit_filter_news').hide();
                $('#edit_custom').show();
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            } else {
                $('#edit_custom').hide();
                // Restore category / subcategory selection
                if (row_category_id || row_subcategory_id) {
                    var prefixed = [];
                    if (row_category_id) {
                        prefixed = prefixed.concat(row_category_id.split(',').map(function (v) { return 'cat-' + v; }));
                    }
                    if (row_subcategory_id) {
                        prefixed = prefixed.concat(row_subcategory_id.split(',').map(function (v) { return 'subcat-' + v; }));
                    }
                    var tries = 0;
                    var applyEditCats = function () {
                        var available = {};
                        $('#edit_category_ids option').each(function () { available[$(this).val()] = 1; });
                        var valid = prefixed.filter(function (v) { return available[v]; });
                        if (valid.length || ++tries >= 20) {
                            $('#edit_category_ids').val(valid).trigger('change');
                        } else {
                            setTimeout(applyEditCats, 100);
                        }
                    };
                    applyEditCats();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            }
        });

        // =====================================================================
        // EDIT FORM — #edit_category_list change (RSS feeds)
        // =====================================================================

        $(document).on('change', '#edit_category_list', function () {
            if ($('#edit_news_type').val() !== 'rss_feeds_news') return;

            var validIds = getValidCategoryIds('#edit_category_list');
            if (!validIds.length) {
                $('#edit_rss_feeds_news_type').html('<option value="">{{ __("select") . " " . __("rss_feeds") }}</option>')
                    .val(null).trigger('change');
                return;
            }

            var url = '{{ route("rss_feeds_list", ["category_ids" => ":category_ids"]) }}'
                .replace(':category_ids', validIds.join(','));

            // Read and clear any pending RSS pre-selection from modal open
            var pendingRss = $('#edit_category_list').data('pending-rss-feeds');
            $('#edit_category_list').removeData('pending-rss-feeds');

            fetchEditRssFeedsList(url, '#edit_rss_feeds_news_type', pendingRss);
        });

        // =====================================================================
        // EDIT FORM — #edit_filter_type change
        // =====================================================================

        $(document).on('change', '#edit_filter_type', function (e, row_filter_type, row_news_id) {
            var filterType = $(this).val();
            var newsType = $('#edit_news_type').val();
            var videosType = $('#edit_videos_type').val();
            var languageId = $('#edit_language_id').val();

            if (filterType === 'custom') {
                $('#edit_custom').show();
                $('#edit_filter_news').hide();
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
                if (!languageId) {
                    $('#edit_news_ids').html('');
                    return;
                }
                if (newsType === 'videos' && !videosType) {
                    $('#edit_news_ids').html('');
                    return;
                }
                $.ajax({
                    url: '{{ route('get_custom_news') }}',
                    type: 'POST',
                    data: { language_id: languageId, news_type: newsType, videos_type: videosType },
                    beforeSend: function () { $('#edit_news_ids').html('{{ __('please_wait') }}...'); },
                    success: function (result) {
                        $('#edit_news_ids').html(result);
                        $('#edit_news_ids').trigger('change.select2');
                        if (filterType === row_filter_type && row_news_id) {
                            var wanted = String(row_news_id).split(',').map(function (v) { return String(v).trim(); }).filter(Boolean);
                            var available = {};
                            $('#edit_news_ids option').each(function () { available[$(this).val()] = 1; });
                            var valid = wanted.filter(function (v) { return available[v]; });
                            if (valid.length) $('#edit_news_ids').val(valid).trigger('change');
                        }
                    },
                    error: function (err) { console.error(err); }
                });
            } else {
                $('#edit_custom').hide();
                if (newsType === 'news' || newsType === 'videos') {
                    $('#edit_filter_news').show();
                } else {
                    $('#edit_filter_news').hide();
                }
                if (typeof window.refreshVisibleSelect2 === 'function') window.refreshVisibleSelect2();
            }
        });

        // =====================================================================
        // Shared — reset filter_type when language / news_type / videos_type change
        // =====================================================================

        $('.language_id, .news_type, .videos_type').on('change', function () {
            $('.filter_type').prop('selected', false).find('option:first').prop('selected', true);
        });

    </script>
    <script type="text/javascript">


        // generate with ai script starts here
        initMetaFieldGeneration({
            isEditForm: false,
            buttonSelector: '#generate_meta_fields',
            routeUrl: '{{ route('generate-all-meta-fields') }}',
            csrfToken: '{{ csrf_token() }}',
            titleSelector: '#title',
            languageSelector: '#language_id',
            includeDescription: false,
            includeSummarizedDescription: false,
            fieldMappings: {
                metaTags: '#meta_tags',
                metaTitle: '#meta_title',
                metaDescription: '#meta_description',
            },
            validationMessages: {
                selectLanguage: '{{ __('please_select_language_first') }}',
                enterTitle: '{{ __('please_enter_title_first') }}'
            }
        });
    </script>


@endsection
