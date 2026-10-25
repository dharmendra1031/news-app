@extends('layouts.main')

@section('title')
    {{ __('breaking_news') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('breaking_news') }}</h1>
                    @if (is_breaking_news_enabled() == 0)
                        <label class="badge badge-danger">{{ __('disabled') }}</label>
                    @endif
                </div>

                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i
                                class="nav-icon fas fa-newspaper mr-1"></i>{{ __('breaking_news') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('breaking-news-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('breaking_news') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('breaking_news') }}</h3>
                        </div>
                        <form id="create_form" action="{{ url('breaking_news') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                {{-- ===== Group: Basic Information ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-info-circle mr-1"></i>{{ __('basic_information') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('language') }}</label>
                                                <select id="language" name="language" class="form-control" required>
                                                    @if (count($languageList) > 1)
                                                        <option value="">{{ __('select') . ' ' . __('language') }}
                                                        </option>
                                                    @endif
                                                    @foreach ($languageList as $item)
                                                        <option value="{{ $item->id }}" data-name="{{ $item->language }}">
                                                            {{ $item->language }}</option>
                                                    @endforeach
                                                </select>
                                            </div>
                                            <div class="form-group">
                                                <label class="required">{{ __('title') }}</label>
                                                <input id="title" name="title" required type="text"
                                                    placeholder="{{ __('title') }}" class="form-control"
                                                    data-slug-table="tbl_breaking_news"
                                                    data-slug-target="#slug">
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('slug') }}</label><span class="">({{ __('english_only') }})</span>
                                                <input id="slug" name="slug" required type="text"
                                                    placeholder="{{ __('slug') }}" class="form-control">
                                                <small class="form-text text-muted"><i class="fas fa-info-circle mr-1"></i>{{ __('avoid_special_characters') }}</small>
                                            </div>
                                            <div class="form-group">
                                                <label class="required">{{ __('content_type') }}</label>
                                                <select name="content_type" id="content_type" class="form-control" required>
                                                    <option value="standard_post" selected>{{ __('standard_post') }}</option>
                                                    <option value="video_youtube">{{ __('video_youtube') }}</option>
                                                    <option value="video_other">{{ __('video_other_url') }}</option>
                                                    <option value="video_upload">{{ __('video_upload') }}</option>
                                                </select>
                                            </div>
                                            <div class="form-group video_youtube">
                                                <label class="required">{{ __('youtube_url') }}</label>
                                                <input type="url" name="youtube_url" class="form-control">
                                            </div>
                                            <div class="form-group video_other">
                                                <label class="required">{{ __('other_url') }}</label>
                                                <input type="url" name="other_url" class="form-control">
                                            </div>
                                            <div class="form-group video_upload">
                                                <label class="required">{{ __('video_uploads') }}</label>
                                                <input name="video_file" type="file" class="filepond-video">
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
                                                <label class="required">{{ __('description') }}</label>
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

                                {{-- ===== Group: Media Assets ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-images mr-1"></i>{{ __('media_assets') }}</h6>
                                    <div class="row">
                                        <div class="col-md-12 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('image') }} </label>
                                                <input name="file" type="file" class="filepond" required>
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
                                                <label>{{ __('meta_keywords') }}</label>
                                                <input id="meta_tags" style="border-radius: 0.25rem" class="w-100"
                                                    type="text" name="meta_keyword"
                                                    placeholder="{{ __('press_enter_add_keywords') }}">
                                            </div>
                                            <div class="form-group">
                                                <x-schema-markup-field />
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
                                            <div class="form-group">
                                                <label>{{ __('meta_description') }}</label>
                                                <textarea id="meta_description" name="meta_description" class="form-control"
                                                    oninput="getWordCount('meta_description','meta_description_count','12.9px arial')"></textarea>
                                                <h6 id="meta_description_count">0</h6>
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
                            </div>
                        </form>
                    </div>
                </div>
                @can('breaking-news-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('breaking_news') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    @can('breaking-news-bulk-delete')
                                    <button class="btn bg-primary text-white" type="submit"
                                        id="bulk_order_update">{{ __('bulk_delete') }}</button>
                                    @endcan
                                    <div class="toolbar-filter">
                                        <select id="filter_language_id" class="form-control">
                                            <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_content_type" class="form-control">
                                            <option value="0">{{ __('select') . ' ' . __('content_type') }}</option>
                                            <option value="standard_post">{{ __('standard_post') }}</option>
                                            <option value="video_youtube">{{ __('video_youtube') }}</option>
                                            <option value="video_other">{{ __('video_other_url') }}</option>
                                            <option value="video_upload">{{ __('video_upload') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('breakingNewsList') }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                    data-sort-order="desc" data-query-params="breakingNewsParams">
                                    <thead>
                                        <tr>
                                            <th class="text-center multi-check" data-checkbox="true">
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="image" data-sortable="false">{{ __('image') }}
                                            </th>
                                            <th scope="col" data-field="language">{{ __('language') }}</th>
                                            <th scope="col" data-field="title">{{ __('title') }}</th>
                                            <th scope="col" data-field="slug" data-sortable="false" data-visible="false">{{ __('slug') }}</th>
                                            </th>
                                            <th scope="col" data-field="content_type">{{ __('content_type') }}</th>
                                            <th scope="col" data-field="description"
                                                data-formatter="descriptionFormatter">{{ __('description') }}</th>
                                            <th scope="col" data-field="views" data-sortable="false">{{ __('views') }}
                                            </th>
                                            <th scope="col" data-field="schema_markup" data-visible="false">
                                                {{ __('schema_markup') }}</th>
                                            <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_keywords') }}</th>
                                            <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_title') }}</th>
                                            <th scope="col" data-field="meta_description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_description') }}</th>
                                            @canany(['breaking-news-edit', 'breaking-news-delete'])
                                                <th scope="col" data-field="operate" data-events="breakingNewsEvents">
                                                    {{ __('operate') }}</th>
                                            @endcanany
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    @endcan
                </div>
            </div>
            <div class="modal fade" id="editDataModal">
                <div class="modal-dialog modal-xl">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h4 class="modal-title">{{ __('edit') . ' ' . __('breaking_news') }}</h4>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <form id="update_form" action="{{ url('breaking_news') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <input type='hidden' name="edit_id" id="edit_id" value='' />
                            <input type='hidden' name="image_url" id="image_url" value='' />
                            <input type='hidden' name="video_url" id="video_url" value='' />

                            <div class="modal-body">
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label class="required">{{ __('language') }}</label>
                                            <select id="edit_language" name="language" class="form-control" required>
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                                @foreach ($languageList as $item)
                                                    <option value="{{ $item->id }}">{{ $item->language }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('title') }}</label>
                                            <input id="edit_title" name="title" required type="text"
                                                class="form-control"
                                                data-slug-table="tbl_breaking_news"
                                                data-slug-target="#edit_slug"
                                                data-slug-id="#edit_id">
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('slug') }}</label><span
                                                class="">({{ __('english_only') }})</span>
                                            <input id="edit_slug" name="slug" required type="text"
                                                class="form-control">
                                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('content_type') }}</label>
                                            <select name="content_type" id="edit_content_type" class="form-control"
                                                required>
                                                <option value="standard_post" selected>{{ __('standard_post') }}</option>
                                                <option value="video_youtube">{{ __('video_youtube') }}</option>
                                                <option value="video_other">{{ __('video_other_url') }}</option>
                                                <option value="video_upload">{{ __('video_upload') }}</option>
                                            </select>
                                        </div>
                                        <div class="form-group evideo_youtube">
                                            <label class="required">{{ __('youtube_url') }}</label>
                                            <input type="url" name="youtube_url" id="youtube_url"
                                                class="form-control">
                                        </div>
                                        <div class="form-group evideo_other">
                                            <label class="required">{{ __('other_url') }}</label>
                                            <input type="url" name="other_url" id="other_url" class="form-control">
                                        </div>
                                        <div class="form-group evideo_upload">
                                            <label class="required">{{ __('video_uploads') }}</label>
                                            <input name="video_file" type="file" class="filepond-video"
                                                id="exampleVideoInputFile1">
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
                                            <label class="required">{{ __('image') }}</label>
                                            <input name="file" type="file" class="filepond">
                                             <div id="edit_image_preview_container" class="mt-2" style="">
                                                <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                                <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label>{{ __('meta_keywords') }}</label>
                                            <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100"
                                                type="text" name="meta_keyword"
                                                placeholder="{{ __('press_enter_add_keywords') }}">
                                        </div>
                                        <div class="form-group">
                                            <x-schema-markup-field id="edit_schema_markup" />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('meta_description') }}</label>
                                            <textarea id="edit_meta_description" name="meta_description" class="form-control"
                                                oninput="getWordCount('edit_meta_description','edit_meta_description_count','12.9px arial')"></textarea>
                                            <h6 id="edit_meta_description_count">0</h6>
                                        </div>
                                        <div class="form-group">
                                            <label class="required"> {{ __('description') }}</label>
                                            <textarea id="edit_des" name="des" class="form-control"></textarea>
                                            <small id="edit_des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                        </div>
                                        <div class="form-group">
                                            <label >{{ __('summarized_description') }}</label>
                                            <textarea name="summarized_description" id="edit_summarized_description" cols="30" rows="2" class="form-control"
                                                oninput="getWordCount('edit_summarized_description','edit_summarized_description_count','12.9px arial',0,300,'summarized_description')"></textarea>
                                            <small id="edit_summarized_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                        </div>
                                    </div>

                                    {{-- <div class="col-12"> --}}

                                    {{-- </div> --}}
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
    {{-- Slug generation is handled globally by slug-helper.js via data-slug-* attributes --}}
    <script type="text/javascript">
        $("#filter_language_id").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_content_type").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
    </script>
    <script type="text/javascript">
        $(document).ready(function(e) {
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

        $(document).on('change', '#edit_content_type', function() {
            var type = $("#edit_content_type").val();
            $('.evideo_youtube').hide();
            $('.evideo_other').hide();
            $('.evideo_upload').hide();
            if (type == "video_youtube") {
                $('.evideo_youtube').show();
            } else if (type == "video_other") {
                $('.evideo_other').show();
            } else if (type == "video_upload") {
                $('.evideo_upload').show();
            }
        });
    </script>
    <script type="text/javascript">
    $(document).ready(function() {
        
        // Prevent TinyMCE dialog focus issues
        $(document).on('focusin', function(e) {
            if ($(e.target).closest(".tox-tinymce-aux, .moxman-window, .tam-assetmanager-root").length) {
                e.stopImmediatePropagation();
            }
        });

        var base_url = "{{ url('/') }}";

        var tinyConfig = {
            toolbar_mode: "wrap",
            height: 300,
            plugins: [
                'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
                'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
                'insertdatetime', 'media', 'table', 'wordcount'
            ],
            toolbar: 'undo redo | blocks | bold italic backcolor | alignleft aligncenter alignright alignjustify bullist numlist outdent indent removeformat link image media',
            image_uploadtab: false,
            paste_data_images: false,
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
                        var fd = new FormData();
                        fd.append("file", file);
                        fd.append('filetype', meta.filetype);
                        fd.append("page", 'breaking_new');
                        $.ajax({
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
                    });
                    input.click();
                }
            },

            setup: function(editor) {
                editor.on("change keyup", function() {
                    editor.save();
                    clearTinyMCEError(editor.id);
                });
            }
        };

        // Init create-form editor immediately (visible on page load)
        initThemeAwareTinyMCE('#des', tinyConfig);

        // Init edit-form editor lazily on first modal open (avoids hidden-element slow init)
        $('#editDataModal').one('shown.bs.modal', function() {
            initThemeAwareTinyMCE('#edit_des', tinyConfig);
        });


        function clearTinyMCEError(editorId) {
            // Remove ALL error elements for this editor (prevents stacking)
            $('.tox-custom-error[data-editor=\"' + editorId + '\"]').remove();
            
            // Also remove red border
            var editor = tinymce.get(editorId);
            if (editor) {
                $(editor.getContainer()).css('border', '');
            }
        }

        function showTinyMCEError(editorId, message) {
            // Always clear first (prevents duplicates)
            clearTinyMCEError(editorId);
            
            var editor = tinymce.get(editorId);
            if (!editor) return;
            
            // Find the form-group that contains this TinyMCE
            // The textarea is inside a form-group, and TinyMCE is inserted after it
            var $textarea = $('#' + editorId);
            var $formGroup = $textarea.closest('.form-group');
            
            // Create error element with unique data attribute for easy removal
            var $error = $('<span>', {
                class: 'tox-custom-error invalid-feedback d-block',
                'data-editor': editorId,
                text: message,
                css: {
                    'color': '#dc3545',
                    'font-size': '0.875rem',
                    'margin-top': '0.25rem',
                    'display': 'block !important'  // Force display
                }
            });
            
            // Append to the form-group (most reliable location)
            $formGroup.append($error);
            
            // Add red border to TinyMCE container for visual feedback
            $(editor.getContainer()).css({
                'border': '1px solid #dc3545',
                'border-radius': '0.25rem'
            });
        }

        function validateTinyMCE(editorId) {
            var editor = tinymce.get(editorId);
            var content = editor
                ? editor.getContent({ format: 'text' }).trim()
                : $('#' + editorId).val().trim();

            if (content.length === 0) {
                showTinyMCEError(editorId, '{{ __("description_field_required") }}');
                return false;
            }
            clearTinyMCEError(editorId);
            return true;
        }

        // ============================================
        // CREATE FORM
        // ============================================
        $("#create_form").on("submit", function(e) {
            tinymce.triggerSave();
            
            if (!validateTinyMCE('des')) {
                e.preventDefault();
                e.stopImmediatePropagation();
                return false;
            }
        });

        // ============================================
        // EDIT FORM
        // ============================================
        $("#update_form").on("submit", function(e) {
            tinymce.triggerSave();
            
            if (!validateTinyMCE('edit_des')) {
                e.preventDefault();
                e.stopPropagation();
                return false;
            }
        });
    });
    </script>
    <script type="text/javascript">
        $('#bulk_order_update').click(function() {
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
                    title: trans('are_you_sure'),
                    text: trans('you_wont_be_able_to_revert_this'),
                    icon: 'error',
                    showCancelButton: true,
                    confirmButtonText: trans('yes_proceed') || 'Yes, proceed',
                    cancelButtonText: trans('cancel'),
                }).then((result) => {
                    if (result.value) {
                        $.ajaxSetup({
                            headers: {
                                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                            }
                        });
                        $.ajax({
                            type: 'POST',
                            url: "{{ url('bulk_breaking_news_delete') }}",
                            data: {
                                request_ids: request_ids,
                            },
                            success: function(response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message)
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
routeUrl: "{{ route('generate-all-meta-fields') }}",
csrfToken: "{{ csrf_token() }}",
            titleSelector: '#title',
            languageSelector: '#language',
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
