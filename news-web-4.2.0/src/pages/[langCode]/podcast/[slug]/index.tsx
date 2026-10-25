import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import PodcastDetails from '@/components/pagesComp/podcast/PodcastDetails'
import Meta from "@/components/common/Meta";
import JsonLd from "@/components/schema/JsonLd";
import { getEpisodeApi } from "@/api/apiRoutes";
import { fetchDefaultLocale } from "@/lib/defaultLocale";
import { withLang } from "@/lib/localizedUrl";
import { getServerLangCode } from "@/lib/getServerLangCode";
import { isValidLocaleSegment } from "@/lib/locale";
import { EpisodesApiResponse } from "@/hooks/queries/podcast/useGetEpisodes";
import { isStaticExport } from "@/lib/staticExport";

interface PodcastMetadata {
  title?: string;
  description?: string;
  keywords?: string;
  ogImage?: string | null;
  pathName?: string;
  schema?: Record<string, unknown> | null;
}

interface IndexProps {
  metadata?: PodcastMetadata;
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
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/podcast/foo" with
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
  const currentURL = process.env.NEXT_PUBLIC_WEB_URL + `${withLang(`/podcast/${slug}`, language_code, defaultLocale)}/`;

  const queryClient = new QueryClient();

  const response = await queryClient.fetchQuery<EpisodesApiResponse>({
    queryKey: ["episodes", slug, 0, 6, "all", 0],
    queryFn: () => getEpisodeApi({ podcast_slug: slug, offset: 0, limit: 6, type: "all", is_author_check: 0 }),
  });

  const podcast = response?.data;
  if (!response || response.error || !podcast) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } };
  }

  const metadata: PodcastMetadata = {
    title: podcast.meta_title || podcast.title,
    description: podcast.meta_description || podcast.description,
    keywords: podcast.meta_keyword || process.env.NEXT_PUBLIC_kEYWORDS,
    ogImage: podcast.image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(podcast.schema_markup),
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
            <PodcastDetails />
            {metadata?.schema && <JsonLd data={metadata.schema} />}
        </>
    );
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
