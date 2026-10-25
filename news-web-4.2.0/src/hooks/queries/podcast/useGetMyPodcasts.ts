import { useQuery } from "@tanstack/react-query";
import { getMyPodcastsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { PodcastApi } from "./useGetPodcasts";

export type MyPodcastsApiResponse = ListApiResponseType<PodcastApi>;

export interface UseGetMyPodcastsParams {
  type?: string;
  offset?: number;
  limit?: number;
  search?: string;
  enabled?: boolean;
}

export const useGetMyPodcasts = (params: UseGetMyPodcastsParams = {}) => {
  const { type, offset = 0, limit = 20, search, enabled = true } = params;

  return useQuery<MyPodcastsApiResponse>({
    queryKey: ["myPodcasts", type, offset, limit, search],
    enabled,
    queryFn: async () => {
      try {
        const response = await getMyPodcastsApi({ type, offset, limit, search });
        if (!response) {
          throw new Error("Failed to fetch podcasts");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch podcasts");
        }
        return response as MyPodcastsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch podcasts";
        throw new Error(apiMessage);
      }
    },
  });
};
