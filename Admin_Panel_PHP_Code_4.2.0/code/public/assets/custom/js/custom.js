function trans(label) {
    return window.languageLabels && window.languageLabels.hasOwnProperty(label)
        ? window.languageLabels[label]
        : label;
}
$(function() {
	// FOUC safety net (see custom.css): if bootstrap-table JS fails to
	// initialise (blocked CDN, JS error, ...), the raw tables/toolbars
	// hidden by CSS would stay hidden forever. After 4s, force-show any
	// table that is still a direct child of .card-body (i.e. never wrapped
	// in div.bootstrap-table by the plugin).
	setTimeout(function() {
		try {
			var pending = document.querySelector('.card-body > table[data-toggle="table"]');
			if (pending && !document.querySelector('.bootstrap-table table[data-toggle="table"]')) {
				document.body.classList.add('bt-fallback-show');
			} else if (pending) {
				// Mixed state (some tables initialised, some not): still unblock.
				var wrapped = document.querySelectorAll('.bootstrap-table').length;
				var raw = document.querySelectorAll('.card-body > table[data-toggle="table"]').length;
				if (raw > 0 && wrapped === 0) {
					document.body.classList.add('bt-fallback-show');
				}
			}
		} catch (e) {}
	}, 4000);

	// Hide the card body initially
	$("#add_card").hide();

	// Toggle the card body when the button is clicked
	$("#toggleButton").click(function() {
		$("#add_card").slideToggle();
	});

	$(".select2-multiple").select2();

	getWordCount("meta_title", "meta_title_count", "19.9px arial");
	getWordCount("meta_description", "meta_description_count", "12.9px arial");
	getWordCount("summarized_description", "summarized_description_count", "12.9px arial", 0, 300, "summarized_description");
	getWordCount("des", "des_count", "12.9px arial", 0, 0, "description");
	getWordCount("page_content", "page_content_count", "12.9px arial", 0, 0, "description");
	getWordCount("edit_meta_title", "edit_meta_title_count", "19.9px arial");
	getWordCount(
		"edit_meta_description",
		"edit_meta_description_count",
		"12.9px arial"
	);

	// Bulk delete toolbar: hidden by default (see custom.css), shown only
	// when at least one bootstrap-table row is selected. Global handler so
	// every list view (all use div#toolbar + data-toolbar) behaves the same.
	function toggleBulkToolbar($table) {
		var toolbarSel = $table.data("toolbar") || "#toolbar";
		var $toolbar = $(toolbarSel);
		if (!$toolbar.length) {
			return;
		}
		var selections = [];
		try {
			selections = $table.bootstrapTable("getSelections") || [];
		} catch (e) {
			selections = [];
		}
		var show = selections.length > 0;
		$toolbar.toggleClass("bulk-visible", show);
		// Only the bulk buttons are selection-gated; the toolbar itself may
		// also hold always-visible filters (e.g. Tag language filter).
		var $bulkBtns = $toolbar.find("#bulk_delete, #bulk_order_update, #commentflag_bulk_delete");
		if ($bulkBtns.length) {
			$bulkBtns.toggle(show);
		}
		var hasFilter = $toolbar.find("select, input[type='text'], input[type='search']").length > 0;
		var keepVisible = show || hasFilter;
		// bootstrap-table moves #toolbar inside a .bs-bars wrapper; hide the
		// wrapper too so no empty gap remains, otherwise toggle #toolbar itself.
		var $bars = $toolbar.closest(".bs-bars");
		if ($bars.length) {
			$bars.toggle(keepVisible);
		} else {
			$toolbar.toggle(keepVisible);
		}
	}
	$(document).on(
		"check.bs.table uncheck.bs.table check-all.bs.table uncheck-all.bs.table load-success.bs.table page-change.bs.table",
		'table[data-toggle="table"]',
		function () {
			toggleBulkToolbar($(this));
		}
	);
	$('table[data-toggle="table"]').each(function () {
		toggleBulkToolbar($(this));
	});
	// Sidebar: a full page load resets the scrollable .main-sidebar to the
	// top, hiding the active (often far-below) menu item. If the active link
	// is out of view, scroll the sidebar so it is visible again (centered).
	try {
		var sidebarEl = document.querySelector('.main-sidebar');
		var activeLink = sidebarEl ? sidebarEl.querySelector('.nav-sidebar .nav-link.active') : null;
		if (sidebarEl && activeLink) {
			var sbRect = sidebarEl.getBoundingClientRect();
			var linkRect = activeLink.getBoundingClientRect();
			if (linkRect.top < sbRect.top || linkRect.bottom > sbRect.bottom) {
				var linkTop = linkRect.top - sbRect.top + sidebarEl.scrollTop;
				sidebarEl.scrollTop = linkTop - sidebarEl.clientHeight / 2 + activeLink.offsetHeight / 2;
			}
		}
	} catch (e) {}
	// Operate-column menus (last column).
	// .fixed-table-container is a clipping box (overflow:hidden, see
	// custom.css) so the table keeps its rounded border — but that also
	// clips this menu, which is why the bundle forced overflow:visible
	// and broke the border. So the menu is moved to <body> and placed
	// from the toggle's viewport rect instead: no clipping ancestor is
	// left, and the menu may overlap the table / card / pagination.
	// Body-level styles for the detached menu live in custom.css
	// (.table-operate-menu). Delegated, so rows re-rendered by
	// bootstrap-table (pagination/sort/search) are covered too.
	var tableOperateMenuPad = 8;
	var tableOperateMenuGap = 4;
	var tableOperateMenuFrame = null;

	// Shared through window: custom.js can be re-executed by
	// jQuery's $.globalEval, and a stale copy must act on the same menu.
	function tableOperateMenuState() {
		return window.__tableOperateMenu || null;
	}

	// Put a detached menu back inside its .dropdown (or drop it when the
	// row was re-rendered and the .dropdown is gone).
	function tableOperateMenuReattach() {
		var state = window.__tableOperateMenu;
		window.__tableOperateMenu = null;
		if (!state) {
			return;
		}
		var $menu = state.$menu,
			$dropdown = state.$dropdown;
		if (!$menu.length) {
			return;
		}
		$menu.removeClass("table-operate-menu");
		// Drop every inline property we wrote plus Popper's leftovers, so
		// the menu goes back to being positioned by the .dropdown itself.
		$menu[0].removeAttribute("style");
		if ($dropdown.length && document.body.contains($dropdown[0])) {
			$dropdown.append($menu);
		} else {
			$menu.remove();
		}
	}

	// Right-align the menu with the toggle and keep it on screen: below
	// when there is room, flipped above when there is not, always inside
	// the viewport. position is fixed, so these are viewport coordinates.
	function tableOperateMenuPlace() {
		var state = tableOperateMenuState();
		if (!state) {
			return;
		}
		var $menu = state.$menu,
			$toggle = state.$toggle;
		// Row re-rendered while the menu was open: nothing to anchor to.
		if (!$toggle.length || !document.body.contains($toggle[0])) {
			tableOperateMenuReattach();
			return;
		}
		var vw = window.innerWidth || document.documentElement.clientWidth;
		var vh = window.innerHeight || document.documentElement.clientHeight;
		var toggleRect = $toggle[0].getBoundingClientRect();

		// Measure unconstrained first, then cap + scroll if it cannot fit.
		// Bootstrap triggers show.bs.dropdown *before* it puts .show on the
		// menu, so the menu still measures 0x0 here: lay it out (invisible)
		// to get a real box, then hand it straight back to bootstrap.
		var style = $menu[0].style;
		style.display = "block";
		style.visibility = "hidden";
		style.maxHeight = "";
		var menuHeight = $menu[0].offsetHeight;
		var menuWidth = $menu[0].offsetWidth;
		if (menuHeight + tableOperateMenuPad * 2 > vh) {
			style.maxHeight = vh - tableOperateMenuPad * 2 + "px";
			menuHeight = $menu[0].offsetHeight;
		}

		var top;
		if (toggleRect.bottom + tableOperateMenuGap + menuHeight <= vh - tableOperateMenuPad) {
			top = toggleRect.bottom + tableOperateMenuGap;
		} else if (toggleRect.top - tableOperateMenuGap - menuHeight >= tableOperateMenuPad) {
			top = toggleRect.top - tableOperateMenuGap - menuHeight;
		} else {
			top = Math.max(tableOperateMenuPad, vh - tableOperateMenuPad - menuHeight);
		}
		// Right edge aligned with the toggle, then clamped to the viewport.
		var left = Math.max(tableOperateMenuPad, Math.min(toggleRect.right - menuWidth, vw - tableOperateMenuPad - menuWidth));

		// Written inline (not via the stylesheet): Popper has left
		// position/transform/right/bottom inline on this element, and inline
		// styles outrank .table-operate-menu, so they have to be reset here.
		style.position = "fixed";
		style.display = "";
		style.visibility = "";
		style.right = "auto";
		style.bottom = "auto";
		style.margin = "0";
		style.transform = "none";
		style.willChange = "auto";
		style.top = top + "px";
		style.left = left + "px";
	}

	function tableOperateMenuSchedule() {
		if (tableOperateMenuFrame) {
			return;
		}
		tableOperateMenuFrame = window.requestAnimationFrame(function () {
			tableOperateMenuFrame = null;
			tableOperateMenuPlace();
		});
	}

	$(document).on("show.bs.dropdown", 'table[data-toggle="table"] .dropdown', function () {
		var $dropdown = $(this);
		// Menu is a direct child of .dropdown in every list view.
		var $menu = $dropdown.children(".dropdown-menu");
		if (!$menu.length) {
			return;
		}
		// A menu from a previous row may still be detached — and, when it was
		// opened without a click (keyboard / programmatic), still open.
		var previous = window.__tableOperateMenu;
		tableOperateMenuReattach();
		if (previous && previous.$menu.hasClass("show")) {
			previous.$menu.removeClass("show");
			previous.$dropdown.children('[data-toggle="dropdown"]').removeClass("show");
		}
		var $toggle = $dropdown.children('[data-toggle="dropdown"]').first();
		$menu.addClass("dropdown-menu-right");
		// Bootstrap's Popper keeps writing inline top/left/transform for
		// an element that no longer lives under its reference, so drop it
		// and position the detached menu ourselves.
		var instance = $toggle.data("bs.dropdown");
		if (instance && instance._popper) {
			instance._popper.destroy();
			instance._popper = null;
		}
		window.__tableOperateMenu = { $menu: $menu, $dropdown: $dropdown, $toggle: $toggle };
		$("body").append($menu.addClass("table-operate-menu"));
		tableOperateMenuPlace();
		// If bootstrap never shows it (show prevented), .show never arrives —
		// take the menu back instead of stranding it on <body>.
		window.requestAnimationFrame(function () {
			var open = tableOperateMenuState();
			if (open && open.$menu.length && !open.$menu.hasClass("show")) {
				tableOperateMenuReattach();
			}
		});
	});

	// Back inside the .dropdown once bootstrap has finished hiding it.
	$(document).on("hidden.bs.dropdown", 'table[data-toggle="table"] .dropdown', function () {
		tableOperateMenuReattach();
	});

	// Safety net: if the table re-renders while a menu is open, the toggle
	// is destroyed, so the delegated hidden.bs.dropdown above never fires
	// and the menu would be stranded on <body>.
	$(document).on("load-success.bs.table post-body", 'table[data-toggle="table"]', function () {
		if (tableOperateMenuState()) {
			tableOperateMenuReattach();
		}
	});

	// Keep the detached menu glued to its toggle while the page or the
	// table scrolls (capture phase, so .fixed-table-body's horizontal
	// scroll counts too). Bound once per page, even if this file runs twice.
	if (!window.__tableOperateMenuBound) {
		window.__tableOperateMenuBound = true;
		document.addEventListener("scroll", tableOperateMenuSchedule, true);
		window.addEventListener("resize", tableOperateMenuSchedule);
	}
	// First register any plugins
	FilePond.registerPlugin(
		FilePondPluginImagePreview,
		FilePondPluginFileValidateSize,
		FilePondPluginFileValidateType
	);
	// Turn input element into a pond
	$(".filepond").filepond({
		credits: null,
		allowFileSizeValidation: "true",
		maxFileSize: "25MB",
		labelMaxFileSizeExceeded: trans('file_too_large') || "File is too large",
		labelMaxFileSize: trans('maximum_file_size') + " {filesize}" || "Maximum file size is {filesize}",
		allowFileTypeValidation: true,
		acceptedFileTypes: ["image/*"],
		labelFileTypeNotAllowed: trans('file_invalid_type') || "File of invalid type",
		// fileValidateTypeLabelExpectedTypes: "Expects {allButLastType} or {lastType}",
        fileValidateTypeLabelExpectedTypes: (trans('expects_files') || "Expects {allButLastType} or {lastType}"),
        labelIdle: `${trans('drag_drop_files') || "Drag & Drop your files"} ${trans('or') || "or"} <span class="filepond--label-action">${trans('browse') || "Browse"}</span>`,
		storeAsFile: true,
		allowPdfPreview: true,
		pdfPreviewHeight: 320,
		pdfComponentExtraParams: "toolbar=0&navpanes=0&scrollbar=0&view=fitH",
	});

	$(".filepond-video").filepond({
		credits: null,
		allowFileSizeValidation: "true",
		maxFileSize: "25MB",
		labelMaxFileSizeExceeded: trans('file_too_large') || "File is too large",
		labelMaxFileSize: trans('maximum_file_size') + " {filesize}" || "Maximum file size is {filesize}",
		allowFileTypeValidation: true,
		acceptedFileTypes: ["video/*"],
		labelFileTypeNotAllowed: trans('file_invalid_type') || "File of invalid type",
		// fileValidateTypeLabelExpectedTypes: "Expects {allButLastType} or {lastType}",
        fileValidateTypeLabelExpectedTypes: (trans('expects_files') + " {allButLastType} " + trans('or') + " {lastType}" || "Expects {allButLastType} or {lastType}"),
        labelIdle: `${trans('drag_drop_files') || "Drag & Drop your files"} ${trans('or') || "or"} <span class="filepond--label-action">${trans('browse') || "Browse"}</span>`,
		storeAsFile: true,
		allowPdfPreview: true,
		pdfPreviewHeight: 320,
		pdfComponentExtraParams: "toolbar=0&navpanes=0&scrollbar=0&view=fitH",
	});

	$(".filepond-json").filepond({
		credits: null,
		allowFileSizeValidation: "true",
		maxFileSize: "25MB",
		labelMaxFileSizeExceeded: trans('file_too_large') || "File is too large",
		labelMaxFileSize: trans('maximum_file_size') + " {filesize}" || "Maximum file size is {filesize}",
		allowFileTypeValidation: true,
		acceptedFileTypes: ["application/JSON"],
		labelFileTypeNotAllowed: trans('file_invalid_type') || "File of invalid type",
		// fileValidateTypeLabelExpectedTypes: "Expects {allButLastType} or {lastType}",
        fileValidateTypeLabelExpectedTypes: (trans('expects_files') + " {allButLastType} " + trans('or') + " {lastType}" || "Expects {allButLastType} or {lastType}"),
        labelIdle: `${trans('drag_drop_files') || "Drag & Drop your files"} ${trans('or') || "or"} <span class="filepond--label-action">${trans('browse') || "Browse"}</span>`,
		storeAsFile: true,
		allowPdfPreview: true,
		pdfPreviewHeight: 320,
		pdfComponentExtraParams: "toolbar=0&navpanes=0&scrollbar=0&view=fitH",
	});
	$(".filepond-pdf").filepond({
		credits: null,
		allowFileSizeValidation: "true",
		maxFileSize: "50MB",
		labelMaxFileSizeExceeded: trans('file_too_large') || "File is too large",
		labelMaxFileSize: trans('maximum_file_size') + " {filesize}" || "Maximum file size is {filesize}",
		allowFileTypeValidation: true,
		acceptedFileTypes: ["application/pdf"],
		labelFileTypeNotAllowed: trans('file_invalid_type') || "File of invalid type",
		fileValidateTypeLabelExpectedTypes: (trans('expects_files') + " {allButLastType} " + trans('or') + " {lastType}" || "Expects {allButLastType} or {lastType}"),
		fileValidateTypeDetectType: (source, type) =>
			new Promise((resolve, reject) => {
				if (type === 'application/pdf') {
					resolve(type);
					return;
				}
				const ext = source.name ? source.name.split('.').pop().toLowerCase() : '';
				if (ext === 'pdf') {
					resolve('application/pdf');
					return;
				}
				reject(type);
			}),
		labelIdle: `${trans('drag_drop_files') || "Drag & Drop your files"} ${trans('or') || "or"} <span class="filepond--label-action">${trans('browse') || "Browse"}</span>`,
		storeAsFile: true,
	});

    // txt file with filepond
    $(".filepond-txt").filepond({
		credits: null,
		allowFileSizeValidation: "true",
		maxFileSize: "25MB",
		labelMaxFileSizeExceeded: trans('file_too_large') || "File is too large",
		labelMaxFileSize: trans('maximum_file_size') + " {filesize}" || "Maximum file size is {filesize}",
		allowFileTypeValidation: true,
		acceptedFileTypes: ["text/plain"],
		labelFileTypeNotAllowed: trans('file_invalid_type') || "File of invalid type",
		// fileValidateTypeLabelExpectedTypes: "Expects {allButLastType} or {lastType}",
        fileValidateTypeLabelExpectedTypes: (trans('expects_files') + " {allButLastType} " + trans('or') + " {lastType}" || "Expects {allButLastType} or {lastType}"),
        labelIdle: `${trans('drag_drop_files') || "Drag & Drop your files"} ${trans('or') || "or"} <span class="filepond--label-action">${trans('browse') || "Browse"}</span>`,
		storeAsFile: true,
		allowPdfPreview: true,
		pdfPreviewHeight: 320,
		pdfComponentExtraParams: "toolbar=0&navpanes=0&scrollbar=0&view=fitH",
	});
	$('.fa').popover({
		trigger: "manual",
		html: true,
	}).on('click', function() {
		$(this).popover('toggle');
	});

	// Enable links inside the popover to be clickable
	$('body').on('click', '.popover-content a', function(e) {
		e.stopPropagation();
	});

	// Close the popover when clicking outside of it
	$('body').on('click', function(e) {
		if (!$('.fa').is(e.target) && $('.fa').has(e.target).length === 0 && $('.popover').has(e
				.target).length === 0) {
			$('.fa').popover('hide');
		}
	});
});

