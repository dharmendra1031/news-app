// Shared by next.config.ts and ImagePreview — keep relative imports only (no "@/" alias)

// API paths allowed through the Next.js image optimizer
export const IMAGE_PATHNAMES = ["/storage/", "/public/storage/", "/images/"];

// Static export (NEXT_PUBLIC_SEO="false") has no image optimizer server
const isStaticExport = process.env.NEXT_PUBLIC_SEO === "false";

const apiHostname = (() => {
    try {
        return process.env.NEXT_PUBLIC_API_URL ? new URL(process.env.NEXT_PUBLIC_API_URL).hostname : null;
    } catch {
        return null;
    }
})();

// True when next/image can optimize src; otherwise it must be rendered unoptimized
// (unknown hosts would throw "hostname is not configured")
export const canOptimizeImage = (src: string): boolean => {
    if (isStaticExport) return false;
    if (src.startsWith("data:") || src.startsWith("blob:")) return false;
    if (src.startsWith("/")) return true;
    try {
        const url = new URL(src);
        return url.hostname === apiHostname && IMAGE_PATHNAMES.some((p) => url.pathname.startsWith(p));
    } catch {
        return false;
    }
};
