@extends('layouts.main')

@section('title')
    {{ __('language') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('language') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ 'system-settings' }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="fas fas fa-language mr-1"></i>{{ __('language') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('language-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('language') }}</button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('language') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('language.store') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <input name="language" class="form-control" required>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('display_in_app_web') }}</label>
                                        <input name="display_name" class="form-control" placeholder="{{__("example:english")}}" required>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('code') }}</label>
                                        <input id="code" name="code" class="form-control" placeholder="{{__("example:en")}}" required>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <div class="form-check">
                                            <label>{{ __('is_rtl') }}</label>
                                            <div>
                                                <input type="checkbox" id="is_rtl_switch" name="is_rtl_switch" class="status-switch">
                                                <input type="hidden" id="isRTL" name="isRTL" value="0">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('flag_image') }}</label>
                                        <input name="flag" type="file" accept="image/*" class="filepond" required>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('app') . ' ' . __('json_file') }}</label>
                                        <input name="app_json" type="file" accept="application/json" class="filepond-json logo" required>
                                        <a class="btn btn-info form-control" href="{{ url('download-app-json') }}">{{ __('download_sample_file') }}</a>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('web') . ' ' . __('json_file') }}</label>
                                        <input name="web_json" type="file" accept="application/json" class="filepond-json logo" required>
                                        <a class="btn btn-info form-control" href="{{ url('download-web-json') }}">{{ __('download_sample_file') }}</a>
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label class="required">{{ __('admin_panel') . ' ' . __('json_file') }}</label>
                                        <input name="admin_json" type="file" accept="application/json" class="filepond-json logo" id="" required>
                                        <a class="btn btn-info form-control" href="{{ url('download-panel-json/en') }}">{{ __('download_sample_file') }}</a>
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
                @can('language-list')
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('language') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <table aria-describedby="mydesc" id='table' data-toggle="table" data-url="{{ route('languageList') }}" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false" data-sort-name="status" data-sort-order="desc"
                                data-query-params="languageParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="language" data-sortable="true">{{ __('language') }}</th>
                                        <th scope="col" data-field="display_name">{{ __('display_name') }}</th>
                                        <th scope="col" data-field="code">{{ __('code') }}</th>
                                        <th scope="col" data-field="image">{{ __('flag_image') }}</th>
                                        <th scope="col" data-field="default1">{{ __('default') }}</th>
                                        <th scope="col" data-field="isRTL">{{ __('is_rtl') }}</th>
                                        <th scope="col" data-field="status1">{{ __('status') }}</th>
                                        <th scope="col" data-field="app_json" data-align="center">{{ __('app') . ' ' . __('json_file') }}</th>
                                        <th scope="col" data-field="web_json" data-align="center">{{ __('web') . ' ' . __('json_file') }}</th>
                                        <th scope="col" data-field="panel_json" data-align="center">{{ __('admin_panel') . ' ' . __('json_file') }}</th>
                                        @canany(['language-edit', 'language-delete'])
                                        <th scope="col" data-field="operate" data-events="languageEvents">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
                @endcan
                <div class="modal fade " id="editDataModal">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h4 class="modal-title">{{ __('edit') . ' ' . __('language') }}</h4>
                                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                    <span aria-hidden="true">&times;</span>
                                </button>
                            </div>
                            <form id="update_form" action="{{ url('language') }}" role="form" method="POST" enctype="multipart/form-data">
                                @csrf
                                <input type='hidden' name="edit_id" id="edit_id" value='' />
                                <div class="modal-body">
                                    <div class="row">
                                        <div class="form-group col-sm-12 col-md-6">
                                            <label class="required">{{ __('language') }}</label>
                                            <input id="edit_language" name="language" class="form-control" required>
                                        </div>
                                        <div class="form-group col-sm-12 col-md-6">
                                            <label class="required">{{ __('display_in_app_web') }}</label>
                                            <input id="edit_display_name" name="display_name" class="form-control">
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="form-group col-sm-12 col-md-6">
                                            <label class="required">{{ __('code') }}</label>
                                            <input id="edit_code" name="code" class="form-control" required>
                                        </div>
                                        <div class="form-group col-sm-12 col-md-6">
                                            <label>{{ __('is_rtl') }}</label>
                                            <div>
                                                <input type="checkbox" id="edit_isRTL" name="is_rtl_switch" class="status-switch editInModel">
                                                <input type="hidden" id="isRTLedit" name="isRTL" value="0">
                                            </div>
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="form-group col-sm-12 col-md-4">
                                            <label>{{ __('app') . ' ' . __('json_file') }}</label>
                                            <input name="edit_app_json" type="file" accept="application/json" class="filepond-json logo">
                                        </div>
                                        <div class="form-group col-sm-12 col-md-4">
                                            <label>{{ __('web') . ' ' . __('json_file') }}</label>
                                            <input name="edit_web_json" type="file" accept="application/json" class="filepond-json logo">
                                        </div>
                                        <div class="form-group col-sm-12 col-md-4">
                                            <label>{{ __('admin_panel') . ' ' . __('json_file') }}</label>
                                            <input name="edit_json_admin" type="file" accept="application/json" class="filepond-json logo">
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="form-group col-sm-12 col-md-6">
                                            <label>{{ __('flag_image') }}</label>
                                            <input name="flag" type="file" accept="image/*" class="filepond">
                                            <div id="edit_image_preview_container" class="mt-2" style="">
                                                <label class="d-block small text-muted">{{ __('current_flag_image') }}</label>
                                                <img id="edit_image_preview" src="" alt="Current Image" class="img-thumbnail" style="max-height: 100px;">
                                            </div>
                                            <p style="display:none" id="img_error_msg_edit" class="alert alert-danger">
                                            </p>
                                        </div>
                                        <div id="is_default" class="form-group col-sm-12 col-md-6">
                                            <label>{{ __('status') }}</label><br>
                                            <div id="status1" class="btn-group">
                                                <label class="btn btn-success" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                                    <input type="radio" name="status" value="1">{{ __('active') }}
                                                </label>
                                                <label class="btn btn-danger" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
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
            </div>
        </div>
    </section>
