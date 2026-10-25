<!-- jQuery -->
<script src="{{ url('assets/plugins/jquery/jquery.min.js') }}"></script>
<!-- jQuery UI 1.11.4 -->
<script src="{{ url('assets/plugins/jquery-ui/jquery-ui.min.js') }}"></script>
<!-- Resolve conflict in jQuery UI tooltip with Bootstrap tooltip -->
<script type="text/javascript">
    $.widget.bridge('uibutton', $.ui.button)
</script>
<!-- Bootstrap 4 -->
<script src="{{ url('assets/plugins/bootstrap/js/bootstrap.bundle.min.js') }}"></script>

<script src="{{ url('assets/plugins/bootstrap-switch/js/bootstrap-switch.js') }}"></script>
<script src="{{ url('assets/plugins/bootstrap-switch/js/bootstrap-switch.min.js') }}"></script>


<script src="{{ url('assets/plugins/moment/moment.min.js') }}"></script>
<!-- overlayScrollbars -->
<script src="{{ url('assets/plugins/overlayScrollbars/js/jquery.overlayScrollbars.min.js') }}"></script>
{{-- AdminLTE theme (disabled; TailAdmin active) --
<!-- Disable AdminLTE auto height BEFORE it initialises (it runs on window.load) -->
<script>
    (function () {
        try {
            var b = document.body;
            if (b) {
                b.setAttribute('data-panel-auto-height', 'false');
                b.setAttribute('data-login-register-auto-height', 'false');
            }
            if (window.jQuery) {
                var $b = window.jQuery('body');
                $b.data('panelAutoHeight', false);
                $b.data('loginRegisterAutoHeight', false);
            }
        } catch (e) {}
        function earlyPatch() {
            if (!window.jQuery || !window.jQuery.fn.Layout || !window.jQuery.fn.Layout.Constructor) return false;
            var Ctor = window.jQuery.fn.Layout.Constructor;
            try { Ctor.Default.panelAutoHeight = false; } catch (e2) {}
            if (Ctor.prototype && Ctor.prototype.fixLayoutHeight && !Ctor.prototype._taPatched) {
                Ctor.prototype._taPatched = true;
                Ctor.prototype.fixLayoutHeight = function () {
                    var $body = window.jQuery('body');
                    if (!$body.hasClass('layout-fixed')) return;
                    var $sb = window.jQuery('.main-sidebar .sidebar');
                    if ($sb.length === 0) $sb = window.jQuery('.main-sidebar');
                    if (typeof window.jQuery.fn.overlayScrollbars !== 'undefined') {
                        $sb.overlayScrollbars({ className: 'os-theme-light', sizeAutoCapable: true, scrollbars: { autoHide: 'l', clickScrolling: true } });
                    } else { $sb.css('overflow-y', 'auto'); }
                };
            }
            return true;
        }
        if (!earlyPatch()) {
            var n = 0, t = setInterval(function(){ if (earlyPatch() || ++n>50) clearInterval(t); }, 50);
        }
    })();
</script>
<!-- AdminLTE App -->
<script src="{{ url('assets/dist/js/adminlte.js') }}"></script>
<!-- AdminLTE for demo purposes -->
<script src="{{ url('assets/dist/js/demo.js') }}"></script>
--}}

<script src="{{ url('assets/dist/js/layout.js') }}"></script>
<!-- AdminLTE dashboard demo (This is only for demo purposes) -->

<script src="{{ url('assets/custom/js/sweetalert2.all.min.js') }}"></script>

<script src="{{ url('assets/plugins/ekko-lightbox/ekko-lightbox.min.js') }}"></script>

<script src="{{ url('assets/plugins/bootstrap-table/dist/bootstrap-table.min.js') }}"></script>
<script src="{{ url('assets/plugins/bootstrap-table/extensions/fixed-columns/bootstrap-table-fixed-columns.min.js') }}"></script>
<script src="{{ url('assets/plugins/bootstrap-table/extensions/mobile/bootstrap-table-mobile.min.js') }}"></script>
<script src="{{ url('assets/plugins/bootstrap-table/extensions/resizable/bootstrap-table-resizable.min.js') }}"></script>

<script type="text/javascript" src="{{ url('assets/custom/js/actionEvents.js') }}"></script>


<!-- start :: include FilePond library -->
<script src="{{ url('assets/plugins/filepond/js/filepond.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-image-preview.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-image-validate-size.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-media-preview.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-file-validate-size.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-file-validate-type.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond-plugin-pdf-preview.min.js') }}"></script>
<script src="{{ url('assets/plugins/filepond/js/filepond.jquery.js') }}"></script>
<!-- end :: include FilePond library -->

