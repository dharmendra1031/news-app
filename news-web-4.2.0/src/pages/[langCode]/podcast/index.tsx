import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import Podcast from '@/components/pagesComp/podcast/Podcast'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getPodcastsApi } from "@/api/apiRoutes";
import { fetchMetaInfo } from "@/utils/fetchMetaInfo";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { isStaticExport } from "@/lib/staticExport";

interface IndexProps {
  metadata?: Awaited<ReturnType<typeof fetchMetaInfo>>;
}

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/podcast" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang('/podcast', language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const [metadata] = await Promise.all([
    fetchMetaInfo({
      pageType: "podcast",
      langCode: language_code,
      currentURL,
    }),
    queryClient.prefetchQuery({
      queryKey: ["podcasts", "all", 0, 6, null, null],
      queryFn: () => getPodcastsApi({ type: "all", offset: 0, limit: 6 }),
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
            <Podcast />
            {metadata?.schema && <JsonLd data={metadata.schema} />}
        </>
    )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
