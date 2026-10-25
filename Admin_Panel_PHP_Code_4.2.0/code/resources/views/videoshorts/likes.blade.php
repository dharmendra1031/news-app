@extends('layouts.main')

@section('title')
    {{ __('reactions') }} - {{ $videoShort->title }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('reactions') }} - {{ $videoShort->title }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('video_shorts.index') }}" class="text-dark"><i
                                    class="fas fa-video mr-1"></i>{{ __('video_shorts') }}</a>
                        </li>
                        <li class="breadcrumb-item active">{{ __('likes') }}</li>
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
                            <h3 class="card-title">{{ __('video_shorts') }}</h3>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4"><strong>{{ __('title') }}:</strong> {{ $videoShort->title }}</div>
                                <div class="col-md-4"><strong>{{ __('language') }}:</strong>
                                    {{ $videoShort->language->language ?? '-' }}</div>
                                @if (is_category_enabled() == 1)
                                    <div class="col-md-4"><strong>{{ __('category') }}:</strong>
                                        {{ $videoShort->category->category_name ?? '-' }}</div>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('reactions') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            @can('newsbuzz-delete')
                                <div id="toolbar">
                                    <button class="btn bg-primary text-white" type="submit"
                                        id="bulk_delete">{{ __('bulk_delete') }}</button>
                                </div>
                            @endcan
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                                data-url="{{ route('video_shorts.likes_list', $videoShort->id) }}"
                                data-click-to-select="true" data-side-pagination="server" data-pagination="true"
                                data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-show-columns="true"
                                data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                data-buttons-class="primary" data-trim-on-search="false" data-sort-name="id"
                                data-sort-order="desc" data-unique-id="id">
                                <thead>
                                    <tr>
                                        <th class="text-center multi-check" data-checkbox="true"></th>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="user_name">{{ __('user') }}</th>
                                        <th scope="col" data-field="like">{{ __('likes') }}</th>
                                        <th scope="col" data-field="dislike">{{ __('dislikes') }}</th>
                                        </th>
                                        @can('newsbuzz-delete')
                                            <th scope="col" data-field="operate" data-events="videoShortLikeEvents">
                                                {{ __('operate') }}</th>
                                        @endcan
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('script')
    <script type="text/javascript">
        $('#bulk_delete').click(function () {
            var selected = $('#table').bootstrapTable('getSelections');
            if(selected.length===0){
                    showErrorToast(trans("Please select at least one record to delete"));
                    return;
                }
            var request_ids = selected.map(({ id }) => id);
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
                        $.ajaxSetup({ headers: { 'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content') } });
                        $.ajax({
                            type: 'POST',
                            url: '{{ route('video_shorts.likes.bulk_delete') }}',
                            data: { request_ids: request_ids },
                            success: function (response) {
                                if (response.error == false) {
                                    showSuccessToast(response.message);
                                    $('#table').bootstrapTable('refresh');
                                } else {
                                    showErrorToast(response.message);
                                }
                            },
                            error: function (response) { return showToastMessage(response.message, "error"); }
                        });
                    }
                });
            } else {
                showErrorToast('{{ __('select_data_to_delete') }}');
            }
        });
    </script>
@endsection