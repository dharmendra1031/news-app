import { useQuery } from "@tanstack/react-query";
import { getBreaingNewsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface BreakingNewsApi {
  id: number;
  title: string;
  image: string;
  content_type: string;
  content_value: string;
  description: string;
  summarized_description: string | null;
  language_id: number;
  slug: string;
  meta_keyword: string | null;
  schema_markup: string | null;
  meta_description: string | null;
  meta_title: string | null;
  created_at: string | null;
  updated_at: string | null;
  total_views: number;
  read_time: number;
}

export type BreakingNewsApiResponse = ListApiResponseType<BreakingNewsApi>;

export interface UseGetBreakingNewsParams {
  language_code: string;
  slug?: string;
  offset?: number;
  limit?: number;
  enabled?: boolean;
}

export const useGetBreakingNews = (params: UseGetBreakingNewsParams) => {
  const { language_code, slug, offset = 0, limit = 20, enabled = true } = params;

  return useQuery<BreakingNewsApiResponse>({
    queryKey: ["breaking-news", language_code, slug, offset, limit],
    enabled: !!language_code && enabled,
    queryFn: async () => {
      try {
        const response = await getBreaingNewsApi({ language_code, slug, offset, limit });
        if (!response) {
          throw new Error("Failed to fetch breaking news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch breaking news");
        }
        return response as BreakingNewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch breaking news";
        throw new Error(apiMessage);
      }
    },
  });
};
