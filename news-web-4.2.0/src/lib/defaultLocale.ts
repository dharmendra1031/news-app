import { getSettingsApi } from '@/api/apiRoutes';

export const FALLBACK_LOCALE = 'en';

const CACHE_TTL_MS = 60 * 60 * 1000;

let cachedDefaultLocale: string | null = null;
let cachedAt = 0;

/**
 * Server-side default language code, cached module-level so `proxy.ts`
 * (which runs on every request) and `getServerSideProps` calls don't hit
 * the settings API more than once per hour.
 */
export async function fetchDefaultLocale(): Promise<string> {
    const now = Date.now();
    if (cachedDefaultLocale && now - cachedAt < CACHE_TTL_MS) {
        return cachedDefaultLocale;
    }

    const settings = await getSettingsApi();
    const code = settings?.data?.default_language?.code;
    if (code) {
        cachedDefaultLocale = code;
        cachedAt = now;
        return code;
    }

    return cachedDefaultLocale || FALLBACK_LOCALE;
}
