import { useQuery } from "@tanstack/react-query";
import { getAuthorDetailsApi } from "@/api/apiRoutes";
import { ApiResponseType, userDetailsType } from "@/types/GlobalTypes";
import { NewsApi } from "./useGetNews";

export interface AuthorNewsPagination {
  current_page: number;
  last_page: number;
  next_page_url: string | null;
  data: NewsApi[];
}

export interface AuthorDetailsApiResponse extends Omit<ApiResponseType, "data"> {
  data: {
    user: userDetailsType;
    news: AuthorNewsPagination;
  };
}

export interface UseGetAuthorDetailsParams {
  user_slug: string;
  language_code: string;
  page?: number;
  enabled?: boolean;
}

export const useGetAuthorDetails = (params: UseGetAuthorDetailsParams) => {
  const { user_slug, language_code, page = 1, enabled = true } = params;

  return useQuery<AuthorDetailsApiResponse>({
    queryKey: ["authorDetails", user_slug, language_code, page],
    enabled: !!user_slug && enabled,
    queryFn: async () => {
      try {
        const response = await getAuthorDetailsApi({ user_slug, language_code, page });
        if (!response) {
          throw new Error("Failed to fetch author details");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch author details");
        }
        return response as AuthorDetailsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch author details";
        throw new Error(apiMessage);
      }
    },
  });
};
