import { useQuery } from "@tanstack/react-query";
import { getCategoriesApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface SubCategoryApi {
  id: number;
  language_id: number;
  category_id: number;
  subcategory_name: string;
  slug: string;
  row_order: number;
  image: string;
  created_at: string | null;
  updated_at: string;
}

export interface CategoryApi {
  id: number;
  language_id: number;
  category_name: string;
  slug: string;
  row_order: number;
  image: string;
  meta_title: string;
  meta_description: string;
  meta_keyword: string;
  schema_markup: string | null;
  created_at: string | null;
  updated_at: string;
  sub_categories: SubCategoryApi[];
}

export type CategoriesApiResponse = ListApiResponseType<CategoryApi>;

export interface UseGetCategoriesParams {
  offset?: number;
  limit?: number;
  language_code: string;
}

export const useGetCategories = (params: UseGetCategoriesParams) => {
  const { offset = 0, limit = 20, language_code } = params;

  return useQuery<CategoriesApiResponse>({
    queryKey: ["categories", offset, limit, language_code],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getCategoriesApi({ offset, limit, language_code });
        if (!response) {
          throw new Error("Failed to fetch categories");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch categories");
        }
        return response as CategoriesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch categories";
        throw new Error(apiMessage);
      }
    },
  });
};
