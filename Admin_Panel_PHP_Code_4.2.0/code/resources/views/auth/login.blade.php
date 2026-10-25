<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/x-icon" href="{{ url(Storage::url($setting['app_logo'])) }}" />
    <title> {{ __('login') }} || {{ $setting['app_name'] }}</title>
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
    <link href="{{ url('assets/dist/css/tailadmin.bundle.min.css') }}" rel="stylesheet">

    @php
        $setting = getSetting();
        $primary_color = isset($setting['primary_color']) ? $setting['primary_color'] : '#1B2D51';
        $secondary_color = isset($setting['secondary_color']) ? $setting['secondary_color'] : '#EE2934';
    @endphp

    <style>
        :root {
            --primary-color: <?php echo $primary_color; ?>;
            --secondary-color: <?php echo $secondary_color; ?>;
        }

        .login-page {
            background-image: url("{{ asset(config('installer.background')) }}");
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
        }
    </style>
</head>

<body class="hold-transition login-page" data-theme="tailadmin">
    @if (env('DEMO_MODE'))
        <div class="alert bg-warning  mb-3" style="font-size:12px ;">
            <b>Note:</b> If you cannot login here, please close the codecanyon frame by clicking on <b>x Remove Frame</b> button from top right corner on the page or <a href="https://news-admin.wrteam.me/" target="_blank">&gt;&gt; Click here &lt;&lt;</a>
        </div>
    @endif
    <div class="login-box">
        <div class="card" id="login_form_card">
            <div class="card-body login-card-body">
                <div class="login-logo">
                    <a href="javascript:void(0)">
                        <img src="{{ url(Storage::url($setting['app_logo_full'])) }}" alt="image" width="200" />
                    </a>
                </div>

                <h3 class="login-box-title">Welcome!</h3>
                <p class="login-box-msg">Please Login to your Account</p>
                <form role="form" id="login_form" action="{{ route('authenticate') }}" novalidate method="post">
                    @csrf
                    <div class="form-group inner-addon left-addon">
                        <i class="fa fa-user"></i>
                        <input type="text" name="username" class="form-control" @if(env('DEMO_MODE')) value="admin" @endif placeholder="Username or Email" else placeholder="Email or Username" required>
                    </div>
                    <div class="form-group inner-addon left-addon">
                        <i class="fa fa-lock"></i>
                        <input id="password" type="password" name="password" class="form-control" @if(env('DEMO_MODE')) value="admin123" @endif placeholder="Password" required>
                        <i class="fa fa-eye password-toggle" id="eye-icon" onclick="togglePasswordVisibility()"></i>
                    </div>
                    {{-- <div class="form-group text-right">
                        <a id="forgot_password_btn" href="javascript:void(0)">Forgot Password?</a>
                    </div> --}}
                    @if (session('error'))
                        <div class="row col-12">
                            <p id="error_msg" class="alert alert-danger">{{ session('error') }}</p>
                        </div>
                    @endif
                    <div class="row">
                        <div class="col-12">
                            <button type="submit" class="btn btn-primary btn-block login-btn">Login</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
        <div class="card" id="forgot_password_card" style="display: none">
            <div class="card-body login-card-body">
                <div class="login-logo">
                    <a href="javascript:void(0)">
                        <img src="{{ url(Storage::url($setting['app_logo_full'])) }}" alt="image" width="200" />
                    </a>
                </div>

                <h3 class="login-box-title">Reset Your<br />Password here!</h3>
                <p class="login-box-msg"></p>
                <form role="form" id="forgot_password_form" action="" method="post">
                    @csrf
                    <div class="form-group inner-addon left-addon">
                        <i class="fa fa-user"></i>
                        <input type="email" name="email" class="form-control" id="email" placeholder="Email Address">
                    </div>
                    <div class="row col-12">
                        <p id="email_sent" class="alert alert-success"></p>
                    </div>
                    <div class="row col-12">
                        <p id="invalid_email" class="alert alert-danger"></p>
                    </div>
                    <div class="row">
                        <div class="col-12">
                            <button type="submit" id="forgot_submit_btn" class="btn btn-primary btn-block login-btn">Reset Password</button>
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
        $('#login_form').validate({
            rules: {},
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
        $(document).ready(function() {
            $('#error_msg').delay(4000).fadeOut();
            /*By Default Hide Forgot Password Form*/
            $('#forgot_password_card').hide();

            /*On click Forgot Password -> show Forgot password form*/
            $('#forgot_password_btn').on('click', function(e) {
                e.preventDefault();
                $('#login_form_card').hide();
                $('#forgot_password_card').show();
            });
            /*Hide error, success msg*/
            $('#email_sent').hide();
            $('#invalid_email').hide();


            // /*on submit forgot password - email sent*/
            $('#forgot_password_form').submit(function(e) {
                e.preventDefault();
                var email = $('#email').val();
                $.ajaxSetup({
                    headers: {
                        "X-CSRF-TOKEN": $('meta[name="csrf-token"]').attr("content"),
                    },
                });
                $.ajax({
                    type: "POST",
                    dataType: "JSON",
                    url: "check_email",
                    data: {
                        email: email
                    },
                    beforeSend: function() {
                        $('#forgot_submit_btn').html('Checking...');
                    },
                    success: function(result) {
                        $('#forgot_submit_btn').html('Reset Password');
                        if (result == true) {
                            $('#email_sent').html("Email Sent Successfully").show().delay(4000)
                                .fadeOut();
                            allowsubmit = true;
                        } else {
                            $('#invalid_email').html("Invalid Email ID.").show().delay(4000)
                                .fadeOut();
                        }
                    },
                    error: function(result) {
                        $('#old_status').html("Error" + result);
                    }
                });
            });

        });
    </script>
    <script type="text/javascript">
        function togglePasswordVisibility() {
            const passwordInput = document.getElementById("password");
            const eyeIcon = document.getElementById("eye-icon");

            if (passwordInput.type === "password") {
                passwordInput.type = "text";
                eyeIcon.classList.remove("fa-eye-slash");
                eyeIcon.classList.add("fa-eye");
            } else {
                passwordInput.type = "password";
                eyeIcon.classList.remove("fa-eye");
                eyeIcon.classList.add("fa-eye-slash");
            }
        }
    </script>

</body>

</html>
