import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import HomePage from "@/components/homePage/HomePage";
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getCategoriesApi, getMarketAlertsApi, getPodcastsApi, getMorePagesApi, getBreaingNewsApi, getFeatureSectionsApi, getLiveNewsApi, getAdSpacesApi } from "@/api/apiRoutes";
import { featureSectionsQueryKey, FEATURE_SECTION_NEWS_LIMIT, FEATURE_SECTIONS_PER_PAGE } from "@/hooks/queries/useGetFeatureSections";
import { LIVE_NEWS_LIMIT } from "@/components/homePage/LiveNewsSect";
import { fetchMetaInfo } from "@/utils/fetchMetaInfo";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { isStaticExport } from "@/lib/staticExport";

const DEFAULT_OFFSET = 0;
const DEFAULT_LIMIT = 20;
const ALERTS_LIMIT = 10; // matches AlertsSect.tsx's DATA_PER_PAGE

interface IndexProps {
  metadata?: Awaited<ReturnType<typeof fetchMetaInfo>>;
}

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so a request for a
  // missing static asset (e.g. a browser probing "/manifest.json") lands
  // here too. Only treat it as a real page if the segment looks like a
  // locale, otherwise 404 instead of sending garbage to the language APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  const queryClient = new QueryClient();
  const language_code = getServerLangCode(context);

  // Only fetched when SEO mode is on, but run alongside the other prefetches
  // below (not awaited separately first) so it doesn't add to the waterfall.
  const metadataPromise = process?.env?.NEXT_PUBLIC_SEO === "true"
    ? (async () => {
      const defaultLocale = await fetchDefaultLocale();
      const currentURL = process.env.NEXT_PUBLIC_WEB_URL + withLang('/', language_code, defaultLocale);
      return fetchMetaInfo({
        pageType: "home",
        langCode: language_code,
        currentURL,
      });
    })()
    : Promise.resolve(undefined);

  const [metadata] = await Promise.all([
    metadataPromise,
    queryClient.prefetchQuery({
      queryKey: ["categories", DEFAULT_OFFSET, DEFAULT_LIMIT, language_code],
      queryFn: () => getCategoriesApi({ offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT, language_code }),
    }),
    queryClient.prefetchQuery({
      queryKey: ["market-alerts", DEFAULT_OFFSET, ALERTS_LIMIT],
      queryFn: () => getMarketAlertsApi({ offset: DEFAULT_OFFSET, limit: ALERTS_LIMIT }),
    }),
    queryClient.prefetchQuery({
      queryKey: ["podcasts", 'all', DEFAULT_OFFSET, DEFAULT_LIMIT, '', ''],
      queryFn: () => getPodcastsApi({ type: 'all', offset: DEFAULT_OFFSET, limit: 4, search: '' }),
    }),
    queryClient.prefetchQuery({
      queryKey: ["more-pages", language_code, null, DEFAULT_OFFSET, DEFAULT_LIMIT],
      queryFn: () => getMorePagesApi({ language_code, offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT }),
    }),
    // `slug` is `null` here, not `undefined` — Next can't serialize `undefined`
    // into the dehydrated state, and react-query hashes both the same way.
    queryClient.prefetchQuery({
      queryKey: ["breaking-news", language_code, null, DEFAULT_OFFSET, DEFAULT_LIMIT],
      queryFn: () => getBreaingNewsApi({ language_code, offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT }),
    }),
    // Drives the whole home-page feed — which styles render, and with what data.
    // Only the first page of sections; the rest load on scroll, client-side.
    queryClient.prefetchQuery({
      queryKey: featureSectionsQueryKey({
        language_code,
        offset: 0,
        limit: FEATURE_SECTION_NEWS_LIMIT,
        section_offset: 0,
        section_limit: FEATURE_SECTIONS_PER_PAGE,
      }),
      // `getFeatureSectionsApi` swallows request failures and resolves to
      // `null` — the client hook re-throws on that to surface a real query
      // error, so this prefetch must do the same. Otherwise a failed SSR
      // fetch dehydrates as a fake "success" with null data, and the client
      // never sees `isError`, permanently skipping the news fallback.
      queryFn: async () => {
        const response = await getFeatureSectionsApi({
          language_code,
          offset: 0,
          limit: FEATURE_SECTION_NEWS_LIMIT,
          section_offset: 0,
          section_limit: FEATURE_SECTIONS_PER_PAGE,
        });
        if (!response) throw new Error("Failed to fetch featured sections");
        return response;
      },
    }),
    queryClient.prefetchQuery({
      queryKey: ["live-news", language_code, DEFAULT_OFFSET, LIVE_NEWS_LIMIT],
      queryFn: () => getLiveNewsApi({ language_code, offset: DEFAULT_OFFSET, limit: LIVE_NEWS_LIMIT }),
    }),
    queryClient.prefetchQuery({
      queryKey: ["ad-spaces", language_code, "home_page", "web"],
      queryFn: () => getAdSpacesApi({ language_code, page: "home_page" }),
    }),
  ]);

  return {
    props: {
      metadata: metadata ?? null,
      dehydratedState: dehydrate(queryClient),
    },
  };
};

export default function LangPage({ metadata }: IndexProps) {
  return (
    <>
      <Meta
        title={metadata?.title}
        description={metadata?.description}
        keywords={metadata?.keywords}
        ogImage={metadata?.ogImage}
        pathName={metadata?.pathName}
      />
      <HomePage />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  );
}

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
