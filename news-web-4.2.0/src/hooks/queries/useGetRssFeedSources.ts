import { useQuery } from "@tanstack/react-query";
import { getRssFeedsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { RssFeedCategoryRefApi, RssFeedTagApi } from "./useGetRssFeeds";

export interface RssFeedSourceListItemApi {
  id: number;
  language_id: number;
  category_id: number;
  subcategory_id: number;
  tag_id: string;
  feed_name: string;
  feed_url: string;
  status: number;
  created_at: string;
  updated_at: string;
  last_fetched_at: string | null;
  tag: RssFeedTagApi[];
  tag_name?: string;
  category: RssFeedCategoryRefApi | null;
  sub_category: RssFeedCategoryRefApi | null;
}

export type RssFeedSourcesApiResponse = ListApiResponseType<RssFeedSourceListItemApi>;

export interface UseGetRssFeedSourcesParams {
  language_code: string;
  offset?: number;
  limit?: number;
  category_id?: number;
  category_slug?: string;
  subcategory_id?: number;
  subcategory_slug?: string;
  tag_id?: number;
  tag_slug?: string;
  search?: string;
}

export const useGetRssFeedSources = (params: UseGetRssFeedSourcesParams) => {
  const {
    language_code,
    offset = 0,
    limit = 20,
    category_id,
    category_slug,
    subcategory_id,
    subcategory_slug,
    tag_id,
    tag_slug,
    search,
  } = params;

  return useQuery<RssFeedSourcesApiResponse>({
    queryKey: [
      "rss-feed-sources",
      language_code,
      offset,
      limit,
      category_id,
      category_slug,
      subcategory_id,
      subcategory_slug,
      tag_id,
      tag_slug,
      search,
    ],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getRssFeedsApi({
          language_code,
          offset,
          limit,
          category_id,
          category_slug,
          subcategory_id,
          subcategory_slug,
          tag_id,
          tag_slug,
          search,
        });
        if (!response) {
          throw new Error("Failed to fetch RSS feed sources");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch RSS feed sources");
        }
        return response as RssFeedSourcesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch RSS feed sources";
        throw new Error(apiMessage);
      }
    },
  });
};
