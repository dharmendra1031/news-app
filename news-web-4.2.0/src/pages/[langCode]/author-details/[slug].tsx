import type { GetServerSideProps } from 'next'
import { QueryClient, dehydrate } from '@tanstack/react-query'
import AuthorDetails from '@/components/pagesComp/authorDetails/AuthorDetails'
import Meta from '@/components/common/Meta'
import { getAuthorDetailsApi } from '@/api/apiRoutes'
import { withLang } from '@/lib/localizedUrl'
import { fetchDefaultLocale } from '@/lib/defaultLocale'
import { getServerLangCode } from '@/lib/getServerLangCode'
import { isValidLocaleSegment } from '@/lib/locale'
import { webName } from '@/components/utils/helpers'
import { isStaticExport } from '@/lib/staticExport'

const DEFAULT_PAGE = 1

interface SeoData {
  title?: string
  pathName?: string | null
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
  const defaultLocale = await fetchDefaultLocale()
  const currentURL =
    process.env.NEXT_PUBLIC_WEB_URL +
    `${withLang(`/author-details/${slug}`, language_code, defaultLocale)}/`

  const queryClient = new QueryClient()

  const authorData = await queryClient.fetchQuery({
    queryKey: ['authorDetails', slug, language_code, DEFAULT_PAGE],
    queryFn: () => getAuthorDetailsApi({ user_slug: slug, language_code, page: DEFAULT_PAGE }),
  })

  if (!authorData || authorData?.error) {
    // Render the page so its empty state shows instead of the global 404.
    return { props: { dehydratedState: dehydrate(queryClient) } }
  }

  const authorName = authorData?.data?.user?.name

  const metadata: SeoData = {
    title: `${webName()} | ${authorName || ''}`,
    pathName: currentURL,
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
      <Meta title={metadata?.title} pathName={metadata?.pathName} />
      <AuthorDetails />
    </>
  )
}

export default Index

export const getServerSideProps = isStaticExport ? undefined : serverSideProps
