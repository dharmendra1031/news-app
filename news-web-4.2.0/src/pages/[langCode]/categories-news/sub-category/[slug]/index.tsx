import type { GetServerSideProps } from 'next'
import { useRouter } from 'next/router'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import SubCategoryNews from '@/components/pagesComp/SubCategoryNews'
import Meta from '@/components/common/Meta'
import { getNewsApi } from '@/api/apiRoutes'
import { fetchDefaultLocale } from '@/lib/defaultLocale'
import { withLang } from '@/lib/localizedUrl'
import { getServerLangCode } from '@/lib/getServerLangCode'
import { isValidLocaleSegment } from '@/lib/locale'
import { isStaticExport } from '@/lib/staticExport'

const DEFAULT_OFFSET = 0
const DEFAULT_LIMIT = 8

interface SeoData {
  pathName?: string | null
  slug?: string | null
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

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: {} }
  }

  const language_code = getServerLangCode(context)
  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/categories-news/sub-category/${slug}`, language_code, defaultLocale)}/`

  const queryClient = new QueryClient()

  const newsQueryParams = {
    language_code,
    subcategory_slug: slug,
    offset: DEFAULT_OFFSET,
    limit: DEFAULT_LIMIT,
  }

  // Prefetch news for warm SSR cache — there is no dedicated subcategory-meta
  // endpoint, so title/description fall back to the site defaults.
  await queryClient.prefetchQuery({
    queryKey: ['news', language_code, DEFAULT_OFFSET, DEFAULT_LIMIT, { subcategory_slug: slug }],
    queryFn: () => getNewsApi(newsQueryParams),
  })

  const metadata: SeoData = {
    pathName: currentURL,
    slug: slug
  }

  return {
    props: {
      metadata,
      dehydratedState: dehydrate(queryClient),
    },
  }
}

const Index = ({ metadata }: IndexProps) => {
  // Same route, different slug: Next reuses this instance, so key it to reset the
  // list's page/offset state instead of carrying the previous slug's items over.
  const slug = useRouter().query.slug

  const webName = process.env.NEXT_PUBLIC_WEB_NAME;

  return (
    <>
      <Meta title={`${webName} | Sub-Category${metadata?.slug ? ` | ${metadata.slug}` : ''}`} pathName={metadata?.pathName} />
      <SubCategoryNews key={String(slug)} />
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
