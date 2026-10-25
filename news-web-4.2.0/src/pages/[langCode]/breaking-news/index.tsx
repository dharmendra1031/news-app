import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import BreakingNews from '@/components/pagesComp/BreakingNews'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getBreaingNewsApi, getAdSpacesApi } from "@/api/apiRoutes";
import { fetchMetaInfo } from "@/utils/fetchMetaInfo";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { isStaticExport } from "@/lib/staticExport";

const DEFAULT_OFFSET = 0;
const DEFAULT_LIMIT = 8;

interface IndexProps {
  metadata?: Awaited<ReturnType<typeof fetchMetaInfo>>;
}

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/breaking-news" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang('/breaking-news', language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const [metadata] = await Promise.all([
    fetchMetaInfo({
      pageType: "all_breaking_news",
      langCode: language_code,
      currentURL,
    }),
    queryClient.prefetchQuery({
      // `slug` is `null` here, not `undefined` — Next can't serialize `undefined`
      // into the dehydrated state, and react-query hashes both the same way.
      queryKey: ["breaking-news", language_code, null, DEFAULT_OFFSET, DEFAULT_LIMIT],
      queryFn: () => getBreaingNewsApi({ language_code, offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT }),
    }),
    queryClient.prefetchQuery({
      queryKey: ["ad-spaces", language_code, "news_page", "web"],
      queryFn: () => getAdSpacesApi({ language_code, page: "news_page" }),
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
      <BreakingNews />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
