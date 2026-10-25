'use client'
import { useState } from 'react'
import { useRouter } from 'next/router'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import CommonNewsSection from '../common/CommonNewsSection'
import { useGetNews, NewsApi } from '@/hooks/queries/useGetNews'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { useLatLong } from '@/hooks/useLatLong'

const dataPerPage = 6

const TagNews = () => {

    const { t } = useTranslation();
    const router = useRouter();
    const slug = router?.query?.slug as string | undefined

    const langCode = useLangCode();
    const { latitude, longitude } = useLatLong();

    const [loadMore, setLoadMore] = useState(false);
    const [tagNewsData, setTagNewsData] = useState<NewsApi[]>([]);
    const [offset, setOffset] = useState(0);
    const [totalData, setTotalData] = useState(0);

    const { data: newsQueryData, isLoading, isFetching, isError, error } = useGetNews({
        language_code: langCode,
        tag_slug: slug,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        latitude,
        longitude,
        enabled: !!slug,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setTagNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof newsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && newsQueryData !== prevQueryData) {
        setPrevQueryData(newsQueryData)
        if (newsQueryData) {
            const items = newsQueryData?.data?.data ?? []
            setTotalData(newsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setTagNewsData((prev) => [...prev, ...items])
            } else {
                setTagNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('tagNews err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('tagLbl')} thirdElement={slug} />
                <CommonNewsSection
                    newsData={tagNewsData}
                    isLoading={isLoading}
                    isFetching={isFetching}
                    loadMore={loadMore}
                    dataPerPage={dataPerPage}
                    totalData={totalData}
                    handleLoadMore={handleLoadMore}
                    showCateBagde
                />
            </>
        </Layout>
    )
}

export default TagNews
