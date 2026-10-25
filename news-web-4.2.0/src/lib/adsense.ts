const ADSENSE_SCRIPT_URL = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js";

/**
 * Normalizes the admin panel's `web_setting.google_adsense` value into the
 * AdSense loader URL. Admins paste it in different shapes, so all of these
 * are accepted:
 *   - the full snippet:  <script async src="https://...adsbygoogle.js?client=ca-pub-xxx" ...></script>
 *   - just the URL:      https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-xxx
 *   - just the pub ID:   ca-pub-xxx
 *
 * Only Google's own AdSense host is allowed through, so a bad value in the
 * settings can't inject an arbitrary script into every page.
 */
export const getAdsenseSrc = (value?: string | null): string | null => {
  const raw = value?.trim();
  if (!raw) return null;

  if (/^ca-pub-\d+$/.test(raw)) {
    return `${ADSENSE_SCRIPT_URL}?client=${raw}`;
  }

  const src = raw.startsWith("<")
    ? raw.match(/\ssrc\s*=\s*["']([^"']+)["']/i)?.[1]
    : raw;
  if (!src) return null;

  try {
    const url = new URL(src.replace(/&amp;/g, "&"));
    const isGoogleHost = url.hostname === "googlesyndication.com" || url.hostname.endsWith(".googlesyndication.com");
    return url.protocol === "https:" && isGoogleHost ? url.toString() : null;
  } catch {
    return null;
  }
};
