@extends('layouts.main')

@section('title')
    {{ __('app_setting') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-md-6"></div>
                <div class="col-md-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i
                                    class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('system-settings') }}" class="text-dark"><i
                                    class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="fas fas fa-tablet-alt mr-1"></i>{{ __('app_setting') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>
    <section class="content">
        <div class="container-fluid">
            <div class="row mb-3">
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('system_settings_for_app') }}
                                <small class="text-bold">{{ __('directly_reflect_changes_in_app') }} </small>
                            </h3>
                        </div>
                        <form id="extra_form" action="{{ route('app-settings.store') }}" novalidate role="form"
                            method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('appstore_app_id') }}</label>
                                        <input name="appstore_app_id"
                                            value="{{ $setting['appstore_app_id'] ? $setting['appstore_app_id'] : '' }}"
                                            class="form-control">
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('shareapp_text') }}</label>
                                        <textarea name="shareapp_text" class="form-control">{{ $setting['shareapp_text'] ? $setting['shareapp_text'] : '0' }}</textarea>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('video_type_preference') }}</label>
                                        <div>
                                            <div class="form-check form-check-inline">
                                                <input type="radio" class="form-check-input" name="video_type_preference"
                                                    value="normal_style" @if ($setting['video_type_preference'] == 'normal_style' || !isset($setting['video_type_preference'])) checked @endif>
                                                <label class="form-check-label">{{ __('normal_style') }}</label>
                                            </div>
                                            <div class="form-check form-check-inline">
                                                <input type="radio" class="form-check-input" name="video_type_preference"
                                                    value="page_style" @if ($setting['video_type_preference'] == 'page_style') checked @endif>
                                                <label class="form-check-label">{{ __('page_style') }}</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="row mt-3 px-3">
                                <div class="form-group col-md-6 col-sm-12">
                                    <div class="card card-secondary">
                                        <div class="card-header">
                                            <h3 class="card-title">{{ __('android_ads') }}</h3>
                                        </div>
                                        <div class="card-body">
                                            <div class="row">
                                                <div class="form-group col-md-2 col-sm-6">
                                                    <label>{{ __('in_app_ads') }}</label>
                                                    <div>
                                                        <input type="checkbox" id="in_app_ads" name="in_app_ads"
                                                            class="status-switch"
                                                            @if ($setting['in_app_ads_mode'] == '1') checked @endif>
                                                        <input type="hidden" id="in_app_ads_mode" name="in_app_ads_mode"
                                                            value="{{ $setting['in_app_ads_mode'] ? $setting['in_app_ads_mode'] : '0' }}">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row">
                                                <div class="form-group col-md-12 col-sm-12 adsHide">
                                                    <div>
                                                        <div class="form-check">
                                                            <input type="radio" class="form-check-input" name="ads_type"
                                                                value="1"
                                                                @if ($setting['ads_type'] == '1') checked @endif>
                                                            <label
                                                                class="form-check-label mr-4">{{ __('google_admob') }}</label>

                                                            <input type="radio" class="form-check-input" name="ads_type"
                                                                value="3"
                                                                @if ($setting['ads_type'] == '3') checked @endif>
                                                            <label class="form-check-label">{{ __('unity_ads') }}</label>
                                                        </div>
                                                    </div>
                                                    <hr>
                                                </div>
                                            </div>
                                            <div class="adsgoogle adsHide row">
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label> {{ __('google_rewarded_video_id') }}</label>
                                                    <input type="text" name="google_rewarded_video_id"
                                                        class="form-control googleAtt"
                                                        placeholder="google Rewarded Video Id" required
                                                        value="{{ $setting['google_rewarded_video_id'] ? $setting['google_rewarded_video_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_interstitial_id') }}</label>
                                                    <input type="text" name="google_interstitial_id"
                                                        class="form-control googleAtt" placeholder="google Interstitial Id"
                                                        required
                                                        value="{{ $setting['google_interstitial_id'] ? $setting['google_interstitial_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_banner_id') }}</label>
                                                    <input type="text" name="google_banner_id"
                                                        class="form-control googleAtt" required
                                                        value="{{ $setting['google_banner_id'] ? $setting['google_banner_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_native_unit_id') }}</label>
                                                    <input type="text" name="google_native_unit_id"
                                                        class="form-control googleAtt" required
                                                        value="{{ $setting['google_native_unit_id'] ? $setting['google_native_unit_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_app_open_unit_id') }}</label>
                                                    <input type="text" name="google_app_open_unit_id"
                                                        class="form-control googleAtt" placeholder="{{ __('google_app_open_unit_id') }}"
                                                        value="{{ isset($setting['google_app_open_unit_id']) && $setting['google_app_open_unit_id'] ? $setting['google_app_open_unit_id'] : '' }}" />
                                                </div>
                                            </div>
                                            <div class="adsunity adsHide row">
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_rewarded_video_id') }}</label>
                                                    <input type="text" name="unity_rewarded_video_id"
                                                        class="form-control unityAtt" required
                                                        value="{{ $setting['unity_rewarded_video_id'] ? $setting['unity_rewarded_video_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_interstitial_id') }}</label>
                                                    <input type="text" name="unity_interstitial_id"
                                                        class="form-control unityAtt" required
                                                        value="{{ $setting['unity_interstitial_id'] ? $setting['unity_interstitial_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_banner_id') }}</label>
                                                    <input type="text" name="unity_banner_id"
                                                        class="form-control unityAtt" required
                                                        value="{{ $setting['unity_banner_id'] ? $setting['unity_banner_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_game_id') }}</label>
                                                    <input type="text" name="android_game_id"
                                                        class="form-control unityAtt" required
                                                        value="{{ $setting['android_game_id'] ? $setting['android_game_id'] : '0' }}" />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group col-md-6 col-sm-12">
                                    <div class="card card-secondary">
                                        <div class="card-header">
                                            <h3 class="card-title">{{ __('ios_ads') }} </h3>
                                        </div>
                                        <div class="card-body">
                                            <div class="row">
                                                <div class="form-group col-md-2 col-sm-6">
                                                    <label>{{ __('in_app_ads') }}</label>
                                                    <div>
                                                        <input type="checkbox" id="ios_in_app_ads" name="ios_in_app_ads"
                                                            class="status-switch"
                                                            @if ($setting['ios_in_app_ads_mode'] == '1') checked @endif>
                                                        <input type="hidden" id="ios_in_app_ads_mode"
                                                            class="status-switch" name="ios_in_app_ads_mode"
                                                            value="{{ $setting['ios_in_app_ads_mode'] ? $setting['ios_in_app_ads_mode'] : '0' }}">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row">
                                                <div class="form-group col-md-12 col-sm-12 iOSadsHide">
                                                    <div>
                                                        <div class="form-check">
                                                            <input type="radio" class="form-check-input"
                                                                name="ios_ads_type" value="1"
                                                                @if ($setting['ios_ads_type'] == '1') checked @endif>
                                                            <label
                                                                class="form-check-label mr-4">{{ __('google_admob') }}</label>

                                                            <input type="radio" class="form-check-input"
                                                                name="ios_ads_type" value="3"
                                                                @if ($setting['ios_ads_type'] == '3') checked @endif>
                                                            <label class="form-check-label">{{ __('unity_ads') }} </label>
                                                        </div>
                                                    </div>
                                                    <hr>
                                                </div>
                                            </div>
                                            <div class="iOSadsgoogle iOSadsHide row">
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_rewarded_video_id') }}</label>
                                                    <input type="text" name="ios_google_rewarded_video_id"
                                                        class="form-control iOSgoogleAtt"
                                                        placeholder="google Rewarded Video Id" required
                                                        value="{{ $setting['ios_google_rewarded_video_id'] ? $setting['ios_google_rewarded_video_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_interstitial_id') }}</label>
                                                    <input type="text" name="ios_google_interstitial_id"
                                                        class="form-control iOSgoogleAtt"
                                                        placeholder="google Interstitial Id" required
                                                        value="{{ $setting['ios_google_interstitial_id'] ? $setting['ios_google_interstitial_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_banner_id') }}</label>
                                                    <input type="text" name="ios_google_banner_id"
                                                        class="form-control iOSgoogleAtt" required
                                                        value="{{ $setting['ios_google_banner_id'] ? $setting['ios_google_banner_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_native_unit_id') }}</label>
                                                    <input type="text" name="ios_google_native_unit_id"
                                                        class="form-control iOSgoogleAtt" required
                                                        value="{{ $setting['ios_google_native_unit_id'] ? $setting['ios_google_native_unit_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('google_app_open_unit_id') }}</label>
                                                    <input type="text" name="ios_google_app_open_unit_id"
                                                        class="form-control iOSgoogleAtt" placeholder="{{ __('google_app_open_unit_id') }}"
                                                        value="{{ isset($setting['ios_google_app_open_unit_id']) && $setting['ios_google_app_open_unit_id'] ? $setting['ios_google_app_open_unit_id'] : '' }}" />
                                                </div>
                                            </div>
                                            <div class="iOSadsunity iOSadsHide row">
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_rewarded_video_id') }}</label>
                                                    <input type="text" name="ios_unity_rewarded_video_id"
                                                        class="form-control iOSunityAtt" required
                                                        value="{{ $setting['ios_unity_rewarded_video_id'] ? $setting['ios_unity_rewarded_video_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_interstitial_id') }}</label>
                                                    <input type="text" name="ios_unity_interstitial_id"
                                                        class="form-control iOSunityAtt" required
                                                        value="{{ $setting['ios_unity_interstitial_id'] ? $setting['ios_unity_interstitial_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_banner_id') }}</label>
                                                    <input type="text" name="ios_unity_banner_id"
                                                        class="form-control iOSunityAtt" required
                                                        value="{{ $setting['ios_unity_banner_id'] ? $setting['ios_unity_banner_id'] : '0' }}" />
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('unity_game_id') }}</label>
                                                    <input type="text" name="ios_game_id"
                                                        class="form-control iOSunityAtt" required
                                                        value="{{ $setting['ios_game_id'] ? $setting['ios_game_id'] : '0' }}" />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            {{-- force update starts here --}}
                            <div class="form-group col-md-12 col-sm-12">
                                <div class="card card-secondary">
                                    <div class="card-header">
                                        <h3 class="card-title">{{ __('force_update') }} </h3>
                                    </div>
                                    <div class="card-body">
                                        <div class="row">
                                            <div class="form-group col-md-2 col-sm-6">
                                                <label>{{ __('force_update') }}</label>
                                                <div>
                                                    <input type="checkbox" id="force_update_app" name="force_update_app"
                                                        class="status-switch" @if ($setting['force_update_app_mode'] == '1') checked @endif >
                                                    <input type="hidden" id="force_update_app_mode"
                                                        name="force_update_app_mode"
                                                        value="{{ $setting['force_update_app_mode'] ? $setting['force_update_app_mode'] : '0' }}">
                                                </div>
                                            </div>
                                        </div>
                                        <div class="row">
                                            <div class="force_update_app_mode row">
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('android_app_version') }}</label>
                                                    <input type="text" name="android_app_version"
                                                        class="form-control version-input"
                                                        placeholder="{{ __('android_app_version') }}" required
                                                        pattern="^[0-9]+(\.[0-9]+)*$"
                                                        title="Please enter a valid version format (e.g., 1.0.0)"
                                                        value="{{ $setting['android_app_version'] ? $setting['android_app_version'] : '0' }}" />
                                                    <small class="text-muted">{{__('format_version')}}</small>
                                                </div>
                                                <div class="form-group col-md-6 col-sm-12">
                                                    <label>{{ __('ios_app_version') }}</label>
                                                    <input type="text" name="ios_app_version"
                                                        class="form-control version-input"
                                                        placeholder="{{ __('ios_app_version') }}" required
                                                        pattern="^[0-9]+(\.[0-9]+)*$"
                                                        title="Please enter a valid version format (e.g., 1.0.0)"
                                                        value="{{ $setting['ios_app_version'] ? $setting['ios_app_version'] : '0' }}" />
                                                    <small class="text-muted">{{__('format_version')}}</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            {{-- force update ends here --}}
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('file') }} <small
                                                class="text-danger">({{ __('upload_ads_file') }})</small></label>
                                        {{-- only txt files allowed --}}
                                        <input name="ads_file" type="file" class="filepond-txt">
                                        <small>{{ __('supported_format:_.txt') }}</small>
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('ad_after_page_clicks') }}</label>
                                        <input type="number" name="ad_after_page_clicks" min="1"
                                            value="{{ $setting['ad_after_page_clicks'] ?? 1 }}" class="form-control" />
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
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
        $('#extra_form').validate({
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


            /* on change of google ads mode btn - switchery js */
            var in_app_ads = document.querySelector('#in_app_ads');
            in_app_ads.onchange = function() {
                if (in_app_ads.checked) {
                    $('#in_app_ads_mode').val(1);
                    $('.adsHide').show();
                    var ads_type = $("input:radio[name=ads_type]:checked").val();
                    ads_type_manage(ads_type);
                } else {
                    $('#in_app_ads_mode').val(0);
                    $('.adsHide').hide();
                    ads_type_manage(0);
                }
            };
            var ios_in_app_ads = document.querySelector('#ios_in_app_ads');
            ios_in_app_ads.onchange = function() {
                if (ios_in_app_ads.checked) {
                    $('#ios_in_app_ads_mode').val(1);
                    $('.iOSadsHide').show();
                    var ios_ads_type = $("input:radio[name=ios_ads_type]:checked").val();
                    ios_ads_type_manage(ios_ads_type);
                } else {
                    $('#ios_in_app_ads_mode').val(0);
                    $('.iOSadsHide').hide();
                    ios_ads_type_manage(0);
                }
            };
        });
    </script>
    <script type="text/javascript">
        $(document).ready(function() {
            //google ads
            $('.adsHide').hide();
            $('.adsgoogle').hide();
            $('.adsunity').hide();
            var ads = $('#in_app_ads_mode').val();
            if (ads === '1' || ads === 1) {
                $('.adsHide').show();
                var ads_type = $("input:radio[name=ads_type]:checked").val();
                if (ads_type == undefined) {
                    $("input[name=ads_type][value=1]").prop('checked', true);
                }
            } else {
                $('.adsHide').hide();
                $('.adsgoogle').hide();
                $('.googleAtt').removeAttr('required');
                $('.adsunity').hide();
                $('.unityAtt').removeAttr('required');
            }
            var ads_type = $("input:radio[name=ads_type]:checked").val();
            ads_type_manage(ads_type);
            //ios ads
            $('.iOSadsHide').hide();
            $('.iOSadsgoogle').hide();
            $('.iOSadsunity').hide();
            var ios_ads = $('#ios_in_app_ads_mode').val();
            if (ios_ads === '1' || ios_ads === 1) {
                $('.iOSadsHide').show();
                var ios_ads_type = $("input:radio[name=ios_ads_type]:checked").val();
                if (ios_ads_type == undefined) {
                    $("input[name=ios_ads_type][value=1]").prop('checked', true);
                }
            } else {
                $('.iOSadsHide').hide();
                $('.iOSadsgoogle').hide();
                $('.iOSgoogleAtt').removeAttr('required');
                $('.iOSadsunity').hide();
                $('.iOSunityAtt').removeAttr('required');
            }
            var ios_ads_type = $("input:radio[name=ios_ads_type]:checked").val();
            ios_ads_type_manage(ios_ads_type);
        });

        function ads_type_manage(ads_type) {
            var ads = $('#in_app_ads_mode').val();
            if (ads == 1 || ads == '1') {
                // $('.adsHide').hide();
                $('.adsgoogle').hide();
                $('.googleAtt').prop('required', false);
                $('.adsunity').hide();
                $('.unityAtt').prop('required', false);
                if (ads_type === '1' || ads_type === 1) {
                    $('.adsgoogle').show();
                    $('.googleAtt').prop('required', true);
                } else if (ads_type === '3' || ads_type === 3) {
                    $('.adsunity').show();
                    $('.unityAtt').prop('required', true);
                }
            }
        }

        function ios_ads_type_manage(ios_ads_type) {
            var ios_ads = $('#ios_in_app_ads_mode').val();
            if (ios_ads === '1' || ios_ads === 1) {
                // $('.iOSadsHide').hide();
                $('.iOSadsgoogle').hide();
                $('.iOSgoogleAtt').prop('required', false);
                $('.iOSadsunity').hide();
                $('.iOSunityAtt').prop('required', false);
                if (ios_ads_type === '1' || ios_ads_type === 1) {
                    $('.iOSadsgoogle').show();
                    $('.iOSgoogleAtt').prop('required', true);
                } else if (ios_ads_type === '3' || ios_ads_type === 3) {
                    $('.iOSadsunity').show();
                    $('.iOSunityAtt').prop('required', true);
                }
            }
        }
        $(document).on('click', 'input[name="ios_ads_type"]', function() {
            var ios_ads_type = $(this).val();
            ios_ads_type_manage(ios_ads_type);
        });
        $(document).on('click', 'input[name="ads_type"]', function() {
            var ads_type = $(this).val();
            ads_type_manage(ads_type);
        });

        // force update starts here
        $(document).ready(function() {
            // let force_update_app_checkbox = $('#force_update_app_mode').val();
            console.log("force_update_app checked:", $('#force_update_app_mode').val());
            console.log("force_update_app checked:", $('#force_update_app_mode').val() == '1' ? true : false);


            // Function to toggle the force update mode visibility
            function toggleForceUpdateMode() {
                // console.log("hello", typeof($('#force_update_app_mode_hidden').val()));
                // console.log($('#force_update_app_mode_hidden').val())
                if ($('#force_update_app').is(':checked')) {
                    $('#force_update_app_mode').val(1);
                } else {
                    $('#force_update_app_mode').val(0);
                }
            }

            // Handle checkbox change event
            $('#force_update_app').on('change', function() {
                toggleForceUpdateMode();
                console.log("function ",$('#force_update_app_mode').val());
            });
        });

        // Version format validation
        $(document).ready(function() {
            // Real-time validation for version inputs
            $('.version-input').on('input', function() {
                var value = $(this).val();
                var versionPattern = /^[0-9]+(\.[0-9]+)*$/;
                var isValid = versionPattern.test(value) || value === '';

                // Remove any existing validation classes
                $(this).removeClass('is-valid is-invalid');

                if (value !== '') {
                    if (isValid) {
                        $(this).addClass('is-valid');
                        $(this).siblings('.invalid-feedback').remove();
                    } else {
                        $(this).addClass('is-invalid');
                        if (!$(this).siblings('.invalid-feedback').length) {
                            $(this).after('<div class="invalid-feedback">Please enter a valid version format (e.g., 1.0.0)</div>');
                        }
                    }
                }
            });

            // Prevent non-numeric and non-dot characters
            $('.version-input').on('keypress', function(e) {
                var charCode = e.which;
                var currentValue = $(this).val();
                var char = String.fromCharCode(charCode);

                // Allow backspace, delete, tab, escape, enter
                if (charCode === 8 || charCode === 9 || charCode === 27 || charCode === 13 ||
                    charCode === 46 || charCode === 110 || charCode === 190) {
                    return;
                }

                // Allow numbers (0-9)
                if (charCode >= 48 && charCode <= 57) {
                    return;
                }

                // Allow dot (.) but prevent multiple consecutive dots
                if (char === '.' && currentValue.indexOf('.') === -1) {
                    return;
                }

                // Prevent all other characters
                e.preventDefault();
            });
        });
    </script>
@endsection
