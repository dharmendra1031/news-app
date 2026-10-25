<section class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('news_buzz') }}</h1>
            </div>
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item text-dark">
                        <a href="{{ route('home') }}" class="text-dark"><i
                                class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                    </li>
                    <li class="breadcrumb-item active"><i
                            class="nav-icon fas fa-play-circle mr-1"></i>{{ __('news_buzz') }}
                    </li>
                </ol>
            </div>
        </div>
    </div>
</section>

<section class="content" style="padding-bottom: 0.5rem;">
    <div class="container-fluid">
        <div class="row">
            @can('newsbuzz-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-2 ml-1"><i
                            class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('news_buzz') }}</button>
                </div>
            @endcan
            <div class="col-md-12" id="add_card">
                <div class="card card-secondary">
                    <div class="card-header">
                        <h3 class="card-title">{{ __('create') . ' ' . __('news_buzz') }}</h3>
                    </div>
                    <div class="card-body">
                        <form id="create_form" action="{{ route('video_shorts.store') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
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
                                                <option value="{{ $row->id }}" data-name="{{ $row->language }}">
                                                    {{ $row->language }}
                                                </option>
                                            @endforeach
                                        </select>
                                    </div>
                                    @if (is_category_enabled() == 1)
                                        <div class="form-group">
                                            <label class="required">{{ __('category') }}</label>
                                            <select id="category_id" name="category_id" class="form-control" required>
                                                <option value="">{{ __('select') . ' ' . __('category') }}
                                                </option>
                                                @foreach ($categoryList as $row)
                                                    <option value="{{ $row->id }}">{{ $row->category_name }}
                                                    </option>
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif
                                    <div class="form-group">
                                        <label>{{ __('description') }}</label>
                                        <textarea id="des" name="des" class="form-control"
                                            oninput="getWordCount('des','des_count','12.9px arial',0,0,'description')"></textarea>
                                        <small id="des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('video_type') }}</label>
                                        <select name="video_type" id="video_type" class="form-control" required>
                                            <option value="video_upload">{{ __('video_uploads') }}</option>
                                            <option value="youtubelink">{{ __('video_youtube') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group video_youtube" style="display: none;">
                                        <label class="required">{{ __('youtube_url') }}</label>
                                        <input type="url" name="youtube_url" class="form-control youtube_url"
                                            required>
                                        <span class="error invalid-feedback youtube_url_error"></span>
                                    </div>
                                    <div class="form-group video_upload">
                                        <label
                                            class="required">{{ __('video_uploads') }}</label><small>{{ __('max_size_25mb') }}</small>
                                        <input name="video_file" type="file" class="filepond-video"
                                            id="create_video_file" required>
                                        <div id="create_video_error" class="text-danger mt-1" style="display:none;">
                                        </div>
                                    </div>

                                </div>
                                <div class="col-md-6 col-sm-12">
                                    <div class="form-group">
                                        <label class="required">{{ __('title') }}</label>
                                        <input id="title" name="title" required type="text"
                                            placeholder="{{ __('title') }}" class="form-control"
                                            data-slug-table="video_shorts" data-slug-target="#slug">
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('slug') }}</label><span
                                            class="">({{ __('english_only') }})</span>
                                        <input id="slug" name="slug" required type="text"
                                            placeholder="{{ __('slug') }}" class="form-control">
                                        <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('date') }}</label>
                                        <input id="published_date" name="published_date" min="{{ date('Y-m-d') }}"
                                            type="date" class="form-control" value="{{ date('Y-m-d') }}">
                                    </div>


                                    <div class="form-group ">
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
        </div>
    </div>
</section>
