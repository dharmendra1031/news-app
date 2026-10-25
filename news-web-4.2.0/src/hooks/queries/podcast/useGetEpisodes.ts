import { useQuery } from "@tanstack/react-query";
import { getEpisodeApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";
import { PodcastApi } from "./useGetPodcasts";

export interface EpisodeListeningHistory {
  listened_seconds: number;
  completed?: boolean;
}

export interface EpisodeApi {
  id: number;
  podcast_id: number;
  episode_no: number;
  title: string;
  slug: string;
  description: string;
  image: string;
  source_type: string;
  audio_url: string;
  status: string;
  duration_seconds: number;
  draft: boolean;
  published_at: string;
  listening_history: EpisodeListeningHistory | null;
  is_bookmarked: boolean;
}

export type PodcastWithEpisodesApi = PodcastApi & {
  episodes: EpisodeApi[];
};

export interface EpisodesApiResponse extends Omit<ApiResponseType, "data"> {
  data: PodcastWithEpisodesApi;
}

export interface UseGetEpisodesParams {
  podcast_slug?: string;
  offset?: number;
  limit?: number;
  type?: string;
  is_author_check?: 0 | 1;
  enabled?: boolean;
}

export const useGetEpisodes = (params: UseGetEpisodesParams) => {
  const { podcast_slug = '', offset = 0, limit = 20, type = 'all', is_author_check = 0, enabled = true } = params;

  return useQuery<EpisodesApiResponse>({
    queryKey: ["episodes", podcast_slug, offset, limit, type, is_author_check],
    enabled,
    queryFn: async () => {
      try {
        const response = await getEpisodeApi({ ...(podcast_slug && { podcast_slug }), offset, limit, type, is_author_check });
        if (!response) {
          throw new Error("Failed to fetch episodes");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch episodes");
        }
        return response as EpisodesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch episodes";
        throw new Error(apiMessage);
      }
    },
  });
};
