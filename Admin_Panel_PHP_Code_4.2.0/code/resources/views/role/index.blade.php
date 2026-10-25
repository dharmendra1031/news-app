@extends('layouts.main')

@section('title')
    {{ __('Role Management') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('roles') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-user-tag mr-1"></i>{{ __('roles') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('role-create')
                <div class="col-md-12 d-flex justify-content-end">
                    <button id="toggleButton" class="btn btn-primary mb-3 ml-1">
                        <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('role') }}
                    </button>
                </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('role') }}</h3>
                        </div>
                        <form id="create_form" method="POST" action="{{ route('roles.store') }}" role="form">
                            @csrf
                            <div class="card-body clearfix">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('role_name') }}</label>
                                        <input type="text" class="form-control" id="name" name="name" required>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-12">
                                        <label class="required">{{ __('permissions') }}</label>
                                        <div class="card">
                                            <div class="card-header">
                                                <div class="custom-control custom-checkbox">
                                                    <input type="checkbox" class="custom-control-input" id="select-all">
                                                    <label class="custom-control-label font-weight-bold" for="select-all">
                                                        {{ __('select_all_permissions') }}
                                                    </label>
                                                </div>
                                            </div>
                                            <div class="card-body">
                                                <div class="row">
                                                    @foreach ($permissions as $permission)
                                                        <div class="col-md-3 col-sm-6 mb-2">
                                                            <div class="custom-control custom-checkbox">
                                                                <input type="checkbox"
                                                                       class="custom-control-input permission-checkbox"
                                                                       id="permission-{{ $permission->id }}"
                                                                       name="permissions[]"
                                                                       value="{{ $permission->id }}">
                                                                <label class="custom-control-label"
                                                                       for="permission-{{ $permission->id }}">
                                                                    {{ __($permission->name) }}
                                                                </label>
                                                            </div>
                                                        </div>
                                                    @endforeach
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                
                                <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            <div class="row">
                @can('role-list')
                <div class="col-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('roles') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <table id="table" class="table table-bordered table-striped" data-toggle="table"
                                data-url="{{ route('roles.list') }}" data-click-to-select="true"
                                data-side-pagination="server" data-pagination="true" data-page-list="[5, 10, 20, 50, 100]"
                                data-search="true" data-unique-id="id" data-show-columns="true" data-show-refresh="true"
                                data-mobile-responsive="true" data-buttons-class="primary">
                                <thead>
                                    <tr>
                                        <th data-field="id" data-sortable="true">ID</th>
                                        <th data-field="name" data-sortable="true">{{ __('name') }}</th>
                                        <th data-field="permissions_count">{{ __('permissions') }}</th>
                                        <th data-field="users_count">{{ __('users') }}</th>
                                        @canany(['role-view', 'role-edit', 'role-delete'])
                                        <th data-field="operate" data-formatter="operateFormatter">{{ __('actions') }}</th>
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
    </section>
@endsection

@section('script')
    <script>
        function operateFormatter(value, row, index) {
            let buttons = '';

            // View button
            buttons += '<a href="{{ url('roles') }}/' + row.id + '" class="btn btn-sm btn-primary text-white mr-1">' +
                '<i class="fas fa-eye"></i></a>';

            // Edit button
            buttons += '<a href="{{ url('roles') }}/' + row.id + '/edit" class="btn btn-sm btn-primary text-white mr-1">' +
                '<i class="fas fa-edit"></i></a>';

            // Delete button - only if no users are using this role
            if (row.users_count === 0) {
                buttons += '<a data-url="{{ url('roles') }}/' + row.id + '" ' +
                    'class="btn btn-sm btn-primary text-white delete-form" data-id="' + row.id + '">' +
                    '<i class="fas fa-trash"></i></a>';
            }

            return buttons;
        }

        // Select All Permissions
        $('#select-all').on('change', function() {
            $('.permission-checkbox').prop('checked', this.checked);
        });

        // Uncheck "Select All" if any individual permission is unchecked
        $('.permission-checkbox').on('change', function() {
            if (!$(this).prop('checked')) {
                $('#select-all').prop('checked', false);
            }

            // Check if all checkboxes are selected
            if ($('.permission-checkbox:checked').length === $('.permission-checkbox').length) {
                $('#select-all').prop('checked', true);
            }
        });
    </script>
@endsection
