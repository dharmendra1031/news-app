@extends('layouts.main')

@section('title')
    {{ __('web_setting') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('system-settings') }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item  active"><i class="fas fas fa-tv mr-1"></i>{{ __('web_setting') }}</li>
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
                            <h3 class="card-title">{{ __('system_settings_for_web') }}
                                <small class="text-bold">{{ __('directly_reflect_changes_in_web') }} </small>
                            </h3>
                        </div>
                        <form action="{{ route('web-settings.store') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('web_name') }}</label>
                                        <input type="text" name="web_name" value="<?= $setting['web_name'] ? $setting['web_name'] : '' ?>" class="form-control" required />
                                    </div>
                                    <div class="form-group col-md-2">
                                        <label>{{ __('accept_cookie') }}</label>
                                        <div>
                                            <input type="checkbox" id="is_accept_cookie" name="is_accept_cookie" class="status-switch" @if (isset($setting['accept_cookie']) && $setting['accept_cookie'] == '1') checked @endif>
                                            <input type="hidden" id="accept_cookie" name="accept_cookie" value="{{ $setting['accept_cookie'] ?? 0 }}">
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('footer_description') }}</label>
                                        <textarea name="web_footer_description" class="form-control">{{ $setting['web_footer_description'] ? $setting['web_footer_description'] : '' }}</textarea>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('google_adsense') }}</label>
                                        <textarea name="google_adsense" class="form-control">{{ isset($setting['google_adsense']) ? $setting['google_adsense'] : '' }}</textarea>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-6 col-sm-12">
                                        <div class="row text-center">
                                            <div class="col-md-12 col-sm-12">
                                                <h5 class="text-bold">{{__('light_theme')}}</h5>
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('body_color') }}</label>
                                                <input name="light_body_color" value="<?= isset($setting['light_body_color']) ? $setting['light_body_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('hover_color') }}</label>
                                                <input name="light_hover_color" value="<?= isset($setting['light_hover_color']) ? $setting['light_hover_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('primary_color') }}</label>
                                                <input name="light_primary_color" value="<?= isset($setting['light_primary_color']) ? $setting['light_primary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('secondary_color') }}</label>
                                                <input name="light_secondary_color" value="<?= isset($setting['light_secondary_color']) ? $setting['light_secondary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('text_primary_color') }}</label>
                                                <input name="light_text_primary_color" value="<?= isset($setting['light_text_primary_color']) ? $setting['light_text_primary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('text_secondary_color') }}</label>
                                                <input name="light_text_secondary_color" value="<?= isset($setting['light_text_secondary_color']) ? $setting['light_text_secondary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('header_logo') }} <small class="text-danger">({{ __('size') }} 180 * 60)</small></label>
                                                <input name="light_header_logo" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['light_header_logo']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['light_header_logo'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="light_header_logo" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('footer_logo') }}<small class="text-danger">({{ __('size') }} 180 * 60)</small></label>
                                                <input name="light_footer_logo" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['light_footer_logo']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['light_footer_logo'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="light_footer_logo" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('placeholder_image') }}</label>
                                                <input name="light_placeholder_image" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['light_placeholder_image']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['light_placeholder_image'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="light_placeholder_image" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-6 col-sm-12">
                                        <div class="row text-center">
                                            <div class="col-md-12 col-sm-12">
                                                <h5 class="text-bold">{{__('dark_theme')}}</h5>
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('body_color') }}</label>
                                                <input name="dark_body_color" value="<?= isset($setting['dark_body_color']) ? $setting['dark_body_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('hover_color') }}</label>
                                                <input name="dark_hover_color" value="<?= isset($setting['dark_hover_color']) ? $setting['dark_hover_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('primary_color') }}</label>
                                                <input name="dark_primary_color" value="<?= isset($setting['dark_primary_color']) ? $setting['dark_primary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('secondary_color') }}</label>
                                                <input name="dark_secondary_color" value="<?= isset($setting['dark_secondary_color']) ? $setting['dark_secondary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('text_primary_color') }}</label>
                                                <input name="dark_text_primary_color" value="<?= isset($setting['dark_text_primary_color']) ? $setting['dark_text_primary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('text_secondary_color') }}</label>
                                                <input name="dark_text_secondary_color" value="<?= isset($setting['dark_text_secondary_color']) ? $setting['dark_text_secondary_color'] : '' ?>" type="color" required class="form-control" />
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('header_logo') }} <small class="text-danger">({{ __('size') }} 180 * 60)</small></label>
                                                <input name="dark_header_logo" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['dark_header_logo']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['dark_header_logo'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="dark_header_logo" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('footer_logo') }}<small class="text-danger">({{ __('size') }} 180 * 60)</small></label>
                                                <input name="dark_footer_logo" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['dark_footer_logo']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['dark_footer_logo'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="dark_footer_logo" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="form-group col-md-6 col-sm-12">
                                                <label>{{ __('placeholder_image') }}</label>
                                                <input name="dark_placeholder_image" type="file" class="filepond">
                                            </div>
                                            <div class="form-group col-md-6 col-sm-12">
                                                @if (isset($setting['dark_placeholder_image']))
                                                    <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                        <img src="{{ url(Storage::url($setting['dark_placeholder_image'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="dark_placeholder_image" />
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-3 col-sm-12">
                                        <label>{{ __('favicon_icon') }}</label>
                                        <input name="favicon_icon" type="file" class="filepond">
                                    </div>
                                    <div class="form-group col-md-3 col-sm-12">
                                        @if (isset($setting['favicon_icon']) && Storage::disk('public')->exists($setting['favicon_icon']))
                                            <div class="d-flex align-items-center justify-content-center border rounded bg-light p-2" style="min-height: 110px;">
                                                <img src="{{ url(Storage::url($setting['favicon_icon'])) }}" class="img-thumbnail img-fluid" style="max-height: 100px; max-width: 100%; width: auto;" alt="favicon_icon" />
                                            </div>
                                        @endif
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12 col-sm-12">
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
            /* on change of accept_cookie mode btn - switchery js */
            var is_accept_cookie = document.querySelector('#is_accept_cookie');
            is_accept_cookie.onchange = function() {
                if (is_accept_cookie.checked)
                    $('#accept_cookie').val(1);
                else
                    $('#accept_cookie').val(0);
            };

        });
    </script>
@endsection
