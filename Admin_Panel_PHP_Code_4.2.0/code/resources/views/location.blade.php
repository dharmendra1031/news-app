@extends('layouts.main')

@section('title')
    {{ __('location') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('location') }}</h1>
                    @if (getSettingMode('location_news_mode') == 0)
                        <label class="badge badge-danger">{{ __('disabled') }}</label>
                    @endif
                </div>

                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-map-marker mr-1"></i>{{ __('location') }}</li>
                    </ol>
                </div>

            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('location-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('location') }}</button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('location') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('location.store') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('location') }}</label>
                                        <input type="text" name="name" class="form-control" placeholder="{{ __('location') }}" required>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('latitude') }}</label>
                                        <input type="text" name="latitude" class="form-control" placeholder="{{ __('latitude') }}" required>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('longitude') }}</label>
                                        <input type="text" name="longitude" class="form-control" placeholder="{{ __('longitude') }}" required>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12 col-sm-12">
                                        <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                @can('location-list')
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('location') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <table aria-describedby="mydesc" id='table' data-toggle="table" data-url="{{ route('locationList') }}" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id" data-sort-order="desc" data-query-params="locationParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="location_name" data-sortable="true">{{ __('name') }}</th>
                                        <th scope="col" data-field="latitude" data-sortable="true">{{ __('latitude') }}</th>
                                        <th scope="col" data-field="longitude" data-sortable="true">{{ __('longitude') }}</th>
                                        @canany(['location-edit', 'location-delete'])
                                        <th scope="col" data-field="operate" data-events="locationEvents">{{ __('operate') }}</th>
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
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('location') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('location') }}" role="form" method="POST" enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('location') }}</label>
                                    <input type="text" name="name" id="name" class="form-control" placeholder="{{ __('location') }}" required>
                                </div>
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('latitude') }}</label>
                                    <input type="text" name="latitude" id="latitude" class="form-control" placeholder="{{ __('latitude') }}" required>
                                </div>
                                <div class="form-group col-md-12 col-sm-12">
                                    <label class="required">{{ __('longitude') }}</label>
                                    <input type="text" name="longitude" id="longitude" class="form-control" placeholder="{{ __('longitude') }} " required>
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

@endsection
