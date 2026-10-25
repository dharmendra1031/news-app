import type { GetServerSideProps } from 'next'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import NewsDetails from '@/components/pagesComp/NewsDetails/NewsDetails'
import Meta from '@/components/common/Meta'
import JsonLd from '@/components/schema/JsonLd'
import { getNewsApi } from '@/api/apiRoutes'
import { NewsApiResponse } from '@/hooks/queries/useGetNews'
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

  const newsResponse = await queryClient.fetchQuery<NewsApiResponse>({
    queryKey: ['news', language_code, 0, 20, { slug }],
    queryFn: () => getNewsApi({ language_code, slug, offset: 0, limit: 20 }),
  })

  const news = newsResponse?.data?.data?.[0]
  // No article: render the page anyway so NewsDetails shows its empty state
  // instead of the global 404.
  if (!news) {
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  // Prefetch RelatedNewsSection's own query so it's present in the initial
  // HTML too, not just the article body — matches the queryKey it builds
  // client-side (page 0, dataPerPage 6, no lat/long on first render).
  if (news?.category?.slug) {
    await queryClient.prefetchQuery({
      queryKey: ['news', language_code, 0, 6, { category_slug: news.category.slug, merge_tag: 1 }],
      queryFn: () => getNewsApi({ language_code, category_slug: news.category?.slug, offset: 0, limit: 6, merge_tag: 1 }),
    })
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/news/${slug}`, language_code, defaultLocale)}/`

  const metadata: SeoData = {
    title: news?.meta_title || news?.title,
    description: news?.meta_description || process.env.NEXT_PUBLIC_DESCRIPTION || '',
    keywords: news?.meta_keyword || process.env.NEXT_PUBLIC_kEYWORDS || '',
    ogImage: news?.image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(news?.schema_markup),
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
      <NewsDetails />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