$("#create_form").on("submit", function(e) {
	e.preventDefault();
	if ($(this).valid()) {
		let formElement = $(this);
		let submitButtonElement = $(this).find(":submit");
		let url = $(this).attr("action");
		let data = new FormData(this);

		function successCallback() {
			$("#table").bootstrapTable("refresh");
			formElement[0].reset();
			setTimeout(function() {
				let filePondElements = document.getElementsByClassName("filepond");
				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements.length; i++) {
					let filePond = FilePond.find(filePondElements[i]);
					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}

				let filePondElements1 =
					document.getElementsByClassName("filepond-json");
				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements1.length; i++) {
					let filePond = FilePond.find(filePondElements1[i]);
					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}

				let filePondElements2 = document.getElementsByClassName("filepond-video");
				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements2.length; i++) {
					let filePond = FilePond.find(filePondElements2[i]);
					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}

				let filePondElements3 = document.getElementsByClassName("filepond-pdf");
				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements3.length; i++) {
					let filePond = FilePond.find(filePondElements3[i]);
					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}

				formElement.find("select").val('').trigger("change");
				$('#order_language_id').trigger('change');
				$('#tag_id').val('').trigger('change');
				$('#category_ids').val('').trigger('change');
				$('#news_ids').val('').trigger('change');
				$('#author_news_type').val(null).trigger('change');
				if (typeof resetUserCategorySwitch === 'function') {
					resetUserCategorySwitch();
				}
			}, 500);
		}

		formAjaxRequest("POST", url, data, formElement, submitButtonElement, successCallback);
	}
});

