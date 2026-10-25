import { useQuery } from "@tanstack/react-query";
import { useSelector } from "react-redux";
import { getGeminiApiKeyApi } from "@/api/apiRoutes";
import { tokenSelector } from "@/redux/reducers/userSlice";

// The API returns `data.google_gemini_api_key` base64-encoded.
const decodeKey = (encoded?: string | null): string | null => {
  if (!encoded) return null;
  try {
    return atob(encoded);
  } catch (error) {
    console.error("Error decoding Gemini key:", error);
    return null;
  }
};

// The endpoint is auth-only, so the key is unavailable to logged-out visitors.
export const useGetGeminiApiKey = (): string | null => {
  const token = useSelector(tokenSelector);

  const { data } = useQuery<string | null>({
    queryKey: ["gemini-api-key", token],
    enabled: !!token,
    staleTime: Infinity,
    queryFn: async () => {
      const response = await getGeminiApiKeyApi();
      if (!response || response?.error) {
        throw new Error(response?.message || "Failed to fetch Gemini API key");
      }
      return decodeKey(response?.data?.google_gemini_api_key);
    },
  });

  return data ?? null;
};
