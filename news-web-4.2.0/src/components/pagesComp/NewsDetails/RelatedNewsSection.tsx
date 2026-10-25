'use client'
import { useEffect, useRef, useState } from 'react'
import SectionTitle from '@/components/common/SectionTitle'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import CommonCardSkeleton from '@/components/skeletons/CommonCardSkeleton'
import { useGetNews } from '@/hooks/queries/useGetNews'
import { useGetVideoNews, toVideoNewsItem } from '@/hooks/queries/useGetVideoNews'
import { FeatureSectionItem } from '@/hooks/queries/useGetFeatureSections'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { useLatLong } from '@/hooks/useLatLong'

interface RelatedNewsSectionProps {
    newsSlug?: string
    categorySlug?: string
    categoryId?: number
    /** On the video-details page, related items come from the videos feed, not news. */
    videoPage?: boolean
}

const dataPerPage = 6

const RelatedNewsSection = ({ newsSlug, categorySlug, categoryId, videoPage = false }: RelatedNewsSectionProps) => {

    const { t } = useTranslation()
    const langCode = useLangCode()
    const { latitude, longitude } = useLatLong()

    const [page, setPage] = useState(0)
    const [relatedNews, setRelatedNews] = useState<FeatureSectionItem[]>([])
    const [totalData, setTotalData] = useState(0)

    const { data: newsQueryData, isLoading: isNewsLoading, isFetching: isNewsFetching } = useGetNews({
        language_code: langCode,
        category_slug: categorySlug,
        offset: page * dataPerPage,
        limit: dataPerPage,
        latitude,
        longitude,
        merge_tag: 1,
        enabled: !!categorySlug && !videoPage,
    })

    const { data: videoQueryData, isLoading: isVideoLoading, isFetching: isVideoFetching } = useGetVideoNews({
        language_code: langCode ?? '',
        category_slug: categorySlug,
        category_id: categoryId,
        offset: page * dataPerPage,
        limit: dataPerPage,
        enabled: !!categorySlug && videoPage,
    })

    const queryData = videoPage ? videoQueryData : newsQueryData
    const isLoading = videoPage ? isVideoLoading : isNewsLoading
    const isFetching = videoPage ? isVideoFetching : isNewsFetching

    // Reset during render (not in an effect) so the previous article's related
    // news never gets a frame to paint after navigating to another article.
    const [prevKey, setPrevKey] = useState(`${categorySlug}|${newsSlug}|${langCode}`)
    const currentKey = `${categorySlug}|${newsSlug}|${langCode}`
    if (currentKey !== prevKey) {
        setPrevKey(currentKey)
        setPage(0)
        setRelatedNews([])
        setTotalData(0)
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof queryData | symbol>(() => Symbol('initial'))
    if (queryData !== prevQueryData) {
        setPrevQueryData(queryData)
        if (queryData) {
            const items: FeatureSectionItem[] = videoPage
                ? (videoQueryData?.data?.data ?? []).map(toVideoNewsItem)
                : (newsQueryData?.data?.data ?? [])
            setTotalData(queryData?.data?.total ?? 0)
            setRelatedNews((prev) => (page > 0 ? [...prev, ...items] : items))
        }
    }

    const hasMore = (page + 1) * dataPerPage < totalData

    const sentinelRef = useRef<HTMLDivElement | null>(null)

    useEffect(() => {
        const sentinel = sentinelRef.current
        if (!sentinel || !hasMore || isFetching) return

        // One-shot: disconnect before advancing so a second intersection can't
        // land before `isFetching` flips and skip a page. The effect re-arms it
        // once that fetch settles.
        const observer = new IntersectionObserver(
            (entries) => {
                if (!entries[0]?.isIntersecting) return
                observer.disconnect()
                setPage((prev) => prev + 1)
            },
            { rootMargin: '200px' }
        )

        observer.observe(sentinel)
        return () => observer.disconnect()
    }, [hasMore, isFetching])

    // The article being read is part of its own category feed — drop it.
    const visibleNews = relatedNews.filter((item) => item?.slug !== newsSlug)

    if (!isLoading && !visibleNews.length) return null

    return (
        <section className='relatedNewsSect container commonMT'>
            <SectionTitle title={t('related-news')} showViewMore={false} />

            <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 gap-y-10'>
                {visibleNews.map((news) => (
                    <VerticalCard key={news?.id} news={news} style='style_2' />
                ))}

                {
                    isFetching &&
                    [...Array(dataPerPage)].map((_, index) => (
                        <CommonCardSkeleton key={`skeleton-${index}`} />
                    ))
                }
            </div>

            {hasMore && <div ref={sentinelRef} className='h-px w-full' />}
        </section>
    )
}

export default RelatedNewsSection