$("#update_form").on("submit", function(e) {
	if ($(this).valid()) {
		e.preventDefault();
		let formElement = $(this);
		let submitButtonElement = $(this).find(":submit");
		let data = new FormData(this);
		data.append("_method", "PUT");
		let url = $(this).attr("action") + "/" + data.get("edit_id");

		function successCallback(response) {
			// console.log(response);
			$("#table").bootstrapTable("refresh");
			setTimeout(function() {
				$("#editDataModal").modal("hide");
				formElement[0].reset();

				let filePondElements = document.getElementsByClassName("filepond");

				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements.length; i++) {
					let filePond = FilePond.find(filePondElements[i]);

					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}
				let filePondElements1 =
					document.getElementsByClassName("filepond-json");

				// Iterate over all elements with the specified class
				for (let i = 0; i < filePondElements1.length; i++) {
					let filePond = FilePond.find(filePondElements1[i]);

					if (filePond != null) {
						// This will remove all files for each FilePond instance
						filePond.removeFiles();
					}
				}

				let filePondPdfElements =
					document.getElementsByClassName("filepond-pdf");

				for (let i = 0; i < filePondPdfElements.length; i++) {
					let filePond = FilePond.find(filePondPdfElements[i]);

					if (filePond != null) {
						filePond.removeFiles();
					}
				}
				$('#order_language_id').trigger('change');
				// $("select").val(false).trigger("change");
			}, 1000);
		}

		formAjaxRequest("POST", url, data, formElement, submitButtonElement, successCallback);
	}
});

