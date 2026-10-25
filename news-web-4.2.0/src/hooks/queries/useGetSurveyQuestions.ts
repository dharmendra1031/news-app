import { useQuery } from "@tanstack/react-query";
import { getSurveyQuestionsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export interface SurveyOptionApi {
  id: number;
  question_id: number;
  options: string;
  /** Only returned by the result endpoint, as a stringified number. */
  percentage?: string;
}

export interface SurveyQuestionApi {
  id: number;
  language_id: number;
  question: string;
  survey_options: SurveyOptionApi[];
}

export type SurveyQuestionsApiResponse = ListApiResponseType<SurveyQuestionApi>;

export interface UseGetSurveyQuestionsParams {
  language_code: string;
  enabled?: boolean;
}

export const useGetSurveyQuestions = ({ language_code, enabled = true }: UseGetSurveyQuestionsParams) => {
  return useQuery<SurveyQuestionsApiResponse>({
    queryKey: ["survey-questions", language_code],
    enabled: !!language_code && enabled,
    // Surveys drop out once answered, so never serve a cached list — the global
    // default `refetchOnMount: false` would otherwise skip the fetch on mount
    // even with `staleTime: 0`.
    gcTime: 0,
    staleTime: 0,
    refetchOnMount: "always",
    queryFn: async () => {
      try {
        const response = await getSurveyQuestionsApi({ language_code });
        if (!response) {
          throw new Error("Failed to fetch survey questions");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch survey questions");
        }
        return response as SurveyQuestionsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch survey questions";
        throw new Error(apiMessage);
      }
    },
  });
};
