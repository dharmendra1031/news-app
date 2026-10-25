@extends('layouts.main')

@section('title')
    {{ __('Staff Management') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('staff') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="nav-icon fas fa-users mr-1"></i>{{ __('staff') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('staff-change-password')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1">
                            <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('staff') }}
                        </button>
                    </div>
                @endcan
                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('staff') }}</h3>
                        </div>
                        <form id="create_form" method="POST" action="{{ route('staff.store') }}" role="form">
                            @csrf
                            <div class="card-body clearfix">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('role') }}</label>
                                        <select class="form-control" id="role" name="role" required>
                                            <option value="">{{ __('select') . ' ' . __('role') }}</option>
                                            @foreach($roles as $role)
                                                <option value="{{ $role->id }}">{{ $role->name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('username') }}</label>
                                        <input type="text" class="form-control" id="username" name="username" required>
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('email') }}</label>
                                        <input type="email" class="form-control" id="email" name="email" required>
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('password') }}</label>
                                        <input type="password" class="form-control" id="password" name="password" required
                                            minlength="8">
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('status') }}</label><br>
                                        <div class="btn-group">
                                            <label class="btn btn-success" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input class="mr-1" type="radio" name="status" value="1"
                                                    checked>{{ __('active') }}
                                            </label>
                                            <label class="btn btn-danger" data-toggle-class="btn-primary"
                                                data-toggle-passive-class="btn-default">
                                                <input class="mr-1" type="radio" name="status"
                                                    value="0">{{ __('deactive') }}
                                            </label>
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            @can('staff-list')
                <div class="row">
                    <div class="col-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('staff') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <div id="toolbar" class="toolbar-with-filter">
                                    <div class="toolbar-filter">
                                        <select id="filter_status" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('status') }}</option>
                                            <option value="1">{{ __('active') }}</option>
                                            <option value="0">{{ __('deactive') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <table id="table" class="table table-bordered table-striped" data-toggle="table"
                                    data-url="{{ route('staff.list') }}" data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" data-unique-id="id"
                                    data-show-columns="true" data-show-refresh="true" data-toolbar="#toolbar" data-mobile-responsive="true"
                                    data-buttons-class="primary" data-query-params="staffQueryParams">
                                    <thead>
                                        <tr>
                                            <th scope="col" data-field="id" data-sortable="true">ID</th>
                                            <th scope="col" data-field="username">{{ __('username') }}</th>
                                            <th scope="col" data-field="email">{{ __('email') }}</th>
                                            <th scope="col" data-field="role_name">{{ __('role') }}</th>
                                            <th scope="col" data-field="status" data-formatter="staffStatusFormatter">
                                                {{ __('status') }}
                                            </th>
                                            @canany(['staff-edit', 'staff-change-password', 'staff-delete'])
                                                <th scope="col" data-field="operate" data-events="staffEvents">{{ __('actions') }}
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
    </section>

    <!-- Modal for Edit -->
    <div class="modal fade" id="editDataModal" tabindex="-1" role="dialog" aria-labelledby="editDataModalLabel"
        aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="editDataModalLabel">{{ __('edit') . ' ' . __('staff') }}</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <form id="update_form" action="{{ url('staff') }}" method="POST">
                    @csrf
                    <input type='hidden' name="edit_id" id="edit_id" value='' />
                    <div class="modal-body">
                        <div class="form-group">
                            <label for="edit_role" class="required">{{ __('role') }}</label>
                            <select class="form-control" id="edit_role" name="role" required>
                                <option value="">{{ __('select') . ' ' . __('role') }}</option>
                                @foreach($roles as $role)
                                    <option value="{{ $role->id }}">{{ $role->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="edit_username" class="required">{{ __('username') }}</label>
                            <input type="text" class="form-control" id="edit_username" name="username" required>
                        </div>
                        <div class="form-group">
                            <label for="edit_email" class="required">{{ __('email') }}</label>
                            <input type="email" class="form-control" id="edit_email" name="email" required>
                        </div>
                        <div class="form-group">
                            <label>{{ __('status') }}</label><br>
                            <div class="btn-group">
                                <label class="btn btn-success" data-toggle-class="btn-primary"
                                    data-toggle-passive-class="btn-default">
                                    <input class="mr-1" type="radio" name="status" value="1">{{ __('active') }}
                                </label>
                                <label class="btn btn-danger" data-toggle-class="btn-primary"
                                    data-toggle-passive-class="btn-default">
                                    <input class="mr-1" type="radio" name="status" value="0">{{ __('deactive') }}
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

    <!-- Modal for Changing Password -->
    <div class="modal fade" id="changePasswordModal" tabindex="-1" role="dialog" aria-labelledby="changePasswordModalLabel"
        aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="changePasswordModalLabel">{{ __('change_password') }}</h5>`
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <form id="change_password_form" action="{{ url('staff/change-password') }}" method="POST">
                    @csrf
                    <input type='hidden' name="staff_id" id="password_staff_id" value='' />
                    <div class="modal-body">
                        <div class="form-group">
                            <label for="new_password" class="required">{{ __('new_password') }}</label>
                            <input type="password" class="form-control" id="new_password" name="password" required
                                minlength="8">
                        </div>
                        <div class="form-group">
                            <label for="confirm_password" class="required">{{ __('confirm_password') }}</label>
                            <input type="password" class="form-control" id="confirm_password" name="password_confirmation"
                                required minlength="8">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                        <button type="submit" class="btn btn-primary">{{ __('update_password') }}</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection

@section('script')
    <script>
        function operateFormatter(value, row, index) {
            let buttons = '';

            // Edit button
            @can('staff-edit')
                buttons += '<button type="button" class="btn btn-sm btn-primary text-white edit-data mr-1" ' +
                    'data-id="' + row.id + '" ' +
                    'data-username="' + row.username + '" ' +
                    'data-email="' + row.email + '" ' +
                    'data-role="' + row.role_id + '" ' +
                    'data-status="' + row.status + '">' +
                    '<i class="fas fa-edit"></i></button>';
            @endcan
            // Change password button
            @can('staff-change-password')
                buttons += '<button type="button" class="btn btn-sm btn-primary text-white change-password mr-1" ' +
                    'data-id="' + row.id + '">' +
                    '<i class="fas fa-key"></i></button>';
            @endcan
            // Delete button - only if not current user and not admin role
            @can('staff-delete')
                // if (row.id !== {{ auth()->id() }} && !row.is_admin) {
                //     buttons += '<a data-url="' + baseUrl + '/staff/' + row.id + '" ' +
                //         'class="btn btn-sm btn-primary text-white delete-form" data-id="' + row.id + '">' +
                //         '<i class="fas fa-trash"></i></a>';
                // }
            @endcan

                                                    return buttons;
        }

        $("#filter_status").on("change", function () {
            $('#table').bootstrapTable('refresh');
        });
        $(document).ready(function () {
            // Change Password Modal handler
            $(document).on('click', '.change-password', function () {
                var id = $(this).data('id');
                $('#password_staff_id').val(id);
                $('#new_password').val('');
                $('#confirm_password').val('');
                $('#changePasswordModal').modal('show');
            });

            // Password confirmation validation
            $('#change_password_form').on('submit', function (e) {
                e.preventDefault();

                var password = $('#new_password').val();
                var confirmPassword = $('#confirm_password').val();

                if (password.length < 8) {
                    showErrorToast('{{ __("password_must_be_at_least_8_characters") }}');
                    return false;
                }

                if (password !== confirmPassword) {
                    showErrorToast('{{ __("Passwords do not match") }}');
                    return false;
                }

                var formData = new FormData(this);
                var url = $(this).attr('action');

                $.ajax({
                    url: url,
                    type: 'POST',
                    data: formData,
                    processData: false,
                    contentType: false,
                    success: function (response) {
                        if (!response.error) {
                            showSuccessToast(response.message);
                            $('#changePasswordModal').modal('hide');
                            $('#table').bootstrapTable('refresh');
                        } else {
                            showErrorToast(response.message);
                        }
                    },
                    error: function (xhr) {
                        if (xhr.status === 422) {
                            let errors = xhr.responseJSON.errors;
                            let errorMessage = '';
                            Object.keys(errors).forEach(function (key) {
                                errorMessage += errors[key][0] + '<br>';
                            });
                            showErrorToast(errorMessage);
                        } else {
                            showErrorToast('{{ __("Something Went Wrong") }}');
                        }
                    }
                });
            });

            // Additional validation for email
            $('#create_form').on('submit', function () {
                var email = $('#email').val();
                var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(email)) {
                    showErrorToast('{{ __("enter_valid_email") }}');
                    return false;
                }

                if ($('#password').val().length < 8) {
                    showErrorToast('{{ __("password_must_be_at_least_8_characters") }}');
                    return false;
                }

                return true;
            });

            $('#update_form').on('submit', function () {
                var email = $('#edit_email').val();
                var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(email)) {
                    showErrorToast('{{ __("enter_valid_email") }}');
                    return false;
                }

                return true;
            });
        });
    </script>
@endsection