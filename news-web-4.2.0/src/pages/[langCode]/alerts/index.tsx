import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import AlertsPage from '@/components/pagesComp/AlertsPage'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getMarketAlertsApi } from "@/api/apiRoutes";
import { fetchMetaInfo } from "@/utils/fetchMetaInfo";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { isStaticExport } from "@/lib/staticExport";

const DEFAULT_OFFSET = 0;
const DEFAULT_LIMIT = 6;

interface IndexProps {
  metadata?: Awaited<ReturnType<typeof fetchMetaInfo>>;
}

const serverSideProps: GetServerSideProps = async (context) => {
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang('/alerts', language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const [metadata] = await Promise.all([
    fetchMetaInfo({
      pageType: "alerts",
      langCode: language_code,
      currentURL,
    }),
    queryClient.prefetchQuery({
      queryKey: ["market-alerts", DEFAULT_OFFSET, DEFAULT_LIMIT],
      queryFn: () => getMarketAlertsApi({ offset: DEFAULT_OFFSET, limit: DEFAULT_LIMIT }),
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
      <AlertsPage />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
