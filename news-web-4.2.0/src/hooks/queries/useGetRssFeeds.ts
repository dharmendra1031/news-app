import { useQuery } from "@tanstack/react-query";
import { getRssFeedItemsApi, getRssFeedsApi } from "@/api/apiRoutes";
import { PaginatedApiResponseType } from "@/types/GlobalTypes";

export interface RssFeedTagApi {
  id: number;
  tag_name: string;
  slug: string;
}

export interface RssFeedCategoryRefApi {
  id: number;
  slug: string;
  category_name: string;
}

export interface RssFeedSourceApi {
  id: number;
  language_id: number;
  category_id: number;
  subcategory_id: number;
  tag_id: string;
  feed_name: string;
  feed_url: string;
  tag: RssFeedTagApi[];
  category: RssFeedCategoryRefApi | null;
  sub_category: RssFeedCategoryRefApi | null;
}

export interface RssFeedItemApi {
  id: number;
  rss_source_id: number;
  title: string;
  url: string;
  description: string;
  image_url: string;
  author: string;
  published_at: string;
  published_at_human: string;
  source: RssFeedSourceApi;
}

export type RssFeedsApiResponse = PaginatedApiResponseType<RssFeedItemApi>;

export interface UseGetRssFeedsParams {
  language_code: string;
  source_ids?: string;
  category_ids?: string;
  subcategory_ids?: string;
  page?: string | number;
  per_page?: string | number;
}

export const useGetRssFeeds = (params: UseGetRssFeedsParams) => {
  const { language_code, source_ids, category_ids, subcategory_ids, page = "1", per_page } = params;

  return useQuery<RssFeedsApiResponse>({
    queryKey: ["rss-feeds", language_code, source_ids, category_ids, subcategory_ids, page, per_page],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getRssFeedItemsApi({ language_code, source_ids, category_ids, subcategory_ids, page, per_page });
        if (!response) {
          throw new Error("Failed to fetch RSS feeds");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch RSS feeds");
        }
        return response as RssFeedsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch RSS feeds";
        throw new Error(apiMessage);
      }
    },
  });
};
