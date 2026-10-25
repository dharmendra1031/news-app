@extends('layouts.main')
@section('title')
    {{ __('news_buzz') }}
@endsection
@section('content')
    @can('newsbuzz-create')
        @include('videoshorts.create')
    @endcan
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('newsbuzz-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('news_buzz') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    @can('newsbuzz-bulk-delete')
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
                                    @endif

                                    <div class="toolbar-filter">
                                        <select id="filter_status" name="status" class="form-control">
                                            <option value="">{{ __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('video_shorts.show', 1) }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-unique-id="id"
                                    data-show-columns="true" data-show-refresh="true" data-toolbar="#toolbar"
                                    data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false"
                                    data-sort-name="id" data-sort-order="desc" data-query-params="newsQueryParams">
                                    <thead>
                                        <tr>
                                            @can('newsbuzz-bulk-delete')
                                                <th class="text-center multi-check" data-checkbox="true"></th>
                                            @endcan
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="language_id" data-sortable="true"
                                                data-visible="false">
                                                {{ __('language_id') }}</th>
                                            <th scope="col" data-field="language_name">{{ __('language') }} </th>
                                            @if (is_category_enabled() == 1)
                                                <th scope="col" data-field="category_id" data-sortable="true"
                                                    data-visible="false">
                                                    {{ __('category_id') }}</th>
                                                <th scope="col" data-field="category_name">{{ __('category') }}</th>
                                            @endif
                                            <th scope="col" data-field="title" data-sortable="true"
                                                data-formatter="textFormatter">
                                                {{ __('title') }}
                                            </th>
                                            <th scope="col" data-field="slug" data-visible="false">{{ __('slug') }}
                                            </th>
                                            <th scope="col" data-field="video_type" data-formatter="videoTypeFormatter">
                                                {{ __('video_type') }}</th>
                                            <th scope="col" data-field="video_url" data-formatter="videoUrlFormatter">
                                                {{ __('video') }}</th>
                                            <th scope="col" data-field="status" data-formatter="videoShortStatusFormatter">
                                                {{ __('status') }}</th>
                                            <th scope="col" data-field="date" data-formatter="publishDateFormatter"
                                                data-visible="false">
                                                {{ __('date') }}</th>

                                            <th scope="col" data-field="description" data-visible="false"
                                                data-formatter="descriptionFormatter">
                                                {{ __('description') }}</th>
                                            <th scope="col" data-field="views_count">{{ __('views') }}</th>

                                            <th scope="col" data-field="likes_count"
                                                data-formatter="videoShortLikesFormatter">
                                                {{ __('reactions') }}</th>
                                            <th scope="col" data-field="comments_count"
                                                data-formatter="videoShortCommentsFormatter">
                                                {{ __('comments') }}</th>

                                            <th scope="col" data-field="shares_count">{{ __('shares') }}</th>

                                            @canany(['newsbuzz-edit', 'newsbuzz-delete'])
                                                <th scope="col" data-field="operate" data-events="videoshortsEvents">
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
    </section>
    @can('newsbuzz-edit')
        @include('videoshorts.editModal')
    @endcan
    @include('videoshorts.videoPlayerModal')
@endsection
@section('script')
    <script>
        console.log("elllo");
    </script>
    <script src="{{ asset('assets/custom/js/video-validations.js') }}"></script>
    <script>
        // ── Video Player Modal ──────────────────────────────────────────────
        $(document).on('click', '.video-play-btn', function() {
            const url = $(this).data('url');
            const type = $(this).data('type');
            const title = $(this).data('title');

            const videoEl = document.getElementById('videoPlayerEl');
            const iframeEl = document.getElementById('youtubePlayerEl');

            $('#videoPlayerTitle').text(title || '{{ __('video_preview') }}');
            $('#videoPlayerFallback').hide();

            if (type === 'youtubelink') {

                let embedUrl = url
                    .replace('https://www.youtube.com/watch?v=', 'https://www.youtube.com/embed/')
                    .replace('https://youtu.be/', 'https://www.youtube.com/embed/');

                $(videoEl).hide();
                $(iframeEl).show();

                iframeEl.src = embedUrl;

            } else {

                $(iframeEl).hide();
                iframeEl.src = '';

                $(videoEl).show();
                videoEl.src = url;
                videoEl.load();
            }

            $('#videoPlayerModal').modal('show');
        });

        document.getElementById('videoPlayerEl').addEventListener('error', function() {
            $(this).hide();
            $('#videoPlayerFallback').show();
            $('#videoPlayerDownload').attr('href', this.src);
        });

        $('#videoPlayerModal').on('hidden.bs.modal', function() {

            const videoEl = document.getElementById('videoPlayerEl');
            const iframeEl = document.getElementById('youtubePlayerEl');

            videoEl.pause();
            videoEl.removeAttribute('src');
            videoEl.load();

            iframeEl.src = '';

            $('#videoPlayerFallback').hide();
            $(videoEl).show();
            $(iframeEl).hide();
        });
        // ───────────────────────────────────────────────────────────────────
    </script>
    <script>
        $(document).on('input', '#slug, #edit_slug', function() {
            var clean = $(this).val().replace(/[^a-z0-9-_]/gi, '');
            $(this).val(clean.toLowerCase());
        });
        $(document).on('change', '#filter_language_id', function() {

            $('#table').bootstrapTable('refresh');
            var data = {
                language_id: $('#filter_language_id').val(),
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#filter_category_id');
        });

        $(document).on('change', '#filter_status', function() {
            $('#table').bootstrapTable('refresh');
        });
        $(document).on('change', '#filter_category_id', function() {

            $('#table').bootstrapTable('refresh');
        });
        $(document).ready(function() {

            $(document).on('change', '#language_id', function(e) {

                let data = {
                    language_id: $('#language_id').val(),
                };
                let url = '{{ route('get_category_by_language') }}';
                fetchList(url, data, '#category_id');
            });

            $('#bulk_delete').on('click', function(e) {
                e.preventDefault();

                var selections = $('#table').bootstrapTable('getSelections');

                if (selections.length === 0) {
                    showErrorToast(trans("Please select at least one record to delete"));
                    return;
                }

                var ids = selections.map(function(row) {
                    return row.id;
                });

                Swal.fire({
                    title: '{{ __('are_you_sure') }}',
                    text: '{{ __('you_wont_be_able_to_revert_this') }}',
                    icon: 'warning',
                    showCancelButton: true,
                    cancelButtonText: '{{ __('cancel') }}',
                    confirmButtonText: '{{ __('yes_proceed') }}'
                }).then((result) => {
                    if (result.value) {
                        $.ajax({
                            url: "{{ route('video_shorts.bulk_delete') }}",
                            type: "POST",
                            data: {
                                request_ids: ids,
                                _token: '{{ csrf_token() }}'
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
                                showErrorToast("Something went wrong.");
                            }
                        });
                    }
                });
            });
            $(document).on('change', '#edit_language_id', function(e) {

                let data = {
                    language_id: $('#edit_language_id').val(),
                };
                let url = '{{ route('get_category_by_language') }}';
                fetchList(url, data, '#edit_category_id');
            });


            initMetaFieldGeneration({
                isEditForm: false,
                buttonSelector: '#generate_meta_fields',
                routeUrl: '{{ route('generate-all-meta-fields') }}',
                csrfToken: '{{ csrf_token() }}',
                languageSelector: '#language_id',
                titleSelector: '#title',
                includeDescription: true,
                includeSummarizedDescription: true,
                fieldMappings: {
                    description: '#des',
                },
                validationMessages: {
                    selectLanguage: '{{ __('please_select_language_first') }}',
                    enterTitle: '{{ __('please_enter_title_first') }}'
                }
            });

            var videoValidationOptions = {
                maxSizeMB: 25,
                maxResolution: 1920,
                maxDuration: 120,
                minDuration: 3
            };

            var createVideoInput = document.getElementById('create_video_file');
            if (createVideoInput) {
                setupVideoValidation(createVideoInput, 'create_video_error', videoValidationOptions);
            }

            var editVideoInput = document.getElementById('edit_video_file');
            if (editVideoInput) {
                setupVideoValidation(editVideoInput, 'edit_video_error', videoValidationOptions);
            }
            $('.video_youtube').hide();
        });
        $(document).on('change', '#video_type', function() {

            var type = $('#video_type').val();

            if (type === 'video_upload') {
                $('.video_upload').show();
                $('.video_youtube').hide();

                $('#create_video_file').prop('required', true);
                $('.youtube_url').prop('required', false);
            } else {
                $('.video_upload').hide();
                $('.video_youtube').show();

                $('#create_video_file').prop('required', false);
                $('.youtube_url').prop('required', true);
            }
        });
        $(document).on('change', '#edit_video_type', function() {

            var type = $(this).val();

            if (type === 'video_upload') {
                $('.edit_video_upload').show();
                $('.edit_video_youtube').hide();

                $('#edit_video_file').prop('required', true);
                $('.edit_youtube_url').prop('required', false);
            } else {
                $('.edit_video_upload').hide();
                $('.edit_video_youtube').show();

                $('#edit_video_file').prop('required', false);
                $('.edit_youtube_url').prop('required', true);
            }
        });
        $('.youtube_url').on('change', function(e) {
            var url = $(this).val();
            if (url != undefined || url != '') {
                var regExp =
                    /^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|watch\?.+&v=|embed\/|v\/|shorts\/))([A-Za-z0-9_-]{11})(?:[?&].*)?$/;
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
        $('.edit_youtube_url').on('change', function(e) {
            var url = $(this).val();
            if (url != undefined || url != '') {
                var regExp =
                    /^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|watch\?.+&v=|embed\/|v\/|shorts\/))([A-Za-z0-9_-]{11})(?:[?&].*)?$/;
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
    </script>
@endsection
