
import Document, { Html, Head, Main, NextScript, DocumentContext, DocumentInitialProps } from "next/document";
import { getCachedSettings } from "@/lib/settingsCache";
import { primaryFont } from "@/lib/fonts";
import { getAdsenseSrc } from "@/lib/adsense";

interface CustomDocumentProps extends DocumentInitialProps {
  favicon: string | null;
  adsenseSrc: string | null;
}

const isSeoMode = process?.env?.NEXT_PUBLIC_SEO === 'true';

const CustomDocument = ({ favicon, adsenseSrc }: CustomDocumentProps) => {
  return (
    // Font variable on <html> so body/portals have it from first paint, not after hydration
    <Html lang="en" dir="ltr" className={primaryFont.variable}>
      <Head>
        {/* PWA Manifest */}
        <link rel="manifest" href="/manifest.json" />
        {/* Favicon */}
        {
          isSeoMode &&
          <link rel="icon" href={favicon ? favicon : '/favicon.png'} sizes="32x32" type="image/png" />
        }

        {/* Google Tag Manager Script */}
        <script
          async
          src={`https://www.googletagmanager.com/gtag/js?id=${process.env.NEXT_PUBLIC_MEASUREMENT_ID}`}
        ></script>
        <script
          dangerouslySetInnerHTML={{
            __html: `
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${process.env.NEXT_PUBLIC_MEASUREMENT_ID}');
    `,
          }}
        />
        {/* Google Tag Manager Script Ends*/}

        {/* Google AdSense — SEO mode only. Rendered into the server HTML
            <head> of every page (what AdSense site verification looks for).
            In static export (SEO false) this would be frozen at build time,
            so Layout loads it client-side from live settings instead. */}
        {
          isSeoMode && adsenseSrc &&
          <script async src={adsenseSrc} crossOrigin="anonymous"></script>
        }
      </Head>
      <body className="antialiased pointer-events-auto!">
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}

CustomDocument.getInitialProps = async (ctx: DocumentContext): Promise<CustomDocumentProps> => {
  const initialProps = await Document.getInitialProps(ctx)

  // Favicon and AdSense are SEO-mode only. In static export this would run
  // at build time and its values would be stale anyway — skip the API call.
  if (!isSeoMode) {
    return { ...initialProps, favicon: null, adsenseSrc: null }
  }

  try {
    // Same cache `_app` already warmed for this request — no extra API call.
    const response = await getCachedSettings();
    const webSetting = response?.data?.web_setting;
    return {
      ...initialProps,
      favicon: webSetting?.favicon_icon ?? null,
      adsenseSrc: getAdsenseSrc(webSetting?.google_adsense),
    }
  } catch (error) {
    console.error('Error fetching settings in _document:', error)
    return {
      ...initialProps,
      favicon: null,
      adsenseSrc: null,
    }
  }
}

export default CustomDocument
