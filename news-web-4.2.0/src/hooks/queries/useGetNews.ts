import { useQuery } from "@tanstack/react-query";
import { getNewsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface NewsCategoryRefApi {
  id: number;
  category_name: string;
  slug: string;
}

export interface NewsSubCategoryRefApi {
  id: number;
  subcategory_name: string;
}

export interface NewsLocationApi {
  id: number;
  location_name: string;
  latitude: string;
  longitude: string;
}

export interface NewsImageApi {
  id: number;
  news_id: number;
  other_image: string;
  created_at: string | null;
  updated_at: string | null;
}

export interface NewsTagApi {
  id: number;
  tag_name: string;
  slug: string;
}

export interface NewsUserApi {
  id: number;
  name: string;
  profile: string;
  is_author: number;
  slug: string;
}

export interface NewsAuthorApi {
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

export interface NewsLanguageApi {
  id: number;
  language: string;
  code: string;
  status: number;
  isRTL: number;
  image: string;
  display_name: string;
  app_file: string;
  web_file: string;
  panel_file: string;
}

export interface NewsApi {
  id: number;
  language_id: number;
  category_id: number;
  subcategory_id: number;
  tag_id: string;
  location_id: number;
  title: string;
  slug: string;
  image: string;
  date: string;
  published_date: string | null;
  content_type: string;
  content_value: string;
  description: string | null;
  summarized_description: string | null;
  user_id: number;
  admin_id: number;
  show_till: string;
  status: number;
  is_draft: number;
  is_clone: number;
  is_comment: number;
  counter: number;
  meta_title: string | null;
  meta_description: string | null;
  meta_keyword: string | null;
  schema_markup: string | null;
  created_at: string | null;
  updated_at: string | null;
  is_short_news: number;
  like: number;
  total_like: number;
  total_bookmark: number;
  bookmark: number;
  total_views: number;
  tag_name: string;
  tag: NewsTagApi[];
  is_expired: number;
  read_time: number;
  language_code: string;
  category: NewsCategoryRefApi | null;
  sub_category: NewsSubCategoryRefApi | null;
  location: NewsLocationApi | null;
  images: NewsImageApi[];
  user: NewsUserApi | null;
  author: NewsAuthorApi | null;
  language: NewsLanguageApi;
}

export type NewsApiResponse = ListApiResponseType<NewsApi>;

export interface UseGetNewsParams {
  language_code?: string;
  offset?: number;
  limit?: number;
  id?: number;
  get_user_news?: 0 | 1;
  search?: string;
  category_id?: number | string;
  category_slug?: string;
  subcategory_id?: number;
  subcategory_slug?: string;
  slug?: string;
  tag_id?: number | string;
  tag_slug?: string;
  latitude?: number | string | null;
  longitude?: number | string | null;
  merge_tag?: 0 | 1;
  last_n_days?: number | null;
  date?: string;
  year?: number | string;
  enabled?: boolean;
  /**
   * Most callers page a single language's news, so a query with no
   * `language_code` is treated as "not ready yet" and left disabled.
   * ManageNews lists a user's own news across all languages, so it has none
   * to wait on — pass `false` there to skip that guard.
   * @default true
   */
  requireLanguageCode?: boolean;
}

export const useGetNews = (params: UseGetNewsParams) => {
  const { language_code, offset = 0, limit = 20, enabled = true, requireLanguageCode = true, ...rest } = params;

  return useQuery<NewsApiResponse>({
    queryKey: ["news", language_code, offset, limit, rest],
    enabled: (requireLanguageCode ? !!language_code : true) && enabled,
    ...(!requireLanguageCode && { staleTime: 0, gcTime: 0 }),
    queryFn: async () => {
      try {
        const response = await getNewsApi({ language_code, offset, limit, ...rest });
        if (!response) {
          throw new Error("Failed to fetch news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch news");
        }
        return response as NewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch news";
        throw new Error(apiMessage);
      }
    },
  });
};
