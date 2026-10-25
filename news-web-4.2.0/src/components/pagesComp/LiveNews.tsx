'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import CommonCardSkeleton from '../skeletons/CommonCardSkeleton'
import LiveNewsCard from '../common/newsCard/LiveNewsCard'
import { useGetLiveNews, LiveNewsApi } from '@/hooks/queries/useGetLiveNews'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import { useTranslation } from '@/hooks/useTranslation'
import LoadMoreBtn from '../common/loadermoreBtn/LoadmoreBtn'
import EmptyStatus from '../common/EmptyStatus'
import AdSpace from '../common/AdSpace'
import { useDefaultLangCode, useLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { usePageMode } from '@/hooks/usePageMode'
import WithPageMode from '../hoc/WithPageMode'

const LiveNews = () => {

    const { t } = useTranslation();
    const router = useRouter()

    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()
    const liveStreamingMode = usePageMode('live_streaming_mode');

    const dataPerPage = 8;

    const [loadMore, setLoadMore] = useState(false)
    const [liveNewsData, setLiveNewsData] = useState<LiveNewsApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    // Settings load after mount, so only redirect once we actually know the mode.
    useEffect(() => {
        if (liveStreamingMode !== undefined && !liveStreamingMode) {
            router.replace(withLang('/', langCode, defaultLangCode))
        }
    }, [liveStreamingMode, langCode, defaultLangCode, router])

    const { data: liveNewsQueryData, isLoading, isFetching, isError, error } = useGetLiveNews({
        language_code: langCode,
        offset: offset * dataPerPage,
        limit: dataPerPage,
    });

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'news_page',
    });

    const adSpacesData = adSpacesQueryData?.data ?? []

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setLiveNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof liveNewsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && liveNewsQueryData !== prevQueryData) {
        setPrevQueryData(liveNewsQueryData)
        if (liveNewsQueryData) {
            const items = liveNewsQueryData?.data?.data ?? []
            setTotalData(liveNewsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setLiveNewsData((prev) => [...prev, ...items])
            } else {
                setLiveNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('liveNews err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('livenews')} />

                <div className='mt-8 container flex flex-col gap-6'>
                    {/* ad spaces */}
                    {
                        adSpacesData?.map((ad) => (
                            ad.placement === 'top' &&
                            <AdSpace key={ad?.id} ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                        ))
                    }

                    <section className='allBreakingNews'>
                        {
                            isLoading && !loadMore ? <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 gap-y-10">
                                {[...Array(dataPerPage)].map((_, index) => (
                                    <div key={index}>
                                        <CommonCardSkeleton />
                                    </div>
                                ))}
                            </div>
                                :
                                liveNewsData?.length > 0 ? <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 gap-y-10">
                                    {liveNewsData?.map((element) => (
                                        <LiveNewsCard key={element?.id} data={element} liveNewsPage={true} />
                                    ))}
                                </div> :
                                    <div> <EmptyStatus /></div>
                        }
                        <div className='my-12'>
                            {totalData > dataPerPage && totalData !== liveNewsData?.length ? (
                                <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                            ) : null}
                        </div>

                    </section>

                    {/* ad spaces */}
                    {
                        adSpacesData?.map((ad) => (
                            ad.placement === 'bottom' &&
                            <div key={ad?.id} className='-mt-2'>
                                <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                            </div>
                        ))
                    }
                </div>

            </>
        </Layout>
    )
}

export default WithPageMode('live_streaming_mode')(LiveNews)