function showErrorToast(message) {
	Swal.fire({
		toast: true,
		icon: "error",
		title: message,
		position: "top-end",
		showConfirmButton: false,
		timer: 3000,
		timerProgressBar: true,
		didOpen: (toast) => {
			toast.addEventListener("mouseenter", Swal.stopTimer);
			toast.addEventListener("mouseleave", Swal.resumeTimer);
		},
	});
}

function showSuccessToast(message) {
	Swal.fire({
		toast: true,
		icon: "success",
		title: message,
		position: "top-end",
		showConfirmButton: false,
		timer: 3000,
		timerProgressBar: true,
		didOpen: (toast) => {
			toast.addEventListener("mouseenter", Swal.stopTimer);
			toast.addEventListener("mouseleave", Swal.resumeTimer);
		},
	});
}

$.ajaxSetup({
	headers: {
		"X-CSRF-TOKEN": $('meta[name="csrf-token"]').attr("content"),
	},
});

function ajaxRequest(type, url, data, beforeSendCallback, successCallback, errorCallback, finalCallback) {
	/*
	 * @param
	 * beforeSendCallback : This function will be executed before Ajax sends its request
	 * successCallback : This function will be executed if no Error will occur
	 * errorCallback : This function will be executed if some error will occur
	 * finalCallback : This function will be executed after all the functions are executed
	 */
	$.ajax({
		type: type,
		url: url,
		data: data,
		cache: false,
		processData: false,
		contentType: false,
		dataType: "json",
		beforeSend: function() {
			if (beforeSendCallback != null) {
				beforeSendCallback();
			}
		},
		success: function(data) {
			if (!data.error) {
				if (data.message) {
					showSuccessToast(data.message);
				}

                	// Handle page reload if requested (e.g., after system update)
				if (data.reload === true) {
					setTimeout(function() {
						if (data.reload_url) {
							window.location.href = data.reload_url;
						} else {
							window.location.reload();
						}
					}, 2500); // Small delay to show success message
					return;
				}
				if (successCallback != null) {
					successCallback(data);
				}
			} else {
				showErrorToast(data.message);
				if (errorCallback != null) {
					errorCallback(data);
				}
			}

			if (finalCallback != null) {
				finalCallback(data);
			}
		},
		error: function(jqXHR, textStatus, errorThrown, data) {

			if (jqXHR?.responseJSON?.message || true) {
				showErrorToast(jqXHR?.responseJSON?.message || 'Something went wrong');
			}
			if (finalCallback != null) {
				finalCallback();
			}
		},
	});
}

function formAjaxRequest(type, url, data, formElement, submitButtonElement, successCallback, errorCallback) {
	if (formElement) {
		let $btn = submitButtonElement && submitButtonElement.jquery ? submitButtonElement.first() : submitButtonElement;
		let isButton = $btn && $btn.is ? $btn.is('button') : false;
		let submitButtonText = isButton ? $btn.html() : $btn.val();

		function beforeSendCallback() {
			if (isButton) {
				// Spinner replaces the label (works for <button>; .val() does nothing visible on buttons).
				if ($btn.data('orig-html') === undefined) {
					$btn.data('orig-html', $btn.html());
				}
				if ($btn.data('orig-width') === undefined) {
					$btn.data('orig-width', $btn.outerWidth());
				}
				$btn.addClass('btn-loading').prop('disabled', true)
					.css('min-width', $btn.data('orig-width') + 'px')
					.html('<i class="fas fa-spinner fa-spin"></i>');
			} else {
				$btn.val("Please Wait...").attr("disabled", true);
			}
		}

		function finalCallback(response) {
			if (isButton) {
				$btn.html($btn.data('orig-html') !== undefined ? $btn.data('orig-html') : submitButtonText)
					.removeClass('btn-loading').prop('disabled', false).css('min-width', '')
					.removeData('orig-html').removeData('orig-width');
				var $form = $btn.closest('form');
				if ($form.length) {
					$form.removeData('submit-btn-clicked');
				}
			} else {
				$btn.val(submitButtonText).attr("disabled", false);
			}
		}
		ajaxRequest(type, url, data, beforeSendCallback, successCallback, errorCallback, finalCallback);
	}
}

$(document).on("click", ".delete-form", function(e) {
	e.preventDefault();

    // Get dynamic title and text from data attributes
    let customTitle = $(this).data('title') || trans('are_you_sure');
    let customText = $(this).data('text') || trans('you_wont_be_able_to_revert_this');


	Swal.fire({
		// title: "Are you sure?",
		title: customTitle,
		text: customText,
		icon: "warning",
		showCancelButton: true,
		confirmButtonColor: "#3085d6",
		cancelButtonColor: "#d33",
		confirmButtonText: trans('yes_delete_it'),
		cancelButtonText: trans('cancel'),
	}).then((result) => {
		if (result.isConfirmed) {
			let url = $(this).attr("data-url");
			let data = {
				_token: "{!! csrf-token() !!}",
			};
			function successCallback() {
				$("#table").bootstrapTable("refresh");
				setTimeout(() => {
					$('#order_language_id').trigger('change');
				}, 1000);
			}
			ajaxRequest("DELETE", url, data, null, successCallback);
		}
	});
});

function getSelect2Config($el) {
	var id = $el.attr('id') || '';
	var cfg = { width: '100%' };
	var ph = $el.data('placeholder');
	if (ph) cfg.placeholder = ph;
	if (id === 'category_list' || id === 'edit_category_list' || id === 'rss_feeds_news_type' || id === 'edit_rss_feeds_news_type') {
		cfg.maximumSelectionLength = 3;
	}
	// Placeholder text per element (matches blade init).
	if (id === 'category_ids' || id === 'edit_category_ids' || id === 'category_list' || id === 'edit_category_list') {
		cfg.placeholder = cfg.placeholder || 'Select Category';
	} else if (id === 'news_ids' || id === 'edit_news_ids') {
		cfg.placeholder = cfg.placeholder || 'Select News';
	} else if (id === 'author_news_type' || id === 'edit_author_news_type') {
		cfg.placeholder = cfg.placeholder || 'Select Author News';
	} else if (id === 'rss_feeds_news_type' || id === 'edit_rss_feeds_news_type') {
		cfg.placeholder = cfg.placeholder || 'Select RSS Feeds';
	}
	return cfg;
}

