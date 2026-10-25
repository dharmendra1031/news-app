import { useQuery } from "@tanstack/react-query";
import { getAdSpacesApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";

export type AdSpacePage = "home_page" | "news_details" | "featured_section" | "news_page";

export interface AdSpaceApi {
  id: number;
  language_id: number;
  ad_featured_section_id: number;
  ad_image: string;
  web_ad_image: string;
  ad_url: string;
  status: number;
  page: AdSpacePage;
  platform: string;
  placement: string;
  ad_type: string;
  duration_days: number;
  start_date: string;
  end_date: string;
}

export interface AdSpacesApiResponse extends Omit<ApiResponseType, "data"> {
  data: AdSpaceApi[];
}

export interface UseGetAdSpacesParams {
  language_code: string;
  page: AdSpacePage;
  platform?: string;
}

export const useGetAdSpaces = (params: UseGetAdSpacesParams) => {
  const { language_code, page, platform = "web" } = params;

  return useQuery<AdSpacesApiResponse>({
    queryKey: ["ad-spaces", language_code, page, platform],
    enabled: !!language_code && !!page,
    queryFn: async () => {
      try {
        const response = await getAdSpacesApi({ language_code, page, platform });
        if (!response) {
          throw new Error("Failed to fetch ad spaces");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch ad spaces");
        }
        return response as AdSpacesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch ad spaces";
        throw new Error(apiMessage);
      }
    },
  });
};
