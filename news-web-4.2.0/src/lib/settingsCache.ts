import { getSettingsApi } from "@/api/apiRoutes";
import type { SettingsApiResponse } from "@/hooks/queries/general/useGetSettings";

// Settings are fetched once per server process (not per page/request) via
// `_app`'s getInitialProps — this short TTL just absorbs bursts of
// concurrent SSR requests hitting the same warm instance, it isn't meant to
// replace the client-side react-query cache.
const CACHE_TTL_MS = 60 * 1000;

let cached: { data: SettingsApiResponse; expiresAt: number } | null = null;
let pending: Promise<SettingsApiResponse> | null = null;

export async function getCachedSettings(): Promise<SettingsApiResponse> {
  const now = Date.now();
  if (cached && cached.expiresAt > now) {
    return cached.data;
  }
  if (pending) {
    return pending;
  }

  pending = (async () => {
    const data = (await getSettingsApi()) as SettingsApiResponse;
    cached = { data, expiresAt: Date.now() + CACHE_TTL_MS };
    pending = null;
    return data;
  })();

  return pending;
}
