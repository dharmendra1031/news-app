<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="{{ url(Storage::url($setting['app_logo'])) }}" />

    <title> Reset Password || {{ $setting['app_name'] }}</title>
    <meta name="csrf-token" content="{{ csrf_token() }}" />
    <!-- Google Font: Source Sans Pro -->
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400i,700&display=fallback">
    <!-- Font Awesome -->
    <link href="{{ url('assets/plugins/fontawesome-free/css/all.min.css') }}" rel="stylesheet">
    <!-- iCheck -->
    <link href="{{ url('assets/plugins/icheck-bootstrap/icheck-bootstrap.min.css') }}" rel="stylesheet">
    {{-- Theme style --}}
    {{-- AdminLTE theme (disabled; TailAdmin active) --
        <link href="{{ url('assets/dist/css/adminlte.min.css') }}" rel="stylesheet">
        <link href="{{ url('assets/dist/css/adminlte.css') }}" rel="stylesheet">
    --}}
    <link href="{{ url('assets/custom/css/tailadmin.bundle.min.css') }}" rel="stylesheet">
    <?php
    $setting = getSetting();
    $primary_color = isset($setting['primary_color']) ? $setting['primary_color'] : '#04132D';
    $secondary_color = isset($setting['secondary_color']) ? $setting['secondary_color'] : '#E64141';
    ?>

    <style>
        :root {
            --primary-color: <?php echo $primary_color; ?>;
            --secondary-color: <?php echo $secondary_color; ?>;
        }
    </style>

</head>

<body class="hold-transition login-page" data-theme="tailadmin">
    <div class="login-box">
        <div class="card" id="login_form_card">
            <div class="card-body login-card-body">
                <div class="login-logo">
                    <a href="javascript:void(0)">
                        <img src="{{ url(Storage::url($setting['app_logo_full'])) }}" alt="image" width="200" />
                    </a>
                </div>
                <h3 class="login-box-title">Reset Password</h3>
                <form role="form" id="reset_password_form" action="" method="post">
                    @csrf
                    <input type="hidden" name="forgot_unique_code" class="form-control" value="<?= $_GET['forgot_code'] ?>">
                    <div class="form-group inner-addon left-addon">
                        <i class="fa fa-lock"></i>
                        <input type="password" name="password" class="form-control" id="password" placeholder="Password">
                    </div>
                    <div class="form-group inner-addon left-addon">
                        <i class="fa fa-lock"></i>
                        <input type="password" name="confirm_password" class="form-control" id="confirm_password" placeholder="Confirm Password">
                    </div>

                    <div class="row col-12">
                        <p id="success_msg" class="alert alert-success"></p>
                    </div>
                    <div class="row col-12">
                        <p id="error_msg" class="alert alert-danger"></p>
                    </div>
                    <div class="row">
                        <div class="col-12">
                            <button type="submit" class="btn btn-primary btn-block login-btn" id="reset_submit_btn">Submit</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- jQuery -->
    <script src="{{ url('assets/plugins/jquery/jquery.min.js') }}"></script>
    <!-- Other scripts and plugins -->
    <script src="{{ url('assets/plugins/bootstrap/js/bootstrap.bundle.min.js') }}"></script>

    <script src="{{ url('assets/plugins/jquery-validation/jquery.validate.min.js') }}"></script>
    <script src="{{ url('assets/plugins/jquery-validation/additional-methods.min.js') }}"></script>

    <script type="text/javascript">
        $(document).ready(function() {
            /*Hide error, success msg*/
            $('#success_msg').hide();
            $('#error_msg').hide();
            /*on submit forgot password - email sent*/
            $('#reset_password_form').submit(function(e) {
                e.preventDefault();
                var form = $("#reset_password_form");
                $.ajax({
                    type: "POST",
                    dataType: "JSON",
                    url: "update_password",
                    data: form.serialize(),
                    beforeSend: function() {
                        $('#reset_submit_btn').html('Checking...');
                    },
                    success: function(result) {
                        $('#reset_submit_btn').html('Reset Password');
                        if (result.error == false) {
                            $('#success_msg').html(result.message).show().delay(4000).fadeOut();
                            setTimeout(window.location.href = "/", 5000);
                        } else {
                            $('#error_msg').html(result.message).show().delay(4000).fadeOut();
                        }
                    },
                    error: function(result) {
                        $('#old_status').html("Error" + result);
                    }
                });
            });

            $('#reset_password_form').validate({
                rules: {
                    password: {
                        required: true
                    },
                    confirm_password: {
                        required: true,
                        equalTo: "#password"
                    }
                },
                messages: {
                    password: {
                        required: "Please enter password"
                    },
                    confirm_password: {
                        required: "Please enter password"
                    }
                },
                errorElement: 'span',
                errorPlacement: function(error, element) {
                    error.addClass('invalid-feedback');
                    element.closest('.form-group').append(error);
                },
                highlight: function(element, errorClass, validClass) {
                    $(element).addClass('is-invalid');
                },
                unhighlight: function(element, errorClass, validClass) {
                    $(element).removeClass('is-invalid');
                }
            });


        });
    </script>


</body>

</html>
