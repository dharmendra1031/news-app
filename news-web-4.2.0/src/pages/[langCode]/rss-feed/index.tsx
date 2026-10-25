import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import RssFeeds from '@/components/pagesComp/rssFeeds/RssFeeds'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getRssFeedItemsApi, getRssFeedsApi } from "@/api/apiRoutes";
import { fetchMetaInfo } from "@/utils/fetchMetaInfo";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { isStaticExport } from "@/lib/staticExport";

const DEFAULT_PAGE = 1;
const DEFAULT_PER_PAGE = 20;
const FEEDS_TAB_LIMIT = 10;

interface IndexProps {
  metadata?: Awaited<ReturnType<typeof fetchMetaInfo>>;
}

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/rss-feed" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang('/rss-feed', language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const [metadata] = await Promise.all([
    fetchMetaInfo({
      pageType: "rss_feeds",
      langCode: language_code,
      currentURL,
    }),
    // Main feed list — no filters applied yet, matches RssFeeds.tsx's initial state.
    // `null` stands in for the unused filter params — Next can't serialize `undefined`
    // into the dehydrated state, and react-query hashes both the same way.
    queryClient.prefetchQuery({
      queryKey: ["rss-feeds", language_code, null, null, null, DEFAULT_PAGE, DEFAULT_PER_PAGE],
      queryFn: () => getRssFeedItemsApi({ language_code, page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE }),
    }),
    // RSS feed sources — powers the "Feeds" tab of the filter modal, matches FeedsFilter.tsx's initial state.
    queryClient.prefetchQuery({
      queryKey: ["rss-feed-sources", language_code, 0, FEEDS_TAB_LIMIT, null, null, null, null, null, null, null],
      queryFn: () => getRssFeedsApi({ language_code, offset: 0, limit: FEEDS_TAB_LIMIT }),
    }),
  ]);

  return {
    props: {
      metadata,
      dehydratedState: dehydrate(queryClient),
    },
  };
};

const Index = ({ metadata }: IndexProps) => {
  return (
    <>
      <Meta
        title={metadata?.title}
        description={metadata?.description}
        keywords={metadata?.keywords}
        ogImage={metadata?.ogImage}
        pathName={metadata?.pathName}
      />
      <RssFeeds />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