@endsection

@section('script')
    <script type="text/javascript">
        $(document).ready(function(e) {
            var elems = Array.prototype.slice.call(
                document.querySelectorAll(".status-switch")
            );
            elems.forEach(function(elem) {
                var switchery = new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
            });
        });
        var is_rtl_switch = document.querySelector('#is_rtl_switch');
        is_rtl_switch.onchange = function() {
            if (is_rtl_switch.checked) {
                $('#is_rtl').val(1);
            } else {
                $('#is_rtl').val(0);
            }
        };
        var _URL = window.URL || window.webkitURL;
        var isRTL = document.querySelector('#isRTL');
        isRTL.onchange = function() {
            if (isRTL.checked)
                $('#isRTL').val(1);
            else
                $('#isRTL').val(0);
        };
    </script>

    <script type="text/javascript">
        $(document).on('click', '.store_default_language', function() {
            var id = $(this).data("id");
            $.ajax({
                url: '{{ url('store_default_language') }}',
                type: "POST",
                dataType: "json",
                data: {
                    id: id
                },
                success: function(result) {
                    if (result) {
                        Swal.fire({
                            toast: true,
                            icon: "success",
                            title: result.message,
                            position: "top-end",
                            showConfirmButton: false,
                            timer: 3000,
                            timerProgressBar: true,
                            didOpen: (toast) => {
                                toast.addEventListener("mouseenter", Swal.stopTimer);
                                toast.addEventListener("mouseleave", Swal.resumeTimer);
                            },
                        });
                        $("#table").bootstrapTable("refresh");
                        setTimeout(() => {
                            location.reload();
                        }, 3000);
                    }
                }
            });
        });
    </script>
@endsection
