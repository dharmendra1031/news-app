import { useQuery } from "@tanstack/react-query";
import { getVideoNewsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { FeatureSectionItem } from "./useGetFeatureSections";

// Mixed feed of news / breaking_news / live_streaming items — each source_type
// carries a different subset of fields, so only what's common across all three
// is required.
export type VideoNewsSourceType = "news" | "breaking_news" | "live_streaming";

export interface VideoNewsApi {
  id: number;
  title: string;
  image: string;
  content_type: string;
  content_value: string;
  description: string | null;
  slug: string;
  like: number;
  total_like: number;
  total_views: number;
  category_name: string | null;
  category_slug: string | null;
  tag_name: string | null;
  source_type: VideoNewsSourceType;
  language_id?: number;
  category_id?: number | null;
  subcategory_id?: number | null;
  tag_id?: string | null;
  location_id?: number;
  date?: string | null;
  published_date?: string | null;
  summarized_description?: string | null;
  user_id?: number;
  admin_id?: number;
  show_till?: string;
  status?: number;
  is_draft?: number;
  is_clone?: number;
  is_comment?: number;
  meta_title?: string | null;
  meta_description?: string | null;
  meta_keyword?: string | null;
  schema_markup?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  is_short_news?: number;
  latitude?: string | null;
  longitude?: string | null;
  distance?: number | null;
}

export type VideoNewsApiResponse = ListApiResponseType<VideoNewsApi>;

/** Video-news rows -> the shared news-card shape; drives the play overlay. */
export const toVideoNewsItem = (item: VideoNewsApi): FeatureSectionItem => ({
  id: item.id,
  slug: item.slug,
  title: item.title,
  image: item.image,
  date: item.date,
  published_date: item.published_date,
  total_views: item.total_views,
  category: item.category_name ? { category_name: item.category_name } : null,
  href: `/video-news/${item.slug}`,
  isVideo: true,
});

export interface UseGetVideoNewsParams {
  language_code: string;
  offset?: number;
  limit?: number;
  slug?: string;
  category_id?: number;
  category_slug?: string;
  enabled?: boolean;
}

export const useGetVideoNews = (params: UseGetVideoNewsParams) => {
  const { language_code, offset = 0, limit = 20, slug, category_id, category_slug, enabled = true } = params;

  return useQuery<VideoNewsApiResponse>({
    queryKey: ["video-news", language_code, offset, limit, slug, category_id, category_slug],
    enabled: !!language_code && enabled,
    queryFn: async () => {
      try {
        const response = await getVideoNewsApi({ language_code, offset, limit, slug, category_id, category_slug });
        if (!response) {
          throw new Error("Failed to fetch video news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch video news");
        }
        return response as VideoNewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch video news";
        throw new Error(apiMessage);
      }
    },
  });
};
