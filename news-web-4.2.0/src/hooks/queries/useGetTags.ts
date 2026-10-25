import { useQuery } from "@tanstack/react-query";
import { getTagsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface TagApi {
  id: number;
  tag_name: string;
  language_id: number;
  slug: string;
  meta_keyword: string | null;
  schema_markup: string | null;
  meta_description: string | null;
  meta_title: string | null;
  og_image: string | null;
}

export type TagsApiResponse = ListApiResponseType<TagApi>;

export interface UseGetTagsParams {
  language_code: string;
  slug?: string;
  limit?: number;
  offset?: number;
}

export const useGetTags = (params: UseGetTagsParams) => {
  const { language_code, slug, limit = 20, offset = 0 } = params;

  return useQuery<TagsApiResponse>({
    queryKey: ["tags", language_code, slug, limit, offset],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getTagsApi({ language_code, slug, limit, offset });
        if (!response) {
          throw new Error("Failed to fetch tags");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch tags");
        }
        return response as TagsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch tags";
        throw new Error(apiMessage);
      }
    },
  });
};
