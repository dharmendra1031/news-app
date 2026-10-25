@extends('layouts.main')

@section('title')
    {{ __('author') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('manage').' '.__('authors') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-user mr-1"></i>{{ __('author') . ' ' . __('list') }}</li>
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
                            <h3 class="card-title">{{ __('author') . ' ' . __('list') }} </h3>
                        </div>
                        <div class="card-body">
                            <div id="toolbar" class="toolbar-with-filter">
                                <select id="filter_status" name="status" class="form-control">
                                    <option value="">{{ __('select') . ' ' . __('status') }}</option>
                                    <option value="approved">{{ __('approved') }}</option>
                                    <option value="pending">{{ __('pending') }}</option>
                                    <option value="rejected">{{ __('rejected') }}</option>
                                </select>
                            </div>
                            <table aria-describedby="mydesc" id='table' data-toggle="table"
                            data-url="{{ route('author.show',1) }}" data-click-to-select="true"
                            data-side-pagination="server" data-pagination="true"
                            data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true"
                            data-show-columns="true" data-show-refresh="true"
                            data-toolbar="#toolbar" data-mobile-responsive="true"
                            data-buttons-class="primary" data-trim-on-search="false"
                            data-sort-name="id" data-sort-order="desc" data-query-params="authorQueryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="user_name">{{ __('user_name') }}</th>
                                        <th scope="col" data-field="user.email">{{ __('email') }}</th>
                                        <th scope="col" data-field="bio" data-formatter="descriptionFormatter">{{ __('bio') }}</th>
                                        {{-- <th scope="col" data-field="telegram_link">{{ __('telegram_link') }}</th>
                                        <th scope="col" data-field="linkedin_link">{{ __('linkedin_link') }}</th>
                                        <th scope="col" data-field="facebook_link">{{ __('facebook_link') }}</th>
                                        <th scope="col" data-field="whatsapp_link">{{ __('whatsapp_link') }}</th> --}}
                                        <th scope="col" data-field="status" data-formatter="statusFormatter">{{ __('status') }}</th>
                                        <th scope="col" data-field="auto_approve" data-formatter="autoApproveformatter">{{__('auto_approve')." ".__('news')}}</th>
                                        @can('author-edit')
                                        <th scope="col" data-field="operate" data-events="authorEvents">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {{-- Modal starts --}}
        <div class="modal fade" id="editDataModal">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h4 class="modal-title">{{ __('verify_author') }}</h4>
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                            <span aria-hidden="true">&times;</span>
                        </button>
                    </div>

                    <form id="update_form" action="{{ url('author') }}" role="form" method="POST" enctype="multipart/form-data">
                        @csrf
                        <input type='hidden' name="edit_id" id="edit_id" value='' />
                        <input type='hidden' name="user_id" id="user_id" value='' />
                        <div class="modal-body">
                            <div class="row">
                                {{-- socail media links --}}

                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('telegram_link') }}</label>
                                        <input type="text" name="telegram_link" id="telegram_link" class="form-control" readonly>
                                    </div>
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('whatsapp_link') }}</label>
                                        <input type="text" name="whatsapp_link" id="whatsapp_link" class="form-control" readonly>
                                    </div>
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('linkedin_link') }}</label>
                                        <input type="text" name="linkedin_link" id="linkedin_link" class="form-control" readonly>
                                    </div>
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('facebook_link') }}</label>
                                        <input type="text" name="facebook_link" id="facebook_link" class="form-control" readonly>
                                    </div>

                                <div class="form-group col-md-12 col-sm-12">
                                    <label>{{ __('author_status') }}</label><br>
                                    <div class="btn-group">
                                        <label class="btn btn-success" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="author_status" value="approved">{{ __('approved') }}
                                        </label>
                                        <label class="btn btn-warning" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="author_status" value="pending" checked>{{ __('pending') }}
                                        </label>
                                        <label class="btn btn-danger" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="author_status" value="rejected">{{ __('rejected') }}
                                        </label>
                                    </div>
                                </div>
                                <div class="form-group col-md-12 col-sm-12">
                                    <label>{{ __('auto_approve') }}</label><br>
                                    <label class="btn btn-success" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="auto_approve" value="1">{{ __('enable') }}
                                        </label>
                                    <label class="btn btn-danger" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                            <input class="mr-1" type="radio" name="auto_approve" value="0">{{ __('disable') }}
                                        </label>
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
        {{-- Modal ends --}}
    </section>
@endsection

@section('script')
<script type="text/javascript">
     $("#filter_status").on("change", function() {
            $('#table').bootstrapTable('refresh');
        });
</script>
@endsection
