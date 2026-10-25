import { GET_WEB_SEO_PAGES } from '@/api/apiEndPoints';
import axios from 'axios';

const FALLBACK_OG_IMAGE = '/favicon.png';

/**
 * Strip Next.js internal routing params (e.g. `nxtPlangCode`) that leak into
 * `initURL` for dynamic routes, so canonical/og:url tags never expose them.
 */
const sanitizePathName = (url?: string | null): string | null | undefined => {
  if (!url) return url;
  try {
    const parsed = new URL(url);
    Array.from(parsed.searchParams.keys())
      .filter((key) => key.startsWith('nxtP'))
      .forEach((key) => parsed.searchParams.delete(key));
    const query = parsed.searchParams.toString();
    return `${parsed.origin}${parsed.pathname}${query ? `?${query}` : ''}`;
  } catch (error) {
    // Fall back to a relative-URL-safe strip if `url` isn't absolute
    return url.replace(/([?&])nxtP[^=&]*=[^&]*/g, '').replace(/[?&]$/, '');
  }
};

interface SeoPageData {
  meta_title?: string;
  meta_description?: string;
  meta_keyword?: string;
  og_image?: string;
  schema_markup?: string;
}

interface SeoDataResponse {
  data?: {
    data?: SeoPageData[];
  };
}

/**
 * Fetch SEO data from API
 * @param pageType - The page type (e.g., 'live_streaming_news', 'home', etc.)
 * @param language_code - Language code (e.g., 'en', 'ar')
 */
const fetchSeoData = async (pageType: string, language_code: string): Promise<SeoDataResponse | null> => {
  try {
    const response = await axios.post(
      `${process.env.NEXT_PUBLIC_API_URL}/${process.env.NEXT_PUBLIC_END_POINT}/${GET_WEB_SEO_PAGES}?type=${encodeURIComponent(pageType)}&language_code=${encodeURIComponent(language_code)}`
    )
    return response.data
  } catch (error) {
    console.error('Error fetching data:', error)
    return null
  }
}

/**
 * Try to parse a schema_markup string into JSON-LD data; returns null if
 * missing or malformed so JsonLd never double-encodes a raw string.
 */
const parseSchemaMarkup = (schemaMarkup?: string | null): Record<string, unknown> | null => {
  if (!schemaMarkup) return null;
  try {
    return JSON.parse(schemaMarkup);
  } catch (error) {
    console.error('Error parsing schema_markup:', error);
    return null;
  }
};

export interface FetchMetaInfoParams {
  pageType: string;
  langCode?: string;
  currentURL?: string;
  fallbackTitle?: string;
  fallbackDescription?: string;
  fallbackKeywords?: string;
}

export interface MetaInfo {
  title: string;
  description: string;
  keywords: string;
  ogImage: string | null;
  pathName: string | null | undefined;
  schema: Record<string, unknown> | null;
}

export async function fetchMetaInfo(params: FetchMetaInfoParams): Promise<MetaInfo> {
  const {
    pageType,
    langCode = 'en',
    currentURL,
    fallbackTitle = process.env.NEXT_PUBLIC_TITLE || 'Default Title',
    fallbackDescription = process.env.NEXT_PUBLIC_DESCRIPTION || 'Default Description',
    fallbackKeywords = process.env.NEXT_PUBLIC_kEYWORDS || 'default, keywords'
  } = params;

  try {
    const seoData = await fetchSeoData(pageType, langCode);
    const metaData = seoData?.data?.data?.[0];
    const ogImage = metaData?.og_image || FALLBACK_OG_IMAGE;

    return {
      title: metaData?.meta_title || fallbackTitle,
      description: metaData?.meta_description || fallbackDescription,
      keywords: metaData?.meta_keyword || fallbackKeywords,
      ogImage,
      pathName: sanitizePathName(currentURL),
      schema: parseSchemaMarkup(metaData?.schema_markup),
    };
  } catch (error) {
    console.error(`Error generating metadata for page type "${pageType}":`, error);

    return {
      title: fallbackTitle,
      description: fallbackDescription,
      keywords: fallbackKeywords,
      ogImage: FALLBACK_OG_IMAGE,
      pathName: sanitizePathName(currentURL),
      schema: null
    };
  }
}

export interface GetSchemaMarkupParams {
  pageType: string;
  langCode?: string;
}

/**
 * Get schema markup (JSON-LD) for any page using SEO settings from API
 */
export async function getSchemaMarkup(params: GetSchemaMarkupParams): Promise<Record<string, unknown> | null> {
  const {
    pageType,
    langCode = 'en'
  } = params;

  try {
    const seoData = await fetchSeoData(pageType, langCode);
    const metaData = seoData?.data?.data?.[0];
    return parseSchemaMarkup(metaData?.schema_markup);
  } catch (error) {
    console.error(`Error fetching schema markup for page type "${pageType}":`, error);
    return null;
  }
}
