@extends('layouts.main')

@section('title')
    {{ __('survey_option') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . '' . __('survey_option') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item">
                            <a href="{{ url('survey') }}" class="text-dark"><i class="nav-icon fas fa-poll-h mr-1"></i>{{ __('survey') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-poll-h mr-1"></i>{{ __('survey_option') }}</li>
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
                            <h3 class="card-title">{{ __('create') . ' ' . __('survey_option') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('survey-options-store') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <input type="hidden" name="question_id" value="{{ $question->id }}">
                            <div class="card-body">
                                <div class="form-group row">
                                    <div class="col-sm-12">
                                        <label>{{ __('question') }}</label>
                                        <textarea name="question" class="form-control" placeholder="{{ __('question') }}" readonly>{{ $question->question }}</textarea>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12 repeater">
                                        <div data-repeater-list="options">
                                            <div data-repeater-item class="row">
                                                <div class="col-sm-12 col-md-11 mb-1">
                                                    <label class="required">{{ __('option') }}</label>
                                                    <input type="text" name="option" class="form-control" placeholder="{{ __('option') }}" required>
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
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('survey_option') }}</h3>
                        </div>
                        <div class="card-body">
                            <table aria-describedby="mydesc" id='table' data-toggle="table" data-url="{{ route('surveyOptionsList') }}" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true"
                                data-show-columns="true" data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                data-sort-order="desc" data-query-params="queryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="options" data-sortable="false">{{ __('option') }}</th>
                                        <th scope="col" data-field="counter" data-sortable="false">{{ __('counter') }}</th>
                                        <th scope="col" data-field="percentage" data-sortable="false">{{ __('percentage') }}</th>
                                        <th scope="col" data-field="operate" data-sortable="false" data-events="surveyOptionEvents">{{ __('operate') }}</th>
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('edit') . ' ' . __('survey_option') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>
                    <form id="edit_survey_option" action="{{ route('survey-options-edit') }}">
                        @csrf
                        @method('PUT')
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                <div class="form-group col-md-12 col-sm-12">
                                    <label>{{ __('option') }}</label>
                                    <input id="edit_option" name="option" type="text" class="form-control" placeholder="{{ __('option') }}" required>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer justify-content-between">
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
            show: function() {
                $(this).slideDown();
            },
            hide: function(deleteElement) {
                $(this).slideUp(deleteElement);
            },
            isFirstItemUndeletable: true
        });

        function queryParams(p) {
            return {
                sort: p.sort,
                order: p.order,
                limit: p.limit,
                offset: p.offset,
                search: p.search,
                question_id: '{{ $id }}'
            };
        }
    </script>
    {{-- add option button --}}
    <script type="text/javascript">
        $("#edit_survey_option").on("submit", function(e) {
            e.preventDefault();
            let form = $(this);
            let data = form.serialize();
            $.ajax({
                type: "PUT",
                url: form.attr("action"),
                data: data,
                success: function(response) {
                    if (!response.error) {
                        $("#editDataModal").modal("hide");
                        $("#table").bootstrapTable("refresh");
                        showSuccessToast(response.message);
                    }
                },
                error: function(error) {
                    console.error(error);
                },
            });
        });
        $(document).on("click", ".survey-options-delete-form", function(e) {
            e.preventDefault();
            Swal.fire({
                title: '{{ __('are_you_sure') }}',
                text: "You won't be able to revert this!",
                icon: "warning",
                showCancelButton: true,
                confirmButtonColor: "#3085d6",
                cancelButtonColor: "#d33",
                confirmButtonText: "Yes, delete it!",
            }).then((result) => {
                if (result.isConfirmed) {
                    let url = $(this).attr("data-url");
                    let data = {
                        "_token": "{{ csrf_token() }}"
                    };

                    function successCallback() {
                        $("#table").bootstrapTable("refresh");
                    }
                    ajaxRequest("DELETE", url, data, null, successCallback);
                }
            });
        });
    </script>
@endsection
