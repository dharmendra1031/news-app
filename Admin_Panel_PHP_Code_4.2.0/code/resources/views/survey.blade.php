@extends('layouts.main')

@section('title')
    {{ __('survey') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('survey') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-poll-h mr-1"></i>{{ __('survey') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('survey-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1"><i
                                class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('survey_question') }}</button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('survey_question') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('survey.store') }}" role="form" method="POST">
                            @csrf
                            <div class="card-body clearfix">
                                <div class="row">
                                    <div class="form-group col-lg-6 col-md-12 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select name="language" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @endif
                                            @foreach ($languageList as $item)
                                                <option value="{{ $item->id }}">{{ $item->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-lg-6 col-md-12 col-sm-12">
                                        <label class="required">{{ __('question') }}</label>
                                        <textarea name="question" class="form-control" placeholder="{{ __('question') }}"
                                            required></textarea>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12 repeater">
                                        <div data-repeater-list="options">
                                            <div data-repeater-item class="row">
                                                <div class="col-sm-12 col-md-11 mb-1">
                                                    <label class="required">{{ __('option') }}</label>
                                                    <input type="text" name="option" class="form-control"
                                                        placeholder="{{ __('option') }}" required>
                                                </div>
                                                <div class="col-sm-12 col-md-1 text-center mt-4">
                                                    <button type="button" class="btn btn-danger" data-repeater-delete>
                                                        <i class="fas fa-window-close"></i>
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="form-group overflow-hidden">
                                            <button type="button" data-repeater-create class="btn btn-primary">
                                                <i class="fa fa-plus"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <button type="submit"
                                    class="btn btn-primary float-right">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
                @can('survey-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('survey_question') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    @can('survey-bulk-delete')
                                        <button class="btn bg-primary text-white" type="submit"
                                            id="bulk_order_update">{{ __('bulk_delete') }}</button>
                                    @endcan
                                    <div class="toolbar-filter">
                                        <select id="filter_language_id" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="toolbar-filter">
                                        <select id="filter_status" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('surveyQuestionList') }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                    data-sort-order="desc" data-query-params="surveyParams">
                                    <thead>
                                        <tr>
                                            <th class="text-center multi-check" data-checkbox="true">
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="language_name">{{ __('language') }}</th>
                                            <th scope="col" data-field="question">{{ __('question') }}</th>
                                            <th scope="col" data-field="status_badge">{{ __('status') }}</th>
                                            <th scope="col" data-field="counter">{{ __('total') }}</th>
                                            @canany(['survey-view', 'survey-edit', 'survey-delete'])
                                                <th scope="col" data-field="operate" data-events="surveyEvents">
                                                    {{ __('operate') }}
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
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('survey_question') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="update_form" action="{{ url('survey') }}" role="form" method="POST"
                        enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
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
                                    <label class="required">{{ __('question') }}</label>
                                    <input id="question" name="question" type="text" class="form-control"
                                        placeholder="{{ __('question') }}" required>
                                </div>
                            </div>
                            <div class="form-group row">
                                <div class="col-sm-12">
                                    <label class="required">{{ __('status') }}</label><br>
                                    <div id="status" class="btn-group">
                                        <label class="btn btn-success" data-toggle-class="btn-primary"
                                            data-toggle-passive-class="btn-default">
                                            <input type="radio" name="status" value="1"> {{ __('active') }}
                                        </label>
                                        <label class="btn btn-danger" data-toggle-class="btn-primary"
                                            data-toggle-passive-class="btn-default">
                                            <input type="radio" name="status" value="0"> {{ __('deactive') }}
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

@section('js')
    <script src="{{ url('assets/custom/js/jquery.repeater.min.js') }}" type="text/javascript"></script>
@endsection

@section('script')
    <script type="text/javascript">
        $('.repeater').repeater({
            show: function () {
                $(this).slideDown();
            },
            hide: function (deleteElement) {
                $(this).slideUp(deleteElement);
            },
            isFirstItemUndeletable: true
        });
    </script>

    <script type="text/javascript">
        $("#filter_language_id").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $("#filter_status").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
    </script>

    <script type="text/javascript">
        $('#bulk_order_update').click(function () {
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
                            url: '{{ url('bulk_survey_delete') }}',
                            data: {
                                request_ids: request_ids
                            },
                            type: 'post',
                            success: function (response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message)
                                    $('#table').bootstrapTable('refresh');
                                } else {
                                    showErrorToast(response.message);
                                }
                            },
                            error: function (response) {
                                showToastMessage(response.message, "error");
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