function initSelect2On($el) {
	try {
		var $jq = $el instanceof jQuery ? $el : $($el);
		if (!$jq.length || !$jq.is('select')) return;
		if ($jq.hasClass('select2-hidden-accessible')) {
			$jq.select2('destroy');
		}
		$jq.select2(getSelect2Config($jq));
	} catch (e) {
		console.log(e);
	}
}

function refreshSelect2Options(targetElement) {
	try {
		var $t = $(targetElement);
		if ($t.hasClass('select2-hidden-accessible')) {
			// Select2 picks up <option> changes automatically; just notify it.
			// Do NOT destroy/re-init here (previous code called undefined
			// initSelect2On and left a raw native listbox, see screenshot).
			$t.trigger('change.select2');
		}
	} catch (e) {
		console.log(e);
	}
}

function fetchList(url, data, targetElement) {
	$.ajax({
		url: url,
		type: "POST",
		data: data,
		beforeSend: function() {
			$(targetElement).html("Please wait..");
		},
		success: function(result) {
			$(targetElement).html(result);
			refreshSelect2Options(targetElement);
		},
		error: function(errors) {
			console.log(errors);
		},
	});
}

$(".modal").on("hidden.bs.modal", function() {
	let filePondElements = document.getElementsByClassName("filepond");

	// Iterate over all elements with the specified class
	for (let i = 0; i < filePondElements.length; i++) {
		let filePond = FilePond.find(filePondElements[i]);

		if (filePond != null) {
			// This will remove all files for each FilePond instance
			filePond.removeFiles();
		}
	}

	let filePondElements1 = document.getElementsByClassName("filepond-video");

	// Iterate over all elements with the specified class
	for (let i = 0; i < filePondElements1.length; i++) {
		let filePond = FilePond.find(filePondElements1[i]);

		if (filePond != null) {
			// This will remove all files for each FilePond instance
			filePond.removeFiles();
		}
	}
	// put your default event here
	$("#youtube_url").val("");
	$("#other_url").val("");
	$("#exampleVideoInputFile1_edit").val("");
});

function renderCharCount(characterCounter, charCount, minChars, maxChars, fieldLabel) {
	if (!characterCounter) {
		return;
	}

	// Only show feedback once the user has typed something
	if (charCount === 0) {
		characterCounter.innerHTML = "";
		characterCounter.style.display = "none";
		return;
	}
	characterCounter.style.display = "block";

	let info_class, info_icon, message;

	// No upper limit (e.g. rich-text description): informational count only
	if (!(maxChars > 0)) {
		info_class = "text-info";
		info_icon = '<i class="fa fa-info-circle ' + info_class + '"></i>';
		characterCounter.innerHTML = info_icon + " " + '<span>' + fieldLabel + ': <b>' + charCount + '</b> characters</span>';
		characterCounter.className = (characterCounter.className || '').replace(/text-\w+/g, '').trim() + ' form-text seo-hint ' + info_class;
		return;
	}

	const countLine = '<span>' + fieldLabel + ': <b>' + charCount + ' / ' + maxChars + '</b> characters</span>';

	if (minChars > 0 && charCount < minChars) {
		info_class = "text-warning";
		info_icon = '<i class="fa fa-exclamation-triangle ' + info_class + '"></i>';
		message = trans('seo_too_short_hint', '')
			|| ('Too short — aim for ' + minChars + '–' + maxChars + ' characters.');
		characterCounter.innerHTML = info_icon + " " + countLine + ' — <span class="' + info_class + '">' + message + '</span>';
	} else if (charCount <= maxChars) {
		info_class = "text-success";
		info_icon = '<i class="fa fa-check-circle ' + info_class + '"></i>';
		message = trans('seo_good_length_hint', '') || 'Good length — will display well in search results.';
		characterCounter.innerHTML = info_icon + " " + countLine + ' — <span class="' + info_class + '">' + message + '</span>';
	} else {
		info_class = "text-danger";
		info_icon = '<i class="fa fa-exclamation-triangle ' + info_class + '"></i>';
		message = trans('seo_too_long_hint', '')
			|| ('Too long — may be truncated in Google. Keep under ' + maxChars + ' characters.');
		characterCounter.innerHTML = info_icon + " " + countLine + ' — <span class="' + info_class + '">' + message + '</span>';
	}
	// Keep layout stable: preserve seo-hint sizing, only swap the color class
	characterCounter.className = (characterCounter.className || '').replace(/text-\w+/g, '').trim() + ' form-text seo-hint ' + info_class;
}

function getWordCount(fiels_type = "", field_counter = "", font = "0px arial", minChars = null, maxChars = null, labelKey = "") {
	let textArea = document.getElementById(fiels_type);
	let characterCounter = document.getElementById(field_counter);

	if (textArea && characterCounter) {
		// Legacy 3-arg calls resolve limits/label from the field id
		if (labelKey === "" && minChars === null && maxChars === null) {
			const isTitle = fiels_type === "meta_title" || fiels_type === "edit_meta_title";
			labelKey = isTitle ? "meta_title" : "meta_description";
			minChars = isTitle ? 30 : 70;
			maxChars = isTitle ? 60 : 155;
		}
		renderCharCount(characterCounter, (textArea.value || "").length, minChars || 0, maxChars || 0, trans(labelKey));
	}
}

// Rich-text (TinyMCE) character counters. Textareas hidden behind an editor
// don't fire input events, so counters update off editor events instead.
// Register once globally; editors created later (or rebuilt on theme change)
// are picked up via the AddEditor hook.
window._tinyCharCounters = window._tinyCharCounters || {};

function registerTinyCharCounter(editorId, counterId, minChars, maxChars, labelKey) {
	window._tinyCharCounters[editorId] = {
		counterId: counterId,
		minChars: minChars || 0,
		maxChars: maxChars || 0,
		labelKey: labelKey
	};
	if (window.tinymce) {
		var existing = null;
		try {
			existing = tinymce.get(editorId);
		} catch (e) {
			existing = null;
		}
		if (existing) {
			bindTinyCharCounter(existing);
		}
	}
}

function bindTinyCharCounter(editor) {
	if (!editor || editor._charCounterBound) {
		return;
	}
	if (!window._tinyCharCounters[editor.id]) {
		return;
	}
	editor._charCounterBound = true;
	editor.on("keyup change undo redo setcontent init", function () {
		updateTinyCharCounter(editor);
	});
	updateTinyCharCounter(editor);
}

function updateTinyCharCounter(editor) {
	var cfg = window._tinyCharCounters[editor.id];
	if (!cfg) {
		return;
	}
	var characterCounter = document.getElementById(cfg.counterId);
	if (!characterCounter) {
		return;
	}
	var text = "";
	try {
		text = editor.getContent({ format: "text" }) || "";
	} catch (e) {
		text = "";
	}
	renderCharCount(characterCounter, text.trim().length, cfg.minChars, cfg.maxChars, trans(cfg.labelKey));
}

