@extends('layouts.main')
@section('title')
    {{ __('podcast_episodes') }} - {{ $podcast->title }}
@endsection
@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('podcast_episodes') }} - {{ $podcast->title }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('podcast') }}" class="text-dark"><i
                                    class="fas fa-podcast mr-1"></i>{{ __('podcasts') }}</a>
                        </li>
                        <li class="breadcrumb-item active">{{ __('episodes') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('podcast_details') }}</h3>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3">
                                    <strong>{{ __('title') }}:</strong> {{ $podcast->title }}
                                </div>
                                <div class="col-md-3">
                                    <strong>{{ __('status') }}:</strong>
                                    {{ $podcast->status ? __('active') : __('inactive') }}
                                </div>
                            </div>
                            <div class="row mt-3">
                                <div class="col-md-12">
                                    <strong>{{ __('description') }}:</strong> {{ $podcast->description ?? '-' }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                @include('podcast.episodes.create', ['usedEpisodeNumbers' => $usedEpisodeNumbers])
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <div class="d-flex justify-content-between align-items-center">
                                <h3 class="card-title">{{ __('episodes') . ' ' . __('list') }}</h3>
                            </div>
                        </div>
                        <div class="card-body">
                            @can('podcast-bulk-delete')
                                <div id="toolbar">
                                    <button class="btn bg-primary text-white" type="submit"
                                        id="bulk_delete">{{ __('bulk_delete') }}</button>
                                </div>
                            @endcan
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('podcast.episodes.list', $podcast->id) }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                data-sort-order="desc" data-unique-id="id">
                                <thead>
                                    <tr>
                                        @can('podcast-bulk-delete')
                                            <th class="text-center multi-check" data-checkbox="true"></th>
                                        @endcan
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="episode_no" data-sortable="true">
                                            {{ __('episode_no') }}</th>
                                        <th scope="col" data-field="title" data-formatter="textFormatter">
                                            {{ __('title') }}</th>
                                        <th scope="col" data-field="slug" data-visible="false" data-formatter="textFormatter">
                                            {{ __('slug') }}</th>
                                        <th scope="col" data-field="description" data-formatter="descriptionFormatter">
                                            {{ __('description') }}</th>
                                        <th scope="col" data-field="source_type" data-visible="true"
                                            data-formatter="sourceTypeFormatter">{{ __('source_type') }}</th>
                                        <th scope="col" data-field="audio_url" data-formatter="audioUrlFormatter">
                                            {{ __('audio') }}</th>
                                        <th scope="col" data-field="image" data-formatter="generalImageFormatter">
                                            {{ __('image') }}</th>
                                        <th scope="col" data-field="duration_seconds">{{ __('duration') }}</th>
                                        <th scope="col" data-field="status" data-formatter="videoShortStatusFormatter">
                                            {{ __('status') }}</th>
                                        <th scope="col" data-field="is_draft" data-formatter="isDraftNewsFormatter">
                                            {{ __('is_draft') }}</th>
                                        <th scope="col" data-field="published_at" data-formatter="publishDateFormatter"
                                            data-sortable="true">{{ __('published_date') }}</th>
                                        <th scope="col" data-field="operate" data-events="podcastEpisodeEvents">
                                            {{ __('operate') }}</th>
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    @include('podcast.episodes.editModal')
@endsection

