import type { GetServerSideProps } from 'next'
import { useRouter } from 'next/router'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import ViewAll from '@/components/pagesComp/ViewAll'
import Meta from '@/components/common/Meta'
import JsonLd from '@/components/schema/JsonLd'
import { getFeatureSectionsApi } from '@/api/apiRoutes'
import { featureSectionsQueryKey } from '@/hooks/queries/useGetFeatureSections'
import { fetchDefaultLocale } from '@/lib/defaultLocale'
import { withLang } from '@/lib/localizedUrl'
import { getServerLangCode } from '@/lib/getServerLangCode'
import { isValidLocaleSegment } from '@/lib/locale'
import { isStaticExport } from '@/lib/staticExport'


const parseSchemaMarkup = (markup?: string | null): Record<string, unknown> | null => {
  if (!markup) return null
  try { return JSON.parse(markup) } catch { return null }
}

const DEFAULT_OFFSET = 0
const DEFAULT_LIMIT = 6

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

  if (process?.env?.NEXT_PUBLIC_SEO !== 'true') {
    return { props: {} }
  }

  const language_code = getServerLangCode(context)
  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/view-all/${slug}`, language_code, defaultLocale)}/`

  const queryClient = new QueryClient()

  const queryParams = {
    language_code,
    offset: DEFAULT_OFFSET,
    limit: DEFAULT_LIMIT,
    slug,
  }

  // Prefetch the feature section for this slug (also used for SEO meta)
  const sectionData = await getFeatureSectionsApi(queryParams)

  await queryClient.prefetchQuery({
    queryKey: featureSectionsQueryKey(queryParams),
    queryFn: () => sectionData,
  })

  // SEO meta comes from the feature section's own meta fields
  const sectionMeta = sectionData?.data?.data?.[0]

  const metadata: SeoData = {
    title: sectionMeta?.meta_title || process.env.NEXT_PUBLIC_TITLE || '',
    description: sectionMeta?.meta_description || process.env.NEXT_PUBLIC_DESCRIPTION || '',
    keywords: sectionMeta?.meta_keyword || process.env.NEXT_PUBLIC_kEYWORDS || '',
    ogImage: sectionMeta?.og_image || null,
    pathName: currentURL,
    schema: parseSchemaMarkup(sectionMeta?.schema_markup ?? undefined),
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
  return (
    <>
      <Meta
        title={metadata?.title}
        description={metadata?.description}
        keywords={metadata?.keywords}
        ogImage={metadata?.ogImage}
        pathName={metadata?.pathName}
      />
      <ViewAll key={String(slug)} />
      {metadata?.schema && <JsonLd data={metadata.schema} />}
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
