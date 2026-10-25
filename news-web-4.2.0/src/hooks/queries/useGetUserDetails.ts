import { useQuery } from "@tanstack/react-query";
import { getUserByIdApi } from "@/api/apiRoutes";
import { ApiResponseType, userDetailsType } from "@/types/GlobalTypes";

export interface UserDetailsApiResponse extends Omit<ApiResponseType, 'data'> {
  data: userDetailsType;
}

export interface UseGetUserDetailsParams {
  enabled?: boolean;
}

export const useGetUserDetails = (params: UseGetUserDetailsParams = {}) => {
  const { enabled = true } = params;

  return useQuery<UserDetailsApiResponse>({
    queryKey: ["userDetails"],
    enabled,
    queryFn: async () => {
      try {
        const response = await getUserByIdApi();
        if (!response) {
          throw new Error("Failed to fetch user details");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch user details");
        }
        return response as UserDetailsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch user details";
        throw new Error(apiMessage);
      }
    },
  });
};