@section('script')
    <script type="text/javascript">
        // Bulk delete episodes
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
                title: '{{ __("are_you_sure") }}',
                text: '{{ __("you_wont_be_able_to_revert_this") }}',
                icon: 'warning',
                showCancelButton: true,
                cancelButtonText: '{{ __("cancel") }}',
                confirmButtonText: '{{ __("yes_proceed") }}'
            }).then((result) => {
                if (result.value) {
                    $.ajax({
                        url: "{{ route('podcast.episodes.bulk_delete', $podcast->id) }}",
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
                        error: function(xhr) {
                            showErrorToast(xhr.responseJSON.message);
                        }
                    });
                }
            });
        });

        // Hide conditional fields initially
        $(document).ready(function() {
            $('.audio_upload').hide();
            $('.youtube_url_field').hide();
        });

        $(document).on('change', '#source_type', function() {
            var type = $(this).val();
            $('.audio_upload').hide();
            $('.youtube_url_field').hide();

            if (type == "upload") {
                $('.audio_upload').show();
            } else if (type == "youtube_link") {
                $('.youtube_url_field').show();
            }
        });

        // YouTube URL validation
        $(document).on('change', '.youtube_url', function(e) {
            var url = $(this).val();
            if (url != undefined && url != '') {
                var regExp =
                    /^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$/;
                var match = url.match(regExp);
                if (match && match[1].length == 11) {
                    $(this).closest(".youtube_url_field").find(".youtube_url_error").hide();
                    $(this).closest(".youtube_url_field").find(".youtube_url_error").text("");
                } else {
                    $(this).closest(".youtube_url_field").find(".youtube_url_error").show();
                    $(this).closest(".youtube_url_field").find(".youtube_url_error").text(
                        "{{ __('please_enter_valid_youtube_url') }}");
                    $(this).val("");
                }
            }
        });

        // Switchery initialization
        var elems = document.querySelectorAll(".status-switch");
        elems.forEach(function(elem) {
            if (!elem.switcheryInitialized) {
                new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
                elem.switcheryInitialized = true;
            }
        });
        var elems = document.querySelectorAll(".edit-status-switch");
        elems.forEach(function(elem) {
            if (!elem.switcheryInitialized) {
                new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
                elem.switcheryInitialized = true;
            }
        });

        // Draft switch handler - Create form
        var createDraftSwitch = document.querySelector('#draft_switch');
        if (createDraftSwitch) {
            createDraftSwitch.onchange = function() {
                if (createDraftSwitch.checked) {
                    $('#create_form input[name="is_draft"]').val(1);
                } else {
                    $('#create_form input[name="is_draft"]').val(0);
                }
            };
        }
        // Draft switch handler - Edit form
        var editDraftSwitch = document.querySelector('#edit_draft_switch');
        if (editDraftSwitch) {
            editDraftSwitch.onchange = function() {
                if (editDraftSwitch.checked) {
                    $('#update_form input[name="is_draft"]').val(1);
                } else {
                    $('#update_form input[name="is_draft"]').val(0);
                }
            };
        }
    </script>
    <script>
        $(document).ready(function() {

            // Show/Hide fields based on source type
            $('#edit_source_type').on('change', function() {

                const type = $(this).val();

                if (type === 'upload') {
                    $('.audio_upload').show();
                    $('.youtube_url_field').hide();
                } else if (type === 'youtube_link') {
                    $('.audio_upload').hide();
                    $('.youtube_url_field').show();
                } else {
                    $('.audio_upload').hide();
                    $('.youtube_url_field').hide();
                }
            });
            const usedEpisodeNumbers = @json($usedEpisodeNumbers);

        $('#episode_no').on('input', function() { 
            const value = parseInt($(this).val());

            if (usedEpisodeNumbers.includes(value)) {
                $('#episode_error').removeClass('d-none');
                $(this).addClass('is-invalid');
            } else {
                $('#episode_error').addClass('d-none');
                $(this).removeClass('is-invalid');
            }
        });
        $('#edit_episode_no').on('input', function() { 
            const value = parseInt($(this).val());
            const originalValue = parseInt($(this).data('original-episode-no'));

            if (value !== originalValue && usedEpisodeNumbers.includes(value)) {
                $('#edit_episode_error').removeClass('d-none');
                $(this).addClass('is-invalid');
            } else {
                $('#edit_episode_error').addClass('d-none');
                $(this).removeClass('is-invalid');
            }
        });

        });
        
    </script>
@endsection
