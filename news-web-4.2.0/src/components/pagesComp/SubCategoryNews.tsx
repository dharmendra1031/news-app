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

const SubCategoryNews = () => {

    const router = useRouter();
    const slug = router?.query?.slug as string | undefined

    const langCode = useLangCode();
    const { latitude, longitude } = useLatLong();

    const [loadMore, setLoadMore] = useState(false);
    const [subCategoryNewsData, setSubCategoryNewsData] = useState<NewsApi[]>([]);
    const [offset, setOffset] = useState(0);
    const [totalData, setTotalData] = useState(0);

    const { data: newsQueryData, isLoading, isFetching, isError, error } = useGetNews({
        language_code: langCode,
        subcategory_slug: slug,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        latitude,
        longitude,
        enabled: !!slug,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setSubCategoryNewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof newsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && newsQueryData !== prevQueryData) {
        setPrevQueryData(newsQueryData)
        if (newsQueryData) {
            const items = newsQueryData?.data?.data ?? []
            setTotalData(newsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setSubCategoryNewsData((prev) => [...prev, ...items])
            } else {
                setSubCategoryNewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('subCategoryNews err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const currentCategoryName = subCategoryNewsData?.[0]?.category?.category_name
    const currentCategorySlug = subCategoryNewsData?.[0]?.category?.slug
    const currentSubCategoryName = subCategoryNewsData?.[0]?.sub_category?.subcategory_name

    return (
        <Layout>
            <>
                <Breadcrumb
                    secondElement={currentCategoryName}
                    thirdElement={currentSubCategoryName || slug}
                    categorySlug={currentCategorySlug}
                />
                <CommonNewsSection
                    newsData={subCategoryNewsData}
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

export default SubCategoryNews
