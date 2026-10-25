import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { fetchDefaultLocale } from '@/lib/defaultLocale';
import { LOCALE_SEGMENT_PATTERN } from '@/lib/locale';

// Set by `LanguageSwitcher` when the user picks a non-default language, so a
// later bare-URL request (new tab, reload, typed-in address) still lands on
// their chosen language instead of silently falling back to default.
const LANG_COOKIE = 'lang';

export async function proxy(request: NextRequest) {
    const { pathname, search } = request.nextUrl;

    const firstSegment = pathname.split('/')[1] ?? '';
    const pathnameHasLocale = LOCALE_SEGMENT_PATTERN.test(firstSegment);

    // Runs in the Node.js runtime (Next 16 default) — the module-level TTL
    // cache in defaultLocale.ts persists here across requests, so this is a
    // real network call at most once per hour, not per request.
    const defaultLocale = await fetchDefaultLocale();

    if (pathnameHasLocale) {
        if (firstSegment === defaultLocale) {
            // Canonicalize away an explicit default-locale prefix, e.g.
            // "/en/podcast" -> "/podcast".
            const url = request.nextUrl.clone();
            url.pathname = pathname.slice(firstSegment.length + 1) || '/';
            return NextResponse.redirect(url, 308);
        }
        return NextResponse.next();
    }

    const preferredLocale = request.cookies.get(LANG_COOKIE)?.value || defaultLocale;

    const url = request.nextUrl.clone();
    url.pathname = `/${preferredLocale}${pathname}`;
    url.search = search;

    // Default language stays invisible in the URL — rewrite serves
    // /[langCode] content under the original bare URL (e.g. "/podcast"
    // keeps showing "/podcast", not "/en/podcast"). A non-default language
    // (from the "lang" cookie) is a real distinct page, so redirect visibly.
    if (preferredLocale === defaultLocale) {
        return NextResponse.rewrite(url);
    }
    return NextResponse.redirect(url);
}

export const config = {
    matcher: ['/((?!_next|api|.*\\..*).*)'],
};
