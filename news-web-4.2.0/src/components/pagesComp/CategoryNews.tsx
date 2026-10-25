'use client'
import { useState } from 'react'
import { useRouter } from 'next/router'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import CommonNewsSection from '../common/CommonNewsSection'
import { useGetNews, NewsApi } from '@/hooks/queries/useGetNews'
import { useLangCode } from '@/hooks/useLangCode'
import { useLatLong } from '@/hooks/useLatLong'

const dataPerPage = 8

const CategoryNews = () => {

    const router = useRouter();
    const slug = router?.query?.slug as string | undefined

    const langCode = useLangCode();
    const { latitude, longitude } = useLatLong();

    const [loadMore, setLoadMore] = useState(false);
    const [categoryNewsData, setCategoryNewsData] = useState<NewsApi[]>([]);
    const [offset, setOffset] = useState(0);
    const [totalData, setTotalData] = useState(0);

    const { data: newsQueryData, isLoading, isFetching, isError, error } = useGetNews({
        language_code: langCode,
        category_slug: slug,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        latitude,
        longitude,
        enabled: !!slug,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setCategoryNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof newsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && newsQueryData !== prevQueryData) {
        setPrevQueryData(newsQueryData)
        if (newsQueryData) {
            const items = newsQueryData?.data?.data ?? []
            setTotalData(newsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setCategoryNewsData((prev) => [...prev, ...items])
            } else {
                setCategoryNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('categoryNews err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const currentCategoryName = categoryNewsData?.[0]?.category?.category_name

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={currentCategoryName || slug} />
                <CommonNewsSection
                    newsData={categoryNewsData}
                    isLoading={isLoading}
                    isFetching={isFetching}
                    loadMore={loadMore}
                    dataPerPage={dataPerPage}
                    totalData={totalData}
                    handleLoadMore={handleLoadMore}
                />
            </>
        </Layout>
    )
}

export default CategoryNews
