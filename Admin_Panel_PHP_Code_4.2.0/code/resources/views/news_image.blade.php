@extends('layouts.main')

@section('title')
    {{ __('news') . ' ' . __('image') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('news') . ' ' . __('image') }}</h1>
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
                            <h3 class="card-title">{{ __('create') . ' ' . __('news') . ' ' . __('image') }}</h3>
                        </div>
                        <form id="create_form" action="{{ route('store-image') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <input type='hidden' name="news_id" id="news_id" value='{{ request()->segment(2) }}' />
                            <div class="card-body">
                                <div class="form-group row">
                                    <div class="col-sm-6">
                                        <label>{{ _('title') }}</label>
                                        <input value="<?= $news ? $news->title : '' ?>" type="text" name="title" readonly class="form-control" required>
                                    </div>
                                    <div class="col-sm-6">
                                        <label>{{ __('image') }}</label>
                                        <div>
                                            <input name="file[]" type="file" multiple class="filepond" required>
                                        </div>
                                        <p style="display:none" id="img_error_msg" class="alert alert-danger"></p>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('news') . ' ' . __('image') }}</h3>
                        </div>
                        <div class="card-body">
                            <table aria-describedby="mydesc" class='table-striped' id='table' data-toggle="table" data-url="{{ url('news-image-list') }}" data-click-to-select="true" data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100, 200]"
                                data-toolbar="#toolbar" data-show-columns="true" data-show-refresh="true" data-trim-on-search="false" data-sort-name="id" data-sort-order="desc" data-mobile-responsive="true"
                                data-maintain-selected="true" data-buttons-class="primary" data-query-params="queryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="image" data-sortable="false">{{ __('image') }}</th>
                                        <th scope="col" data-field="operate" data-sortable="false" data-events="actionEvents">{{ __('operate') }}</th>
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
        window.actionEvents = {};
    </script>
    
    <script type="text/javascript">
        function queryParams(p) {
            return {
                'news_id': $('#news_id').val(),
                sort: p.sort,
                order: p.order,
                limit: p.limit,
                offset: p.offset,
                search: p.search,
            };
        }
    </script>
@endsection
