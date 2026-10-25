'use client'
import { useState } from 'react'
import { useRouter } from 'next/router'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import EmptyStatus from '@/components/common/EmptyStatus'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import CommonCardSkeleton from '@/components/skeletons/CommonCardSkeleton'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import HorizontalCard from '@/components/common/newsCard/HorizontalCard'
import AuthorCardSkeleton from '@/components/skeletons/AuthorCardSkeleton'
import AuthorCard, { AuthorViewType } from './AuthorCard'
import { useGetAuthorDetails } from '@/hooks/queries/useGetAuthorDetails'
import { NewsApi } from '@/hooks/queries/useGetNews'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'

const AuthorDetails = () => {
    const { t } = useTranslation()
    const router = useRouter()
    const langCode = useLangCode()
    const slug = typeof router.query.slug === 'string' ? router.query.slug : undefined

    const [viewType, setViewType] = useState<AuthorViewType>('grid')
    const [loadMore, setLoadMore] = useState(false)
    const [page, setPage] = useState(1)
    const [newsData, setNewsData] = useState<NewsApi[]>([])

    // Reset paging when navigating to a different author — done at render
    // time (not in an effect), same idiom this project's other listing
    // pages use.
    const [syncedSlug, setSyncedSlug] = useState<string | undefined>(undefined)
    if (slug && slug !== syncedSlug) {
        setSyncedSlug(slug)
        setPage(1)
        setLoadMore(false)
        setNewsData([])
    }

    const { data: authorQueryData, isLoading, isFetching } = useGetAuthorDetails({
        user_slug: slug || '',
        language_code: langCode,
        page,
        enabled: !!slug,
    })

    const [prevQueryData, setPrevQueryData] = useState<typeof authorQueryData | symbol>(() => Symbol('initial'))
    if (authorQueryData !== prevQueryData) {
        setPrevQueryData(authorQueryData)
        if (authorQueryData) {
            const items = authorQueryData?.data?.news?.data ?? []
            if (loadMore) {
                setNewsData((prev) => [...prev, ...items])
            } else {
                setNewsData(items)
            }
        }
    }

    const authorDetails = authorQueryData?.data?.user
    const pagination = authorQueryData?.data?.news
    const hasMorePages = !!pagination && (!!pagination.next_page_url || pagination.current_page < pagination.last_page)

    const handleLoadMore = () => {
        setLoadMore(true)
        setPage((prev) => prev + 1)
    }

    const gridClass = viewType === 'grid' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1 md:grid-cols-2'

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('author')} />

                <section className='commonMT pb-8 lg:pb-16'>
                    <div className='container'>
                        {
                            isLoading ? (
                                <div>
                                    <AuthorCardSkeleton />
                                    <div className={`mt-6 grid gap-6 ${gridClass}`}>
                                        {[...Array(viewType === 'grid' ? 6 : 4)].map((_, index) => (
                                            <div key={index}><CommonCardSkeleton /></div>
                                        ))}
                                    </div>
                                </div>
                            ) : authorDetails ? (
                                <div>
                                    <AuthorCard authorDetails={authorDetails} viewType={viewType} setViewType={setViewType} />

                                    {
                                        newsData.length > 0 ? (
                                            <div className={`mt-6 grid gap-6 ${gridClass}`}>
                                                {
                                                    viewType === 'grid'
                                                        ? newsData.map((item) => <div key={item.id} className='customBgWhite p-4 rounded-2xl [&_img]:rounded-2xl'><VerticalCard news={item} style='style_4' /></div>)
                                                        : newsData.map((item) => <div key={item.id} className='customBgWhite p-4 rounded-2xl [&_img]:rounded-2xl'><HorizontalCard news={item} style='style_4' /></div>)
                                                }
                                            </div>
                                        ) : (
                                            <div className='mt-6'><EmptyStatus /></div>
                                        )
                                    }

                                    {
                                        hasMorePages && (
                                            <div className='mt-8'>
                                                <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                                            </div>
                                        )
                                    }
                                </div>
                            ) : (
                                <EmptyStatus />
                            )
                        }
                    </div>
                </section>
            </>
        </Layout>
    )
}

export default AuthorDetails
