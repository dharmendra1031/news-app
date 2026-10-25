/**
 * Select2 Custom Translation Override
 * This file overrides Select2's default English translations with our custom trans() function
 */

// Function to initialize Select2 translations
function initSelect2Translations() {
    if (typeof $.fn.select2 !== 'undefined' && typeof trans === 'function') {
        // console.log('Initializing Select2 translations...'); // Debug log

        // Override Select2's language settings
        $.fn.select2.defaults.set('language', {
            errorLoading: function() {
                return trans('The results could not be loaded.');
            },
            inputTooLong: function(args) {
                var remainingChars = args.input.length - args.maximum;
                var message = trans('Please delete') + ' ' + remainingChars + ' ' + trans('character');
                if (remainingChars !== 1) {
                    message += 's';
                }
                return message;
            },
            inputTooShort: function(args) {
                return trans('Please enter') + ' ' + (args.minimum - args.input.length) + ' ' + trans('or more characters');
            },
            loadingMore: function() {
                return trans('Loading more results…');
            },
            maximumSelected: function(args) {
                var message = trans('You can only select') + ' ' + args.maximum + ' ' + trans('item');
                if (args.maximum !== 1) {
                    message += 's';
                }
                return message;
            },
            noResults: function() {
                return trans('No results found');
            },
            searching: function() {
                return trans('Searching…');
            },
            removeAllItems: function() {
                return trans('Remove all items');
            },
            removeItem: function() {
                return trans('Remove item');
            },
            search: function() {
                return trans('Search');
            }
        });

        // console.log('Select2 translations initialized'); // Debug log
    }
}

// Wait for DOM and translations to be ready
$(document).ready(function() {
    // Try to initialize immediately
    initSelect2Translations();

    // Also try after a short delay in case translations are still loading
    setTimeout(function() {
        initSelect2Translations();
    }, 100);

    // Re-initialize any existing Select2 elements
    $('.select2').each(function() {
        if ($(this).hasClass('select2-hidden-accessible')) {
            $(this).select2('destroy');
            $(this).select2();
        }
    });
});

if (typeof window.translations !== 'undefined') {
    // Override immediately
    if (typeof $.fn.select2 !== 'undefined') {
        $.fn.select2.defaults.set('language', {
            errorLoading: function() {
                return window.translations['The results could not be loaded.'] || 'The results could not be loaded.';
            },
            noResults: function() {
                return window.translations['No results found'] || 'No results found';
            },
            searching: function() {
                return window.translations['Searching…'] || 'Searching…';
            },
            search: function() {
                return window.translations['Search'] || 'Search';
            }
            // Add other translations as needed
        });
    }
}
