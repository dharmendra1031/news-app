/**
 * Attach video validation to a FilePond (or plain) video input.
 * Invalid files are NOT removed from FilePond — the error is shown below
 * the input and form submission is blocked until a valid file is chosen.
 *
 * @param {HTMLElement} inputElement  The original <input type="file"> element
 * @param {string}      errorId       id of the <div> that will show error messages
 * @param {object}      [options]
 * @param {number}      [options.maxSizeMB=25]       Max file size in MB
 * @param {number}      [options.maxResolution=1920]  Max px on either dimension
 * @param {number}      [options.maxDuration=120]     Max duration in seconds
 * @param {number}      [options.minDuration=3]       Min duration in seconds
 */
function setupVideoValidation(inputElement, errorId, options) {
    const config = Object.assign({
        maxSizeMB: 25,
        maxResolution: 1920,
        maxDuration: 120,
        minDuration: 3
    }, options || {});
    // console.log('[VideoValidation] Init on element:', inputElement, '| errorId:', errorId, '| config:', config);

    const errorContainer = document.getElementById(errorId);
    // console.log('[VideoValidation] Error container found:', errorContainer);

    // null = no file, true = valid, false = invalid
    let fileValid = null;

    function t(key, fallback, replacements) {
        let str = (typeof trans === 'function' ? trans(key, fallback) : null) || fallback;
        if (replacements) {
            Object.keys(replacements).forEach(function (placeholder) {
                str = str.replace(':' + placeholder, replacements[placeholder]);
            });
        }
        return str;
    }

    function showError(messages) {
        if (!errorContainer) return;
        errorContainer.innerHTML = Array.isArray(messages) ? messages.join('<br>') : messages;
        errorContainer.style.display = 'block';
    }

    function clearError() {
        if (!errorContainer) return;
        errorContainer.innerHTML = '';
        errorContainer.style.display = 'none';
    }

    function runValidation(file) {
        clearError();
        fileValid = null; // pending

        // console.log('[VideoValidation] File received:', {
        //     name: file.name,
        //     size: file.size,
        //     sizeMB: (file.size / 1024 / 1024).toFixed(2) + ' MB',
        //     type: file.type
        // });

        if (file.size > config.maxSizeMB * 1024 * 1024) {
            console.warn('[VideoValidation] FAIL size:', (file.size / 1024 / 1024).toFixed(2) + 'MB > ' + config.maxSizeMB + 'MB');
            showError(t('video_file_too_large', 'File too large. Max :maxSizeMB MB allowed.', { maxSizeMB: config.maxSizeMB }));
            fileValid = false;
            // fileValid = true;
            return;
        }

        const url = URL.createObjectURL(file);
        const video = document.createElement('video');
        video.preload = 'metadata';

        video.onloadedmetadata = function () {
            const width  = video.videoWidth;
            const height = video.videoHeight;

            // WebM (and some MP4 variants) recorded via MediaRecorder often omit
            // duration from the header, so the browser reports Infinity here.
            // Force a seek to compute the real duration before validating.
            if (video.duration === Infinity || isNaN(video.duration)) {
                console.warn('[VideoValidation] duration reported as Infinity/NaN — forcing recalculation.');
                video.currentTime = 1e101; // seek absurdly far forward
                video.ontimeupdate = function () {
                    video.ontimeupdate = null;
                    video.currentTime = 0; // reset playhead
                    finishValidation(width, height, video.duration, url);
                };
            } else {
                finishValidation(width, height, video.duration, url);
            }
        };

        function finishValidation(width, height, duration, url) {
            URL.revokeObjectURL(url);
            const errors = [];

            // console.log('[VideoValidation] Metadata loaded:', {
            //     width: width,
            //     height: height,
            //     duration: duration.toFixed(2) + 's',
            //     maxDim: Math.max(width, height)
            // });

            if (Math.max(width, height) > config.maxResolution) {
                errors.push(t('video_resolution_too_high', 'Resolution :width×:height exceeds max :maxResolution px on any side.', {
                    width: width, height: height, maxResolution: config.maxResolution
                }));
            }
            if (duration > config.maxDuration) {
                errors.push(t('video_duration_too_long', 'Video is :duration s long. Max :maxDuration s allowed.', {
                    duration: Math.round(duration), maxDuration: config.maxDuration
                }));
            }
            if (duration < config.minDuration) {
                errors.push(t('video_duration_too_short', 'Video is :duration s long. Min :minDuration s required.', {
                    duration: Math.round(duration), minDuration: config.minDuration
                }));
            }

            if (errors.length > 0) {
                console.error('[VideoValidation] Rejected with errors:', errors);
                showError(errors);
                fileValid = false;
            } else {
                // console.log('[VideoValidation] PASS - file accepted.');
                fileValid = true;
            }
        }

        video.onerror = function () {
            URL.revokeObjectURL(url);
            // Browser cannot decode this format (e.g. AVI) — skip client-side metadata
            // checks and let the backend (getID3) validate instead.
            console.warn('[VideoValidation] Browser cannot read metadata — skipping client-side checks, backend will validate.');
            fileValid = true;
        };

        video.src = url;
    }

    // Block the closest form from submitting when the file is invalid
    const form = inputElement.closest('form');
    if (form) {
        form.addEventListener('submit', function (e) {
            if (fileValid === false) {
                e.preventDefault();
                e.stopImmediatePropagation();
                errorContainer && errorContainer.scrollIntoView({ behavior: 'smooth', block: 'center' });
                console.warn('[VideoValidation] Form submission blocked — invalid video.');
            }
        }, true);
    }

    const pond = (window.FilePond && FilePond.find) ? FilePond.find(inputElement) : null;
    // console.log('[VideoValidation] FilePond instance:', pond);

    if (pond) {
        pond.setOptions({
            onaddfile: function (error, fileItem) {
                // console.log('[VideoValidation] onaddfile triggered | error:', error, '| fileItem:', fileItem);
                if (error) return;
                runValidation(fileItem.file);
            },
            onremovefile: function (_error, fileItem) {
                // console.log('[VideoValidation] onremovefile triggered | fileItem:', fileItem);
                fileValid = null;
                clearError();
            }
        });
    } else {
        console.warn('[VideoValidation] No FilePond instance found — falling back to plain change event.');
        inputElement.addEventListener('change', function (e) {
            const file = e.target.files[0];
            if (!file) { fileValid = null; clearError(); return; }
            runValidation(file);
        });
    }
}
