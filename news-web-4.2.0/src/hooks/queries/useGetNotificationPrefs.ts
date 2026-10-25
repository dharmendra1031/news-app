import { useQuery } from "@tanstack/react-query";
import { getNotificationPrefApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";

export type NotificationPrefKey = "news" | "podcasts" | "alerts" | "comments" | "announcements";

export interface NotificationPrefApi {
  id: number;
  key: NotificationPrefKey;
  enabled: number | boolean;
}

export interface NotificationPrefsApiResponse extends Omit<ApiResponseType, "data"> {
  data: NotificationPrefApi[];
}

export interface UseGetNotificationPrefsParams {
  enabled?: boolean;
}

export const useGetNotificationPrefs = (params: UseGetNotificationPrefsParams = {}) => {
  const { enabled = true } = params;

  return useQuery<NotificationPrefsApiResponse>({
    queryKey: ["notificationPref"],
    enabled,
    queryFn: async () => {
      try {
        const response = await getNotificationPrefApi();
        if (!response) {
          throw new Error("Failed to fetch notification preferences");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch notification preferences");
        }
        return response as NotificationPrefsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch notification preferences";
        throw new Error(apiMessage);
      }
    },
  });
};