if (window.tinymce && typeof window.tinymce.on === "function") {
	window.tinymce.on("AddEditor", function (e) {
		bindTinyCharCounter(e.editor);
	});
}

// Rich-text description editors across modules (plain-text char count)
registerTinyCharCounter("des", "des_count", 0, 0, "description");
registerTinyCharCounter("edit_des", "edit_des_count", 0, 0, "description");
registerTinyCharCounter("page_content", "page_content_count", 0, 0, "description");
registerTinyCharCounter("edit_page_content", "edit_page_content_count", 0, 0, "description");
// function textFormatter(value, row, index) {
//     if (!value) return '';
//     let tempDiv = document.createElement('div');
//     tempDiv.innerHTML = value;
//     let textContent = tempDiv.textContent || tempDiv.innerText || '';

//     if (textContent.length > 100) {
//         return '<div class="description-container">' +
//             '<div class="short-desc">' + textContent.substring(0, 150) + '...</div>' +
//             '<div class="full-desc" style="display:none">' + value + '</div>' +
//             `<a href="javascript:void(0)" class="toggle-desc" data-show="more">${translations.see_more}</a>` +
//         '</div>';
//     }
//     return value;

// }


// // table column text show more and less formatter
// function textFormatter(value, row, index) {
//     if (value.length > 100) {
//         return '<div class="short-description">' + value.substring(0, 50) +
//             '... <a href="#" class="view-more" data-index="' + index + '">' + trans('see_more') + '</a></div>' +
//             '<div class="full-description" style="display:none;">' + value +
//             ' <a href="#" class="view-more" data-index="' + index + '">' + trans('see_less') + '</a></div>';
//     } else {
//         return value;
//     }
// }

// function smallTextFormatter (value, row, index){
//     if (!value) return '';

//     // Remove heading tags and other large tags
//     let sanitized = value.replace(/<\/?h[1-6][^>]*>/gi, '');

//     // Optionally, remove all HTML comments
//     sanitized = sanitized.replace(/<!--.*?-->/gs, '');

//     return `<small style="font-size: 1.0rem;">${sanitized}</small>`;
// }

$(document).ready(function () {
    $('body').on('click', '.view-more', function (e) {
        e.preventDefault();
        var $this = $(this);
        var $row = $this.closest('tr');
        var $fullDescription = $row.find('.full-description');
        var $shortDescription = $row.find('.short-description');

        if ($fullDescription.is(':visible')) {
            $fullDescription.hide();
            $shortDescription.show();
            $this.text(trans('see_less'));
        } else {
            $fullDescription.show();
            $shortDescription.hide();
            $this.text(trans('see_more'));
        }
    });
});

// Global function to generate all meta fields using AI
function generateAllMetaFields(options = {}) {


    // Default configuration
    const config = {
        isEditForm: false,
        buttonSelector: '#generate_meta_fields',
        // titleSelector: options.isEditForm ? '#edit_title' : '#name',
        // contentSelector: options.isEditForm ? 'edit_des' : 'des',
        // categorySelector: options.isEditForm ? '#edit_category_id' : '#category_id',
        // languageSelector: '',
        routeUrl: '',
        csrfToken: '',
        // fieldMappings: {
        //     metaTags: options.isEditForm ? '#edit_meta_tags' : '#meta_tags',
        //     metaTitle: options.isEditForm ? '#edit_meta_title' : '#meta_title',
        //     metaDescription: options.isEditForm ? '#edit_meta_description' : '#meta_description'
        // },
        validationMessages: {
            selectLanguage: 'Please select language first',
            enterTitle: 'Please enter title first'
        },
        ...options
    };

    var title = '';
    // var content = '';
    // var category = '';

    // Get title based on configuration
    if ($(config.titleSelector).length) {
        title = $(config.titleSelector).val();
    }

    // Get content from TinyMCE editor
    // if (tinymce.get(config.contentSelector)) {
    //     content = tinymce.get(config.contentSelector).getContent({format: 'text'}).substring(0, 200);
    // }

    // Get category
    // if ($(config.categorySelector).length) {
    //     category = $(config.categorySelector + ' option:selected').text();
    // }

    // Get language
    let languageName = $(config.languageSelector + ' option:selected').data('name');

    // Validate we have at least a language
    if (!languageName || languageName === '') {
        showErrorToast(config.validationMessages.selectLanguage);
        return;
    }

    // Validate we have at least a title
    if (!title.trim()) {
        showErrorToast(config.validationMessages.enterTitle);
        return;
    }

    // Get the button element
    var buttonElement = $(config.buttonSelector);
    if (!buttonElement.length) {
        console.error('Button element not found:', config.buttonSelector);
        return;
    }

    // Show loading state
    var originalHtml = buttonElement.html();
    buttonElement.prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> ' + (trans('generating_meta_fields') || 'Generating All Meta Fields...'));

    // Add progress animation
    var progressSteps = [
        trans('analyzing_content') || 'Analyzing content...',
        trans('generating_keywords') || 'Generating keywords...',
        trans('creating_meta_title') || 'Creating meta title...',
        trans('writing_description') || 'Writing description...',
        trans('finalizing') || 'Finalizing...'
    ];

    var currentStep = 0;
    var progressInterval = setInterval(function() {
        if (currentStep < progressSteps.length) {
            buttonElement.html('<i class="fas fa-spinner fa-spin"></i> ' + progressSteps[currentStep]);
            currentStep++;
        }
    }, 800);

    // console.log(config);

    // Make AJAX request
    $.ajax({
        url: config.routeUrl,
        type: 'POST',
        data: {
            _token: config.csrfToken,
            title: title,
            // content: content,
            // category: category,
            language_name: languageName,
            includeDescription: Boolean(config.includeDescription) || false,
            includeSummarizedDescription: Boolean(config.includeSummarizedDescription) || false,
        },
        success: function(response) {
            clearInterval(progressInterval);

            if (response.success && response.data) {
                // Set meta keywords
                if ($(config.fieldMappings.metaTags).length) {
                    $(config.fieldMappings.metaTags).val(response.data.meta_keywords);
                }

                // Set meta title
                if ($(config.fieldMappings.metaTitle).length) {
                    $(config.fieldMappings.metaTitle).val(response.data.meta_title);
                    $(config.fieldMappings.metaTitle).trigger('input'); // Trigger word count
                }

                // Set meta description
                if ($(config.fieldMappings.metaDescription).length) {
                    $(config.fieldMappings.metaDescription).val(response.data.meta_description);
                    $(config.fieldMappings.metaDescription).trigger('input'); // Trigger word count
                }

                // Set description
                if (config.fieldMappings.description && response.data.description) {
                    // console.log('Setting description to:', config.fieldMappings.description);
                    setTinyMCEContent(config.fieldMappings.description, response.data.description);
                }

                // Set summarized description
                if ($(config.fieldMappings.summarizedDescription).length) {
                    $(config.fieldMappings.summarizedDescription).val(response.data.summarized_description);
                    $(config.fieldMappings.summarizedDescription).trigger('input'); // Trigger word count
                }

                // Success animation
                buttonElement.html('<i class="fas fa-check"></i> ' + (trans('generated_successfully') || 'Generated Successfully!'));

                setTimeout(function() {
                    buttonElement.html(originalHtml);
                }, 2000);

                // Show success message with details
                var successMsg = (trans('meta_fields_generated_successfully') || 'All meta fields generated successfully!') +
                    '\n• ' + (trans('keywords') || 'Keywords') + ': ' + response.data.meta_keywords.split(',').length + ' ' + (trans('keywords') || 'keywords') +
                    '\n• ' + (trans('title') || 'Title') + ': ' + response.data.meta_title.length + ' ' + (trans('characters') || 'characters') +
                    '\n• ' + (trans('description') || 'Description') + ': ' + response.data.meta_description.length + ' ' + (trans('characters') || 'characters');

                showSuccessToast(successMsg);
            } else {
                showErrorToast(response.message || (trans('failed_to_generate_meta_fields') || 'Failed to generate meta fields'));
            }
        },
        error: function(xhr, status, error) {
            clearInterval(progressInterval);

            var errorMessage = trans('failed_to_generate_meta_fields') || 'Failed to generate meta fields. Please try again.';
            if (xhr.responseJSON && xhr.responseJSON.message) {
                errorMessage = xhr.responseJSON.message;
            }
            showErrorToast(errorMessage);

            // Error animation
            buttonElement.html('<i class="fas fa-exclamation-triangle"></i> ' + (trans('generation_failed') || 'Generation Failed'));

            setTimeout(function() {
                buttonElement.html(originalHtml);
            }, 3000);
        },
        complete: function() {
            clearInterval(progressInterval);
            // Reset button state
            buttonElement.prop('disabled', false);
        }
    });
}