<!-- Ekko Lightbox -->
<script src="{{ url('assets/plugins/ekko-lightbox/ekko-lightbox.min.js') }}"></script>

<script src="{{ url('assets/custom/js/switchery.min.js') }}"></script>
<script src="{{ url('assets/plugins/tagify/tagify.min.js') }}"></script>

<script src="{{ url('assets/plugins/tinymce/tinymce.min.js') }}"></script>
<script type="text/javascript">
    // Theme-aware TinyMCE options: picks oxide / oxide-dark UI skin and matching
    // content CSS based on the app dark-mode state (ta.darkMode).
    function tinyThemeConfig() {
        var dark = false;
        try { dark = localStorage.getItem('ta.darkMode') === '1'; } catch (e) {}
        var base = "{{ url('/') }}/assets/plugins/tinymce";
        if (dark) {
            return {
                skin: 'oxide-dark',
                content_css: base + '/skins/content/dark/content.min.css'
            };
        }
        return {
            skin: 'oxide',
            content_css: base + '/skins/content/default/content.min.css'
        };
    }

    // Theme-aware TinyMCE initializer. Registers each editor's user options so
    // that toggling dark mode can destroy + re-init the editor with the matched
    // skin while preserving its content (no page refresh needed).
    var _taEditorOpts = {};

    function _taEditorIds(selector) {
        return selector.split(',').map(function (s) { return s.trim().replace(/^#/, ''); }).filter(Boolean);
    }

    function _taRebuildEditor(selector) {
        var userOpts = _taEditorOpts[selector];
        if (!userOpts) return;
        var ids = _taEditorIds(selector);
        ids.forEach(function (id) {
            var ed = tinymce.get(id);
            if (ed) {
                var textarea = document.getElementById(id);
                if (textarea) textarea.value = ed.getContent();
                ed.remove();
            }
        });
        tinymce.init(Object.assign({}, tinyThemeConfig(), userOpts, { selector: selector }));
    }

    function initThemeAwareTinyMCE(selector, userOpts) {
        _taEditorOpts[selector] = userOpts;
        _taRebuildEditor(selector);
    }

    document.addEventListener('ta:theme-changed', function () {
        Object.keys(_taEditorOpts).forEach(_taRebuildEditor);
    });
</script>

<script src="{{ url('assets/plugins/jquery-validation/jquery.validate.min.js') }}"></script>
<script src="{{ url('assets/plugins/jquery-validation/additional-methods.min.js') }}"></script>

<script type="text/javascript">
    $(function() {
        $(document).on('click', '[data-toggle="lightbox"]', function(event) {
            event.preventDefault();
            $(this).ekkoLightbox({
                alwaysShowClose: true
            });
        });
        if (document.getElementById("meta_tags") != null) {
            var input = document.querySelector('input[id=meta_tags]');
            new Tagify(input);
        }

        if (document.getElementById("edit_meta_tags") != null) {
            var input1 = document.querySelector('input[id=edit_meta_tags]');
            new Tagify(input1);
        }
    });


    $('#create_form').validate({
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

    $('#update_form').validate({
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

</script>


{{--Language Translation--}}
<script src="{{route('common.language.read')}}"></script>

<!-- start :: include i18n library -->
<script src="{{ url('assets/custom/js/i18n.js') }}"></script>
<!-- end :: include i18n library -->

<!-- Global jQuery Validation messages (label-aware, translatable) -->
<script src="{{ url('assets/custom/js/validation-messages.js') }}"></script>

<script type="text/javascript" src="{{ url('assets/custom/js/bootstrap-table-locale.js') }}"></script>

<script src="{{ url('assets/custom/js/custom.js') }}"></script>

{{-- Slug helper: expose the route URL once so slug-helper.js never needs Blade --}}
<script>window.getSlugUrl = '{{ route('get-slug') }}';</script>
<script src="{{ url('assets/custom/js/slug-helper.js') }}"></script>
<script src="{{ url('assets/custom/js/bootstrap-table/formatter.js') }}"></script>
<script src="{{ url('assets/custom/js/bootstrap-table/queryParams.js') }}"></script>


<!-- Select2 -->
<script src="{{ url('assets/plugins/select2/js/select2.min.js') }}"></script>


<!-- Then include your custom translation override -->
<script src="{{ asset('assets/custom/js/select2-locale.js') }}"></script>

@if (Session::has('error'))
    <script type='text/javascript'>
        showErrorToast('{{ Session::get('error') }}');
    </script>
@endif
@if (Session::has('success'))
    <script type='text/javascript'>
        showSuccessToast('{{ Session::get('success') }}');
    </script>
@endif

