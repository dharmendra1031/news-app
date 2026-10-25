<!-- Google Font: Outfit (TailAdmin original font) -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Outfit:wght@100..900&display=swap">
<!-- Font Awesome -->
<link href="{{ url('assets/plugins/fontawesome-free/css/all.min.css') }}" rel="stylesheet">
<!-- iCheck -->
<link href="{{ url('assets/plugins/icheck-bootstrap/icheck-bootstrap.min.css') }}" rel="stylesheet">
<!-- JQVMap -->
<link href="{{ url('assets/plugins/jqvmap/jqvmap.min.css') }}" rel="stylesheet">

{{-- Theme style --}}
@php
    $currentLang = session('locale');

    if (!$currentLang) {
        $defaultLang = get_default_language();
        $currentLang = $defaultLang?->code ?? 'en';
        session(['locale' => $currentLang]);
    }

    // $language = \App\Models\Language::where('code', $currentLang)->first();
    // $isRTL = $language && $language->isRTL == 1;
@endphp
{{-- <!-- Base Theme style -->
<link href="{{ url('assets/dist/css/adminlte.min.css') }}" rel="stylesheet">
<link href="{{ url('assets/dist/css/adminlte.css') }}" rel="stylesheet"> --}}

<link href="{{ url('assets/dist/css/tailadmin.bundle.min.css') }}" rel="stylesheet">

<!-- overlayScrollbars -->
<link href="{{ url('assets/plugins/overlayScrollbars/css/OverlayScrollbars.min.css') }}" rel="stylesheet">

{{-- bootstrape switch --}}
<link href="{{ url('assets/plugins/bootstrap-switch/css/bootstrap3/bootstrap-switch.css') }}" rel="stylesheet">

<link href="{{ url('assets/custom/css/sweetalert2.min.css') }}" rel="stylesheet">
<link href="{{ url('assets/plugins/select2/css/select2.min.css') }}" rel="stylesheet">
{{-- Ekko Lightbox --}}
<link href="{{ url('assets/plugins/ekko-lightbox/ekko-lightbox.css') }}" rel="stylesheet">
<link href="{{ url('assets/custom/css/switchery.min.css') }}" rel="stylesheet">
<link href="{{ url('assets/plugins/tagify/tagify.css') }}" rel="stylesheet">

<!-- filepond Css -->
<link href="{{ url('assets/plugins/filepond/css/filepond.min.css') }}" rel="stylesheet" type="text/css" />
<link href="{{ url('assets/plugins/filepond/css/filepond-plugin-image-preview.min.css') }}" rel="stylesheet"
    type="text/css" />
<link href="{{ url('assets/plugins/filepond/css/filepond-plugin-media-preview.min.css') }}" rel="stylesheet"
    type="text/css" />
<link href="{{ url('assets/plugins/filepond/css/filepond-plugin-pdf-preview.min.css') }}" rel="stylesheet"
    type="text/css" />

<link href="{{ url('assets/plugins/bootstrap-table/dist/bootstrap-table.min.css') }}" rel="stylesheet">
<link href="{{ url('assets/plugins/bootstrap-table/extensions/fixed-columns/bootstrap-table-fixed-columns.min.css') }}"
    rel="stylesheet">

<!-- Custom styles should be loaded last -->
<link href="{{ url('assets/custom/css/custom.css') }}?v=1.5" rel="stylesheet">
@if($isRTL)
    <link href="{{ url('assets/custom/css/rtl.css') }}" rel="stylesheet">
@endif