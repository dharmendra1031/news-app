import { useQuery } from "@tanstack/react-query";
import { getLiveNewsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface LiveNewsApi {
  id: number;
  title: string;
  image: string;
  type: string;
  url: string;
  language_id: number;
  meta_keyword: string | null;
  schema_markup: string | null;
  meta_description: string | null;
  meta_title: string | null;
  created_at: string | null;
  updated_at: string | null;
  slug: string;
}

export type LiveNewsApiResponse = ListApiResponseType<LiveNewsApi>;

export interface UseGetLiveNewsParams {
  language_code: string;
  offset?: number;
  limit?: number;
}

export const useGetLiveNews = (params: UseGetLiveNewsParams) => {
  const { language_code, offset = 0, limit = 20 } = params;

  return useQuery<LiveNewsApiResponse>({
    queryKey: ["live-news", language_code, offset, limit],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getLiveNewsApi({ language_code, offset, limit });
        if (!response) {
          throw new Error("Failed to fetch live news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch live news");
        }
        return response as LiveNewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch live news";
        throw new Error(apiMessage);
      }
    },
  });
};
