@extends('layouts.main')

@section('title')
    {{ __('news') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('news') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-newspaper mr-1"></i>{{ __('news') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('news-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                            class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('news') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('news') }}</h3>
                        </div>
                        <div class="card-body">
                            <form id="create_form" action="{{ url('news') }}" role="form" method="POST"
                                enctype="multipart/form-data">
                                @csrf
                                {{-- ===== Group: Basic Information ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-info-circle mr-1"></i>{{ __('basic_information') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('language') }}</label>
                                                <select id="language_id" name="language" class="form-control" required>
                                                    @if (count($languageList) > 1)
                                                        <option value="">{{ __('select') . ' ' . __('language') }}
                                                        </option>
                                                    @endif
                                                    @foreach ($languageList as $row)
                                                        <option value="{{ $row->id }}" data-name="{{ $row->language }}">{{ $row->language }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                            </div>
                                            @if (is_category_enabled() == 1)
                                                <div class="form-group">
                                                    <label class="required">{{ __('category') }}</label>
                                                    <select id="category_id" name="category_id" class="form-control" required>
                                                        <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                                        @foreach ($categoryList as $row)
                                                            <option value="{{ $row->id }}">{{ $row->category_name }}
                                                            </option>
                                                        @endforeach
                                                    </select>
                                                </div>
                                                @if (is_subcategory_enabled() == 1)
                                                    <div class="form-group">
                                                        <label>{{ __('subcategory') }}</label>
                                                        <select id="subcategory_id" name="subcategory_id" class="form-control">
                                                            <option value="">{{ __('select') . ' ' . __('subcategory') }}
                                                            </option>
                                                        </select>
                                                    </div>
                                                @endif
                                            @endif
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('title') }}</label>
                                                <input id="title" name="title" required type="text"
                                                    placeholder="{{ __('title') }}" class="form-control"
                                                    data-slug-table="tbl_news"
                                                    data-slug-target="#slug">
                                            </div>
                                            <div class="form-group">
                                                <label class="required">{{ __('slug') }}</label><span class="">({{__('english_only')}})</span>
                                                <input id="slug" name="slug" required type="text"
                                                    placeholder="{{ __('slug') }}" class="form-control">
                                                <small class="form-text text-muted"><i class="fas fa-info-circle mr-1"></i>{{ __('avoid_special_characters') }}</small>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {{-- ===== Group: Publishing Settings ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-calendar-alt mr-1"></i>{{ __('publishing_settings') }}</h6>
                                    <div class="row">
                                    <div class="col-md-6 col-sm-12">
                                        <div class="form-group">
                                            <label class="required">{{ __('content_type') }}</label>
                                            <select id="content_type" name="content_type" class="form-control" required>
                                                <option value="standard_post">{{ __('standard_post') }}</option>
                                                <option value="video_youtube">{{ __('video_youtube') }}</option>
                                                <option value="video_other">{{ __('video_other_url') }}</option>
                                                <option value="video_upload">{{ __('video_upload') }}</option>
                                            </select>
                                        </div>
                                        <div class="form-group video_youtube">
                                            <label class="required">{{ __('youtube_url') }}</label>
                                            <input type="url" name="youtube_url" class="form-control youtube_url" required>
                                            <span class="error invalid-feedback youtube_url_error"></span>
                                        </div>
                                        <div class="form-group video_other">
                                            <label class="required">{{ __('other_url') }}</label>
                                            <input type="url" name="other_url" class="form-control other_url" required>
                                            <span class="error invalid-feedback other_url_error"></span>
                                        </div>
                                        <div class="form-group video_upload">
                                            <label class="required">{{ __('video_uploads') }}</label>
                                            <input name="video_file" type="file" class="filepond-video" accept="video/*" required >
                                        </div>
                                         <div class="form-group">
                                            <label for="TagifyCustomListSuggestion">{{ __('tag') }}</label>
                                            <input id="TagifyCustomListSuggestion" name="tag_id" class="form-control h-auto" placeholder="{{ __('select_or_type_tag') }}" value="">
                                        </div>
                                    </div>
                                    <div class="col-md-6 col-sm-12">
                                        @if (is_location_news_enabled() == 1)
                                            <div class="form-group">
                                                <label>{{ __('location') }}</label>
                                                <select name="location_id" class="form-control" required>
                                                    <option value="">{{ __('select') . ' ' . __('location') }}
                                                    </option>
                                                    @foreach ($locationList as $row)
                                                        <option value="{{ $row->id }}">{{ $row->location_name }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                            </div>
                                        @endif
                                        <div class="form-group">
                                            <label>{{ __('published_date') }}</label>
                                            <input id="published_date" name="published_date" value=""
                                                min="{{ date('Y-m-d') }}" type="date" class="form-control">
                                        </div>
                                        <div class="form-group">
                                            <?php
                                            $datetime = new DateTime('tomorrow');
                                            $tomorrow = $datetime->format('Y-m-d');
                                            ?>
                                            <label>{{ __('show_till_expiry_date') }}</label>
                                            <input id="show_till" name="show_till" type="date"
                                                min="{{ $tomorrow }}" class="form-control">
                                        </div>
                                        <div class="form-group mb-2">
                                            <div class="d-flex gap-4 align-items-center flex-wrap">
                                                <div class="form-check form-switch d-flex align-items-center p-0">
                                                    <label class="mr-2">{{ __('notify_users') }}</label>
                                                    <input type="hidden" name="notification" value="0">
                                                    <input class="form-check-input me-2 status-switch" type="checkbox" id="is_notification" name="is_notification">
                                                </div>
                                                @if (getSettingMode('comments_mode') == 1)
                                                    <div class="form-check form-switch d-flex align-items-center">
                                                        <label class="mr-2">{{ __('comments') }}</label>
                                                        <input type="hidden" name="is_comment" value="1">
                                                        <input class="form-check-input me-2 status-switch" type="checkbox" id="comments_switch" name="comments_switch" checked>
                                                    </div>
                                                @endif
                                                <div class="form-check form-switch d-flex align-items-center">
                                                    <label class="mr-2">{{ __('want_to_save_as_draft') }}?</label>
                                                    <input type="hidden" name="is_draft" value="0">
                                                    <input class="form-check-input status-switch" type="checkbox" id="draft_switch" name="draft_switch">
                                                </div>
                                                <div class="form-check form-switch d-flex align-items-center">
                                                    <label class="mr-2">{{ __('is_short_news') }}?</label>
                                                    <input type="hidden" name="is_short_news" value="0">
                                                    <input class="form-check-input status-switch" type="checkbox" id="is_short_news_switch" name="is_short_news_switch">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    </div>
                                </div>

                                {{-- ===== Group: Content ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-align-left mr-1"></i>{{ __('description') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('description') }}</label>
                                                <textarea id="des" name="des" class="form-control"></textarea>
                                                <small id="des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('summarized_description') }}</label>
                                                <textarea name="summarized_description" id="summarized_description" cols="30" rows="13" class="form-control"
                                                    oninput="getWordCount('summarized_description','summarized_description_count','12.9px arial',0,300,'summarized_description')"></textarea>
                                                <small id="summarized_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {{-- ===== Group: SEO & Metadata ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-search mr-1"></i>{{ __('seo_metadata') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <x-schema-markup-field />
                                            </div>
                                        </div>
                                         <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('meta_keywords') }}</label>
                                                <input id="meta_tags" style="border-radius: 0.25rem" class="w-100"
                                                    type="text" name="meta_keyword"
                                                    placeholder="{{ __('press_enter_add_keywords') }}">
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('meta_title') }}</label>
                                                <input type="text" name="meta_title" class="form-control" id="meta_title"
                                                    oninput="getWordCount('meta_title','meta_title_count','19.9px arial')"
                                                    placeholder="{{ __('meta_title') }}">
                                                <h6 id="meta_title_count">0</h6>
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('meta_description') }}</label>
                                                <textarea id="meta_description" name="meta_description" class="form-control"
                                                    oninput="getWordCount('meta_description','meta_description_count','12.9px arial')"></textarea>
                                                <h6 id="meta_description_count">0</h6>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {{-- ===== Group: Media Assets ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-images mr-1"></i>{{ __('media_assets') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('image') }}</label>
                                                <input name="file" type="file" accept="image/*" class="filepond" required>
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('gallery_image') }}</label>
                                                <input name="ofile[]" type="file" accept="image/*" multiple
                                                    class="filepond logo">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="d-flex justify-content-end">
                                    <button type="button" class="btn btn-outline-primary" id="generate_meta_fields">
                                        <i class="fas fa-magic"></i> {{ __('generate') }}
                                    </button>
                                    <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                @can('news-list')
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('news') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <div id="toolbar" class="toolbar-with-filter">
                                @can('news-bulk-delete')
                                <button class="btn bg-primary text-white" type="submit"
                                    id="bulk_delete">{{ __('bulk_delete') }}</button>
                                @endcan
                                <div class="toolbar-filter">
                                    <select id="filter_language_id" class="form-control">
                                        <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $row)
                                            <option value="{{ $row->id }}">{{ $row->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                @if (is_category_enabled() == 1)
                                    <div class="toolbar-filter">
                                        <select id="filter_category_id" class="form-control">
                                            <option value="0">{{ __('select') . ' ' . __('category') }}</option>
                                        </select>
                                    </div>
                                    @if (is_subcategory_enabled() == 1)
                                        <div class="toolbar-filter">
                                            <select id="filter_subcategory_id" class="form-control">
                                                <option value="0">{{ __('select') . ' ' . __('subcategory') }}
                                                </option>
                                            </select>
                                        </div>
                                    @endif
                                @endif
                                @if (is_location_news_enabled() == 1)
                                    <div class="toolbar-filter">
                                        <select id="filter_location_id" name="location" class="form-control" required>
                                            <option value="0">{{ __('select') . ' ' . __('location') }}</option>
                                            @foreach ($locationList as $row)
                                                <option value="{{ $row->id }}">{{ $row->location_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                @endif
                                <div class="toolbar-filter">
                                    <select id="filter_status" name="status" class="form-control">
                                        <option value="">{{ __('status') }}</option>
                                        <option value="1">{{ __('active') }}</option>
                                        <option value="0">{{ __('deactive') }}</option>
                                    </select>
                                </div>
                                <div class="toolbar-filter">
                                    <select id="filter_user_id" class="form-control">
                                        <option value="0">{{ __('select') . ' ' . __('author') }}</option>
                                        @foreach ($userList as $row)
                                            <option value="{{ $row->id }}">{{ $row->name }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('newsList') }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-unique-id="id"
                                data-show-columns="true" data-show-refresh="true" data-toolbar="#toolbar"
                                data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false"
                                data-sort-name="id" data-sort-order="desc" data-query-params="newsQueryParams">
                                <thead>
                                    <tr>
                                        <th class="text-center multi-check" data-checkbox="true">
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="language_id" data-sortable="true"
                                            data-visible="false">{{ __('language_id') }}</th>
                                        <th scope="col" data-field="language_name">{{ __('language') }} </th>
                                        @if (is_category_enabled() == 1)
                                            <th scope="col" data-field="category_id" data-sortable="true"
                                                data-visible="false">{{ __('category_id') }}</th>
                                            <th scope="col" data-field="category_name">{{ __('category') }}</th>
                                        @endif
                                        @if (is_subcategory_enabled() == 1)
                                            <th scope="col" data-field="subcategory_id" data-visible="false">
                                                {{ __('subcategory_id') }}</th>
                                            <th scope="col" data-field="subcategory_name" data-visible="false">
                                                {{ __('subcategory') }}</th>
                                        @endif
                                        <th scope="col" data-field="image">{{ __('image') }}</th>
                                        <th scope="col" data-field="title" data-sortable="true" data-formatter="textFormatter">{{ __('title') }}
                                        </th>
                                        <th scope="col" data-field="slug" data-visible="false">{{ __('slug') }}
                                        </th>
                                        <th scope="col" data-field="content_type">{{ __('content_type') }}</th>
                                        <th scope="col" data-field="status_badge">{{ __('status') }}</th>
                                        <th scope="col" data-field="is_draft" data-formatter="isDraftNewsFormatter">{{ __('is_draft') }}</th>
                                        <th scope="col" data-field="is_short_news" data-formatter="isShortNewsFormatter">{{ __('is_short_news') }}</th>
                                        <th scope="col" data-field="published_date" data-formatter="dateFormate" data-visible="false">
                                            {{ __('published_date') }}</th>
                                        <th scope="col" data-field="show_till" data-formatter="dateFormate"
                                            data-visible="false">{{ __('show_till') }}</th>
                                        <th scope="col" data-field="tag_id" data-visible="false">{{ __('tag_id') }}
                                        </th>
                                        <th scope="col" data-field="tag_name" data-visible="false">
                                            {{ __('tags') }}</th>
                                        <th scope="col" data-field="created_at" data-visible="false">
                                            {{ __('created_at') }}</th>
                                        {{-- <th scope="col" data-field="short_description" data-visible="true" data-formatter="smallTextFormatter"> --}}
                                        <th scope="col" data-field="short_description" data-formatter="descriptionFormatter" data-visible="false">
                                            {{ __('description') }}</th>
                                        <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                            {{ __('meta_title') }}</th>
                                        <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                            {{ __('meta_keywords') }}</th>
                                        <th scope="col" data-field="meta_description" data-formatter="descriptionFormatter" data-visible="false">
                                            {{ __('meta_description') }}</th>
                                        <th scope="col" data-field="is_clone1" data-visible="false">
                                            {{ __('is_clone') }}</th>
                                        @if (is_location_news_enabled() == 1)
                                            <th scope="col" data-field="location" data-visible="false">
                                                {{ __('location') }}</th>
                                            <th scope="col" data-field="location_id" data-sortable="true"
                                                data-visible="false">{{ __('location_id') }}</th>
                                        @endif
                                        <th scope="col" data-field="is_expire">{{ __('is_expired') }}</th>
                                        <th scope="col" data-field="total_image">{{ __('gallery_image') }}</th>
                                        <th scope="col" data-field="views">{{ __('views') }}</th>
                                        <th scope="col" data-field="likes">{{ __('likes') }}</th>
                                        @canany(['news-edit', 'news-delete','news-edit-description','news-clone'])
                                        <th scope="col" data-field="operate" data-events="newsEvents">
                                            {{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
                @endcan
            </div>
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('news') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('news') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <input type='hidden' name="image_url" id="image_url" value='' />
                        <input type='hidden' name="video_url" id="video_url" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-4 col-sm-12">
                                    <div class="form-group">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="edit_language_id" name="language" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    @if (is_category_enabled() == 1)
                                        <div class="form-group">
                                            <label class="required">{{ __('category') }}</label>
                                            <select id="edit_category_id" name="category_id" class="form-control"
                                                required>
                                                <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                            </select>
                                        </div>
                                        @if (is_subcategory_enabled() == 1)
                                            <div class="form-group">
                                                <label>{{ __('subcategory') }}</label>
                                                <select id="edit_subcategory_id" name="subcategory_id"
                                                    class="form-control">
                                                    <option value="">{{ __('select') . ' ' . __('subcategory') }}
                                                    </option>
                                                </select>
                                            </div>
                                        @endif
                                    @endif
                                    <div class="form-group">
                                        <label>{{ __('published_date') }}</label>
                                        <input id="edit_published_date" name="published_date" type="date"
                                            class="form-control">
                                    </div>
                                    <div class="form-group">
                                        <x-schema-markup-field id="edit_schema_markup" />
                                    </div>
                                    <div class="form-group mb-3">
                                        <div class="d-flex gap-4 align-items-center flex-wrap">
                                            <div class="form-check form-switch d-flex align-items-center p-0">
                                                <label class="mr-2">{{ __('notify_users') }}</label>
                                                <input type="checkbox" id="edit_is_notification" name="edit_is_notification"
                                                    class="edit-status-switch">
                                                <input type="hidden" id="edit_notification" name="notification" value="0">
                                            </div>
                                            @if (getSettingMode('comments_mode') == 1)
                                                <div class="form-check form-switch d-flex align-items-center">
                                                    <label class="mr-2">{{ __('comments') }}</label>
                                                    <input type="checkbox" id="edit_comments_switch" name="edit_comments_switch"
                                                        class="edit-status-switch">
                                                    <input type="hidden" id="edit_is_comment" name="is_comment" value="0">
                                                </div>
                                            @endif
                                            <div class="form-check form-switch d-flex align-items-center">
                                                <label class="mr-2">{{ __('want_to_save_as_draft') }}?</label>
                                                <input type="hidden" id="edit_is_draft" name="edit_is_draft" value="0">
                                                <input class="form-check-input status-switch" type="checkbox" id="edit_draft_switch" name="edit_draft_switch">
                                            </div>
                                            <div class="form-check form-switch d-flex align-items-center">
                                                <label class="mr-2">{{ __('is_short_news') }}</label>
                                                <input type="hidden" id="edit_is_short_news" name="edit_is_short_news" value="0">
                                                <input class="form-check-input status-switch" type="checkbox" id="edit_is_short_news_switch" name="edit_is_short_news_switch">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('status') }}</label><br>
                                        <div id="status1" class="btn-group">
                                            <label class="btn btn-success" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input type="radio" name="status" value="1"
                                                    checked>{{ __('active') }}
                                            </label>
                                            <label class="btn btn-danger" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input type="radio" name="status"
                                                    value="0">{{ __('deactive') }}
                                            </label>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-4 col-sm-12">
                                    <div class="form-group">
                                        <label class="required">{{ __('title') }}</label>
                                        <input type="text" name="title" id="edit_title" class="form-control"
                                            placeholder="news title" required
                                            data-slug-table="tbl_news"
                                            data-slug-target="#edit_slug"
                                            data-slug-id="#edit_id">
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('slug') }}</label><span class="">({{__('english_only')}})</span>
                                        <input type="text" name="slug" id="edit_slug" class="form-control"
                                            placeholder="{{ __('slug') }}" required>
                                        <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                    </div>
                                    <div class="form-group">
                                        <?php
                                        $datetime = new DateTime('tomorrow');
                                        $tomorrow = $datetime->format('Y-m-d');
                                        ?>
                                        <label>{{ __('show_till_expiry_date') }}</label>
                                        <div class="custom-file">
                                            <input id="edit_show_till" type="date" name="show_till"
                                                class="form-control" placeholder="" min="{{ $tomorrow }}">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('content_type') }}</label>
                                        <select name="content_type" id="edit_content_type" class="form-control" required>
                                            <option value="standard_post" selected>{{ __('standard_post') }}</option>
                                            <option value="video_youtube">{{ __('video_youtube') }}</option>
                                            <option value="video_other">{{ __('video_other_url') }}</option>
                                            <option value="video_upload">{{ __('video_upload') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group evideo_youtube">
                                        <label>{{ __('youtube_url') }}</label>
                                        <input type="url" name="youtube_url" id="youtube_url"
                                            class="form-control youtube_url">
                                        <span class="error invalid-feedback youtube_url_error"></span>
                                    </div>
                                    <div class="form-group evideo_other">
                                        <label>{{ __('other_url') }}</label>
                                        <input type="url" name="other_url" id="other_url"
                                            class="form-control other_url">
                                        <span class="error invalid-feedback other_url_error"></span>
                                    </div>
                                    <div class="form-group evideo_upload">
                                        <label>{{ __('video_uploads') }}</label>
                                        <input name="video_file" type="file" class="filepond-video"
                                            id="exampleVideoInputFile1_edit">
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('image') }} </label>
                                        <input name="file" type="file" accept="image/*" class="filepond">
                                         <div id="edit_image_preview_container" class="mt-2" style="">
                                        <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                        <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                    </div>
                                    </div>
                                </div>

                                <div class="col-md-4 col-sm-12">
                                    @if (is_location_news_enabled() == 1)
                                        <div class="form-group">
                                            <label class="required">{{ __('location') }}</label>
                                            <select name="location_id" id="edit_location_id" class="form-control"
                                                required>
                                                <option value="">{{ __('select') . ' ' . __('location') }}</option>
                                                @foreach ($locationList as $row)
                                                    <option value="{{ $row->id }}">{{ $row->location_name }}
                                                    </option>
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif
                                    <div class="form-group">
                                        {{-- <label>{{ __('tag') }}</label> --}}
                                        {{-- <select id="edit_tag_id" name="tag_id[]"
                                            class="form-control select2 select2-multiple" multiple="multiple">
                                        </select> --}}
                                        <label for="edit_news_tagify">{{ __('tag') }}</label>

                                        <input id="edit_news_tagify" name="tag_id" class="form-control h-auto" placeholder="{{ __('select_or_type_tag') }}" value="">

                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_keywords') }}</label>
                                        <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100"
                                            type="text" name="meta_keyword"
                                            placeholder="{{ __('press_enter_add_keywords') }}">
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_title') }}</label>
                                        <input type="text" name="meta_title" class="form-control"
                                            id="edit_meta_title"
                                            oninput="getWordCount('edit_meta_title','edit_meta_title_count','19.9px arial')"
                                            placeholder="{{ __('meta_title') }}">
                                        <h6 id="edit_meta_title_count">0</h6>
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_description') }}</label>
                                        <textarea id="edit_meta_description" name="meta_description" class="form-control"
                                            oninput="getWordCount('edit_meta_description','edit_meta_description_count','12.9px arial')"></textarea>
                                        <h6 id="edit_meta_description_count">0</h6>
                                    </div>

                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-default"
                                data-dismiss="modal">{{ __('close') }}</button>
                            <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <div class="modal fade" id="editDataDesModal">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('description') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form action="{{ route('news_update_description') }}" method="POST" role="form"
                        enctype="multipart/form-data">
                        @csrf
                        @method('PUT')
                        <div class="modal-body">
                            <input type='hidden' name="edit_id" value='' />
                            <div class="form-group row">
                                <div class="col-sm-12">
                                    <label>{{ __('description') }}</label>
                                    <textarea id="edit_des" name="des" class="form-control"></textarea>
                                    <small id="edit_des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                </div>
                            </div>
                            <div class="form-group row">
                                <div class="col-sm-12">
                                    <label>{{ __('summarized_description') }}</label>
                                    {{-- <input type="text" id="edit_summarized_description" name="summarized_description" placeholder="{{ __('enter_summarized_description') }}" class="form-control"> --}}
                                    <textarea name="summarized_description" id="edit_summarized_description" cols="30" rows="2" class="form-control"
                                        oninput="getWordCount('edit_summarized_description','edit_summarized_description_count','12.9px arial',0,300,'summarized_description')"></textarea>
                                    <small id="edit_summarized_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-default"
                                data-dismiss="modal">{{ __('close') }}</button>
                            <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('script')
    <script type="text/javascript">
        $(document).on('change', '#language_id', function(e) {
            var data = {
                language_id: $('#language_id').val(),
            };
            var url = "{{ route('get_category_by_language') }}";
            fetchList(url, data, '#category_id');
            
            // Clear all selected tags when language changes
            if (typeof window.TagifyCustomListSuggestion !== 'undefined' && window.TagifyCustomListSuggestion) {
                // Try multiple methods to ensure tags are cleared
                try {
                    // Method 1: Try removeAllTags if available
                    if (typeof window.TagifyCustomListSuggestion.removeAllTags === 'function') {
                        window.TagifyCustomListSuggestion.removeAllTags();
                    } else {
                        // Method 2: Set value to empty and update
                        window.TagifyCustomListSuggestion.value = [];
                    }
                } catch (e) {
                    // Method 3: Fallback - set value directly and remove DOM elements
                    try {
                        window.TagifyCustomListSuggestion.value = [];
                        if (window.TagifyCustomListSuggestion.removeTagsFromDOM) {
                            window.TagifyCustomListSuggestion.removeTagsFromDOM();
                        }
                        // window.TagifyCustomListSuggestion.update();
                    } catch (err) {
                        console.log('Error clearing tags:', err);
                    }
                }
            }
            // $('#tag_id').val(null).trigger('change');
            // var url1 = '{{ route('get_tag_by_language') }}';
            // fetchList(url1, data, '#tag_id');
var url1 = "{{ route('get_tag_by_language') }}";
            $.ajax({
                url: url1,
                type: 'POST',
                data: data,
                success: function(result) {
                    // Parse the HTML options and extract tag data
                    var $temp = $('<div>').html(result);
                    var tags = [];
                    $temp.find('option').each(function() {
                        var $option = $(this);
                        tags.push({
                            value: $option.data('text'),
                            id: $option.val(),
                            // text: $option.data('text')
                        });
                    });

                    // Update Tagify whitelist
                    if (typeof TagifyCustomListSuggestion !== 'undefined' && TagifyCustomListSuggestion) {
                        TagifyCustomListSuggestion.settings.whitelist = tags;
                        // TagifyCustomListSuggestion.dropdown.show.call(TagifyCustomListSuggestion);
                    }
                },
                error: function(errors) {
                    console.log('Error fetching tags:', errors);
                    // Clear whitelist on error
                    if (typeof window.TagifyCustomListSuggestion !== 'undefined' && window.TagifyCustomListSuggestion) {
                        window.TagifyCustomListSuggestion.settings.whitelist = [];
                    }
                }
            });
        });

        // edit tag

        $(document).on('change', '#category_id', function(e) {
            var data = {
                category_id: $('#category_id').val(),
            };
            var url = "{{ route('get_subcategory_by_category') }}";
            fetchList(url, data, '#subcategory_id');
        });

        $(document).on('change', '#edit_language_id', function(e, row_language_id, row_category_id, row_subcategory_id,
            row_tag_id) {
                // console.log("direct trigger");

            var language_id = $('#edit_language_id').val();
            $.ajax({
                url: "{{ route('get_category_by_language') }}",
                type: "POST",
                data: {
                    language_id: language_id,
                },
                beforeSend: function() {
                    $('#edit_category_id').html("Please wait..");
                },
                success: function(result) {
                    $('#edit_category_id').html(result);
                    if (language_id == row_language_id && row_category_id != 0) {
                        $('#edit_category_id').val(row_category_id).trigger('change', [row_category_id,
                            row_subcategory_id
                        ]);
                    }
                },
                error: function(errors) {
                    console.log(errors);
                },
            });

            // let url1 = '{{ route('get_tag_by_language') }}';
            // let data1 = {
            //     language_id: $('#language_id').val(),
            // };
            // fetchList(url1, data1, '#edit_news_tagify');

            // Clear all selected tags when language changes
            if (typeof window.editTagCustomListSuggestion !== 'undefined' && window.editTagCustomListSuggestion) {
                // Try multiple methods to ensure tags are cleared
                try {
                    // Method 1: Try removeAllTags if available
                    if (typeof window.editTagCustomListSuggestion.removeAllTags === 'function') {
                        window.editTagCustomListSuggestion.removeAllTags();
                    } else {
                        // Method 2: Set value to empty and update
                        window.editTagCustomListSuggestion.value = [];
                    }
                } catch (e) {
                    // Method 3: Fallback - set value directly and remove DOM elements
                    try {
                        window.editTagCustomListSuggestion.value = [];
                        if (window.editTagCustomListSuggestion.removeTagsFromDOM) {
                            window.editTagCustomListSuggestion.removeTagsFromDOM();
                        }
                        // window.editTagCustomListSuggestion.update();
                    } catch (err) {
                        console.log('Error clearing tags:', err);
                    }
                }
            }

            $.ajax({
                url: "{{ route('get_tag_by_language') }}",
                type: "POST",
                data: {
                    language_id: language_id,
                },
                beforeSend: function() {
                    $('#edit_news_tagify').html("Please wait..");
                },
                success: function(result) {
                    // $('#edit_news_tagify').html(result).trigger("change");
                    // if (language_id == row_language_id && row_tag_id != '') {
                    //     var valueArray = row_tag_id;
                    //     var arrayArea = valueArray.split(',');
                    //     $("#edit_news_tagify").val(arrayArea).trigger("change");
                    // }
                           // Parse the HTML options and extract tag data
                    let $temp = $('<div>').html(result);
                    let tags = [];
                    let selectedTags = [];

                    // Convert row_tag_id to an array for exact matching
                    let rowTagIds = [];
                    if (row_tag_id && row_tag_id != '') {
                        if (Array.isArray(row_tag_id)) {
                            rowTagIds = row_tag_id.map(id => String(id));
                        } else {
                            // Split by comma if it's a comma-separated string
                            rowTagIds = String(row_tag_id).split(',').map(id => id.trim());
                        }
                    }

                    $temp.find('option').each(function() {
                        let $option = $(this);
                        let tagObj = {
                            value: $option.data('text'),
                            id: $option.val(),
                            // text: $option.data('text')
                        };
                        tags.push(tagObj);

                        // need to add the attribute value tag where row_tag_id matches
                        // Use exact matching instead of substring matching
                        if (rowTagIds.length > 0 && rowTagIds.includes(String($option.val()))) {
                            selectedTags.push(tagObj);
                        }
                    });

                    // Update Tagify whitelist
                    if (typeof editTagCustomListSuggestion !== 'undefined' && editTagCustomListSuggestion) {
                        // Clear all existing tags first to prevent old tags from persisting
                        editTagCustomListSuggestion.removeAllTags();

                        editTagCustomListSuggestion.settings.whitelist = tags;

                        // Add selected tags if any match
                        if (selectedTags.length > 0) {
                            editTagCustomListSuggestion.addTags(selectedTags);
                        }
                    }
                },
                error: function(errors) {
                    console.log(errors);
                },
            });
        });

        $(document).on('change', '#edit_category_id', function(e, row_category_id, row_subcategory_id) {
            var category_id = $('#edit_category_id').val();
            $.ajax({
                url: "{{ route('get_subcategory_by_category') }}",
                type: "POST",
                data: {
                    category_id: category_id,
                },
                beforeSend: function() {
                    $('#edit_subcategory_id').html("Please wait..");
                },
                success: function(result) {
                    $('#edit_subcategory_id').html(result);
                    if (category_id == row_category_id && row_subcategory_id != 0) {
                        $('#edit_subcategory_id').val(row_subcategory_id);
                    }
                },
                error: function(errors) {
                    console.log(errors);
                },
            });
        });

        $('input[name=status]').on('change', function(e) {
            var status = $('input[name=status]:checked').val();
            var published_date = $('#edit_published_date').val();
            switcheryInstances1.forEach(function(switchery) {
                if (switchery.element.id === 'edit_is_notification') {
                    if (status == 0 || published_date > today) {
                        switchery.disable();
                    } else {
                        switchery.enable();
                    }
                }
            });
        });
    </script>

    <script type="text/javascript">
        $('.youtube_url').on('change', function(e) {
            var url = $(this).val();
            if (url != undefined || url != '') {
                var regExp =
                    /^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$/;
                var match = url.match(regExp);
                if (match && match[1].length == 11) {
                    $(this).closest(".video_youtube").find(".youtube_url_error").hide();
                    $(this).closest(".video_youtube").find(".youtube_url_error").text("");
                    $(this).closest(".evideo_youtube").find(".youtube_url_error").hide();
                    $(this).closest(".evideo_youtube").find(".youtube_url_error").text("");
                } else {
                    $(this).closest(".video_youtube").find(".youtube_url_error").show();
                    $(this).closest(".video_youtube").find(".youtube_url_error").text("Please enter youtube url.");
                    $(this).val("");
                    $(this).closest(".evideo_youtube").find(".youtube_url_error").show();
                    $(this).closest(".evideo_youtube").find(".youtube_url_error").text("Please enter youtube url.");
                }
            }
        });
        $('.other_url').on('change', function(e) {
            var url = $(this).val();
            if (url != undefined || url != '') {
                var regExp =
                    /^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$/;
                var match = url.match(regExp);
                if (match && match[1].length == 11) {
                    $(this).closest(".video_other").find(".other_url_error").show();
                    $(this).closest(".video_other").find(".other_url_error").text(
                        "Youtube url is not valid for other url.");
                    $(this).val("");
                    $(this).closest(".evideo_other").find(".other_url_error").show();
                    $(this).closest(".evideo_other").find(".other_url_error").text(
                        "Youtube url is not valid for other url.");
                } else {
                    $(this).closest(".video_other").find(".other_url_error").hide();
                    $(this).closest(".video_other").find(".other_url_error").text("");
                    $(this).closest(".evideo_other").find(".other_url_error").hide();
                    $(this).closest(".evideo_other").find(".other_url_error").text("");
                }
            }
        });
        var notification = document.querySelector('#is_notification');
        notification.onchange = function() {
            if (notification.checked) {
                $('input[name="notification"]').first().val(1);
            } else {
                $('input[name="notification"]').first().val(0);
            }
        };

        var comments_switch = document.querySelector('#comments_switch');
        if(comments_switch) {
            comments_switch.onchange = function() {
                if (comments_switch.checked) {
                    $('input[name="is_comment"]').first().val(1);
                } else {
                    $('input[name="is_comment"]').first().val(0);
                }
            };
        }
        var draft_switch = document.querySelector('#draft_switch');
        if(draft_switch) {
            draft_switch.onchange = function() {
                if (draft_switch.checked) {
                    $('input[name="is_draft"]').first().val(1);
                } else {
                    $('input[name="is_draft"]').first().val(0);
                }
            };
        }
        var is_short_news_switch = document.querySelector('#is_short_news_switch');
        if(is_short_news_switch) {
            is_short_news_switch.onchange = function() {
                if (is_short_news_switch.checked) {
                    $('input[name="is_short_news"]').first().val(1);
                } else {
                    $('input[name="is_short_news"]').first().val(0);
                }
            };
        }

        var edit_is_short_news_switch = document.querySelector('#edit_is_short_news_switch');
        if(edit_is_short_news_switch) {
            edit_is_short_news_switch.onchange = function() {
                if (edit_is_short_news_switch.checked) {
                    $('#edit_is_short_news').val(1);
                } else {
                    $('#edit_is_short_news').val(0);
                }
            };
        }

        var edit_is_notification = document.querySelector('#edit_is_notification');
        edit_is_notification.onchange = function() {
            if (edit_is_notification.checked) {
                $('#edit_notification').val(1);
            } else {
                $('#edit_notification').val(0);
            }
        };

        var edit_comments_switch = document.querySelector('#edit_comments_switch');
        if(edit_comments_switch) {
            edit_comments_switch.onchange = function() {
                if (edit_comments_switch.checked) {
                    $('#edit_is_comment').val(1);
                } else {
                    $('#edit_is_comment').val(0);
                }
            };

            // Initialize the switch state based on the hidden input value
            if ($('#edit_is_comment').val() === '1') {
                edit_comments_switch.checked = true;
                // Force update the switch UI
                var event = new Event('change');
                edit_comments_switch.dispatchEvent(event);
            }
        }
        var edit_draft_switch = document.querySelector('#edit_draft_switch');
        if(edit_draft_switch) {
            edit_draft_switch.onchange = function() {
                if (edit_draft_switch.checked) {
                    $('#edit_is_draft').val('1');
                } else {
                    $('#edit_is_draft').val('0');
                }
            };
        }
        // if ($('#edit_is_draft').val() == 1 || $('#edit_is_draft').val() == '1') {
        //     // console.log('edit_draft_switch');

        //     $('#edit_draft_switch').prop('checked', true);
        //     // Force update the switch UI
        //     var event = new Event('change');
        //     edit_draft_switch.dispatchEvent(event);
        // }
        $(document).ready(function() {
            $(document).on('focusin', function(e) {
                if ($(e.target).closest(".tox-tinymce-aux, .moxman-window, .tam-assetmanager-root")
                    .length) {
                    e.stopImmediatePropagation();
                }
            });
            var base_url = "{{ url('/') }}";
            initThemeAwareTinyMCE('#des, #edit_des', {
                toolbar_mode: "wrap",
                height: 300,
                plugins: [
                    'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
                    'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
                    'insertdatetime', 'media', 'table', 'wordcount'
                ],
                toolbar: 'undo redo | blocks | bold italic backcolor | alignleft aligncenter alignright alignjustify bullist numlist outdent indent removeformat link image media',
                image_uploadtab: false,
                paste_data_images: false, // Disable image pasting
                images_upload_url: base_url + "/upload_img",
                relative_urls: false,
                remove_script_host: false,
                file_picker_types: 'image media',
                media_poster: false,
                media_alt_source: false,
                file_picker_callback: function(callback, value, meta) {
                    if (meta.filetype == "media" || meta.filetype == "image") {
                        const input = document.createElement('input');
                        input.setAttribute('type', 'file');
                        input.setAttribute('accept', 'image/* audio/* video/*');
                        input.addEventListener('change', (e) => {
                            const file = e.target.files[0];
                            var reader = new FileReader();
                            var fd = new FormData();
                            var files = file;
                            fd.append("file", files);
                            fd.append('filetype', meta.filetype);
                            fd.append("page", 'news');
                            // AJAX
                            jQuery.ajax({
                                url: base_url + "/upload_img",
                                type: "post",
                                data: fd,
                                contentType: false,
                                processData: false,
                                success: function(response) {
                                    const url = base_url + "/storage/" + response;
                                    callback(url);
                                }
                            });
                            reader.onload = function(e) {};
                            reader.readAsDataURL(file);
                        });
                        input.click();
                    }
                },
                setup: function(editor) {
                    editor.on("change keyup", function(e) {
                        editor.save();
                        $(editor.getElement()).trigger('change');
                    });
                    editor.on('dragover drop', function(e) {
                        e.preventDefault(); // Prevent the default drag and drop behavior
                    });
                }
            });
        });
    </script>

    <script type="text/javascript">
        var switcheryInstances = [];
        var today = new Date().toISOString().split('T')[0];
        $(document).ready(function(e) {
            var elems = Array.prototype.slice.call(document.querySelectorAll(".status-switch"));
            elems.forEach(function(elem) {
                var switchery = new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
                switcheryInstances.push(switchery);
            });
            $('.video_youtube').hide();
            $('.video_other').hide();
            $('.video_upload').hide();
        });

        $(document).on('change', '#content_type', function() {
            var type = $("#content_type").val();
            $('.video_youtube').hide();
            $('.video_other').hide();
            $('.video_upload').hide();
            if (type == "video_youtube") {
                $('.video_youtube').show();
            } else if (type == "video_other") {
                $('.video_other').show();
            } else if (type == "video_upload") {
                $('.video_upload').show();
            }
        });

        $(document).on('change', '#published_date', function(e) {
            var published_date = $('#published_date').val();
            $('#show_till').prop('min', published_date);
            switcheryInstances.forEach(function(switchery) {
                if (switchery.element.id === 'edit_is_notification') {
                    if (status == 0) {
                        switchery.disable();
                    } else {
                        switchery.enable();
                    }
                }
            });
        });

        $(document).on('change', '#edit_content_type', function() {
            var type = $("#edit_content_type").val();
            $('.evideo_youtube').hide();
            $('.evideo_other').hide();
            $('.evideo_upload').hide();
            $('#youtube_url').prop('required', false);
            $('#other_url').prop('required', false);
            $('#exampleVideoInputFile1_edit').prop('required', false);
            if (type == "video_youtube") {
                $('#youtube_url').prop('required', true);
                $('.evideo_youtube').show();
            } else if (type == "video_other") {
                $('#other_url').prop('required', true);
                $('.evideo_other').show();
            } else if (type == "video_upload") {
                var edit_id = $('#edit_id').val();
                var data = $("#table").bootstrapTable('getRowByUniqueId', edit_id);
                var old = data.content_type1;
                if (old != type) {
                    $('#exampleVideoInputFile1_edit').prop('required', true);
                }
                $('.evideo_upload').show();
            }
        });

        $(document).on('change', '#edit_published_date', function(e) {
            var published_date = $('#edit_published_date').val();
            var status = $('input[name=status]:checked').val();
            $('#edit_show_till').prop('min', published_date);
            switcheryInstances1.forEach(function(switchery) {
                if (switchery.element.id === 'edit_is_notification') {
                    if (status == 0 || published_date > today) {
                        switchery.disable();
                    } else {
                        switchery.enable();
                    }
                }
            });
        });
    </script>

    <script type="text/javascript">
        //Clone News
        $(document).on('click', '.clone-data', function() {
            var base_url = "{{ url('/') }}" ;
            var id = $(this).data("id");
            var image = $(this).data("image");
            var con_value = $(this).data("cvalue");
            $.ajax({
                url: base_url + '/clone_news',
                type: "POST",
                dataType: "json",
                data: {
                    id: id,
                    image_url: image,
                    con_value: con_value
                },
                success: function(result) {
                    if (result) {
                        showSuccessToast(result.message);
                        setTimeout(function() {
                            $("#table").bootstrapTable("refresh");
                        }, 1000);
                    }
                }
            });
        });

        $("#editDataDesModal form").on("submit", function(e) {
            e.preventDefault();
            let form = $(this);
            let data = form.serialize();

            $.ajax({
                type: "PUT",
                url: form.attr("action"),
                data: data,
                success: function(response) {
                    if (!response.error) {
                        $("#editDataDesModal").modal("hide");
                        $("#table").bootstrapTable("refresh");
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                },
                error: function(xhr, status, error) {
                    // Handle validation errors
                    if (xhr.responseJSON && xhr.responseJSON.message) {
                        showErrorToast(xhr.responseJSON.message);
                    } else {
                        showErrorToast('An error occurred. Please try again.');
                    }
                    console.error(error);
                },
            });
        });

        var elems = Array.prototype.slice.call(document.querySelectorAll(".edit-status-switch"));
        var switcheryInstances1 = [];
        elems.forEach(function(elem) {
            var switchery = new Switchery(elem, {
                size: "small",
                color: "#47C363",
                secondaryColor: "#EB4141",
                jackColor: "#ffff",
                jackSecondaryColor: "#ffff",
            });
            switcheryInstances1.push(switchery);
        });
    </script>


    <script type="text/javascript">
        $(document).on('input', '#slug, #edit_slug', function () {
            var clean = $(this).val().replace(/[^a-z0-9-_]/gi, '');
            $(this).val(clean.toLowerCase());
        });
    // Slug generation is handled globally by slug-helper.js via data-slug-* attributes
    </script>

    <script type="text/javascript">
        $(document).on('change', '#filter_language_id', function() {
            $('#table').bootstrapTable('refresh');
            var data = {
                language_id: $('#filter_language_id').val(),
            };
            var url = "{{ route('get_category_by_language') }}";
            fetchList(url, data, '#filter_category_id');
        });
        $(document).on('change', '#filter_category_id', function() {
            $('#table').bootstrapTable('refresh');
            var data = {
                category_id: $('#filter_category_id').val(),
            };
            var url = "{{ route('get_subcategory_by_category') }}";
            fetchList(url, data, '#filter_subcategory_id');
        });
        $(document).on('change', '#filter_subcategory_id', function() {
            $('#table').bootstrapTable('refresh');
        });
        $(document).on('change', '#filter_location_id', function() {
            $('#table').bootstrapTable('refresh');
        });
        $(document).on('change', '#filter_user_id', function() {
            $('#table').bootstrapTable('refresh');
        });
        $(document).on('change', '#filter_status', function() {
            $('#table').bootstrapTable('refresh');
        });
    </script>

    <script type="text/javascript">
        $('#bulk_delete').click(function() {
            var request_ids = [];
            selected = $('#table').bootstrapTable('getSelections');
             if(selected.length===0){
                    showErrorToast(trans("Please select at least one record to delete"));
                    return;
                }
            var arr = Object.values(selected);
            var i;
            var final_selection = [];
            var request_ids = arr.map(({
                id
            }) => id); 
            if (request_ids.length) {
                Swal.fire({
                    title:'{{ __("are_you_sure") }}',
                    text:'{{ __("you_wont_be_able_to_revert_this") }}',
                    icon:'warning',
                    showCancelButton:true,
                    cancelButtonText: '{{ __("cancel") }}',
                    confirmButtonText:'{{ __("yes_proceed") }}'
                }).then((result) => {
                    if (result.value) {
                        $.ajaxSetup({
                            headers: {
                                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                            }
                        });
                        $.ajax({
                            type: 'POST',
                            url: "{{ url('bulk_news_delete') }}",
                            data: {
                                request_ids: request_ids
                            },
                            success: function(response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message);
                                    $('#table').bootstrapTable('refresh');
                                } else {
                                    showErrorToast(response.message);
                                }
                            },
                            error: function(response) {
                                return showToastMessage(response.message, "error");
                            }
                        });
                    }
                });
            } else {
                var message = "{{ __('select_data_to_delete') }}";
                showErrorToast(message);
            }
        });


    </script>

    <script type="text/javascript">
    // generate with ai script starts here
    initMetaFieldGeneration({
        isEditForm: false,
        buttonSelector: '#generate_meta_fields',
        routeUrl: '{{ route("generate-all-meta-fields") }}',
        csrfToken: '{{ csrf_token() }}',
        languageSelector: '#language_id',
        titleSelector: '#title',
        includeDescription: true,
        includeSummarizedDescription: true,
        fieldMappings: {
            metaTags: '#meta_tags',
            metaTitle: '#meta_title',
            metaDescription: '#meta_description',
            description: '#des',
            summarizedDescription: '#summarized_description',
        },
        validationMessages: {
selectLanguage: '{{ __("please_select_language_first") }}',
enterTitle: '{{ __("please_enter_title_first") }}'
        }
    });
    </script>
@endsection
