import { useQuery } from "@tanstack/react-query";
import { getVideoShortsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface VideoShortApi {
  id: number;
  language_id: number;
  category_id: number;
  title: string;
  slug: string;
  video_type: string;
  video_url: string;
  description: string | null;
  published_date: string | null;
  status: boolean;
  views_count: number;
  shares_count: number;
  comments_count: number;
  total_like_count: number;
  is_liked: boolean;
  is_disliked: boolean;
}

export type VideoShortsApiResponse = ListApiResponseType<VideoShortApi>;

export interface UseGetVideoShortsParams {
  language_code: string;
  offset?: number;
  limit?: number;
  order?: "asc" | "desc";
}

export const useGetVideoShorts = (params: UseGetVideoShortsParams) => {
  const { language_code, offset = 0, limit = 20, order = "desc" } = params;

  return useQuery<VideoShortsApiResponse>({
    queryKey: ["video-shorts", language_code, offset, limit, order],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getVideoShortsApi({ language_code, offset, limit, order });
        if (!response) {
          throw new Error("Failed to fetch video shorts");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch video shorts");
        }
        return response as VideoShortsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch video shorts";
        throw new Error(apiMessage);
      }
    },
  });
};
