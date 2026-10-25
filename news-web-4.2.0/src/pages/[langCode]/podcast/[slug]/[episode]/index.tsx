import type { GetServerSideProps } from "next";
import { QueryClient, dehydrate } from "@tanstack/react-query";
import EpisodePlay from '@/components/pagesComp/podcast/EpisodePlay'
import { getEpisodeApi } from "@/api/apiRoutes";
import { isValidLocaleSegment } from "@/lib/locale";
import { EpisodesApiResponse } from "@/hooks/queries/podcast/useGetEpisodes";
import { isStaticExport } from "@/lib/staticExport";

const serverSideProps: GetServerSideProps = async (context) => {
  // `[langCode]` matches ANY single path segment, so e.g. "/xy/podcast/foo/bar" with
  // a bogus "xy" would otherwise still render this page and hit the APIs.
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true };
  }

  const slug = context.params?.slug;
  const episode = context.params?.episode;
  if (typeof slug !== "string" || typeof episode !== "string") {
    return { notFound: true };
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== "true") {
    return { props: {} };
  }

  const queryClient = new QueryClient();

  const response = await queryClient.fetchQuery<EpisodesApiResponse>({
    queryKey: ["episodes", slug, 0, 6, "all", 0],
    queryFn: () => getEpisodeApi({ podcast_slug: slug, offset: 0, limit: 6, type: "all", is_author_check: 0 }),
  });

  if (!response || response.error || !response.data) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } };
  }

  return {
    props: {
      dehydratedState: dehydrate(queryClient),
    },
  };
};

const Index = () => {
    return (
        <EpisodePlay />
    )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps;
