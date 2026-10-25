import fs from "node:fs";
import path from "node:path";
import type { NextConfig } from "next";
import { IMAGE_PATHNAMES } from "./src/utils/imageConfig";

// NEXT_PUBLIC_SEO="false" -> static export into `out/` (no Node server).
// Anything else          -> standalone server build in `.next/standalone`.
const isStaticExport = process.env.NEXT_PUBLIC_SEO === "false";

const LANG_PAGES_DIR = path.join(process.cwd(), "src", "pages", "[langCode]");

/** Route segments (after `[langCode]`) of every page under src/pages/[langCode]. */
const collectLangRoutes = (dir = LANG_PAGES_DIR, segments: string[] = []): string[][] =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    if (entry.isDirectory()) return collectLangRoutes(path.join(dir, entry.name), [...segments, entry.name]);
    if (!entry.name.endsWith(".tsx")) return [];
    const name = entry.name.replace(/\.tsx$/, "");
    return [name === "index" ? segments : [...segments, name]];
  });

// First match wins, so a static segment must beat a dynamic one at the same
// position (categories-news/sub-category/x before categories-news/[slug]/x).
const compareRoutes = (a: string[], b: string[]) => {
  const isDynamic = (segment: string) => Number(segment.startsWith("["));
  for (let i = 0; i < Math.min(a.length, b.length); i++) {
    const diff = isDynamic(a[i]) - isDynamic(b[i]);
    if (diff) return diff;
  }
  return b.length - a.length;
};

const fetchDefaultLanguage = async (): Promise<string> => {
  const api = process.env.NEXT_PUBLIC_API_URL?.replace(/\/+$/, "");
  const endpoint = process.env.NEXT_PUBLIC_END_POINT?.replace(/^\/+|\/+$/g, "");
  const response = await fetch(`${api}/${endpoint}/get_settings`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: "{}",
  });
  const code = (await response.json())?.data?.default_language?.code;
  if (!code) throw new Error("Default language code missing from get_settings response");
  return code;
};

/**
 * Static export has no src/proxy.ts to serve the default language at bare
 * URLs ("/news/foo" instead of "/en/news/foo"). The client router applies
 * these rewrites itself when resolving links and on hydration, so bare URLs
 * map onto the `[langCode]` pages while the address bar stays bare. Apache
 * does the same for full page loads (public/.htaccess).
 */
const defaultLanguageRewrites = async () => {
  const defaultLang = await fetchDefaultLanguage();
  return collectLangRoutes()
    .sort(compareRoutes)
    .map((segments) => {
      const source = `/${segments.map((s) => (s.startsWith("[") ? `:${s.slice(1, -1)}` : s)).join("/")}`;
      return { source, destination: source === "/" ? `/${defaultLang}` : `/${defaultLang}${source}` };
    });
};

type RemotePattern = Exclude<NonNullable<NonNullable<NextConfig["images"]>["remotePatterns"]>[number], URL>;

// Only the API host's upload paths go through the image optimizer
const remotePatterns: RemotePattern[] = (() => {
  const raw = process.env.NEXT_PUBLIC_API_URL;
  if (!raw) return [];
  try {
    const apiUrl = new URL(raw);
    return IMAGE_PATHNAMES.map((prefix) => ({
      protocol: apiUrl.protocol.replace(":", "") as "http" | "https",
      hostname: apiUrl.hostname,
      port: apiUrl.port,
      pathname: `${prefix}**`,
    }));
  } catch {
    throw new Error(`NEXT_PUBLIC_API_URL is not a valid URL: ${raw}`);
  }
})();

const nextConfig: NextConfig = {
  output: isStaticExport ? "export" : "standalone",
  // Static export can't run src/proxy.ts, but if it's still detected the
  // client router believes middleware exists, fetches /_next/data/*.json
  // (never exported) and hard-reloads on every link click. Every page is
  // .tsx, so dropping "ts" hides proxy.ts from detection in export only.
  ...(isStaticExport && {
    pageExtensions: ["tsx"],
    rewrites: async () => ({ beforeFiles: await defaultLanguageRewrites(), afterFiles: [], fallback: [] }),
  }),
  images: isStaticExport
    ? // Static export has no optimizer server
      { unoptimized: true }
    : {
        formats: ["image/avif", "image/webp"],
        remotePatterns,
        // Uploaded files get unique names, so optimized variants can be cached long (default is 4h)
        minimumCacheTTL: 2592000, // 30 days
      },
  // Static export has no server to attach headers; public/.htaccess does it there.
  // Public images are served with max-age=0 by default, which Lighthouse flags.
  ...(!isStaticExport && {
    headers: async () => [
      {
        source: "/:path*.(png|jpg|jpeg|gif|webp|avif|svg|ico|woff2)",
        headers: [{ key: "Cache-Control", value: "public, max-age=2592000, stale-while-revalidate=86400" }],
      },
    ],
  }),
  // Next's built-in polyfill-module (String.trimStart, Array.flat, Object.fromEntries, ...)
  // ships in every page bundle but the supported browsers (Chrome 111+, Safari 16.4+) have all of it.
  turbopack: {
    resolveAlias: {
      "../build/polyfills/polyfill-module": "./src/utils/emptyPolyfill.js",
    },
  },
  trailingSlash: false,
  reactCompiler: true,
  reactStrictMode: true,
};

export default nextConfig;
