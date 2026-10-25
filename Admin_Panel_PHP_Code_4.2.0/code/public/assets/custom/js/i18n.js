(function () {
    // Simple translator from window.languageLabels (JSON loaded from backend)
    window.trans = function (key, fallback) {
        try {
            if (window.languageLabels && typeof window.languageLabels[key] !== 'undefined') {
                return window.languageLabels[key];
            }
        } catch (e) {}
        return typeof fallback !== 'undefined' ? fallback : key;
    };

    // If FilePond is on the page, set its UI strings using trans()
    if (window.FilePond && typeof window.FilePond.setOptions === 'function') {
        FilePond.setOptions({
            labelIdle: trans('Drag & Drop your files or Browse'),
            labelInvalidField: trans('Field contains invalid files', 'Field contains invalid files'),
            labelFileWaitingForSize: trans('Waiting for size', 'Waiting for size'),
            labelFileSizeNotAvailable: trans('Size not available', 'Size not available'),
            labelFileLoading: trans('Loading', 'Loading'),
            labelFileAdded: trans('Added', 'Added'),
            labelFileLoadError: trans('Error during load', 'Error during load'),
            labelFileRemoved: trans('Removed', 'Removed'),
            labelFileRemoveError: trans('Error during remove', 'Error during remove'),
            labelFileProcessing: trans('Uploading', 'Uploading'),
            labelFileProcessingComplete: trans('Upload complete', 'Upload complete'),
            labelFileProcessingAborted: trans('Upload cancelled', 'Upload cancelled'),
            labelFileProcessingError: trans('Error during upload', 'Error during upload'),
            labelFileProcessingRevertError: trans('Error during revert', 'Error during revert'),
            labelTapToCancel: trans('tap to cancel', 'tap to cancel'),
            labelTapToRetry: trans('tap to retry', 'tap to retry'),
            labelTapToUndo: trans('tap to undo', 'tap to undo'),
            labelButtonRemoveItem: trans('Remove', 'Remove'),
            labelButtonAbortItemLoad: trans('Abort', 'Abort'),
            labelButtonRetryItemLoad: trans('Retry', 'Retry'),
            labelButtonAbortItemProcessing: trans('Cancel', 'Cancel'),
            labelButtonUndoItemProcessing: trans('Undo', 'Undo'),
            labelButtonRetryItemProcessing: trans('Retry', 'Retry'),
            labelButtonProcessItem: trans('Upload', 'Upload'),
            labelFileCountSingular: trans('file in list', 'file in list'),
            labelFileCountPlural: trans('files in list', 'files in list'),
        });
    }
})();
