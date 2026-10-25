const isExternal =(href: string): boolean =>
    /^([a-z][a-z0-9+.-]*:)?\/\//i.test(href) || href.startsWith('mailto:') || href.startsWith('tel:');

const LOCALE_SEGMENT_RE = /^\/([a-z]{2}(?:-[A-Z]{2})?)(?=\/|$)/;

/**
 * Prefix a relative path with the current language code (e.g. `/podcast` -> `/en/podcast`).
 * When `lang` matches `defaultLang`, the prefix is omitted (the default language is unprefixed).
 * Leaves external URLs, anchors, and query-only hrefs untouched.
 */
export const withLang = (href: string, lang: string, defaultLang?: string): string => {
    if (!href || !lang || isExternal(href) || href.startsWith('#') || href.startsWith('?')) {
        return href;
    }

    const path = href.startsWith('/') ? href : `/${href}`;

    if (defaultLang && lang === defaultLang) {
        return path;
    }

    return path === '/' ? `/${lang}` : `/${lang}${path}`;
};

/**
 * Strip a leading `/xx` (or `/xx-XX`) locale segment from a pathname, if present.
 * Pass `lang` to only strip when the leading segment matches that exact code.
 */
export const stripLangPrefix = (pathname: string, lang?: string): string => {
    if (!pathname) return '/';
    const match = pathname.match(LOCALE_SEGMENT_RE);
    if (!match || (lang && match[1] !== lang)) return pathname;
    return pathname.slice(match[0].length) || '/';
};
