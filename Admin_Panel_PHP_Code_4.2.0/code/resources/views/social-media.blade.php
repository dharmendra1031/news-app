@extends('layouts.main')

@section('title')
    {{ __('social_media') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('social_media') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('system-settings') }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-cube mr-1"></i>{{ __('social_media') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('social-media-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                            class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('social_media') }}</button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('social_media') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('social-media.store') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('link') }}</label>
                                        <input name="link" type="url" required placeholder="{{ __('link') }}"
                                            class="form-control">
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('image') }} </label>
                                        <input name="file" type="file" class="filepond" required>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-12 text-right">
                                        <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            @can('social-media-list')
            <div class="row">
                <div class="col-lg-12 col-md-12 col-sm-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('social_media') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('socialMediaList') }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                data-buttons-class="primary" data-trim-on-search="false" data-sort-name="row_order"
                                data-sort-order="asc" data-query-params="socialMediaQueryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="image">{{ __('image') }}</th>
                                        <th scope="col" data-field="link">{{ __('link') }}</th>
                                        @canany(['social-media-edit', 'social-media-delete'])
                                        <th scope="col" data-field="operate" data-events="socialMediaEvents">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            @endcan
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('social_media') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('social-media') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('link') }}</label>
                                    <input id="edit_link" name="link" type="url" required
                                        placeholder="{{ __('link') }}" class="form-control">
                                </div>
                            </div>
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label>{{ __('image') }} </label>
                                    <input name="file" type="file" class="filepond">
                                    <div id="edit_image_preview_container" class="mt-2" style="">
                                      <label class="d-block small text-muted">{{ __('current_image') }}</label>
                                      <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
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
        $(function() {
            $("#sortable-row").sortable();
        });

        function saveOrder() {
            var selectedData = new Array();
            $('ol#sortable-row li').each(function() {
                selectedData.push($(this).attr("id"));
            });
            document.getElementById("row_order").value = selectedData;
        };
    </script>

@endsection
