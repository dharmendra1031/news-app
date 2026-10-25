// Must match next.config.ts: NEXT_PUBLIC_SEO="false" builds a static export
// (`out/`), where Next refuses any page that exports getServerSideProps —
// even one that would return early — so pages drop the export entirely.
export const isStaticExport = process.env.NEXT_PUBLIC_SEO === "false";
