@extends('layouts.main')

@section('title')
    {{ __('comment') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0"></h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-comments mr-1"></i>{{ __('comment') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        @can('comment-list')
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('comment') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            @can('comment-bulk-delete')
                            <div id="toolbar">
                                <button class="btn bg-primary text-white" type="submit" id="bulk_order_update">{{ __('bulk_delete') }}</button>
                            </div>
                            @endcan
                            <table aria-describedby="mydesc" id='table' data-toggle="table" data-url="{{ route('commentsList') }}" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true" data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id" data-sort-order="desc"
                                data-query-params="commonQueryParams">
                                <thead>
                                    <tr>
                                        @can('comment-bulk-delete')
                                        <th class="text-center multi-check" data-checkbox="true">
                                        @endcan
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="name">{{ __('user') }}</th>
                                        <th scope="col" data-field="title">{{ __('news') }}</th>
                                        <th scope="col" data-field="message" data-formatter="descriptionFormatter">{{ __('comment') }}</th>
                                        @canany(['comment-delete'])
                                        <th scope="col" data-field="operate" data-sortable="false">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        @endcan
    </section>
@endsection

@section('script')

    <script type="text/javascript">
        $('#bulk_order_update').click(function() {
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
                            url: '{{ url('bulk_comment_delete') }}',
                            data: {
                                request_ids: request_ids
                            },
                            type: 'post',
                            success: function(response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message)
                                    $('#table').bootstrapTable('refresh');
                                } else {
                                    showErrorToast(response.message);
                                }
                            },
                            error: function(response) {
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
