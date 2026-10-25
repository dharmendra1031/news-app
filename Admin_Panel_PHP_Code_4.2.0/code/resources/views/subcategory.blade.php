@extends('layouts.main')

@section('title')
    {{ __('subcategory') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('subcategory') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-cubes mr-1"></i>{{ __('subcategory') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('sub-category-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                            class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('subcategory') }}</button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('subcategory') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('sub_category.store') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="language_id" name="language" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @endif
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('category') }}</label>
                                        <select id="category_id" name="category" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                            @foreach ($categoryList as $row)
                                                <option value="{{ $row->id }}">{{ $row->category_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('name') }}</label>
                                        <input id="name" name="name" required placeholder="{{ __('name') }}"
                                            type="text" class="form-control"
                                            data-slug-table="tbl_subcategory"
                                            data-slug-target="#slug">
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('slug') }}</label><span class="">({{__('english_only')}})</span>
                                        <input id="slug" name="slug" required placeholder="{{ __('slug') }}"
                                            type="text" class="form-control">
                                        <span class="text-danger">{{ __('avoid_special_characters') }}</span>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            <div class="row">
                @can('sub-category-list')
                <div class="col-lg-8 col-md-12 col-sm-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('subcategory') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <div id="toolbar" class="toolbar-with-filter">
                                <div class="mr-3">
                                    <select id="filter_language_id" class="form-control" required>
                                        <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $row)
                                            <option value="{{ $row->id }}">{{ $row->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div>
                                    <select id="filter_category_id" class="form-control">
                                        <option value="0">{{ __('select') . ' ' . __('category') }}</option>
                                    </select>
                                </div>
                            </div>
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('subcategoryList') }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                data-buttons-class="primary" data-trim-on-search="false" data-sort-name="row_order"
                                data-sort-order="asc" data-query-params="subcategoryQueryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="language_id" data-visible="false">
                                            {{ __('language_id') }}</th>
                                        <th scope="col" data-field="language">{{ __('language') }}</th>
                                        <th scope="col" data-field="category_id" data-visible="false"
                                            data-sortable="true">{{ __('category_id') }}</th>
                                        <th scope="col" data-field="category_name">{{ __('category') }}</th>
                                        <th scope="col" data-field="subcategory_name">{{ __('name') }}</th>
                                        <th scope="col" data-field="slug" data-sortable="false" data-visible="false">{{ __('slug') }}</th>
                                        </th>
                                        <th scope="col" data-field="row_order" data-sortable="true">
                                            {{ __('row_order') }}</th>
                                        @canany(['sub-category-edit', 'sub-category-delete'])
                                            <th scope="col" data-field="operate" data-sortable="false"
                                                data-events="subCategoryEvents">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
                @endcan
                @can('sub-category-order-create')
                <div class="col-lg-4 col-md-12 col-sm-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('subcategory') . ' ' . __('order') }}</h3>
                        </div>
                        <div class="card-body">
                            <form id="order_form" action="{{ route('update_subcategory_order') }}" method="post"
                                onsubmit="return saveOrder()">
                                @csrf
                                <div class="form-group col-md-12 col-sm-12">
                                    <select id="order_language_id" class="form-control">
                                        <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $row)
                                            <option value="{{ $row->id }}">{{ $row->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="form-group col-md-12 col-sm-12">
                                    <select id="order_category_id" class="form-control">
                                        <option value="0">{{ __('select') . ' ' . __('category') }}</option>
                                    </select>
                                </div>
                                <div class="col-md-12 col-sm-12">
                                    <input id="row_order" name="row_order" required type="hidden">
                                    <ol id="sortable-row">
                                        @foreach ($subcategoryList as $row)
                                            <li id="{{ $row->id }}">{{ $row->subcategory_name }}</li>
                                        @endforeach
                                    </ol>
                                </div>
                                <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                @endcan
            </div>
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('subcategory') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('sub_category') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <input type='hidden' name="image_url" id="image_url" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('language') }}</label>
                                    <select id="edit_language_id" name="language" class="form-control" required>
                                        <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                        @foreach ($languageList as $item)
                                            <option value="{{ $item->id }}">{{ $item->language }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('category') }}</label>
                                    <select id="edit_category_id" name="category" class="form-control" required>
                                        <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('name') }}</label>
                                    <input id="edit_name" name="name" type="text" required class="form-control"
                                        placeholder="{{ __('name') }}"
                                        data-slug-table="tbl_subcategory"
                                        data-slug-target="#edit_slug"
                                        data-slug-id="#edit_id">
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('slug') }}</label><span class="">({{__('english_only')}})</span>
                                    <input id="edit_slug" name="slug" required placeholder="{{ __('slug') }}"
                                        type="text" class="form-control">
                                    <span class="text-danger">{{ __('avoid_special_characters') }}</span>
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
        $(function() {
            $("#sortable-row").sortable();
        });

        function saveOrder() {
            var selectedLanguage = new Array();
            $('ol#sortable-row li').each(function() {
                selectedLanguage.push($(this).attr("id"));
            });
            document.getElementById("row_order").value = selectedLanguage;
        }

        $(document).on('change', '#language_id', function(e) {
            var language_id = $('#language_id').val();
            var data = {
                language_id: language_id,
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#category_id');
        });

        $(document).on('change', '#filter_language_id', function(e) {
            var language_id = $('#filter_language_id').val();
            var data = {
                language_id: language_id,
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#filter_category_id');
        });

        $(document).on('change', '#order_language_id', function(e) {
            var language_id = $('#order_language_id').val();
            var data = {
                language_id: language_id,
            };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#order_category_id');

            data['sortable'] = 1;
            var url1 = '{{ route('get_subcategory_by_category') }}';
            fetchList(url1, data, '#sortable-row');
        });

        $(document).on('change', '#order_category_id', function(e) {
            var category_id = $('#order_category_id').val();
            var data = {
                category_id: category_id,
                sortable: 1
            };
            var url = '{{ route('get_subcategory_by_category') }}';
            fetchList(url, data, '#sortable-row');
        });

        $(document).on('change', '#edit_language_id', function(e, row_language, row_category) {
            var language_id = $('#edit_language_id').val();
            var data = {
                language_id: language_id,
            };
            $.ajax({
                url: '{{ route('get_category_by_language') }}',
                type: "POST",
                data: {
                    language_id: language_id,
                },
                beforeSend: function() {
                    $('#edit_category_id').html("Please wait..");
                },
                success: function(result) {
                    $('#edit_category_id').html(result);
                    if (language_id == row_language && row_category != 0) {
                        $('#edit_category_id').val(row_category);
                    }
                },
                error: function(errors) {
                    console.log(errors);
                },
            });
        });
    </script>

    {{-- Slug generation is handled globally by slug-helper.js via data-slug-* attributes --}}

    <script type="text/javascript">
        $("#filter_language_id").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_category_id").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
    </script>
@endsection
