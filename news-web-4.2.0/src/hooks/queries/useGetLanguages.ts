import { useQuery } from "@tanstack/react-query";
import { getLanguagesApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";
import { DefaultLanguage } from "./general/useGetSettings";

export interface LanguagesApiResponse extends Omit<ApiResponseType, "data"> {
  data: {
    default_language: DefaultLanguage;
    data: DefaultLanguage[];
  };
}

export const useGetLanguages = () => {
  return useQuery<LanguagesApiResponse>({
    queryKey: ["languages"],
    queryFn: async () => {
      try {
        const response = await getLanguagesApi();
        if (!response) {
          throw new Error("Failed to fetch languages");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch languages");
        }
        return response as LanguagesApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch languages";
        throw new Error(apiMessage);
      }
    },
  });
};
