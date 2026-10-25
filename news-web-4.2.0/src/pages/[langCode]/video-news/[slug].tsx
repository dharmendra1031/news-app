import type { GetServerSideProps } from 'next'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import VideoDetails from '@/components/pagesComp/video-news/VideoDetails'
import Meta from '@/components/common/Meta'
import JsonLd from '@/components/schema/JsonLd'
import { getVideoNewsApi, getNewsApi } from '@/api/apiRoutes'
import { VideoNewsApiResponse } from '@/hooks/queries/useGetVideoNews'
import { fetchDefaultLocale } from '@/lib/defaultLocale'
import { withLang } from '@/lib/localizedUrl'
import { getServerLangCode } from '@/lib/getServerLangCode'
import { isValidLocaleSegment } from '@/lib/locale'
import { isStaticExport } from '@/lib/staticExport'

const parseSchemaMarkup = (markup?: string | null): Record<string, unknown> | null => {
  if (!markup) return null
  try { return JSON.parse(markup) } catch { return null }
}

interface SeoData {
  title?: string
  description?: string
  keywords?: string
  ogImage?: string | null
  pathName?: string | null
  schema?: Record<string, unknown> | null
}

interface IndexProps {
  metadata?: SeoData
}

const serverSideProps: GetServerSideProps = async (context) => {
  if (!isValidLocaleSegment(context.params?.langCode)) {
    return { notFound: true }
  }

  const slugParam = context.params?.slug
  const slug = Array.isArray(slugParam) ? slugParam[0] : slugParam

  if (!slug) {
    return { notFound: true }
  }

  const language_code = getServerLangCode(context)
  const queryClient = new QueryClient()

  const videoResponse = await queryClient.fetchQuery<VideoNewsApiResponse>({
    queryKey: ['video-news', language_code, 0, 20, slug, null, null],
    queryFn: () => getVideoNewsApi({ language_code, slug, offset: 0, limit: 20 }),
  })

  const video = videoResponse?.data?.data?.[0]
  if (!video) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  // Prefetch RelatedNewsSection's own query so it's present in the initial
  // HTML too — matches the queryKey it builds client-side (page 0,
  // dataPerPage 6, no lat/long on first render).
  if (video?.category_slug) {
    await queryClient.prefetchQuery({
      queryKey: ['news', language_code, 0, 6, { category_slug: video.category_slug, merge_tag: 1 }],
      queryFn: () => getNewsApi({ language_code, category_slug: video.category_slug ?? undefined, offset: 0, limit: 6, merge_tag: 1 }),
    })
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/video-news/${slug}`, language_code, defaultLocale)}/`

  const metadata: SeoData = {
    title: video?.meta_title || video?.title,
    description: video?.meta_description || process.env.NEXT_PUBLIC_DESCRIPTION || '',
    keywords: video?.meta_keyword || process.env.NEXT_PUBLIC_kEYWORDS || '',
    ogImage: video?.image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(video?.schema_markup),
  }

  return {
    props: {
      metadata,
      dehydratedState: dehydrate(queryClient),
    },
  }
}

const Index = ({ metadata }: IndexProps) => {
  return (
    <>
      <Meta
        title={metadata?.title}
        description={metadata?.description}
        keywords={metadata?.keywords}
        ogImage={metadata?.ogImage}
        pathName={metadata?.pathName}
      />
      <VideoDetails />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
