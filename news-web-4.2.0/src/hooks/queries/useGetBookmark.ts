import { useQuery } from "@tanstack/react-query";
import { getBookmarkApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { NewsTagApi } from "./useGetNews";
import { FeatureSectionItem } from "./useGetFeatureSections";

/**
 * `get_bookmark` returns the underlying news row flattened onto the bookmark
 * record — `id` is the *bookmark* row's id (not the news id) and the category
 * comes back as a bare `category_name` string rather than a nested object.
 */
export interface BookmarkNewsApi {
  id: number;
  user_id: number;
  news_id: number;
  created_at: string | null;
  updated_at: string | null;
  category_id: number;
  category_name: string | null;
  subcategory_id: number;
  language_id: number;
  title: string;
  slug: string;
  date: string;
  published_date: string | null;
  show_till: string;
  is_comment: number;
  tag_id: string;
  content_type: string;
  content_value: string;
  image: string;
  description: string | null;
  like: number;
  total_like: number;
  total_bookmark: number;
  bookmark: number;
  total_views: number;
  tag_name: string;
  tag: NewsTagApi[];
  is_expired: number;
  read_time: number;
}

export type BookmarkApiResponse = ListApiResponseType<BookmarkNewsApi>;

/** `FeatureSectionItem.id` must be the *news* id — that's what bookmark/link actions key off of. */
const toBookmarkItem = (item: BookmarkNewsApi): FeatureSectionItem => ({
  id: item.news_id,
  slug: item.slug,
  title: item.title,
  image: item.image,
  date: item.date,
  published_date: item.published_date,
  total_views: item.total_views,
  category: item.category_name ? { category_name: item.category_name } : null,
});

export interface UseGetBookmarkParams {
  language_code: string;
  offset?: number;
  limit?: number;
  enabled?: boolean;
}

export const useGetBookmark = (params: UseGetBookmarkParams) => {
  const { language_code, offset = 0, limit = 20, enabled = true } = params;

  return useQuery<ListApiResponseType<FeatureSectionItem>>({
    queryKey: ["bookmark", language_code, offset, limit],
    enabled: !!language_code && enabled,
    queryFn: async () => {
      try {
        const response = await getBookmarkApi({ language_code, offset, limit });
        if (!response) {
          throw new Error("Failed to fetch bookmarks");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch bookmarks");
        }
        const typed = response as BookmarkApiResponse;
        return {
          ...typed,
          data: {
            total: typed.data?.total ?? 0,
            data: (typed.data?.data ?? []).map(toBookmarkItem),
          },
        };
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch bookmarks";
        throw new Error(apiMessage);
      }
    },
  });
};

export type { FeatureSectionItem as BookmarkItem };
