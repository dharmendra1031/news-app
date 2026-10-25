@extends('layouts.main')

@section('title')
    {{ __('panel_setting') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6"></div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('system-settings') }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item  active"><i class="fas fas fa-cogs mr-1"></i>{{ __('panel_setting') }}</li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row mb-3">
                <div class="col-md-12">
                    <div class="card card-secondary h-100">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('system_settings_for_panel') }}</h3>
                        </div>
                        <form action="{{ route('panel-settings') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <label for="system_timezone">{{ __('system_timezone') }}</label>
                                            <select id="system_timezone" name="system_timezone" required class="form-control">
                                                @foreach (getTimezoneOptions() as $option)
                                                    <option value="{{ $option['timezone_id'] }}" @if ($setting['system_timezone'] == $option['timezone_id']) selected @endif data-gmt="{{ $option['offset'] }}">
                                                        {{ $option['timezone_id'] }} - sGMT{{ $option['offset'] }}-{{ $option['time'] }}
                                                    </option>
                                                @endforeach
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('panel_name') }}</label>
                                            <input type="text" name="app_name" value="<?= $setting['app_name'] ? $setting['app_name'] : '' ?>" class="form-control" required />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('primary_color') }}</label>
                                            <input type="color" name="primary_color" value="<?= isset($setting['primary_color']) ? $setting['primary_color'] : '' ?>" class="form-control" required />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('auto_delete_expire_news') }}</label>
                                            <div>
                                                <input type="checkbox" id="is_expire" name="is_expire" class="status-switch" @if ($setting['auto_delete_expire_news_mode'] == '1') checked @endif>
                                                <input type="hidden" id="auto_delete_expire_news_mode" class="status-switch" name="auto_delete_expire_news_mode" value="{{ $setting['auto_delete_expire_news_mode'] ? $setting['auto_delete_expire_news_mode'] : 0 }}">
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-4 col-sm-12">
                                        <div class="form-group">
                                            <label>{{ __('admin_panel_full_logo') }} <small class="text-danger">({{ __('size') }} 460 * 115)</small></label>
                                            <input name="file1" type="file" class="filepond">
                                            <div class="col-sm-6 col-md-6">
                                                <img src="{{ url(Storage::url($setting['app_logo_full'])) }}" width="300" alt="logo" />
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('admin_panel_favicon') }} <small class="text-danger">({{ __('size') }} 128 * 128)</small></label>
                                            <input name="file" type="file" class="filepond">
                                            <div class="col-sm-6 col-md-6">
                                                <img src="{{ url(Storage::url($setting['app_logo'])) }}" height="100" alt="favicon" />
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-4 col-sm-12">
                                        {{-- <div class="form-group">
                                            <label>{{ __('smtp_host') }}</label>
                                            <input value="{{ $setting['smtp_host'] ? $setting['smtp_host'] : 'smtp.googlemail.com' }}" name="smtp_host" required type="text" class="form-control" />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('smtp_user') }}</label>
                                            <input value="{{ $setting['smtp_user'] ? $setting['smtp_user'] : 'SMTP User' }}" name="smtp_user" required type="text" class="form-control" />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('smtp_password') }}</label>
                                            <input value="{{ $setting['smtp_password'] ? $setting['smtp_password'] : 'SMTP Password' }}" name="smtp_password" required type="password" class="form-control" />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('smtp_port') }}</label>
                                            <input value="{{ $setting['smtp_port'] ? $setting['smtp_port'] : '465' }}" name="smtp_port" required type="text" class="form-control" />
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('smtp_encryption') }}</label>
                                            <select name="smtp_crypto" class="form-control">
                                                <option @if ($setting['smtp_crypto'] == 'tls') selected @endif>tls</option>
                                                <option @if ($setting['smtp_crypto'] == 'ssl') selected @endif>ssl</option>
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label>{{ __('from_name') }}</label>
                                            <input value="{{ $setting['from_name'] ? $setting['from_name'] : env('APP_NAME') }}" name="from_name" type="text" required class="form-control" />
                                        </div> --}}
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-12">
                                        <button type="submit" class="btn btn-primary float-right">{{ __('submit') }}</button>
                                    </div>
                                </div>
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
        $(document).ready(function(e) {
            var elems = Array.prototype.slice.call(
                document.querySelectorAll(".status-switch")
            );
            elems.forEach(function(elem) {
                var switchery = new Switchery(elem, {
                    size: "small",
                    color: "#47C363",
                    secondaryColor: "#EB4141",
                    jackColor: "#ffff",
                    jackSecondaryColor: "#ffff",
                });
            });

            /* on change of Location wise news mode btn - switchery js */
            var auto_delete_expire = document.querySelector('#is_expire');
            auto_delete_expire.onchange = function() {
                if (auto_delete_expire.checked) {
                    $('#auto_delete_expire_news_mode').val(1);
                } else {
                    $('#auto_delete_expire_news_mode').val(0);
                }
            };
        });
    </script>
@endsection
