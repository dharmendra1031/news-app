import { useQuery } from "@tanstack/react-query";
import { getPodcastsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface PodcastAuthorApi {
  id: number;
  user_id: number;
  bio: string | null;
  telegram_link: string | null;
  linkedin_link: string | null;
  facebook_link: string | null;
  whatsapp_link: string | null;
  status: string;
  auto_approve: number;
}

export interface PodcastUserApi {
  id: number;
  name: string;
  profile: string | null;
  is_author: number;
}

export interface PodcastApi {
  id: number;
  user_id: number | null;
  title: string;
  slug: string;
  description: string;
  image: string;
  draft: number;
  status: string;
  published_at: string;
  meta_title: string | null;
  meta_description: string | null;
  meta_keyword: string | null;
  schema_markup: string | null;
  is_followed: boolean;
  follower_count: string;
  episode_count: number;
  user: PodcastUserApi | null;
  author: PodcastAuthorApi | null;
}

export type PodcastsApiResponse = ListApiResponseType<PodcastApi>;

export interface UseGetPodcastsParams {
  type?: string;
  offset?: number;
  limit?: number;
  slug?: string;
  search?: string;
  enabled?: boolean;
}

export const useGetPodcasts = (params: UseGetPodcastsParams = {}) => {
  const { type, offset = 0, limit = 20, slug, search, enabled = true } = params;

  return useQuery<PodcastsApiResponse>({
    queryKey: ["podcasts", type, offset, limit, slug, search],
    enabled,
    queryFn: async () => {
      try {
        const response = await getPodcastsApi({ type, offset, limit, slug, search });
        if (!response) {
          throw new Error("Failed to fetch podcasts");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch podcasts");
        }
        return response as PodcastsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch podcasts";
        throw new Error(apiMessage);
      }
    },
  });
};
