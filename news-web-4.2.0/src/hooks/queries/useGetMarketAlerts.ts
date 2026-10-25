import { useQuery } from "@tanstack/react-query";
import { getMarketAlertsApi } from "@/api/apiRoutes";
import { ListApiResponseType } from "@/types/GlobalTypes";

export type MarketAlertDirection = "up" | "down";

export interface MarketAlertApi {
  id: number;
  alert_type: string;
  name: string;
  symbol: string;
  exchange: string;
  ipo_price: string | null;
  current_price: string | null;
  currency: string | null;
  percent_change: string | null;
  direction: MarketAlertDirection | null;
  status: number;
  last_updated_at: string;
  created_at: string;
  updated_at: string;
}

export type MarketAlertsApiResponse = ListApiResponseType<MarketAlertApi>;

export interface UseGetMarketAlertsParams {
  offset?: number;
  limit?: number;
}

export const useGetMarketAlerts = (params: UseGetMarketAlertsParams = {}) => {
  const { offset = 0, limit = 20 } = params;

  return useQuery<MarketAlertsApiResponse>({
    queryKey: ["market-alerts", offset, limit],
    queryFn: async () => {
      try {
        const response = await getMarketAlertsApi({ offset, limit });
        if (!response) {
          throw new Error("Failed to fetch market alerts");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch market alerts");
        }
        return response as MarketAlertsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch market alerts";
        throw new Error(apiMessage);
      }
    },
  });
};
