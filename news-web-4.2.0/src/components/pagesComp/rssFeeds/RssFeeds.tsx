'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import EmptyStatus from '@/components/common/EmptyStatus'
import AdSpace from '@/components/common/AdSpace'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { useTranslation } from '@/hooks/useTranslation'
import { useDefaultLangCode, useLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { useGetRssFeeds, RssFeedItemApi } from '@/hooks/queries/useGetRssFeeds';
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import FeedCardSkeleton from '@/components/skeletons/rssFeeds/FeedCardSkeleton';
import FeedCard from './FeedCard';
import FeedsFilter, { RssFeedSelectedFilters } from './FeedsFilter';
import { usePageMode } from '@/hooks/usePageMode';
import WithPageMode from '@/components/hoc/WithPageMode'

const RssFeeds = () => {

    const { t } = useTranslation();
    const router = useRouter()

    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const rssFeedMode = usePageMode('rss_feed_mode');

    const dataPerPage = 20;

    const [data, setData] = useState<RssFeedItemApi[]>([])
    const [loadMore, setLoadMore] = useState(false)
    const [offset, setOffset] = useState(1)
    const [totalData, setTotalData] = useState(0)

    const [selectedFilters, setSelectedFilters] = useState<RssFeedSelectedFilters>({
        cateIds: [],
        subCateIds: [],
        feedsIds: [],
    });

    // Settings load after mount, so only redirect once we actually know the mode.
    useEffect(() => {
        if (rssFeedMode !== undefined && !rssFeedMode) {
            router.replace(withLang('/', langCode, defaultLangCode))
        }
    }, [rssFeedMode, langCode, defaultLangCode, router])

    const { data: rssFeedsQueryData, isLoading, isFetching, isError, error } = useGetRssFeeds({
        language_code: langCode,
        per_page: dataPerPage,
        page: offset,
        source_ids: selectedFilters.feedsIds?.length > 0 ? selectedFilters.feedsIds.join(',') : undefined,
        category_ids: selectedFilters.cateIds?.length > 0 ? selectedFilters.cateIds.join(',') : undefined,
        subcategory_ids: selectedFilters.subCateIds?.length > 0 ? selectedFilters.subCateIds.join(',') : undefined,
    });

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'news_page',
    });

    const adSpacesData = adSpacesQueryData?.data ?? []

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof rssFeedsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && rssFeedsQueryData !== prevQueryData) {
        setPrevQueryData(rssFeedsQueryData)
        if (rssFeedsQueryData) {
            const items = rssFeedsQueryData?.data?.data ?? []
            setTotalData(rssFeedsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setData((prev) => [...prev, ...items])
            } else {
                setData(items)
            }
        }
    }

    if (isError && error) {
        console.log('rssFeeds err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <Breadcrumb secondElement={t('rssFeed')} />
            <div className='mt-8 container flex flex-col gap-6'>
                {/* ad spaces */}
                {
                    adSpacesData?.map((ad) => (
                        ad.placement === 'top' &&
                        <div key={ad?.id}>
                            <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                        </div>
                    ))
                }
                <section>
                    <FeedsFilter
                        selectedFilters={selectedFilters}
                        setSelectedFilters={setSelectedFilters}
                        setOffset={setOffset}
                        setLoadMore={setLoadMore}
                    />

                    <div className='mt-6'>
                        <div className={`grid gap-6 ${data && data?.length > 0 ? 'lg:grid-cols-2' : 'grid-cols-1'}`}>
                            {
                                isLoading && !loadMore ? [...Array(10)].map((_, index) => (
                                    <div key={index}>
                                        <FeedCardSkeleton />
                                    </div>
                                ))
                                    :
                                    data && data?.length > 0 ?
                                        data?.map((item) => (
                                            <div key={item?.id}><FeedCard data={item} selectedCate={selectedFilters.cateIds?.length > 0} /></div>
                                        ))
                                        :
                                        <div>
                                            <EmptyStatus />
                                        </div>


                            }
                        </div>
                        {
                            !isLoading &&
                            <div className='my-12'>
                                {totalData > dataPerPage && totalData !== data?.length ? (
                                    <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                                ) : null}
                            </div>
                        }
                    </div>
                </section>
                {/* ad spaces */}
                {
                    adSpacesData?.map((ad) => (
                        ad.placement === 'bottom' &&
                        <div key={ad?.id} className='mt-6'>
                            <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                        </div>
                    ))
                }
            </div>
        </Layout>
    )
}

export default WithPageMode('rss_feed_mode')(RssFeeds)