// Helper function to safely set TinyMCE content
function setTinyMCEContent(selector, content) {
    if (!selector || !content) return false;

    // Remove # from selector if present for TinyMCE
    var editorId = selector.replace('#', '');

    // Try to get the TinyMCE editor instance
    var editor = tinymce.get(editorId);

    if (editor) {
        // Editor exists, set content
        editor.setContent(content);
        // console.log('Content set successfully to TinyMCE editor:', editorId);
        return true;
    } else {
        // Editor doesn't exist, try to set as regular textarea
        // console.log('TinyMCE editor not found, trying as textarea:', editorId);
        if ($(selector).length) {
            $(selector).val(content);
            $(selector).trigger('input');
            return true;
        }
    }

    // console.warn('Could not set content for:', selector);
    return false;
}

// Helper function to initialize meta field generation for a specific form
function initMetaFieldGeneration(config) {
    $(document).on('click', config.buttonSelector || '#generate_meta_fields', function(e) {
        e.preventDefault();
        generateAllMetaFields(config);
    });
}

// JS is customized for TinyMCE toolbar overflow not hiding when modal is closed
$(document).ready(function() {
    // Fix TinyMCE toolbar overflow not hiding when modal is closed

    $('#editDataModal').on('hidden.bs.modal', function() {
        // Hide all TinyMCE overflow toolbars that might be left visible
        // These elements are often appended to body, so we search globally
        setTimeout(function() {
            $('.tox-toolbar__overflow').each(function() {
                $(this).hide().removeClass('tox-toolbar__overflow--open');
            });

            // Also hide any TinyMCE popups/dropdowns that might be open
            $('.tox-menu').hide();
            $('.tox-collection').hide();
            $('.tox-pop').hide();

            // Remove open state classes
            $('.tox-toolbar__overflow--open').removeClass('tox-toolbar__overflow--open');
        }, 10); // Small delay to ensure modal animation completes

        // update the tox-toolbar__group > button attributes like aria-expanded = false and remove class tox-tbtn--enabled and remove attribute aria-controls
        $('.tox-toolbar__group').each(function() {
            $(this).find('button').attr('aria-expanded', 'false').removeClass('tox-tbtn--enabled').removeAttr('aria-controls');
        });
    });

    // Also handle when modal is shown to ensure proper cleanup
    $('#editDataModal').on('show.bs.modal', function() {
        // Clean up any leftover overflow elements before showing
        $('.tox-toolbar__overflow').hide();
        $('.tox-toolbar__overflow--open').removeClass('tox-toolbar__overflow--open');
        $('.tox-menu').hide();
        $('.tox-collection').hide();
    });
});



// breaking news show more and less formatter
$(document).on('click', '.toggle-desc', function() {
    const container = $(this).closest('.description-container');
    const shortDesc = container.find('.short-desc');
    const fullDesc = container.find('.full-desc');

    if ($(this).data('show') === 'more') {
        shortDesc.hide();
        fullDesc.show();
        $(this).text(trans('see_less'));
        $(this).data('show', 'less');
    } else {
        fullDesc.hide();
        shortDesc.show();
        $(this).text(trans('see_more'));
        $(this).data('show', 'more');
    }
});

// function fetchRssFeedsList(url, data, selector) {
//     $.ajax({
//         url: url,
//         type: "GET",
//         data: data,
//         success: function(result) {
//             $(selector).html(result);
//         },
//         error: function(errors) {
//             $(selector).html('');
//             // console.log(errors);
//         },
//     });
// }
// function fetchCategoriesList(url, data, selector, callback) {
//     $.ajax({
//         url: url,
//         type: "GET",
//         data: data,
//         success: function(result) {
//             $(selector).html(result);
//             // Execute callback if provided (e.g., to reinitialize Select2)
//             if (typeof callback === 'function') {
//                 callback(result);
//             }
//         },
//         error: function(errors) {
//             $(selector).html('');
//             console.error('Error fetching categories list:', errors);
//             // Execute callback even on error to handle cleanup
//             if (typeof callback === 'function') {
//                 callback(null);
//             }
//         },
//     });
// }

function fetchEditRssFeedsList(url, data, selector, selectedValues) {

	$.ajax({
		url: url,
		type: "GET",
		data: data,
		success: function(result) {
			$(selector).html(result);
			// Set selected values if provided
			if (selectedValues) {
				// Convert comma-separated string to array if needed
				var valuesArray = Array.isArray(selectedValues) ? selectedValues : (typeof selectedValues === 'string' ? selectedValues.split(',') : []);
				// Filter out empty values and convert to strings/numbers as needed
				valuesArray = valuesArray.filter(function(val) {
					return val !== null && val !== undefined && String(val).trim() !== '';
				}).map(function(val) {
					// Convert to string and trim
					return String(val).trim();
				});
				if (valuesArray.length > 0) {
					$(selector).val(valuesArray).trigger('change');
				}
			}
		}
	});

}
// function fetchEditCategoryList(url, data, selector, selectedValues) {

