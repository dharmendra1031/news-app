(function () {
    if (typeof jQuery === 'undefined' || !jQuery.validator) {
        return;
    }

    function t(key, fallback) {
        return typeof window.trans === 'function' ? window.trans(key, fallback) : fallback;
    }

    function getFieldLabel(element) {
        var $el = jQuery(element);

        if (element.id) {
            var $for = jQuery('label[for="' + element.id + '"]').first();
            if ($for.length) {
                return cleanLabel($for);
            }
        }

        var $group = $el.closest('.form-group, .form-check, .mb-3, .field');
        if ($group.length) {
            var $label = $group.find('label').first();
            if ($label.length) {
                return cleanLabel($label);
            }
        }

        var placeholder = $el.attr('placeholder');
        if (placeholder) return placeholder;

        var name = $el.attr('name') || element.name || '';
        return name.replace(/[_\-\[\]]+/g, ' ').trim();
    }

    function cleanLabel($label) {
        var text = $label.clone().children().remove().end().text();
        return text.replace(/[\s:*]+$/g, '').trim();
    }

    function format(template, field) {
        return String(template).replace(/:field/g, field).replace(/\{0\}/g, field);
    }

    function fmtN(template, field, value) {
        return String(template).replace(/:field/g, field).replace(/:value|\{0\}/g, value);
    }

    jQuery.extend(jQuery.validator.messages, {
        required: function (_p, el) {
            var $el = jQuery(el);
            var field = getFieldLabel(el);

            // Check file inputs
            if ($el.attr('type') === 'file') {

                var accept = $el.attr('accept') || '';

                // Image files
                if (accept.includes('image')) {
                    return t(
                        'image_field_is_required',
                        'The image field is required.'
                    );
                }

                // PDF files
                if (accept.includes('pdf')) {
                    return t(
                        'pdf_field_is_required',
                        'The PDF field is required.'
                    );
                }

                // Video files
                if (accept.includes('video')) {
                    return t(
                        'video_field_is_required',
                        'The video field is required.'
                    );
                }

                // Audio files
                if(accept.includes('audio')){
                    return t(
                          'audio_field_is_required',
                        'The audio field is required.'
                    );
                }

            }
            return format(t('the_field_is_required', 'The :field field is required.'), getFieldLabel(el));
        },
        email: function (_p, el) {
            return format(t('the_field_must_be_valid_email', 'The :field must be a valid email address.'), getFieldLabel(el));
        },
        url: function (_p, el) {
            return format(t('the_field_must_be_valid_url', 'The :field must be a valid URL.'), getFieldLabel(el));
        },
        number: function (_p, el) {
            return format(t('the_field_must_be_number', 'The :field must be a number.'), getFieldLabel(el));
        },
        digits: function (_p, el) {
            return format(t('the_field_must_be_digits', 'The :field may only contain digits.'), getFieldLabel(el));
        },
        maxlength: function (p, el) {
            return fmtN(t('the_field_max_length', 'The :field may not be greater than :value characters.'), getFieldLabel(el), p);
        },
        minlength: function (p, el) {
            return fmtN(t('the_field_min_length', 'The :field must be at least :value characters.'), getFieldLabel(el), p);
        },
        equalTo: function (_p, el) {
            return format(t('the_field_must_match', 'The :field must match the previous field.'), getFieldLabel(el));
        }
    });
})();
