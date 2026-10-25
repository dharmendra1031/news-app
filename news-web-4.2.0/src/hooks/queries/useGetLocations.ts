import { useQuery } from "@tanstack/react-query";
import { getLocationApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";
import { NewsLocationApi } from "./useGetNews";

export type LocationsApiResponse = ListApiResponseType<NewsLocationApi>;

export interface UseGetLocationsParams {
  limit?: number;
  enabled?: boolean;
}

export const useGetLocations = (params: UseGetLocationsParams = {}) => {
  const { limit = 10000, enabled = true } = params;

  return useQuery<LocationsApiResponse>({
    queryKey: ["locations", limit],
    enabled,
    queryFn: async () => {
      try {
        const response = await getLocationApi({ limit });
        if (!response) {
          throw new Error("Failed to fetch locations");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch locations");
        }
        return response as LocationsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch locations";
        throw new Error(apiMessage);
      }
    },
  });
};
