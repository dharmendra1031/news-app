@extends('layouts.main')

@section('title')
    {{ __('eNews') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('eNews') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-envelope mr-1"></i>{{ __('eNews') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('enews-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('eNews') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('eNews') }}</h3>
                        </div>
                        <div class="card-body">
                            <form id="create_form" action="{{ route('e-news.store') }}" role="form" method="POST"
                                enctype="multipart/form-data">
                                @csrf
                                {{-- ===== Group: Basic Information ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-info-circle mr-1"></i>{{ __('basic_information') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('language') }}</label>
                                                <select id="language" name="language" class="form-control" required>
                                                    @if (count($languageList) > 1)
                                                        <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                                    @endif
                                                    @foreach ($languageList as $item)
                                                        <option value="{{ $item->id }}" data-name="{{ $item->language }}">
                                                            {{ $item->language }}
                                                        </option>
                                                    @endforeach
                                                </select>
                                            </div>
                                            <div class="form-group">
                                                <label class="required">{{ __('title') }}</label>
                                                <input id="title" name="title" required type="text" placeholder="{{ __('title') }}"
                                                    class="form-control"
                                                    data-slug-table="tbl_e_news"
                                                    data-slug-target="#slug">
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('slug') }}</label><span
                                                    class="">({{__('english_only')}})</span>
                                                <input id="slug" name="slug" required type="text" placeholder="{{ __('slug') }}"
                                                    class="form-control">
                                                <small class="form-text text-muted"><i class="fas fa-info-circle mr-1"></i>{{ __('avoid_special_characters') }}</small>
                                            </div>
                                            <div class="form-group">
                                                {{-- no past date selectable --}}
                                                <label class="required">{{ __('date') }} </label>
                                                <input name="date" type="date" class="form-control" min="{{ date('Y-m-d') }}" value="{{ date('Y-m-d') }}">
                                            </div>
                                            <div class="form-group">
                                                <label>{{ __('status') }}</label><br>
                                                <div id="status1" class="btn-group">
                                                    <label class="btn btn-success" data-toggle-class="btn-primary"
                                                        data-toggle-passive-class="btn-default">
                                                        <input type="radio" name="status" value="1" checked>{{ __('active') }}
                                                    </label>
                                                    <label class="btn btn-danger" data-toggle-class="btn-primary"
                                                        data-toggle-passive-class="btn-default">
                                                        <input type="radio" name="status" value="0">{{ __('deactive') }}
                                                    </label>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {{-- ===== Group: Content ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-align-left mr-1"></i>{{ __('description') }}</h6>
                                    <div class="row">
                                        <div class="form-group col-md-12 col-sm-12">
                                            <textarea id="des" name="description" class="form-control"></textarea>
                                            <small id="des_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                        </div>
                                    </div>
                                </div>

                                {{-- ===== Group: Media Assets ===== --}}
                                <div class="form-section-card">
                                    <h6 class="form-section-title"><i class="fas fa-images mr-1"></i>{{ __('media_assets') }}</h6>
                                    <div class="row">
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('thumbnail') }} </label>
                                                <input name="thumbnail" type="file" class="filepond" required>
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label class="required">{{ __('attachment (PDF)') }} </label>
                                                <input name="attachment" type="file" class="filepond-pdf" accept="application/pdf" required>
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
                                            <div class="form-group">
                                                <label>{{ __('meta_keywords') }}</label>
                                                <input id="meta_tags" style="border-radius: 0.25rem" class="w-100" type="text"
                                                    name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                                            </div>
                                        </div>
                                        <div class="col-md-6 col-sm-12">
                                            <div class="form-group">
                                                <label>{{ __('meta_title') }}</label>
                                                <input type="text" name="meta_title" class="form-control" id="meta_title"
                                                    maxlength="70"
                                                    oninput="getWordCount('meta_title','meta_title_count','19.9px arial')"
                                                    placeholder="{{ __('meta_title_placeholder') }}">
                                                <small class="form-text text-muted">{{ __('meta_title_hint') }}</small>
                                                <small id="meta_title_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                            </div>
                                            <div class="form-group">
                                                <label>{{ __('meta_description') }}</label>
                                                <textarea id="meta_description" name="meta_description" class="form-control" rows="3"
                                                    maxlength="170"
                                                    oninput="getWordCount('meta_description','meta_description_count','12.9px arial')"
                                                    placeholder="{{ __('meta_description_placeholder') }}"></textarea>
                                                <small class="form-text text-muted">{{ __('meta_description_hint') }}</small>
                                                <small id="meta_description_count" class="form-text seo-hint text-muted" style="display:none"></small>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="d-flex justify-content-end">
                                    <button type="button" class="btn btn-outline-primary" id="generate_meta_fields">
                                        <i class="fas fa-magic"></i>{{ __('generate') }}
                                    </button>
                                    <button type="submit" class="btn btn-primary ml-2">{{ __('submit') }}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                @can('enews-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('eNews') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    @can('enews-delete')
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
                                        <div class="toolbar-filter">
                                            <select id="filter_status" name="status" class="form-control">
                                                <option value="">{{ __('status') }}</option>
                                                <option value="1">{{ __('active') }}</option>
                                                <option value="0">{{ __('deactive') }}</option>
                                            </select>
                                        </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('e-news.show', 1) }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                    data-sort-order="desc" data-query-params="eNewsQueryParams">
                                    <thead>
                                        <tr>
                                            @can('enews-delete')
                                                <th class="text-center multi-check" data-checkbox="true"></th>
                                            @endcan
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="language_id" data-visible="false">
                                                {{ __('language_id') }}
                                            </th>
                                            <th scope="col" data-field="language" data-align="center">{{ __('language') }}</th>
                                            <th scope="col" data-field="title">{{ __('title') }}</th>
                                            <th scope="col" data-field="slug" data-visible="false">{{ __('slug') }}</th>
                                            <th scope="col" data-field="date" data-align="center" data-formatter="MM_DD_YYYY_dateFormate">{{ __('date') }}</th>
                                            <th scope="col" data-field="thumbnail" data-align="center" data-formatter="generalImageFormatter">{{ __('thumbnail') }}</th>
                                            <th scope="col" data-field="attachment" data-align="center" data-formatter="attachmentFormatter">{{ __('attachment') }}</th>
                                            <th scope="col" data-field="status" data-align="center" data-formatter="eNewsStatusFormatter">
                                                {{ __('status') }}</th>
                                            <th scope="col" data-field="schema_markup" data-visible="false">
                                                {{ __('schema_markup') }}
                                            </th>
                                            <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_keywords') }}
                                            </th>
                                            <th scope="col" data-field="description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_description') }}
                                            </th>
                                            <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_title') }}
                                            </th>
                                            @canany(['enews-edit', 'enews-delete'])
                                                <th scope="col" data-field="operate" data-sortable="false" data-align="center"
                                                    data-events="eNewsEvents">{{ __('operate') }}</th>
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
        @include('enews.editModal', ['languageList' => $languageList])
    </section>
@endsection

@section('script')
    {{-- Slug generation is handled globally by slug-helper.js via data-slug-* attributes --}}

    <script type="text/javascript">
        $("#filter_language_id").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_status").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
    </script>
    {{-- generate with ai script starts here --}}
    <script type="text/javascript">
        $(document).ready(function () {
            // Initialize meta field generation for create form
            initMetaFieldGeneration({
                isEditForm: false,
                buttonSelector: '#generate_meta_fields',
                routeUrl: '{{ route("generate-all-meta-fields") }}',
                csrfToken: '{{ csrf_token() }}',
                titleSelector: '#title',
                languageSelector: '#language',
                includeDescription: true,
                fieldMappings: {
                    metaTags: '#meta_tags',
                    metaTitle: '#meta_title',
                    metaDescription: '#meta_description',
                    description: '#des',
                },
                validationMessages: {
                    selectLanguage: '{{ __("please_select_language_first") }}',
                    enterTitle: '{{ __("please_enter_title_first") }}'
                }
            });

        });

        var switcheryInstances = [];
        $(document).ready(function (e) {
            var elems = Array.prototype.slice.call(document.querySelectorAll(".status-switch"));
            elems.forEach(function (elem) {
                var switchery = new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
                switcheryInstances.push(switchery);
            });
        });

        var status_switch = document.querySelector('#status_switch');
        if (status_switch) {
            status_switch.onchange = function () {
                if (status_switch.checked) {
                    $('#status').val(1);
                } else {
                    $('#status').val(0);
                }
            };
        }

        var edit_status_switch = document.querySelector('#edit_status_switch');
        if (edit_status_switch) {
            edit_status_switch.onchange = function () {
                if (edit_status_switch.checked) {
                    $('#edit_status').val(1);
                } else {
                    $('#edit_status').val(0);
                }
            };
        }

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
        $('#bulk_delete').on('click',function(e){
                e.preventDefault();

                var selections=$('#table').bootstrapTable('getSelections');

                if(selections.length===0){
                    showErrorToast(trans("Please select at least one record to delete"));
                    return;
                }

                var ids=selections.map(function(row){
                    return row.id;
                });

                Swal.fire({
                    title:'{{ __("are_you_sure") }}',
                    text:'{{ __("you_wont_be_able_to_revert_this") }}',
                    icon:'warning',
                    showCancelButton:true,
                    cancelButtonText: '{{ __("cancel") }}',
                    confirmButtonText:'{{ __("yes_proceed") }}'
                }).then((result)=>{
                    if(result.value){
                        $.ajax({
                            url:"{{ route('enews.bulk_delete') }}",
                            type:"POST",
                            data:{
                                request_ids:ids,
                                _token:'{{ csrf_token() }}'
                            },
                            success:function(response){
                                if(response.error==false){
                                    showSuccessToast(response.message);
                                    $('#table').bootstrapTable('refresh');
                                }else{
                                    showErrorToast(response.message);
                                }
                            },
                            error: function(xhr) {
                                   showErrorToast(xhr.responseJSON.message);
                                }
                        });
                    }
                });
            });
    </script>
@endsection