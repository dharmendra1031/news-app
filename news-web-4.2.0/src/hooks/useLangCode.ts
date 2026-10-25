import { useRouter } from 'next/router';
import { useSelector } from 'react-redux';
import { defaultLanguageSelector } from '@/redux/reducers/settingsSlice';

/**
 * Current language code. The `[langCode]` URL segment covers non-default
 * languages; the default language is served under a bare URL (see
 * `src/proxy.ts`), so there's no segment to read there — fall back to the
 * default language from settings.
 */
export const useLangCode = (): string => {
    const { query } = useRouter();
    const defaultLanguage = useSelector(defaultLanguageSelector);

    if (typeof query.langCode === 'string' && query.langCode) return query.langCode;
    return defaultLanguage?.code || 'en';
};

export const useDefaultLangCode = (): string => {
    const defaultLanguage = useSelector(defaultLanguageSelector);
    return defaultLanguage?.code || 'en';
};
