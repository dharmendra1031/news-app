@extends('layouts.main')

@section('title')
    {{ __('Edit Role') }}
@endsection

@section('content')
<section class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h1 class="m-0">{{ __('edit') . ' ' . __('role') }}</h1>
            </div>
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item">
                        <a href="{{ route('home') }}" class="text-dark"><i class="fas fa-home mr-1"></i> {{ __('dashboard') }}</a>
                    </li>
                    <li class="breadcrumb-item">
                        <a href="{{ route('roles.index') }}" class="text-dark"><i class="fas fa-user-tag mr-1"></i> {{ __('roles') }}</a>
                    </li>
                    <li class="breadcrumb-item active">{{ __('edit') }}</li>
                </ol>
            </div>
        </div>
    </div>
</section>

<!-- Role Edit Form -->
<section class="content">
    <div class="container-fluid">
        <form  method="POST" action="{{ route('roles.update', $role->id) }}">
            @csrf
            @method('PUT')

            <div class="row">
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('edit') . ' ' . __('role') }}: {{ $role->name }}</h3>
                        </div>

                        <div class="card-body">

                            <!-- Role Name Input -->
                            <div class="form-group">
                                <label class="required">{{ __('role_name') }}</label>
                                <input type="text" class="form-control" name="name" value="{{ old('name', $role->name) }}" required>
                                @error('name')
                                    <span class="text-danger">{{ $message }}</span>
                                @enderror
                            </div>

                            <!-- Permissions Section -->
                            <div class="form-group">
                                <label class="required">{{ __('permissions') }}</label>
                                <div class="card">
                                    <div class="card-header">
                                        <div class="custom-control custom-checkbox">
                                            <input type="checkbox" class="custom-control-input" id="select-all-permissions">
                                            <label class="custom-control-label font-weight-bold" for="select-all-permissions">
                                                {{ __('select_all_permissions') }}
                                            </label>
                                        </div>
                                    </div>
                                    <div class="card-body">
                                        <div class="row">
                                            @foreach($permissions as $permission)
                                                <div class="col-md-3 col-sm-6 mb-2">
                                                    <div class="custom-control custom-checkbox">
                                                        <input type="checkbox" class="custom-control-input permission-checkbox"
                                                        id="permission-{{ $permission->id }}" name="permissions[]"
                                                        value="{{ $permission->id }}"
                                                        {{ in_array($permission->id, old('permissions', $role->permissions->pluck('id')->toArray())) ? 'checked' : '' }}>

                                                        <label class="custom-control-label" for="permission-{{ $permission->id }}">
                                                            {{ __($permission->name) }}
                                                        </label>
                                                    </div>
                                                </div>
                                            @endforeach
                                        </div>
                                    </div>
                                </div>
                                @error('permissions')
                                    <span class="text-danger">{{ $message }}</span>
                                @enderror
                            </div>

                            <!-- Action Buttons -->
                            <div class="row mt-3">
                                <div class="col-12">
                                    <a href="{{ route('roles.index') }}" class="btn btn-default">{{ __('cancel') }}</a>
                                    <button type="submit" class="btn btn-primary float-right" id="update-btn">{{ __('update') }}</button>
                                </div>
                            </div>
                        </div> <!-- /.card-body -->
                    </div>
                </div>
            </div>
        </form>
    </div>
</section>
@endsection

@section('script')
<script>
$(document).ready(function () {
    // Check "Select All" if all permissions are already checked
    updateSelectAllCheckbox();

    // Check/uncheck all permissions
    $('#select-all-permissions').on('change', function() {
        var isChecked = $(this).prop('checked');
        $('.permission-checkbox').prop('checked', isChecked);
    });

    // Update "Select All" checkbox when individual permissions change
    $('.permission-checkbox').on('change', function() {
        updateSelectAllCheckbox();
    });

    function updateSelectAllCheckbox() {
        var allChecked = $('.permission-checkbox').length === $('.permission-checkbox:checked').length;
        $('#select-all-permissions').prop('checked', allChecked);
    }
});

</script>
@endsection
