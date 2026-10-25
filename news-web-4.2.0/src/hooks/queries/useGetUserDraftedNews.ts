import { useQuery } from "@tanstack/react-query";
import { getUserDraftedNewsApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";
import { NewsApi } from "./useGetNews";

export interface UserDraftedNewsApiResponse extends Omit<ApiResponseType, "data"> {
  data: {
    news: {
      total: number;
      data: NewsApi[];
    };
  };
}

export interface UseGetUserDraftedNewsParams {
  author_id?: number;
  enabled?: boolean;
}

export const useGetUserDraftedNews = (params: UseGetUserDraftedNewsParams) => {
  const { author_id, enabled = true } = params;

  return useQuery<UserDraftedNewsApiResponse>({
    queryKey: ["userDraftedNews", author_id],
    enabled: !!author_id && enabled,
    queryFn: async () => {
      try {
        const response = await getUserDraftedNewsApi({ author_id: author_id as number });
        if (!response) {
          throw new Error("Failed to fetch drafted news");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch drafted news");
        }
        return response as UserDraftedNewsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch drafted news";
        throw new Error(apiMessage);
      }
    },
  });
};
