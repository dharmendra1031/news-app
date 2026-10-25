import { useQuery } from "@tanstack/react-query";
import { getMorePagesApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface MorePageApi {
  id: number;
  title: string;
  slug: string;
  meta_description: string | null;
  meta_keywords: string | null;
  is_custom: number;
  page_content: string;
  page_type: string;
  language_id: number;
  page_icon: string | null;
  is_termspolicy: number;
  is_privacypolicy: number;
  status: number;
  schema_markup: string | null;
  meta_title: string | null;
  og_image: string | null;
}

export type MorePagesApiResponse = ListApiResponseType<MorePageApi>;

export interface UseGetMorePagesParams {
  language_code: string;
  slug?: string;
  offset?: number;
  limit?: number;
  enabled?: boolean;
}

export const useGetMorePages = (params: UseGetMorePagesParams) => {
  const { language_code, slug, offset = 0, limit = 20, enabled = true } = params;

  return useQuery<MorePagesApiResponse>({
    queryKey: ["more-pages", language_code, slug ?? null, offset, limit],
    enabled: !!language_code && enabled,
    queryFn: async () => {
      try {
        const response = await getMorePagesApi({ language_code, slug, offset, limit });
        if (!response) {
          throw new Error("Failed to fetch pages");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch pages");
        }
        return response as MorePagesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch pages";
        throw new Error(apiMessage);
      }
    },
  });
};
