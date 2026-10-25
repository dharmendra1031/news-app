@extends('layouts.main')

@section('title')
    {{ __('firebase_configuration') }}
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
                        <li class="breadcrumb-item active"><i class="fas fa-cog mr-1"></i>{{ __('firebase_configuration') }}</li>
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
                            <h3 class="card-title">{{ __('firebase_configuration') }}</h3>
                        </div>
                        <form action="{{ route('firebase-configuration.store') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    {{-- project id input text --}}
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="control-label required">{{ __('project_id') }}</label>
                                        <input name="project_id" type="text" value="{{ $project_id?->message ?? '' }}" required class="form-control">
                                    </div>
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="control-label">
                                            {{ __('current_file_status') }} :
                                            @if ($is_file)
                                                <small class="badge badge-success">{{ __('file_exists') }}</small>
                                            @else
                                                <small class="badge badge-danger">{{ __('file_not_exists') }}</small>
                                            @endif
                                        </label>
                                        {{-- only json files allowed --}}
                                        <input name="file" type="file" class="filepond-json" accept="application/json" required>

                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-12 col-sm-12">
                                        <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                                    </div>
                                </div>
                            </div>
                        </form>
                        <hr>
                        <div class="card-body">
                            <ol>
                                <li>{{__('open')}} <a href="https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk" target="_blank">https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk </a> {{__('and_select_project')}}</li>
                                <li>{{__('click_generate_new_private_key')}}</b>.
                                    <img src="{{ url('images/generate-key.png') }}" width="100%" />
                                </li>
                                {{-- setup : inside the json file copy the project id and insert it in the project id input text --}}
                                {{-- <li> --}}
                                    {{-- <b>{{__('setup')}}</b> --}}
                                    {{-- <ol> --}}
                                        <li>{{__('inside_the_json_file_copy_the_project_id_and_insert_it_in_the_project_id_input_text')}}</li>
                                    {{-- </ol> --}}
                                {{-- </li> --}}
                            </ol>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection
