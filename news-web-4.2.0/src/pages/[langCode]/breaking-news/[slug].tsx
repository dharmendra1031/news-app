import type { GetServerSideProps } from 'next'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import NewsDetails from '@/components/pagesComp/NewsDetails/NewsDetails'
import WithPageMode from '@/components/hoc/WithPageMode'
import Meta from '@/components/common/Meta'
import JsonLd from '@/components/schema/JsonLd'
import { getBreaingNewsApi } from '@/api/apiRoutes'
import { BreakingNewsApiResponse } from '@/hooks/queries/useGetBreakingNews'
import { fetchDefaultLocale } from '@/lib/defaultLocale'
import { withLang } from '@/lib/localizedUrl'
import { getServerLangCode } from '@/lib/getServerLangCode'
import { isValidLocaleSegment } from '@/lib/locale'
import { isStaticExport } from '@/lib/staticExport'

// NewsDetails is shared with /news, so the breaking-news mode guard lives here.
const BreakingNewsDetails = WithPageMode('breaking_news_mode')(NewsDetails)

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

  const breakingResponse = await queryClient.fetchQuery<BreakingNewsApiResponse>({
    queryKey: ['breaking-news', language_code, slug, 0, 20],
    queryFn: () => getBreaingNewsApi({ language_code, slug, offset: 0, limit: 20 }),
  })

  const breakingNews = breakingResponse?.data?.data?.[0]
  if (!breakingNews) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/breaking-news/${slug}`, language_code, defaultLocale)}/`

  const metadata: SeoData = {
    title: breakingNews?.meta_title || breakingNews?.title,
    description: breakingNews?.meta_description || process.env.NEXT_PUBLIC_DESCRIPTION || '',
    keywords: breakingNews?.meta_keyword || process.env.NEXT_PUBLIC_kEYWORDS || '',
    ogImage: breakingNews?.image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(breakingNews?.schema_markup),
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
      <BreakingNewsDetails breakingNews={true} />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
