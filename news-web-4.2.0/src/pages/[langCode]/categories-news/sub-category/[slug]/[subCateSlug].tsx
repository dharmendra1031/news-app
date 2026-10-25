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

  const subCategoryParam = context.params?.slug
  const newsParam = context.params?.subCateSlug
  const subCategorySlug = Array.isArray(subCategoryParam) ? subCategoryParam[0] : subCategoryParam
  const slug = Array.isArray(newsParam) ? newsParam[0] : newsParam

  if (!slug || !subCategorySlug) {
    return { notFound: true }
  }

  const language_code = getServerLangCode(context)
  const queryClient = new QueryClient()

  const newsResponse = await queryClient.fetchQuery<NewsApiResponse>({
    queryKey: ['news', language_code, 0, 20, { slug }],
    queryFn: () => getNewsApi({ language_code, slug, offset: 0, limit: 20 }),
  })

  const news = newsResponse?.data?.data?.[0]
  if (!news) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/categories-news/sub-category/${subCategorySlug}/${slug}`, language_code, defaultLocale)}/`

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
