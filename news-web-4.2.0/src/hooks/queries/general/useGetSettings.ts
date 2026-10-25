import { useQuery } from "@tanstack/react-query";
import { getSettingsApi } from "@/api/apiRoutes";
import { ApiResponseType } from "@/types/GlobalTypes";

export interface DefaultLanguage {
  id: number;
  language: string;
  code: string;
  status: number;
  isRTL: number;
  image: string;
  display_name: string;
}
export interface WebSetting {
  web_name: string;
  light_primary_color: string;
  light_header_logo: string;
  light_footer_logo: string;
  light_placeholder_image: string;
  web_footer_description: string;
  google_adsense: string;
  android_app_link: string;
  ios_app_link: string;
  light_body_color: string;
  light_hover_color: string;
  light_secondary_color: string;
  light_text_primary_color: string;
  light_text_secondary_color: string;
  dark_body_color: string;
  dark_hover_color: string;
  dark_primary_color: string;
  dark_secondary_color: string;
  dark_text_primary_color: string;
  dark_text_secondary_color: string;
  dark_header_logo: string;
  dark_footer_logo: string;
  dark_placeholder_image: string;
  accept_cookie: string;
  favicon_icon: string;
}
export interface SocialMediaLink {
  id: number;
  image: string;
  link: string;
}
export interface SettingsData {
  system_timezone: string;
  auto_delete_expire_news_mode: string;
  category_mode: string;
  subcategory_mode: string;
  breaking_news_mode: string;
  live_streaming_mode: string;
  comments_mode: string;
  weather_mode: string;
  location_news_mode: string;
  nearest_location_measure: string;
  in_app_ads_mode: string;
  ads_type: string;
  google_rewarded_video_id: string;
  google_interstitial_id: string;
  google_banner_id: string;
  google_native_unit_id: string;
  unity_rewarded_video_id: string;
  unity_interstitial_id: string;
  unity_banner_id: string;
  android_game_id: string;
  ios_in_app_ads_mode: string;
  ios_ads_type: string;
  ios_google_rewarded_video_id: string;
  ios_google_interstitial_id: string;
  ios_google_banner_id: string;
  ios_google_native_unit_id: string;
  ios_unity_rewarded_video_id: string;
  ios_unity_interstitial_id: string;
  ios_unity_banner_id: string;
  ios_game_id: string;
  app_version: string;
  maintenance_mode: string;
  rss_feed_mode: string;
  mobile_login_mode: string;
  country_code: string;
  shareapp_text: string;
  appstore_app_id: string;
  views_auth_mode: string
  video_type_preference: string;
  force_update_app_mode: string;
  ios_app_version: string;
  android_app_version: string;
  google_app_open_unit_id: string;
  ios_google_app_open_unit_id: string;
  auth_short_video_views: string;
  podcast_mode: string;
  ad_after_page_clicks: string;
  news_buzz_mode: string;
  e_news_mode: string;
  default_language: DefaultLanguage;
  web_setting: WebSetting;
  social_media: SocialMediaLink[];
}

export interface SettingsApiResponse extends Omit<ApiResponseType, 'data'> {
  data: SettingsData;
}

export const useGetSettings = () => {
  return useQuery<SettingsApiResponse>({
    queryKey: ["settings"],
    queryFn: async () => {
      try {
        const response = await getSettingsApi();
        if (!response) {
          throw new Error("Failed to fetch settings");
        }
        if (response?.error) {
          throw new Error(response?.message || "Failed to fetch settings");
        }
        return response as SettingsApiResponse;
      } catch (error: any) {
        const apiMessage = error?.response?.data?.message || error?.message || "Failed to fetch settings";
        throw new Error(apiMessage);
      }
    },
  });
};