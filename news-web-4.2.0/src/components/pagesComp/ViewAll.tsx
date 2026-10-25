'use client'
import { useState } from 'react'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import CommonCardSkeleton from '../skeletons/CommonCardSkeleton'
import VerticalCard from '../common/newsCard/VerticalCard'
import EmptyStatus from '../common/EmptyStatus'
import LoadMoreBtn from '../common/loadermoreBtn/LoadmoreBtn'
import {
    useGetFeatureSections,
    getFeatureSectionContent,
    FeatureSectionItem,
} from '@/hooks/queries/useGetFeatureSections'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { useLatLong } from '@/hooks/useLatLong'

const dataPerPage = 6

const ViewAll = () => {

    const { t } = useTranslation()
    const router = useRouter()
    const slug = router?.query?.slug as string | undefined

    const langCode = useLangCode()
    const settingsData = useSelector(settingsSelector)
    const { latitude, longitude } = useLatLong();

    const [loadMore, setLoadMore] = useState(false);
    const [viewAllData, setViewAllData] = useState<FeatureSectionItem[]>([]);
    const [offset, setOffset] = useState(0);
    const [totalData, setTotalData] = useState(0);

    const { data: featureQueryData, isLoading, isFetching, isError, error } = useGetFeatureSections({
        language_code: langCode,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        slug: slug,
        latitude: latitude ?? undefined,
        longitude: longitude ?? undefined,
        enabled: !!slug,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setViewAllData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof featureQueryData | symbol>(() => Symbol('initial'))
    if (!isError && featureQueryData !== prevQueryData) {
        setPrevQueryData(featureQueryData)
        if (featureQueryData) {
            const section = featureQueryData?.data?.data?.[0]
            const { items } = getFeatureSectionContent(section)
            const total =
                section?.news_total ??
                section?.videos_total ??
                section?.breaking_news_total ??
                section?.author_news_total ??
                0

            setTotalData(total)
            if (loadMore) {
                setViewAllData((prev) => [...prev, ...items])
            } else {
                setViewAllData(items)
            }
        }
    }

    if (isError && error) {
        console.log('viewAll err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('viewall')} thirdElement={slug} />

                <section className='viewAllSect container mt-8 md:mt-12'>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 gap-y-10">
                        {
                            isLoading && !loadMore
                                ? [...Array(dataPerPage)].map((_, index) => (
                                    <div key={index}>
                                        <CommonCardSkeleton />
                                    </div>
                                ))
                                : viewAllData?.map((item) => (
                                    <VerticalCard key={item?.id} news={item} />
                                ))
                        }
                    </div>

                    <div className='mt-12'>
                        {totalData > dataPerPage && totalData !== viewAllData.length ? (
                            <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                        ) : null}
                    </div>

                    {viewAllData.length < 1 && !isLoading && <EmptyStatus />}
                </section>
            </>
        </Layout>
    )
}

export default ViewAll
