import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import LiveNews from '@/components/pagesComp/LiveNews'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getLiveNewsApi, getAdSpacesApi } from "@/api/apiRoutes";
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
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/live-news" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang('/live-news', language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const [metadata] = await Promise.all([
    fetchMetaInfo({
      pageType: "live_streaming_news",
      langCode: language_code,
      currentURL,
    }),
    queryClient.prefetchQuery({
      queryKey: ["live-news", language_code, DEFAULT_OFFSET, DEFAULT_LIMIT],
      queryFn: () => getLiveNewsApi({ language_code, offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT }),
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
            <LiveNews />
            {metadata?.schema && <JsonLd data={metadata.schema} />}
        </>
    )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
