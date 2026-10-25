export const LOCALE_SEGMENT_PATTERN = /^[a-z]{2}(-[A-Z]{2})?$/;

/**
 * The `[langCode]` dynamic segment matches ANY single path segment — so a
 * request for a missing static asset (e.g. "/manifest.json",
 * "/some-stale-sw.js") falls through to it with the filename captured as
 * `langCode`, instead of 404ing. Pages under `[langCode]/...` must check
 * this before using the segment as a real language code.
 */
export const isValidLocaleSegment = (value: unknown): value is string =>
    typeof value === 'string' && LOCALE_SEGMENT_PATTERN.test(value);
