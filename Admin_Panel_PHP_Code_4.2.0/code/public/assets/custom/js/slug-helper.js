/**
 * slug-helper.js
 *
 * Generic, reusable slug auto-generation helper.
 *
 * Usage – add the following data attributes to ANY title/name input:
 *
 *   data-slug-table   {string}  DB table name passed to the get-slug endpoint  (REQUIRED)
 *   data-slug-target  {string}  CSS selector of the slug <input> to populate   (REQUIRED)
 *   data-slug-key     {string}  Request key for the title value  (default: "name")
 *   data-slug-id      {string}  CSS selector of the edit-id <input> to include "id"
 *                               in the request when editing an existing record   (OPTIONAL)
 *
 * Example – create form input:
 *   <input id="title"
 *          data-slug-table="tbl_news"
 *          data-slug-target="#slug">
 *
 * Example – edit form input:
 *   <input id="edit_title"
 *          data-slug-table="tbl_news"
 *          data-slug-target="#edit_slug"
 *          data-slug-id="#edit_id">
 *
 * The endpoint URL is resolved from `window.getSlugUrl` (set automatically by
 * the Blade layout) so the route helper is called only once on the server.
 */

(function ($) {
    'use strict';

    /**
     * Core function – kept on window so legacy callers can still invoke it
     * directly if needed:  getSlug({ name: 'Foo', table: 'tbl_news' }, '#title', '#slug')
     *
     * @param {Object} data   - POST payload (must already contain `table`)
     * @param {string} title  - CSS selector of the source input (used to clear slug when empty)
     * @param {string} target - CSS selector of the target slug input
     */
    window.getSlug = function (data, title, target) {
        var titleVal = $(title).val();

        if (!titleVal) {
            $(target).val('');
            return;
        }

        data['_token'] = $('meta[name="csrf-token"]').attr('content')
            || (typeof window.csrfToken !== 'undefined' ? window.csrfToken : '');

        $.ajax({
            url: window.getSlugUrl,
            type: 'POST',
            data: data,
            success: function (result) {
                if (result) {
                    $(target).val(result);
                }
            },
            error: function (errors) {
                console.error('[slug-helper] getSlug error:', errors);
            },
        });
    };

    /** Debounce delay in milliseconds – adjust here if needed. */
    var DEBOUNCE_DELAY = 400;

    /** Per-element timer map keyed by input id. */
    var _timers = {};

    /**
     * Auto-wire: listen for keyup on any input that carries `data-slug-table`.
     * Works for inputs added to the DOM at any time (delegated via document).
     * Requests are debounced so the endpoint is only hit after the user
     * stops typing for DEBOUNCE_DELAY ms.
     */
    $(document).on('keyup', '[data-slug-table]', function () {
        var $input  = $(this);
        var id      = this.id;
        var table   = $input.data('slug-table');
        var target  = $input.data('slug-target');
        var key     = $input.data('slug-key') || 'name';
        var idField = $input.data('slug-id');

        if (!table || !target) {
            console.warn('[slug-helper] Missing data-slug-table or data-slug-target on', this);
            return;
        }

        clearTimeout(_timers[id]);

        _timers[id] = setTimeout(function () {
            var data = { table: table };
            data[key] = $input.val();

            if (idField) {
                var idVal = $(idField).val();
                if (idVal) {
                    data['id'] = idVal;
                }
            }

            window.getSlug(data, '#' + id, target);
        }, DEBOUNCE_DELAY);
    });

})(jQuery);
