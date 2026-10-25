import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import MorePageDetails from '@/components/pagesComp/MorePageDetails'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getMorePagesApi } from "@/api/apiRoutes";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { MorePagesApiResponse } from "@/hooks/queries/useGetMorePages";
import { isStaticExport } from "@/lib/staticExport";

interface MorePageMetadata {
  title?: string;
  description?: string | null;
  keywords?: string;
  ogImage?: string | null;
  pathName?: string;
  schema?: Record<string, unknown> | null;
}

interface IndexProps {
  metadata?: MorePageMetadata;
}

const parseSchemaMarkup = (schemaMarkup?: string | null): Record<string, unknown> | null => {
  if (!schemaMarkup) return null;
  try {
    return JSON.parse(schemaMarkup);
  } catch (error) {
    console.error('Error parsing schema_markup:', error);
    return null;
  }
};

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/more-pages/foo" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  const slug = context.params?.slug;
  if (typeof slug !== "string") {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const language_code = getServerLangCode(context);
  const defaultLocale = await fetchDefaultLocale();
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang(`/more-pages/${slug}`, language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const response = await queryClient.fetchQuery<MorePagesApiResponse>({
    queryKey: ["more-pages", language_code, slug, 0, 1],
    queryFn: () => getMorePagesApi({ language_code, slug, offset: 0, limit: 1 }),
  });

  const page = response?.data?.data?.[0];
  if (!response || response.error || !page) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } };
  }

  const metadata: MorePageMetadata = {
    title: page.meta_title || page.title,
    description: page.meta_description || null,
    keywords: page.meta_keywords || process.env.NEXT_PUBLIC_kEYWORDS,
    ogImage: page.og_image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(page.schema_markup),
  };

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
      <MorePageDetails />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  );
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
