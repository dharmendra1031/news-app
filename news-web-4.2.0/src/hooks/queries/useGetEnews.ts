import { useQuery } from "@tanstack/react-query";
import { getENewsApi } from "@/api/apiRoutes";
import { PaginatedApiResponseType } from "@/types/GlobalTypes";

export interface ENewsApi {
  id: number;
  language_id: number;
  title: string;
  slug: string;
  description: string | null;
  thumbnail: string;
  attachment: string;
  date: string;
  meta_keyword: string | null;
  meta_title: string | null;
  meta_description: string | null;
  schema_markup: string | null;
  status: number;
}

export type ENewsApiResponse = PaginatedApiResponseType<ENewsApi>;

export interface UseGetEnewsParams {
  language_code: string;
  page?: string | number;
  per_page?: string | number;
}

export const useGetEnews = (params: UseGetEnewsParams) => {
  const { language_code, page = "1", per_page } = params;

  return useQuery<ENewsApiResponse>({
    queryKey: ["e-news", language_code, page, per_page],
    enabled: !!language_code,
    queryFn: async () => {
      try {
        const response = await getENewsApi({ language_code, page, per_page });
        if (!response) {
          throw new Error("Failed to fetch e-news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch e-news");
        }
        return response as ENewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch e-news";
        throw new Error(apiMessage);
      }
    },
  });
};
