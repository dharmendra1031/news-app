'use client'
import { useState } from 'react'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import CommonNewsSection from '@/components/common/CommonNewsSection'
import AdSpace from '@/components/common/AdSpace'
import { useGetVideoNews, VideoNewsApi, toVideoNewsItem } from '@/hooks/queries/useGetVideoNews'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'

const VideoNews = () => {

    const { t } = useTranslation();

    const langCode = useLangCode()

    const dataPerPage = 8;

    const [loadMore, setLoadMore] = useState(false)
    const [videoNewsData, setVideoNewsData] = useState<VideoNewsApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const { data: videoNewsQueryData, isLoading, isFetching, isError, error } = useGetVideoNews({
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
        if (isError) setVideoNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof videoNewsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && videoNewsQueryData !== prevQueryData) {
        setPrevQueryData(videoNewsQueryData)
        if (videoNewsQueryData) {
            const items = videoNewsQueryData?.data?.data ?? []
            setTotalData(videoNewsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setVideoNewsData((prev) => [...prev, ...items])
            } else {
                setVideoNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('videoNews err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('videoNews')} />
                <div className='mt-8 flex flex-col gap-6'>

                    {/* ad spaces */}
                    {
                        adSpacesData?.map((ad) => (
                            ad.placement === 'top' &&
                            <div key={ad?.id} className='container'>
                                <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} marginSpace={false}/>
                            </div>
                        ))
                    }

                    <CommonNewsSection
                        newsData={videoNewsData.map(toVideoNewsItem)}
                        isLoading={isLoading}
                        isFetching={isFetching}
                        loadMore={loadMore}
                        dataPerPage={dataPerPage}
                        totalData={totalData}
                        handleLoadMore={handleLoadMore}
                    />

                    {/* ad spaces */}
                    {
                        adSpacesData?.map((ad) => (
                            ad.placement === 'bottom' &&
                            <div key={ad?.id} className='container -mt-2'>
                                <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                            </div>
                        ))
                    }
                </div>
            </>
        </Layout>
    )
}

export default VideoNews
