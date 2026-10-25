@extends('layouts.main')

@section('title')
    {{ __('pages') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('pages') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-file mr-1"></i>{{ __('pages') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('page-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('pages') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('pages') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('pages.store') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <label class="required">{{ __('language') }}</label>
                                            <select name="language" id="language" class="form-control" required>
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
                                            <input type="text" id="title" name="title" class="form-control"
                                                placeholder="{{ __('title') }}" required>
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('page_type') }}</label>
                                            <select id="page_type" name="page_type" required class="form-control">
                                                <option value="">{{ __('select') . ' ' . __('page_type') }}</option>
                                                <option value="privacy-policy">{{ __('privacy_policy') }}</option>
                                                <option value="terms-condition">{{ __('terms_condition') }}</option>
                                                <option value="about-us">{{ __('about_us') }}</option>
                                                <option value="contact-us">{{ __('contact_us') }}</option>
                                                <option value="custom">{{ __('custom') }}</option>
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('slug') }}</label><span
                                                class="">({{__('english_only')}})</span>
                                            <input id="slug" name="slug" placeholder="{{ __('slug') }}" type="text"
                                                class="form-control" required>
                                            <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                        </div>
                                    </div>

                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <label>{{ __('meta_keywords') }}</label>
                                            <input id="meta_tags" name="meta_keyword" style="border-radius: 0.25rem"
                                                class="w-100" type="text"
                                                placeholder="{{ __('press_enter_add_keywords') }}">
                                        </div>
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

                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <x-schema-markup-field />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('og_image') }}</label>
                                            <input name="og_file" type="file" accept="image/*" class="filepond">
                                        </div>
                                        <div class="form-group">
                                            <label class="required">{{ __('page_icon') }}</label>
                                            <input name="file" type="file" accept="image/*" class="filepond" required>
                                            <span class="text-danger">{{ __('note_for_page_icon') }}</span>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label class="required">{{ __('page_content') }}</label>
                                        <textarea id="page_content" name="page_content" class="form-control"
                                            required></textarea>
                                        <small id="page_content_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                    </div>
                                </div>
                                <div class="d-flex justify-content-end">
                                    {{-- <div class="col-12"> --}}
                                        <button type="button" class="btn btn-outline-primary" id="generate_meta_fields">
                                            <i class="fas fa-magic"></i> {{ __('generate') }}
                                        </button>
                                        <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                                        {{--
                                    </div> --}}
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                @can('page-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('pages') . ' ' . __('list') }} </h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    <div class="toolbar-filter">
                                        <select id="filter_language_id" class="form-control">
                                            <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $item)
                                                <option value="{{ $item->id }}">{{ $item->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_page_type" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('page_type') }}</option>
                                            <option value="privacy-policy">{{ __('privacy_policy') }}</option>
                                            <option value="terms-condition">{{ __('terms_condition') }}</option>
                                            <option value="about-us">{{ __('about_us') }}</option>
                                            <option value="contact-us">{{ __('contact_us') }}</option>
                                            <option value="custom">{{ __('custom') }}</option>
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_status" class="form-control">
                                            <option value="">{{ __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('pagesList') }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                    data-sort-order="desc" data-query-params="pageQueryParams">
                                    <thead>
                                        <tr>
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="image">{{ __('image') }}</th>
                                            <th scope="col" data-field="language">{{ __('language') }}</th>
                                            <th scope="col" data-field="title" data-sortable="true">{{ __('title') }}
                                            </th>
                                            <th scope="col" data-field="slug" data-visible="false">{{ __('slug') }}</th>
                                            <th scope="col" data-field="page_type">{{ __('page_type') }}</th>
                                            <th scope="col" data-field="status1">{{ __('status') }}</th>
                                            <th scope="col" data-field="page_content" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('page_content') }}
                                            </th>
                                            <th scope="col" data-field="og_image" data-visible="false">
                                                {{ __('og_image') }}
                                            </th>
                                            <th scope="col" data-field="schema_markup" data-visible="false">
                                                {{ __('schema_markup') }}
                                            </th>
                                            <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_keywords') }}
                                            </th>
                                            <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_title') }}
                                            </th>
                                            <th scope="col" data-field="meta_description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_description') }}
                                            </th>
                                            @canany(['page-edit', 'page-delete'])
                                                <th scope="col" data-field="operate" data-events="pagesEvents">
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
            </div>
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('pages') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('pages') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        @method('PUT')
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="edit_language" name="language" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('title') }}</label>
                                        <input type="text" name="title" id="edit_title" class="form-control"
                                            placeholder="{{ __('title') }}" required>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('page_type') }}</label>
                                        <select id="edit_page_type" name="page_type" required class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('page_type') }}</option>
                                            <option value="privacy-policy">{{ __('privacy_policy') }}</option>
                                            <option value="terms-condition">{{ __('terms_condition') }}</option>
                                            <option value="about-us">{{ __('about_us') }}</option>
                                            <option value="contact-us">{{ __('contact_us') }}</option>
                                            <option value="custom">{{ __('custom') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('slug') }}</label><span
                                            class="">({{__('english_only')}})</span>
                                        <input type="text" name="slug" id="edit_slug" class="form-control"
                                            placeholder="{{ __('slug') }}" required>
                                        <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                    </div>

                                </div>
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>{{ __('meta_keywords') }}</label>
                                        <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                            name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                                    </div>
                                    <div class="form-group">
                                        <x-schema-markup-field id="edit_schema_markup" />
                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('meta_title') }}</label>
                                        <input type="text" name="meta_title" class="form-control" id="edit_meta_title"
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
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>{{ __('og_image') }}</label>
                                        <input name="og_file" type="file" accept="image/*" class="filepond">
                                        <div id="edit_image_preview_container" class="mt-2" >
                                            <label class="d-block small text-muted">{{ __('current_og_image') }}</label>
                                            <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label class="required">{{ __('page_icon') }}</label>
                                        <input name="file" type="file" class="filepond">
                                        <div id="edit_image_preview_container" class="mt-2" >
                                            <label class="d-block small text-muted">{{ __('current_page_icon') }}</label>
                                            <img id="edit_page_icon_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                        </div>
                                        <span class="text-danger">{{ __('note_for_page_icon') }}</span>

                                    </div>
                                    <div class="form-group">
                                        <label>{{ __('status') }}</label><br>
                                        <div id="status1" class="btn-group">
                                            <label class="btn btn-success" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input class="mr-1" type="radio" name="status" value="1">{{ __('active') }}
                                            </label>
                                            <label class="btn btn-danger" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input class="mr-1" type="radio" name="status"
                                                    value="0">{{ __('deactive') }}
                                            </label>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('page_content') }}</label>
                                    <textarea id="edit_page_content" name="page_content" class="form-control"
                                        required></textarea>
                                    <small id="edit_page_content_count" class="form-text seo-hint text-muted" style="display:none"></small>
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
    <script type="text/javascript">
        $(document).on('change', '#page_type', function () {
            var page_type = $('#page_type').val();
            if (page_type == 'custom') {
                $('#slug').val('').prop('readonly', false);
            } else {
                $('#slug').val(page_type).prop('readonly', true);
            }
        });
        $(document).on('change', '#edit_page_type', function () {
            var page_type = $('#edit_page_type').val();
            if (page_type == 'custom') {
                $('#edit_slug').prop('readonly', false);
            } else {
                $('#edit_slug').prop('readonly', true);
            }
        });
    </script>
    <script type="text/javascript">
        $("#filter_language_id").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_status").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_page_type").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
    </script>
    <script type="text/javascript">
        $(document).ready(function () {
            $(document).on('focusin', function (e) {
                if ($(e.target).closest(".tox-tinymce-aux, .moxman-window, .tam-assetmanager-root")
                    .length) {
                    e.stopImmediatePropagation();
                }
            });
            var base_url = "{{ url('/') }}";
            initThemeAwareTinyMCE('#page_content, #edit_page_content', {
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
                file_picker_callback: function (callback, value, meta) {
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
                            fd.append("page", 'pages');
                            // AJAX
                            jQuery.ajax({
                                url: base_url + "/upload_img",
                                type: "post",
                                data: fd,
                                contentType: false,
                                processData: false,
                                success: function (response) {
                                    const url = base_url + "/storage/" +
                                        response; // Adjust the URL path
                                    callback(url);
                                }
                            });
                            reader.onload = function (e) { };
                            reader.readAsDataURL(file);
                        });
                        input.click();
                    }
                },
                setup: function (editor) {
                    editor.on("change keyup", function (e) {
                        editor.save();
                        $(editor.getElement()).trigger('change');
                    });
                    editor.on('dragover drop', function (e) {
                        e.preventDefault(); // Prevent the default drag and drop behavior
                    });
                }
            });

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
            languageSelector: '#language',
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
