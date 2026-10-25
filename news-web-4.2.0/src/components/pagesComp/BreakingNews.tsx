'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import CommonNewsSection from '../common/CommonNewsSection'
import AdSpace from '../common/AdSpace'
import { useGetBreakingNews } from '@/hooks/queries/useGetBreakingNews'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import { FeatureSectionItem, toBreakingNewsItem } from '@/hooks/queries/useGetFeatureSections'
import { useTranslation } from '@/hooks/useTranslation'
import { useDefaultLangCode, useLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { usePageMode } from '@/hooks/usePageMode'
import WithPageMode from '../hoc/WithPageMode'

const BreakingNews = () => {

    const { t } = useTranslation();
    const router = useRouter()

    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const breakingNewsMode = usePageMode('breaking_news_mode');

    const dataPerPage = 8;

    const [loadMore, setLoadMore] = useState(false)
    const [breakingNewsData, setBreakingNewsData] = useState<FeatureSectionItem[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    // Settings load after mount, so only redirect once we actually know the mode.
    useEffect(() => {
        if (breakingNewsMode !== undefined && !breakingNewsMode) {
            router.replace(withLang('/', langCode, defaultLangCode))
        }
    }, [breakingNewsMode, langCode, defaultLangCode, router])

    const { data: breakingNewsQueryData, isLoading, isFetching, isError, error } = useGetBreakingNews({
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
        if (isError) setBreakingNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof breakingNewsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && breakingNewsQueryData !== prevQueryData) {
        setPrevQueryData(breakingNewsQueryData)
        if (breakingNewsQueryData) {
            const items = (breakingNewsQueryData?.data?.data ?? []).map(toBreakingNewsItem)
            setTotalData(breakingNewsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setBreakingNewsData((prev) => [...prev, ...items])
            } else {
                setBreakingNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('breakingNews err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('breakingNewsLbl')} />

                <div className='mt-8 flex flex-col gap-6'>

                    {/* ad spaces */}
                    {
                        adSpacesData?.map((ad) => (
                            ad.placement === 'top' &&
                            <div key={ad?.id} className='container'>
                                <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} marginSpace={false} />
                            </div>
                        ))
                    }

                    <CommonNewsSection
                        newsData={breakingNewsData}
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

export default WithPageMode('breaking_news_mode')(BreakingNews)
