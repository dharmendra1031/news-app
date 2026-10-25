@extends('layouts.main')

@section('title')
    {{ __('ad_spaces') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('ad_spaces') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-ad mr-1"></i>{{ __('ad_spaces') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('ad-space-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                            class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('ad_spaces') }}</button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('ad_spaces') }}</h3>
                        </div>
                        <form id="create_form" action="{{ url('ad_spaces') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="language_id" name="language_id" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @endif
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('platform') }}</label>
                                        <select id="platform" name="platform" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('platform') }}</option>
                                            @foreach (array_keys(config('ad_spaces.platforms')) as $platformKey)
                                                <option value="{{ $platformKey }}">{{ __(str_replace('_', ' ', $platformKey)) }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('page') }}</label>
                                        <select id="page" name="page" class="form-control" required disabled>
                                            <option value="">{{ __('select') . ' ' . __('page') }}adasd</option>
                                        </select>
                                        <small id="page_hint" class="form-text text-muted" style="display:none;"></small>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('placement') }}</label>
                                        <select id="placement" name="placement" class="form-control" required disabled>
                                            <option value="">{{ __('select') . ' ' . __('placement') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12" id="featured_section_group" style="display:none;">
                                        <label class="required">{{ __('featured_section') }}</label>
                                        <input type="hidden" name="featured_section_id" id="featured_section_id_input" value="">
                                        <select id="featured_section_id" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('featured_section') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('banner_type') }}</label>
                                        <select id="banner_type" name="banner_type" class="form-control" required>
                                            <option value="external_link">{{ __('external_link') }}</option>
                                            <option value="banner_only">{{ __('banner_only') }}</option>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12" id="ad_url_group">
                                        <label>{{ __('URL') }}</label>
                                        <input name="ad_url" type="url" class="form-control">
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('duration_days') }}</label>
                                        <input name="duration_days" type="number" class="form-control" min="1" value="1" required>
                                    </div>
                                </div>
                                <div class="row" id="image_upload_group" style="display:none;">
                                    <div class="form-group col-sm-12 col-md-6">
                                        <label class="required">{{ __('banner_image') }}</label>
                                        <small id="ad_image_size_hint" class="form-text text-muted" style="display:none;">
                                            {{ __('recommended_size') }}: <span class="size_value"></span> px
                                        </small>
                                        <input name="ad_image" type="file" accept="image/*" class="filepond" required>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
                @can('ad-space-list')
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('ad_spaces') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <div id="toolbar" class="toolbar-with-filter">
                                @can('ad-space-delete')
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
                                <div class="toolbar-filter">
                                    <select id="filter_platform" name="platform" class="form-control">
                                        <option value="">{{ __('select_platform') }}</option>
                                        <option value="app">{{ __('app') }}</option>
                                        <option value="web">{{ __('web') }}</option>
                                    </select>
                                </div>
                            </div>
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('adSpacesList') }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                data-sort-order="desc" data-query-params="adSpacesQueryParams">
                                <thead>
                                    <tr>
                                        @can('ad-space-delete')
                                        <th class="text-center multi-check" data-checkbox="true">
                                        @endcan
                                        <th scope="col" data-field="id" data-sortable="true" data-visible="false">
                                            {{ __('id') }}</th>
                                        <th scope="col" data-field="language">{{ __('language') }}</th>
                                        <th scope="col" data-field="page" data-formatter="pageFormatter">{{ __('page') }}</th>
                                        <th scope="col" data-field="platform" data-formatter="platformFormatter">{{ __('platform') }}</th>
                                        <th scope="col" data-field="placement" data-formatter="placementFormatter">{{ __('placement') }}</th>
                                        <th scope="col" data-field="ad_featured_section" data-visible="false">
                                            {{ __('featured_section') }}</th>
                                        <th scope="col" data-field="banner_type" data-formatter="bannerTypeFormatter">{{ __('banner_type') }}</th>
                                        <th scope="col" data-field="ad_image" data-formatter="generalImageFormatter">{{ __('banner_image') }}</th>
                                        <th scope="col" data-field="ad_url" data-sortable="true"
                                            data-visible="false"> {{ __('URL') }}</th>
                                        <th scope="col" data-field="duration_days" data-visible="false">
                                            {{ __('duration_days') }}</th>
                                        <th scope="col" data-field="end_date" data-sortable="true" data-formatter="endDateFormatter">
                                            {{ __('end_date') }}</th>
                                        <th scope="col" data-field="status" data-formatter="adSpaceStatusFormatter">{{ __('status') }}</th>
                                        <th scope="col" data-field="date" data-sortable="true" data-visible="false">
                                            {{ __('created_at') }}</th>
                                        @canany(['ad-space-edit', 'ad-space-delete'])
                                        <th scope="col" data-field="operate" data-events="adSpaceEvents">
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
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('ad_spaces') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('ad_spaces') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <input type='hidden' name="ad_image_url" id="ad_image_url" value='' />
                        <div class="card-body">
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('language') }}</label>
                                    <select id="edit_language_id" name="language_id" class="form-control language_id"
                                        required>
                                        <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $item)
                                            <option value="{{ $item->id }}">{{ $item->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('platform') }}</label>
                                    <select id="edit_platform" name="platform" class="form-control" required>
                                        <option value="">{{ __('select') . ' ' . __('platform') }}</option>
                                        @foreach (array_keys(config('ad_spaces.platforms')) as $platformKey)
                                            <option value="{{ $platformKey }}">{{ __(str_replace('_', ' ', $platformKey)) }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('page') }}</label>
                                    <select id="edit_page" name="page" class="form-control" required disabled>
                                        <option value="">{{ __('select') . ' ' . __('page') }}</option>
                                    </select>
                                    <small id="edit_page_hint" class="form-text text-muted" style="display:none;"></small>
                                </div>
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('placement') }}</label>
                                    <select id="edit_placement" name="placement" class="form-control" required disabled>
                                        <option value="">{{ __('select') . ' ' . __('placement') }}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12" id="edit_featured_section_group" style="display:none;">
                                    <label class="required">{{ __('featured_section') }}</label>
                                    <input type="hidden" name="featured_section_id" id="edit_featured_section_id_input" value="">
                                    <select id="edit_featured_section_id" class="form-control">
                                        <option value="">{{ __('select') . ' ' . __('featured_section') }}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="row" id="edit_image_upload_group" style="display:none;">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('banner_image') }}</label>
                                    <small id="edit_ad_image_size_hint" class="form-text text-muted" style="display:none;">
                                        {{ __('recommended_size') }}: <span class="size_value"></span> px
                                    </small>
                                    <input name="ad_image" type="file" accept="image/*" class="filepond">
                                     <div id="edit_image_preview_container" class="mt-2" style="">
                                        <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                        <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('banner_type') }}</label>
                                    <select id="edit_banner_type" name="banner_type" class="form-control" required>
                                        <option value="external_link">{{ __('external_link') }}</option>
                                        <option value="banner_only">{{ __('banner_only') }}</option>
                                    </select>
                                </div>
                                <div class="form-group col-md-6 col-sm-12" id="edit_ad_url_group">
                                    <label>{{ __('URL') }}</label>
                                    <input id="edit_ad_url" type="url" class="form-control" name="ad_url">
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-6 col-sm-12">
                                    <label class="required">{{ __('duration_days') }}</label>
                                    <input id="edit_duration_days" name="duration_days" type="number" class="form-control" min="1" value="1" required>
                                </div>
                                <div class="form-group col-md-6 col-sm-12">
                                    <label>{{ __('status') }}</label><br>
                                    <div id="status1" class="btn-group">
                                        <label class="btn btn-success" data-toggle-class="btn-primary"
                                            data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="status" value="1"
                                                checked>{{ __('active') }}
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
        window.getFeaturedSectionsByLanguageUrl = '{{ route('get_featured_sections_by_language') }}';
        var adSpaceConfig = @json(config('ad_spaces.platforms'));
        var pageHints = {
            news_page: 'Applied on Live-News, Breaking-News, Videos, Rss-Feed, eNews Pages'
        };

        function updatePageHint(prefix) {
            var hintEl = prefix === '' ? '#page_hint' : '#edit_page_hint';
            var pageVal = $(prefix === '' ? '#page' : '#edit_page').val();
            if (pageHints[pageVal]) {
                $(hintEl).text(pageHints[pageVal]).show();
            } else {
                $(hintEl).hide();
            }
        }
        @php
            $adSpaceLabels = ['pages' => [], 'placements' => []];
            foreach (config('ad_spaces.platforms', []) as $platformPages) {
                foreach ($platformPages as $pageKey => $placements) {
                    $adSpaceLabels['pages'][$pageKey] = __($pageKey);
                    foreach (array_keys($placements) as $placementKey) {
                        $adSpaceLabels['placements'][$placementKey] = __($placementKey);
                    }
                }
            }
        @endphp
        var adSpaceLabels = @json($adSpaceLabels);

        function adSpaceLabel(group, key) {
            return (adSpaceLabels[group] && adSpaceLabels[group][key]) || key.replace(/_/g, ' ');
        }

        // --- Helper functions ---
        function populatePageDropdown(platformVal, targetId) {
            var $page = $(targetId);
            $page.html('<option value="">{{ __("select") }} {{ __("page") }}</option>');
            if (platformVal && adSpaceConfig[platformVal]) {
                var pages = Object.keys(adSpaceConfig[platformVal]);
                pages.forEach(function(p) {
                    $page.append('<option value="' + p + '">' + adSpaceLabel('pages', p) + '</option>');
                });
                $page.prop('disabled', pages.length === 0);
            } else {
                $page.prop('disabled', true);
            }
        }

        function populatePlacementDropdown(pageVal, platformVal, targetId) {
            var $placement = $(targetId);
            $placement.html('<option value="">{{ __("select") }} {{ __("placement") }}</option>');
            var placements = (platformVal && pageVal && adSpaceConfig[platformVal] && adSpaceConfig[platformVal][pageVal])
                ? adSpaceConfig[platformVal][pageVal]
                : {};
            var keys = Object.keys(placements);
            keys.forEach(function(p) {
                $placement.append(
                    '<option value="' + p + '" data-size="' + placements[p] + '">'
                    + adSpaceLabel('placements', p) + '</option>'
                );
            });
            $placement.prop('disabled', keys.length === 0);
        }

        function toggleImageUploads(platformVal, prefix) {
            var imgGroup = prefix === '' ? '#image_upload_group' : '#edit_image_upload_group';

            if (!platformVal) {
                $(imgGroup).hide();
                return;
            }

            $(imgGroup).show();
        }

        function toggleUrlField(bannerType, prefix) {
            var urlGroup = prefix === '' ? '#ad_url_group' : '#edit_ad_url_group';
            if (bannerType === 'banner_only') {
                $(urlGroup).hide();
            } else {
                $(urlGroup).show();
            }
        }

        function toggleFeaturedSection(pageVal, prefix) {
            var groupId = prefix === '' ? '#featured_section_group' : '#edit_featured_section_group';
            if (pageVal === 'featured_section') {
                $(groupId).show();
            } else {
                $(groupId).hide();
            }
        }

        function updateSizeHint(prefix) {
            var placementSel = prefix === '' ? '#placement' : '#edit_placement';
            var hintId       = prefix === '' ? '#ad_image_size_hint' : '#edit_ad_image_size_hint';
            var size = $(placementSel).find('option:selected').data('size');
            var $hint = $(hintId);
            if (size) {
                $hint.find('.size_value').text(size);
                $hint.show();
            } else {
                $hint.hide();
            }
        }

        function loadFeaturedSections(languageId, targetSelectId, callback) {
            $.ajax({
                url: '{{ route("get_featured_sections_by_language") }}',
                type: "POST",
                data: { language_id: languageId },
                success: function(result) {
                    $(targetSelectId).html(result);
                    if (callback) callback();
                },
                error: function(errors) {
                    console.log(errors);
                },
            });
        }

        // --- Create form events ---
        $(document).on('change', '#platform', function() {
            var platformVal = $(this).val();
            populatePageDropdown(platformVal, '#page');
            $('#placement').html('<option value="">{{ __("select") }} {{ __("placement") }}</option>').prop('disabled', true);
            toggleFeaturedSection('', '');
            toggleImageUploads(platformVal, '');
            $('#ad_image_size_hint').hide();
            $('#page_hint').hide();
        });

        $(document).on('change', '#page', function() {
            var pageVal = $(this).val();
            var platformVal = $('#platform').val();
            populatePlacementDropdown(pageVal, platformVal, '#placement');
            toggleFeaturedSection(pageVal, '');
            $('#ad_image_size_hint').hide();
            updatePageHint('');

            // If featured_section and language is selected, load featured sections
            if (pageVal === 'featured_section' && $('#language_id').val()) {
                loadFeaturedSections($('#language_id').val(), '#featured_section_id');
            }
        });

        $(document).on('change', '#placement', function() {
            updateSizeHint('');
        });

        $(document).on('change', '#banner_type', function() {
            toggleUrlField($(this).val(), '');
        });

        // When featured section is selected, set the hidden input
        $(document).on('change', '#featured_section_id', function() {
            $('#featured_section_id_input').val($(this).val());
        });

        $(document).on('change', '#language_id', function() {
            if ($('#page').val() === 'featured_section') {
                loadFeaturedSections($(this).val(), '#featured_section_id');
            }
        });

        // --- Edit form events ---
        $(document).on('change', '#edit_platform', function() {
            var platformVal = $(this).val();
            populatePageDropdown(platformVal, '#edit_page');
            $('#edit_placement').html('<option value="">{{ __("select") }} {{ __("placement") }}</option>').prop('disabled', true);
            toggleFeaturedSection('', 'edit_');
            toggleImageUploads(platformVal, 'edit_');
            $('#edit_ad_image_size_hint').hide();
            $('#edit_page_hint').hide();
        });

        $(document).on('change', '#edit_page', function() {
            var pageVal = $(this).val();
            var platformVal = $('#edit_platform').val();
            populatePlacementDropdown(pageVal, platformVal, '#edit_placement');
            toggleFeaturedSection(pageVal, 'edit_');
            $('#edit_ad_image_size_hint').hide();
            updatePageHint('edit_');
        });

        $(document).on('change', '#edit_placement', function() {
            updateSizeHint('edit_');
        });

        $(document).on('change', '#edit_banner_type', function() {
            toggleUrlField($(this).val(), 'edit_');
        });

        $(document).on('change', '#edit_featured_section_id', function() {
            $('#edit_featured_section_id_input').val($(this).val());
        });

        $(document).on('change', '#edit_language_id', function() {
            if ($('#edit_page').val() === 'featured_section') {
                loadFeaturedSections($(this).val(), '#edit_featured_section_id');
            }
        });

        // --- Table filters ---
        $("#filter_language_id").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });

        $("#filter_status").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_platform").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });

        // bulk delete
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
                            url: '{{ route('bulk_ad_spaces_delete') }}',
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
                var message = '{{ __('select_data_to_delete') }}';
                showErrorToast(message);
            }
        });
    </script>
@endsection
