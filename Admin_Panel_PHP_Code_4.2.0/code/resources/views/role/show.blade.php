@extends('layouts.main')

@section('title')
    {{ __('Role Details') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('role_details') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i>{{ __('dashboard') }}</a>
                        </li>
                        <li class="breadcrumb-item">
                            <a href="{{ route('roles.index') }}" class="text-dark"><i class="nav-icon fas fa-user-tag mr-1"></i>{{ __('roles') }}</a>
                        </li>
                        <li class="breadcrumb-item active">{{ __('view') }}</li>
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
                            <h3 class="card-title">{{ __('role_view') }} : {{ $role->name }}</h3>
                        </div>
                        <div class="card-body">
                            <div class="row mt-4">
                                <div class="col-12">
                                    <h5 class="font-weight-bold">{{ __('assigned_permissions') }}</h5>
                                    <div class="card">
                                        <div class="card-body" id="permissions-container">
                                            @foreach($permissions as $group => $permissionGroup)
                                                <div class="permission-group mb-4">
                                                    <div class="row ml-4">
                                                        @foreach($permissionGroup as $permission)
                                                            <div class="col-md-3 col-sm-6 mb-2">
                                                                <div class="custom-control custom-checkbox">
                                                                    <input type="checkbox" class="custom-control-input" 
                                                                           id="permission-{{ $permission->id }}" 
                                                                           value="{{ $permission->id }}"
                                                                           {{ $role->permissions->contains($permission->id) ? 'checked' : '' }}
                                                                           disabled>
                                                                    <label class="custom-control-label" for="permission-{{ $permission->id }}">
                                                                        {{ __($permission->name) }}
                                                                    </label>
                                                                </div>
                                                            </div>
                                                        @endforeach
                                                    </div>
                                                </div>
                                            @endforeach
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="row">
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('users_with_this_role') }}</h3>
                        </div>
                        <div class="card-body">
                            @if($users->count() > 0)
                                <div class="table-responsive">
                                    <table class="table table-bordered table-striped">
                                        <thead>
                                            <tr>
                                                <th>{{ __('username') }}</th>
                                                <th>{{ __('email') }}</th>
                                                <th>{{ __('status') }}</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            @foreach($users as $user)
                                                <tr>
                                                    <td>{{ $user->username }}</td>
                                                    <td>{{ $user->email }}</td>
                                                    <td>
                                                        @if($user->status == 1)
                                                            <span class="badge badge-success">{{ __('active') }}</span>
                                                        @else
                                                            <span class="badge badge-danger">{{ __('inactive') }}</span>
                                                        @endif
                                                    </td>
                                                </tr>
                                            @endforeach
                                        </tbody>
                                    </table>
                                </div>
                            @else
                                <div class="alert alert-info">
                                    {{ __('no_users_with_this_role') }}
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection 