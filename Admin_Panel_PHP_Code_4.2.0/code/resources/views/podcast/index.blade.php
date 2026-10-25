@extends('layouts.main')
@section('title')
    {{ __('podcast') }}
@endsection
@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('podcast') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-podcast mr-1"></i>{{ __('podcast') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('podcast-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1">
                            <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('podcast') }}</button>
                    </div>
                @endcan
                @include('podcast.create')
                @can('podcast-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('podcast') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    <div class="toolbar-filter">
                                        <select id="filter_status" name="status" class="form-control">
                                            <option value="">{{ __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>

                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('podcast.show', 1) }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-unique-id="id"
                                    data-show-columns="true" data-show-refresh="true" data-toolbar="#toolbar"
                                    data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false"
                                    data-sort-name="id" data-sort-order="desc" data-query-params="podcastQueryParams">
                                    <thead>
                                        <tr>
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="title" data-sortable="false"
                                                data-formatter="textFormatter">
                                                {{ __('title') }}
                                            <th scope="col" data-field="slug" data-sortable="false" data-visible="false"
                                                data-formatter="textFormatter">
                                                {{ __('slug') }}
                                            </th>
                                            <th scope="col" data-field="user_name">{{ __('author') }}</th>
                                            <th scope="col" data-field="description" data-formatter="descriptionFormatter">
                                                {{ __('description') }}
                                            </th>
                                            <th scope="col" data-field="image" data-formatter="generalImageFormatter">
                                                {{ __('image') }}
                                            </th>
                                            <th scope="col" data-field="draft" data-sortable="false"
                                                data-formatter="isDraftNewsFormatter">
                                                {{ __('is_draft') }}
                                            </th>
                                            <th scope="col" data-field="status" data-sortable="true"
                                                data-formatter="videoShortStatusFormatter">
                                                {{ __('status') }}
                                            </th>
                                            <th scope="col" data-field="published_at" data-sortable="false"
                                                data-formatter="publishDateFormatter">
                                                {{ __('published_date') }}
                                            </th>
                                            <th scope="col" data-field="episodes" data-sortable="false">
                                                {{ __('episodes') }}
                                            </th>
                                            <th scope="col" data-field="meta_title" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_title') }}
                                            </th>
                                            <th scope="col" data-field="meta_description" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_description') }}
                                            </th>
                                            <th scope="col" data-field="meta_keyword" data-formatter="descriptionFormatter" data-visible="false">
                                                {{ __('meta_keywords') }}
                                            </th>
                                            <th scope="col" data-field="schema_markup" data-visible="false">
                                                {{ __('schema_markup') }}
                                            </th>
                                            <th scope="col" data-field="operate" data-events ="podcastEvents">
                                                {{ __('operate') }}
                                            </th>
                                        </tr>
                                </table>
                            </div>
                        </div>
                    </div>
                @endcan
            </div>
        </div>
    </section>
    @include('podcast.editModal')
@endsection
@section('script')
    <script>
        $(document).on('change', '#filter_status', function() {

            $('#table').bootstrapTable('refresh');
        });

        $(document).ready(function() {
            $('#filter_status').val('');

        });
    </script>

    <script>

        var elems = Array.prototype.slice.call(
            document.querySelectorAll(".status-switch")
        );

        elems.forEach(function(elem) {
            new Switchery(elem, {
                size: "small",
                color: "#47C363",
                secondaryColor: "#EB4141",
                jackColor: "#ffff",
                jackSecondaryColor: "#ffff",
            });
        });
        var draft_switch = document.querySelector('#draft_switch');
        if (draft_switch) {
            draft_switch.onchange = function() {
                if (draft_switch.checked) {
                    $('input[name="is_draft"]').first().val(1);
                } else {
                    $('input[name="is_draft"]').first().val(0);
                }
            };
        }
    </script>
@endsection
