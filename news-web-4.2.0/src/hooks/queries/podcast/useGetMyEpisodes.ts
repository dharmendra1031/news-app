import { useQuery } from "@tanstack/react-query";
import { getMyEpisodesApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";
import { EpisodeApi } from "./useGetEpisodes";

// `/my_episodes` spans every podcast (history/bookmark), so each episode
// carries its own podcast reference instead of one shared podcast_slug.
export interface MyEpisodeApi extends EpisodeApi {
  podcast: {
    id: number;
    slug: string;
    follower_count: string;
    episode_count: number;
  };
}

export interface MyEpisodesApiResponse extends Omit<ApiResponseType, "data"> {
  data: {
    episodes: MyEpisodeApi[];
    total: number;
  };
}

export interface UseGetMyEpisodesParams {
  offset?: number;
  limit?: number;
  type?: string;
  enabled?: boolean;
}

export const useGetMyEpisodes = (params: UseGetMyEpisodesParams) => {
  const { offset = 0, limit = 20, type = 'all', enabled = true } = params;

  return useQuery<MyEpisodesApiResponse>({
    queryKey: ["myEpisodes", offset, limit, type],
    enabled,
    queryFn: async () => {
      try {
        const response = await getMyEpisodesApi({ offset, limit, type });
        if (!response) {
          throw new Error("Failed to fetch episodes");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch episodes");
        }
        return response as MyEpisodesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch episodes";
        throw new Error(apiMessage);
      }
    },
  });
};
