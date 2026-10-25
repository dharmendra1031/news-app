import { useQuery } from "@tanstack/react-query";
import { getFeatureSectionsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { NewsApi } from "./useGetNews";
import { BreakingNewsApi } from "./useGetBreakingNews";
import { RssFeedItemApi } from "./useGetRssFeeds";

export type FeatureSectionStyleWeb = "style_1" | "style_2" | "style_3" | "style_4" | "style_5" | "style_6";

export type FeatureSectionNewsType = "news" | "breaking_news" | "rss_feeds_news" | "videos" | "author_news" | "user_choice";

/** Which payload key a section actually came back with. */
export type FeatureSectionContentType = "news" | "videos" | "breaking_news" | "rss_feeds_news" | "author_news";

export interface FeatureSectionAdSpaceApi {
  id: number;
  language_id: number;
  ad_featured_section_id: number;
  ad_image: string;
  web_ad_image: string;
  ad_url: string;
  status: number;
  page: string;
  platform: string;
  /** "above" / "below" the section's content */
  placement: string;
  ad_type: string;
  duration_days: number;
  start_date: string;
  end_date: string;
}

/**
 * Feature-section news rows are a flatter variant of `NewsApi` — the category
 * arrives as a plain `category_name` string rather than a nested `category`
 * object, and the relation fields aren't included.
 */
export type FeatureSectionNewsApi = Omit<NewsApi, "category" | "sub_category" | "location" | "language" | "language_code" | "user" | "author"> & {
  category_name?: string;
  subcategory_name?: string;
};

export interface FeatureSectionApi {
  id: number;
  language_id: number;
  title: string;
  slug: string;
  short_description: string | null;
  news_type: FeatureSectionNewsType;
  videos_type: string;
  filter_type: string;
  category_ids: string;
  subcategory_ids: string;
  news_ids: string;
  style_app: string;
  style_web: FeatureSectionStyleWeb;
  row_order: number;
  status: number;
  is_based_on_user_choice: number;
  meta_title: string | null;
  meta_description: string | null;
  meta_keyword: string | null;
  schema_markup: string | null;
  og_image: string | null;
  created_at: string | null;
  updated_at: string | null;
  // Only the key matching `news_type` is present on a given section.
  news?: FeatureSectionNewsApi[];
  news_total?: number;
  videos?: FeatureSectionNewsApi[];
  videos_total?: number;
  author_news?: FeatureSectionNewsApi[];
  author_news_total?: number;
  breaking_news?: BreakingNewsApi[];
  breaking_news_total?: number;
  rss_feeds_news?: RssFeedItemApi[];
  rss_feeds_news_total?: number;
  ad_spaces?: FeatureSectionAdSpaceApi | null;
}

export type FeatureSectionsApiResponse = ListApiResponseType<FeatureSectionApi>;

/** The subset of fields the home-page news cards actually read. */
export interface FeatureSectionItem {
  id: number;
  slug: string;
  title: string;
  image: string;
  date?: string | null;
  published_date?: string | null;
  total_views?: number;
  category?: { category_name?: string } | null;
  /** Only set for rss rows — cards show it in place of the view count. */
  rssAuthor?: string | null;
  /** Set for row types that don't live under `/news/<slug>` (rss items link out). */
  href?: string;
  /** True only for rows from a `videos` section — drives the play overlay. */
  isVideo?: boolean;
}

export interface FeatureSectionContent {
  /** `null` when the section came back with no rows at all. */
  type: FeatureSectionContentType | null;
  items: FeatureSectionItem[];
}

/** `news`, `videos` and `author_news` share a shape; only the detail route differs. */
const toNewsItem = (item: FeatureSectionNewsApi, basePath: string, isVideo = false): FeatureSectionItem => ({
  id: item.id,
  slug: item.slug,
  title: item.title,
  image: item.image,
  date: item.date,
  published_date: item.published_date,
  total_views: item.total_views,
  category: item.category_name ? { category_name: item.category_name } : null,
  href: `${basePath}/${item.slug}`,
  isVideo,
});

export const toBreakingNewsItem = (item: BreakingNewsApi): FeatureSectionItem => ({
  id: item.id,
  slug: item.slug,
  title: item.title,
  image: item.image,
  date: item.created_at,
  published_date: item.created_at,
  total_views: item.total_views,
  category: null,
  href: `/breaking-news/${item.slug}`,
});

const toRssFeedItem = (item: RssFeedItemApi): FeatureSectionItem => ({
  id: item.id,
  slug: String(item.id),
  title: item.title,
  image: item.image_url,
  date: item.published_at,
  published_date: item.published_at,
  category: item.source?.category?.category_name ? { category_name: item.source.category.category_name } : null,
  rssAuthor: item.author || null,
  // RSS rows are third-party articles — they link straight out.
  href: item.url,
});

/**
 * A section carries its rows under whichever key matches its `news_type`, and
 * each key has a different shape and detail route. Resolve that once, here,
 * rather than in every style component.
 */
export const getFeatureSectionContent = (section?: FeatureSectionApi): FeatureSectionContent => {
  if (!section) return { type: null, items: [] };

  if (section.videos?.length) {
    return { type: "videos", items: section.videos.map((item) => toNewsItem(item, "/video-news", true)) };
  }
  if (section.breaking_news?.length) {
    return { type: "breaking_news", items: section.breaking_news.map(toBreakingNewsItem) };
  }
  if (section.rss_feeds_news?.length) {
    return { type: "rss_feeds_news", items: section.rss_feeds_news.map(toRssFeedItem) };
  }
  if (section.author_news?.length) {
    return { type: "author_news", items: section.author_news.map((item) => toNewsItem(item, "/news")) };
  }
  if (section.news?.length) {
    return { type: "news", items: section.news.map((item) => toNewsItem(item, "/news")) };
  }

  return { type: null, items: [] };
};

/** News rows requested per section. */
export const FEATURE_SECTION_NEWS_LIMIT = 9;
/** Sections fetched per infinite-scroll page. */
export const FEATURE_SECTIONS_PER_PAGE = 4;

export interface UseGetFeatureSectionsParams {
  language_code: string;
  /** Paging *within* a section's news list. */
  offset?: number;
  limit?: number;
  /** Paging across the sections themselves. */
  section_offset?: number;
  section_limit?: number;
  slug?: string;
  section_id?: number;
  latitude?: number | string;
  longitude?: number | string;
  isToken?: boolean;
  platform?: string;
  enabled?: boolean;
}

/**
 * Built here (and reused by the server prefetch) so the SSR-dehydrated key and
 * the client key can't drift apart. `null` rather than `undefined` for the
 * unset params — Next can't serialize `undefined` into the dehydrated state,
 * and react-query hashes both the same way.
 */
export const featureSectionsQueryKey = (params: UseGetFeatureSectionsParams) => [
  "feature-sections",
  params.language_code,
  params.offset ?? 0,
  params.limit ?? FEATURE_SECTION_NEWS_LIMIT,
  params.section_offset ?? 0,
  params.section_limit ?? FEATURE_SECTIONS_PER_PAGE,
  params.slug ?? null,
  params.section_id ?? null,
  params.latitude ?? null,
  params.longitude ?? null,
  params.isToken ?? false,
  params.platform ?? "web",
];

export const useGetFeatureSections = (params: UseGetFeatureSectionsParams) => {
  const {
    language_code,
    offset = 0,
    limit = FEATURE_SECTION_NEWS_LIMIT,
    section_offset = 0,
    section_limit = FEATURE_SECTIONS_PER_PAGE,
    slug,
    section_id,
    latitude,
    longitude,
    isToken = false,
    platform = "web",
    enabled = true,
  } = params;

  return useQuery<FeatureSectionsApiResponse>({
    queryKey: featureSectionsQueryKey(params),
    enabled: !!language_code && enabled,
    queryFn: async () => {
      try {
        const response = await getFeatureSectionsApi({
          language_code,
          offset,
          limit,
          section_offset,
          section_limit,
          slug,
          section_id,
          latitude,
          longitude,
          isToken,
          platform,
        });
        if (!response) {
          throw new Error("Failed to fetch featured sections");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch featured sections");
        }
        return response as FeatureSectionsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch featured sections";
        throw new Error(apiMessage);
      }
    },
  });
};
