@extends('layouts.main')

@section('title')
    {{__('profile')}}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0"></h1>
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
                            <h3 class="card-title">{{__('edit').' '. __('profile')}}</h3>
                        </div>
                        <form id="create_form" action="{{ route('update-profile') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label ">{{__('name')}}</label>
                                    <div class="col-sm-4">
                                        <input value="<?= $user->username ? $user->username : '' ?>"type="text" id="username" name="username" class="form-control" required>
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label ">{{__('email')}}</label>
                                    <div class="col-sm-4">
                                        <input  placeholder="Email" value="<?= $user->email ? $user->email : '' ?>" type="email" id="email" name="email" class="form-control" required>
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label ">{{ __('image') }}</label>
                                    <div class="col-sm-4">
                                        <input name="file" type="file" class="filepond">
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label">{{__('old_password')}}</label>
                                    <div class="input-group col-sm-4">
                                        <input type="password" id="old_password" name="oldpassword" class="form-control" placeholder="{{__('old_password')}}">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" id="show_old_password_toggle">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                    <label id="old_status"></label>
                                </div>
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label">{{__('new_password')}}</label>
                                    <div class="input-group col-sm-4">
                                        <input type="password" id="new_password" name="newpassword" class="form-control" placeholder="{{__('new_password')}}">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" id="show_password_toggle">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label class="col-sm-2 col-form-label">{{__('confirm_password')}}</label>
                                    <div class="input-group col-sm-4">
                                        <input type="password" id="confirm_password" name="confirmpassword" class="form-control" placeholder="{{__('confirm_password')}}">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" id="show_confirm_password_toggle">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary offset-4">{{__('submit')}}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('script')
<script type="text/javascript">
        document.addEventListener('DOMContentLoaded', function() {
            const newPasswordInput = document.getElementById('new_password');
            const showPasswordToggle = document.getElementById('show_password_toggle');
            showPasswordToggle.addEventListener('click', function() {
                const isPasswordVisible = newPasswordInput.type === 'text';
                newPasswordInput.type = isPasswordVisible ? 'password' : 'text';
                showPasswordToggle.innerHTML = isPasswordVisible ? '<i class="fas fa-eye"></i>' :
                    '<i class="fas fa-eye-slash"></i>';
            });
        });

        document.addEventListener('DOMContentLoaded', function() {
            const confirmPasswordField = document.getElementById('confirm_password');
            const showConfirmPasswordToggle = document.getElementById('show_confirm_password_toggle');
            showConfirmPasswordToggle.addEventListener('click', function() {
                const isConfirmPasswordVisible = confirmPasswordField.type === 'text';
                confirmPasswordField.type = isConfirmPasswordVisible ? 'password' : 'text';
                showConfirmPasswordToggle.innerHTML = isConfirmPasswordVisible ?
                    '<i class="fas fa-eye"></i>' : '<i class="fas fa-eye-slash"></i>';
            });
        });
    </script>
<script type="text/javascript">
    document.addEventListener('DOMContentLoaded', function () {
        const oldPasswordField = document.getElementById('old_password');
        const showOldPasswordToggle = document.getElementById('show_old_password_toggle');
        showOldPasswordToggle.addEventListener('click', function () {
            const isOldPasswordVisible = oldPasswordField.type === 'text';
            oldPasswordField.type = isOldPasswordVisible ? 'password' : 'text';
            showOldPasswordToggle.innerHTML = isOldPasswordVisible ? '<i class="fas fa-eye"></i>' : '<i class="fas fa-eye-slash"></i>';
        });
    });
</script>
<script type="text/javascript">
        $(document).ready(function() {
            $('#old_password').on('change', function() {
                var old_password = $(this).val();
                $.ajax({
                    type: "POST",
                    dataType: "JSON",
                    url: "checkOldPass",
                    data: {
                        oldpass: old_password
                    },
                    beforeSend: function() {
                        $('#old_status').html('Checking..');
                    },
                    success: function(result) {
                        if (result == true) {
                            $('#old_status').html(
                                "<i class='fa fa-check-circle fa-2x text-success'></i>");
                            allowsubmit = true;
                        } else {
                            $('#old_status').html(
                                "<i class='fa fa-times-circle fa-2x text-danger'></i>");
                            allowsubmit = false;
                        }
                    },
                    error: function(result) {
                        $('#old_status').html("Error" + result);
                    }
                });
            });
        });
        $(document).ready(function() {
            $('#create_form').submit(function() {
                if (allowsubmit) {
                    return true;
                } else {
                    $('#old_password').focus();
                    return false;
                }
            });
        });
    </script>
@endsection
