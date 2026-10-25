import { webSettingSelector } from '@/redux/reducers/settingsSlice'
import Head from 'next/head'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import { isStaticExport } from '@/lib/staticExport'

interface MetaProps {
  title?: string | null;
  description?: string | null;
  keywords?: string | null;
  ogImage?: string | null;
  pathName?: string | null;
}

const Meta = ({ title, description, keywords, ogImage, pathName }: MetaProps) => {

  const router = useRouter();

  const webSetting = useSelector(webSettingSelector);
  const favicon = webSetting?.favicon_icon;

  const metaTitle = title || process.env.NEXT_PUBLIC_TITLE;
  const metaDescription = description || process.env.NEXT_PUBLIC_DESCRIPTION;
  const metaKeywords = keywords || process.env.NEXT_PUBLIC_kEYWORDS;
  const siteName = process.env.NEXT_PUBLIC_WEB_NAME || 'News';

  // pathName is already query-sanitized by fetchMetaInfo(); router.asPath is a
  // last-resort fallback, so strip any leftover query string from it too.
  const canonicalUrl = pathName || `${process.env.NEXT_PUBLIC_WEB_URL}${router.asPath.split('?')[0]}`;

  return (
    <>
      <Head>
        {/* title */}
        <title>{metaTitle}</title>

        {/*<!-- Google / Search Engine Tags -->*/}
        <meta name='description' content={metaDescription} />
        <meta name='keywords' content={metaKeywords} />
        <meta name='author' content={siteName} />

        {/*<!-- Facebook Meta Tags -->*/}
        <meta property='og:title' content={metaTitle} />
        <meta property='og:description' content={metaDescription} />
        {
          ogImage && (
            <>
              <meta property='og:image' content={ogImage} />
              <meta property='og:image:type' content='image/jpeg' />
              <meta property="og:image:width" content="1200" />
              <meta property="og:image:height" content="630" />
            </>
          )
        }
        <meta property='og:url' content={canonicalUrl} />
        <meta property='og:type' content='website' />
        <meta property='og:locale' content='en_US' />
        <meta property='og:site_name' content={siteName} />

        {/*<!-- Twitter Meta Tags -->*/}
        <meta name='twitter:title' content={metaTitle} />
        <meta name='twitter:description' content={metaDescription} />
        {ogImage && <meta name='twitter:image' content={ogImage} />}
        <meta name='twitter:card' content='summary_large_image' />
        <meta name='twitter:url' content={canonicalUrl} />

        {/* robot and canonical */}
        <link rel='canonical' href={canonicalUrl} />
        <meta name='viewport' content='width=device-width, initial-scale=1.0' />
        <meta name='robots' content='index, follow,max-snippet:-1,max-video-preview:-1,max-image-preview:large' />

        {
          isStaticExport &&
          <link rel="icon" href={favicon ? favicon : '/favicon.png'} sizes="32x32" type="image/png" />
        }
      </Head>
      <h1 className="sr-only hidden">{title}</h1>
    </>
  )
}

export default Meta