// 	$.ajax({
// 		url: url,
// 		type: "GET",
// 		data: data,
// 		success: function(result) {
// 			$(selector).html(result);
// 			// Set selected values if provided
// 			if (selectedValues) {
// 				// Convert comma-separated string to array if needed
// 				var valuesArray = Array.isArray(selectedValues) ? selectedValues : (typeof selectedValues === 'string' ? selectedValues.split(',') : []);
// 				// Filter out empty values and convert to strings/numbers as needed
// 				valuesArray = valuesArray.filter(function(val) {
// 					return val !== null && val !== undefined && String(val).trim() !== '';
// 				}).map(function(val) {
// 					// Convert to string and trim
// 					return String(val).trim();
// 				});
// 				if (valuesArray.length > 0) {
// 					$(selector).val(valuesArray).trigger('change');
// 				}
// 			}
// 		}
// 	});
// }


// Tagify initialization — wrapped in IIFE to prevent re-declaration errors.
// jQuery's $.globalEval (called by .html() when content has <script> tags) can
// re-execute this file. Using `const` at top level throws SyntaxError on the
// second execution. The IIFE + ._tagify sentinel ensures single init per element.
(function () {
    var _tagifyEl = document.querySelector("#TagifyCustomListSuggestion");
    if (_tagifyEl && !_tagifyEl._tagify) {
        window.TagifyCustomListSuggestion = new Tagify(_tagifyEl, {
            whitelist: [],
            maxTags: 10,
            dropdown: { maxItems: 20, classname: "", enabled: 0, closeOnSelect: false }
        });
        _tagifyEl._tagify = true;
    }

    // edit news
    var _editTagifyEl = document.querySelector("#edit_news_tagify");
    if (_editTagifyEl && !_editTagifyEl._tagify) {
        window.editTagCustomListSuggestion = new Tagify(_editTagifyEl, {
            whitelist: [],
            maxTags: 10,
            dropdown: { maxItems: 20, classname: "", enabled: 0, closeOnSelect: false }
        });
        _editTagifyEl._tagify = true;
    }
}());


// Global submit-button loading spinner (all type=submit, normal + AJAX forms)
(function () {
    function getJq() {
        return window.jQuery || window.$ || null;
    }
    function init() {
        var $ = getJq();
        if (!$ || !$.fn || !$.fn.on) {
            setTimeout(init, 100);
            return;
        }
        // Remember which submit button was clicked (submit event alone doesn't say).
        $(document).on('click', 'button[type="submit"], input[type="submit"]', function () {
            var $form = $(this).closest('form');
            if ($form.length) {
                $form.data('submit-btn-clicked', this);
            }
        });
        // On any form submit: show moving circle on the clicked (or first) button.
        $(document).on('submit', 'form', function () {
            var form = this;
            var $form = $(form);
            if ($form.attr('data-no-spinner') !== undefined) {
                return;
            }
            // Don't spin when client-side validation blocks the submit.
            try {
                var validator = $form.data('validator');
                if (validator && typeof $form.valid === 'function' && !$form.valid()) {
                    return;
                }
            } catch (e) { /* fall through and spin */ }
            var clicked = $form.data('submit-btn-clicked');
            var $btn = clicked && document.contains(clicked) ? $(clicked) : $form.find('button[type="submit"], input[type="submit"]').first();
            if (!$btn || !$btn.length || $btn.prop('disabled') || $btn.hasClass('btn-loading')) {
                // Already spinning: block double submit for normal POST forms.
                if ($btn && $btn.length && $btn.hasClass('btn-loading') && !form.__ajaxSubmit) {
                    return false;
                }
                return;
            }
            if ($btn.is('button')) {
                if ($btn.data('orig-html') === undefined) {
                    $btn.data('orig-html', $btn.html());
                }
                // Spinner replaces the label: lock width to avoid layout jump.
                if ($btn.data('orig-width') === undefined) {
                    $btn.data('orig-width', $btn.outerWidth());
                }
                $btn.addClass('btn-loading').prop('disabled', true)
                    .css('min-width', $btn.data('orig-width') + 'px')
                    .html('<i class="fas fa-spinner fa-spin"></i>');
            } else {
                if ($btn.data('orig-val') === undefined) {
                    $btn.data('orig-val', $btn.val());
                }
                $btn.addClass('btn-loading').prop('disabled', true);
            }
        });
        // AJAX forms call preventDefault: restore button when the request finishes.
        // Normal POST navigates away, so no restore is needed there.
        $(document).ajaxComplete(function () {
            $('button[type="submit"].btn-loading, input[type="submit"].btn-loading').each(function () {
                restoreBtn($(this));
            });
        });
        $(document).ajaxError(function () {
            $('button[type="submit"].btn-loading, input[type="submit"].btn-loading').each(function () {
                restoreBtn($(this));
            });
        });
        // Manual escape hatch for custom JS: window.resetSubmitButtons(formOrNull).
        window.resetSubmitButtons = function (scope) {
            var $scope = scope ? $(scope) : $(document);
            $scope.find('button[type="submit"].btn-loading, input[type="submit"].btn-loading').each(function () {
                restoreBtn($(this));
            });
        };
        function restoreBtn($btn) {
            if (!$btn || !$btn.length || !$btn.hasClass('btn-loading')) {
                return;
            }
            // Don't restore while another AJAX request is still in flight.
            try {
                if (window.jQuery && $.active && $.active > 0) {
                    setTimeout(function () { restoreBtn($btn); }, 300);
                    return;
                }
            } catch (e) {}
            $btn.removeClass('btn-loading').prop('disabled', false).css('min-width', '');
            if ($btn.is('button') && $btn.data('orig-html') !== undefined) {
                // Label was replaced by the spinner: always restore it.
                $btn.html($btn.data('orig-html'));
                $btn.removeData('orig-html');
                $btn.removeData('orig-width');
            }
            if ($btn.is('input') && $btn.data('orig-val') !== undefined) {
                $btn.val($btn.data('orig-val'));
                $btn.removeData('orig-val');
            }
            var $form = $btn.closest('form');
            if ($form.length) {
                $form.removeData('submit-btn-clicked');
            }
        }
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

// create rss feed + edit rss feed Tagify init (same IIFE guard pattern)
(function () {
    var _rssFeedEl = document.querySelector("#rss_feed_tagify");
    if (_rssFeedEl && !_rssFeedEl._tagify) {
        window.RSSFeedTagCustomListSuggestion = new Tagify(_rssFeedEl, {
            whitelist: [],
            maxTags: 10,
            dropdown: { maxItems: 20, classname: "", enabled: 0, closeOnSelect: false }
        });
        _rssFeedEl._tagify = true;
    }

    var _editRssFeedEl = document.querySelector("#edit_rss_tagify");
    if (_editRssFeedEl && !_editRssFeedEl._tagify) {
        window.editRSSFeedTagCustomListSuggestion = new Tagify(_editRssFeedEl, {
            whitelist: [],
            maxTags: 10,
            dropdown: { maxItems: 20, classname: "", enabled: 0, closeOnSelect: false }
        });
        _editRssFeedEl._tagify = true;
    }
}());
