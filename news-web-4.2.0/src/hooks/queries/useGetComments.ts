import { useQuery } from "@tanstack/react-query";
import { getCommentsByNewsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface CommentUserApi {
  id: number;
  name: string;
  mobile?: string | null;
  profile?: string | null;
}

export interface CommentApi {
  id: number;
  news_id: number;
  user_id: number;
  parent_id: number;
  message: string;
  like: number;
  dislike: number;
  total_like: number;
  total_dislike: number;
  created_at: string | null;
  updated_at: string | null;
  user: CommentUserApi | null;
  reply: CommentApi[];
}

export type CommentsApiResponse = ListApiResponseType<CommentApi>;

export interface UseGetCommentsParams {
  news_id: number;
  offset?: number;
  limit?: number;
  enabled?: boolean;
}

export const useGetComments = (params: UseGetCommentsParams) => {
  const { news_id, offset = 0, limit = 20, enabled = true } = params;

  return useQuery<CommentsApiResponse>({
    queryKey: ["comments", news_id, offset, limit],
    enabled: !!news_id && enabled,
    queryFn: async () => {
      try {
        const response = await getCommentsByNewsApi({ news_id, offset, limit });
        if (!response) {
          throw new Error("Failed to fetch comments");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch comments");
        }
        return response as CommentsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch comments";
        throw new Error(apiMessage);
      }
    },
  });
};
