@extends('layouts.main')

@section('title')
    {{ __('rss_fees') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('rss_fees') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i
                                class="nav-icon fas fa-newspaper mr-1"></i>{{ __('rss_fees') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('rss-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('rss_fees') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('rss_fees') }}</h3>
                        </div>
                        <div class="card-body">
                            <form id="create_form" action="{{ url('rss') }}" role="form" method="POST"
                                enctype="multipart/form-data">
                                @csrf
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="language_id" name="language" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}
                                                </option>
                                            @endif
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}
                                                </option>
                                            @endforeach
                                        </select>
                                    </div>
                                    @if (is_category_enabled() == 1)
                                        <div class="form-group col-md-4 col-sm-12">
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
                                        @if (is_subcategory_enabled() == 1)
                                            <div class="form-group col-md-4 col-sm-12">
                                                <label>{{ __('subcategory') }}</label>
                                                <select id="subcategory_id" name="subcategory_id" class="form-control">
                                                    <option value="">{{ __('select') . ' ' . __('subcategory') }}
                                                    </option>
                                                </select>
                                            </div>
                                        @endif
                                    @endif
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('feed_name') }}</label>
                                        <input name="feed_name" required type="text" placeholder="{{ __('feed_name') }}"
                                            class="form-control">
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('feed_url') }}</label>
                                        <input name="feed_url" required type="url" placeholder="{{ __('feed_url') }}"
                                            class="form-control">
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label for="rss_feed_tagify">{{ __('tag') }}</label>

                                        <input id="rss_feed_tagify" name="tag_id" class="form-control h-auto"
                                            placeholder="{{ __('select_or_type_tag') }}" value="">

                                        {{-- <select id="tag_id" name="tag_id[]"
                                            class="form-control select2 select2-multiple" multiple="multiple">
                                            @foreach ($tagList as $row)
                                            <option value="{{ $row->id }}">{{ $row->tag_name }}
                                            </option>
                                            @endforeach
                                        </select> --}}
                                    </div>
                                </div>
                                <div class="d-flex col-12 justify-content-end p-0">
                                    <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
                @can('rss-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('rss_fees') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    @can('rss-bulk-delete')
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
                                    <div class="toolbar-filter">
                                        <select id="filter_status" class="form-control">

                                            <option value="">{{ __('select') . ' ' . __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('rssList') }}" data-click-to-select="true" data-side-pagination="server"
                                    data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true"
                                    data-unique-id="id" data-show-columns="true" data-show-refresh="true"
                                    data-toolbar="#toolbar" data-mobile-responsive="true" data-buttons-class="primary"
                                    data-trim-on-search="false" data-sort-name="id" data-sort-order="desc"
                                    data-query-params="rssQueryParams">
                                    <thead>
                                        <tr>
                                            <th class="text-center multi-check" data-checkbox="true">
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="language_id" data-sortable="true" data-visible="false">
                                                {{ __('language_id') }}
                                            </th>
                                            <th scope="col" data-field="language_name">{{ __('language') }} </th>
                                            @if (is_category_enabled() == 1)
                                                <th scope="col" data-field="category_id" data-sortable="true" data-visible="false">
                                                    {{ __('category_id') }}
                                                </th>
                                                <th scope="col" data-field="category_name">{{ __('category') }}</th>
                                            @endif
                                            @if (is_subcategory_enabled() == 1)
                                                <th scope="col" data-field="subcategory_id" data-visible="false">
                                                    {{ __('subcategory_id') }}
                                                </th>
                                                <th scope="col" data-field="subcategory_name" data-visible="false">
                                                    {{ __('subcategory') }}
                                                </th>
                                            @endif
                                            <th scope="col" data-field="feed_name" data-sortable="true">{{ __('feed_name') }}</th>
                                            <th scope="col" data-field="feed_url">{{ __('feed_url') }}</th>
                                            {{-- crawled feeds counts --}}
                                            <th scope="col" data-field="crawled_feeds_counts" data-align="center" data-formatter="crawledFeedsCountsFormatter">{{ __('crawled_feeds_counts') }}</th>
                                            <th scope="col" data-field="crawl_feed" data-visible="true">{{ __('crawl_feed') }}</th>
                                            <th scope="col" data-field="status_badge">{{ __('status') }}</th>
                                            <th scope="col" data-field="tag_id" data-visible="false">{{ __('tag_id') }}</th>
                                            <th scope="col" data-field="tag_name" data-visible="false">{{ __('tags') }}</th>
                                            <th scope="col" data-field="created_at" data-visible="false">{{ __('created_at') }}</th>
                                            @canany(['rss-edit', 'rss-delete'])
                                                <th scope="col" data-field="operate" data-events="rssEvents">{{ __('operate') }}
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
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('rss_fees') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('rss') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="form-group col-md-4 col-sm-12">
                                    <label class="required">{{ __('language') }}</label>
                                    <select id="edit_language_id" name="language" class="form-control" required>
                                        <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $row)
                                            <option value="{{ $row->id }}">{{ $row->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                @if (is_category_enabled() == 1)
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('category') }}</label>
                                        <select id="edit_category_id" name="category_id" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                        </select>
                                    </div>
                                    @if (is_subcategory_enabled() == 1)
                                        <div class="form-group col-md-4 col-sm-12">
                                            <label>{{ __('subcategory') }}</label>
                                            <select id="edit_subcategory_id" name="subcategory_id" class="form-control">
                                                <option value="">{{ __('select') . ' ' . __('subcategory') }}
                                                </option>
                                            </select>
                                        </div>
                                    @endif
                                @endif
                                <div class="form-group col-md-4 col-sm-12">
                                    <label class="required">{{ __('feed_name') }}</label>
                                    <input id="edit_feed_name" name="feed_name" type="text" class="form-control" required>
                                </div>
                                <div class="form-group col-md-4 col-sm-12">
                                    <label class="required">{{ __('feed_url') }}</label>
                                    <input id="edit_feed_url" name="feed_url" type="text" class="form-control"
                                        placeholder="{{ __('feed_url') }}" required>
                                </div>
                                <div class="form-group col-md-4 col-sm-12">
                                    <label for="edit_rss_tagify">{{ __('tag') }}</label>
                                    <input id="edit_rss_tagify" name="tag_id" class="form-control h-auto"
                                        placeholder="{{ __('select_or_type_tag') }}" value="">

                                    {{-- <select id="edit_tag_id" name="tag_id[]"
                                        class="form-control select2 select2-multiple" multiple="multiple">
                                    </select> --}}
                                </div>
                                <div class="form-group col-md-4 col-sm-12">
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
        $(document).on('change', '#language_id', function (e) {
            var data = {
                language_id: $('#language_id').val(),
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#category_id');

            // var url1 = '{{ route('get_tag_by_language') }}';
            // fetchList(url1, data, '#tag_id');

            // Clear all selected tags when language changes
            if (typeof window.RSSFeedTagCustomListSuggestion !== 'undefined' && window.RSSFeedTagCustomListSuggestion) {
                // Try multiple methods to ensure tags are cleared
                try {
                    // Method 1: Try removeAllTags if available
                    if (typeof window.RSSFeedTagCustomListSuggestion.removeAllTags === 'function') {
                        window.RSSFeedTagCustomListSuggestion.removeAllTags();
                    } else {
                        // Method 2: Set value to empty and update
                        window.RSSFeedTagCustomListSuggestion.value = [];
                    }
                } catch (e) {
                    // Method 3: Fallback - set value directly and remove DOM elements
                    try {
                        window.RSSFeedTagCustomListSuggestion.value = [];
                        if (window.RSSFeedTagCustomListSuggestion.removeTagsFromDOM) {
                            window.RSSFeedTagCustomListSuggestion.removeTagsFromDOM();
                        }
                        // window.RSSFeedTagCustomListSuggestion.update();
                    } catch (err) {
                        console.log('Error clearing tags:', err);
                    }
                }
            }
            // $('#tag_id').val(null).trigger('change');
            // var url1 = '{{ route('get_tag_by_language') }}';
            // fetchList(url1, data, '#tag_id');
            var url1 = '{{ route('get_tag_by_language') }}';
            $.ajax({
                url: url1,
                type: 'POST',
                data: data,
                success: function (result) {
                    // Parse the HTML options and extract tag data
                    var $temp = $('<div>').html(result);
                    var tags = [];
                    $temp.find('option').each(function () {
                        var $option = $(this);
                        tags.push({
                            value: $option.data('text'),
                            id: $option.val(),
                            // text: $option.data('text')
                        });
                    });

                    // Update Tagify whitelist
                    if (typeof RSSFeedTagCustomListSuggestion !== 'undefined' && RSSFeedTagCustomListSuggestion) {
                        RSSFeedTagCustomListSuggestion.settings.whitelist = tags;
                        // RSSFeedTagCustomListSuggestion.dropdown.show.call(RSSFeedTagCustomListSuggestion);
                    }
                },
                error: function (errors) {
                    console.log('Error fetching tags:', errors);
                    // Clear whitelist on error
                    if (typeof window.RSSFeedTagCustomListSuggestion !== 'undefined' && window.RSSFeedTagCustomListSuggestion) {
                        window.RSSFeedTagCustomListSuggestion.settings.whitelist = [];
                    }
                }
            });
        });

        $(document).on('change', '#category_id', function (e) {
            var data = {
                category_id: $('#category_id').val(),
            };
            var url = '{{ route('get_subcategory_by_category') }}';
            fetchList(url, data, '#subcategory_id');
        });

        $(document).on('change', '#edit_language_id', function (e, row_language_id, row_category_id, row_subcategory_id,
            row_tag_id) {
            console.log(row_tag_id);

            var language_id = $('#edit_language_id').val();
            $.ajax({
                url: '{{ route('get_category_by_language') }}',
                type: "POST",
                data: {
                    language_id: language_id,
                },
                beforeSend: function () {
                    $('#edit_category_id').html("Please wait..");
                },
                success: function (result) {
                    $('#edit_category_id').html(result);
                    if (language_id == row_language_id && row_category_id != 0) {
                        $('#edit_category_id').val(row_category_id).trigger('change', [row_category_id,
                            row_subcategory_id
                        ]);
                    }
                },
                error: function (errors) {
                    console.log(errors);
                },
            });

            // Clear all selected tags when language changes
            if (typeof window.editRSSFeedTagCustomListSuggestion !== 'undefined' && window.editRSSFeedTagCustomListSuggestion) {
                // Try multiple methods to ensure tags are cleared
                try {
                    // Method 1: Try removeAllTags if available
                    if (typeof window.editRSSFeedTagCustomListSuggestion.removeAllTags === 'function') {
                        window.editRSSFeedTagCustomListSuggestion.removeAllTags();
                    } else {
                        // Method 2: Set value to empty and update
                        window.editRSSFeedTagCustomListSuggestion.value = [];
                    }
                } catch (e) {
                    // Method 3: Fallback - set value directly and remove DOM elements
                    try {
                        window.editRSSFeedTagCustomListSuggestion.value = [];
                        if (window.editRSSFeedTagCustomListSuggestion.removeTagsFromDOM) {
                            window.editRSSFeedTagCustomListSuggestion.removeTagsFromDOM();
                        }
                        // window.editRSSFeedTagCustomListSuggestion.update();
                    } catch (err) {
                        console.log('Error clearing tags:', err);
                    }
                }
            }

            // console.log(selectedTags);

            $.ajax({
                url: '{{ route('get_tag_by_language') }}',
                type: "POST",
                data: {
                    language_id: language_id,
                },
                beforeSend: function () {
                    $('#edit_rss_tagify').html("Please wait..");
                },
                success: function (result) {
                    // $('#edit_tag_id').html(result).trigger("change");
                    // if (language_id == row_language_id && row_tag_id != '') {
                    //     var valueArray = row_tag_id;
                    //     var arrayArea = valueArray.split(',');
                    //     $("#edit_tag_id").val(arrayArea).trigger("change");
                    // }

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

                    $temp.find('option').each(function () {
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
                            console.log(tagObj);

                            selectedTags.push(tagObj);
                        }


                        // Update Tagify whitelist
                        if (typeof editRSSFeedTagCustomListSuggestion !== 'undefined' && editRSSFeedTagCustomListSuggestion) {

                            editRSSFeedTagCustomListSuggestion.removeAllTags();

                            editRSSFeedTagCustomListSuggestion.settings.whitelist = tags;
                            // console.log(editRSSFeedTagCustomListSuggestion.settings);

                            // Add selected tags if any match
                            if (selectedTags.length > 0) {
                                editRSSFeedTagCustomListSuggestion.addTags(selectedTags);
                            }
                            // editRSSFeedTagCustomListSuggestion.dropdown.show.call(editRSSFeedTagCustomListSuggestion);
                        }
                    });
                },
                error: function (errors) {
                    console.log(errors);
                },
            });
        });

        $(document).on('change', '#edit_category_id', function (e, row_category_id, row_subcategory_id) {
            var category_id = $('#edit_category_id').val();
            $.ajax({
                url: '{{ route('get_subcategory_by_category') }}',
                type: "POST",
                data: {
                    category_id: category_id,
                },
                beforeSend: function () {
                    $('#edit_subcategory_id').html("Please wait..");
                },
                success: function (result) {
                    $('#edit_subcategory_id').html(result);
                    if (category_id == row_category_id && row_subcategory_id != 0) {
                        $('#edit_subcategory_id').val(row_subcategory_id);
                    }
                },
                error: function (errors) {
                    console.log(errors);
                },
            });
        });
    </script>

    <script type="text/javascript">
        $(document).on('change', '#filter_language_id', function () {
            $('#table').bootstrapTable('refresh');
            var data = {
                language_id: $('#filter_language_id').val(),
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#filter_category_id');
        });
        $(document).on('change', '#filter_category_id', function () {
            $('#table').bootstrapTable('refresh');
            var data = {
                category_id: $('#filter_category_id').val(),
            };
            var url = '{{ route('get_subcategory_by_category') }}';
            fetchList(url, data, '#filter_subcategory_id');
        });
        $(document).on('change', '#filter_subcategory_id', function () {
            $('#table').bootstrapTable('refresh');
        });
        $(document).on('change', '#filter_status', function () {
            $('#table').bootstrapTable('refresh');
        });
    </script>

    <script type="text/javascript">
        var crawlAgainIn = '{{ __("crawl_again_in") }}';
        var minLabel = '{{ __("min") }}';

        $('#bulk_delete').click(function () {
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
                            url: '{{ url('bulk_rss_delete') }}',
                            data: {
                                request_ids: request_ids
                            },
                            success: function (response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message);
                                    $('#table').bootstrapTable('refresh');
                                } else {
                                    showErrorToast(response.message);
                                }
                            },
                            error: function (response) {
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
        $(document).on('click', '.crawl-feed-btn', function(e) {
            e.preventDefault();

            let btn = $(this);
            let href = btn.attr('href');

            btn.hide();
            let cooldownEnds = Math.floor(Date.now() / 1000) + (10 * 60);
            let cooldownIso = new Date(cooldownEnds * 1000).toISOString();
            
            // Insert label BEFORE the button, so button remains sibling
            btn.before('<span class="badge badge-success crawled-label" data-cooldown-ends="' + cooldownEnds + '" data-cooldown-iso="' + cooldownIso + '">' + crawlAgainIn + ' 10 ' + minLabel + '</span>');

            // Start timer for this new label
            startSingleTimer(btn.prev('.crawled-label'));

            $.ajax({
                url: href,
                type: 'GET',
                success: function(response) {
                    showSuccessToast(response.message);
                },
                error: function(xhr) {
                    showErrorToast(xhr.responseJSON?.message || 'Something went wrong');
                    let $label = btn.siblings('.crawled-label');
                    if ($label.length) {
                        clearInterval($label.data('timer-interval'));
                        $label.remove();
                    }
                    btn.show();
                }
            });
        });

        function getCooldownEndMs($label) {
            let iso = $label.data('cooldown-iso');
            if (iso) {
                let parsed = Date.parse(iso);
                if (!isNaN(parsed)) return parsed;
            }

            let ts = parseInt($label.data('cooldown-ends'));
            if (!isNaN(ts)) {
                return ts < 946684800000 ? ts * 1000 : ts;
            }

            return Date.now() + (10 * 60000);
        }

        function startSingleTimer($label) {
            if (!$label.length) return;

            // Find the associated button (sibling, not in cell)
            let $btn = $label.siblings('.crawl-feed-btn');

            // Clear any existing interval on this label
            let existingInterval = $label.data('timer-interval');
            if (existingInterval) clearInterval(existingInterval);

            function update() {
                let cooldownEndsMs = getCooldownEndMs($label);
                let now = Date.now();
                let remainingMs = cooldownEndsMs - now;

                if (isNaN(remainingMs) || !isFinite(remainingMs)) {
                    $label.remove();
                    $btn.show();
                    return;
                }

                let remainingMin = Math.ceil(remainingMs / 60000);

                if (remainingMin <= 0) {
                    // Expired - remove label, show button
                    let interval = $label.data('timer-interval');
                    if (interval) clearInterval(interval);
                    $label.remove();
                    $btn.show();
                    return;
                }

                $label.text(crawlAgainIn + ' ' + remainingMin + ' ' + minLabel);
            }

            // Run immediately
            update();

            // Then every 5 seconds
            let interval = setInterval(update, 5000);
            $label.data('timer-interval', interval);
        }

        function startCooldownTimers() {
            $('.crawled-label').each(function() {
                startSingleTimer($(this));
            });
        }

        $('#table').on('load-success.bs.table', function() {
            startCooldownTimers();
        });

        $(document).ready(function() {
            startCooldownTimers();
        });

        // Handle visibility change - browser tab inactive/idle
        $(document).on('visibilitychange', function() {
            if (!document.hidden) {
                // Tab became visible again - recalculate all timers
                startCooldownTimers();
            }
        });
    </script>
@endsection
