@extends('layouts.main')

@section('title')
    {{ __('system_update') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('system_update') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ url('system-settings') }}" class="text-dark"><i class="nav-icon fas fa-cogs mr-1"></i>{{ __('system_setting') }}</a>
                        </li>
                        <li class="breadcrumb-item active"><i class="fas fas fa-upload mr-1"></i>{{ __('system_update') }}</li>
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
                            <h3 class="card-title">{{ __('system_update') }}
                                <small class="text-bold"> {{ __('current_version') }} <?= $setting ? $setting['app_version'] : '' ?></small>
                            </h3>
                        </div>
                        <form id="create_form" action="{{ route('system-update-operation') }}" role="form" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="form-group row">
                                    <div class="col-md-6 col-sm-12">
                                        <label>{{ __('purchase_code') }}</label>
                                        <input type="text" name="purchase_code" required placeholder="{{ __('purchase_code') }}" class="form-control" />
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <div class="col-md-6 col-sm-12">
                                        <label>{{ __('update_zip') }} <small class="text-danger">{{ __('only_zip_file_allow') }} </small></label>
                                        <div class="custom-file">
                                            <input name="file" type="file" required class="form-control">
                                            <small class="text-danger">
                                                {{ $setting ? $setting['app_version'] : '' }} {{ __('update_nearest_version') }}
                                            </small>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <div class="col-12 text-right">
                                        <button type="submit" class="btn btn-primary">{{ __('submit') }} </button>
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
