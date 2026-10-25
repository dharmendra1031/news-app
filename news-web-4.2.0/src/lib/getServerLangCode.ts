import type { GetServerSidePropsContext } from 'next';
import { FALLBACK_LOCALE } from '@/lib/defaultLocale';
import { isValidLocaleSegment } from '@/lib/locale';

/**
 * Resolve the current language code inside `getServerSideProps`.
 *
 * `params.langCode` is always correct for a real page route — `src/proxy.ts`
 * rewrites a bare default-locale URL to `/{langCode}/...` before Next
 * matches routes, so the dynamic segment is populated either way.
 *
 * Callers should first check `isValidLocaleSegment(context.params?.langCode)`
 * and 404 if it fails — `[langCode]` matches ANY single path segment, so a
 * request for a missing static asset (e.g. "/manifest.json") lands here too.
 */
export function getServerLangCode(
    context: Pick<GetServerSidePropsContext, 'params'>
): string {
    const fromParams = context.params?.langCode;
    if (isValidLocaleSegment(fromParams)) return fromParams;

    return FALLBACK_LOCALE;
}
