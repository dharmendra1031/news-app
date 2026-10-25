'use client'
import { useState } from 'react'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import AlertCard from '../common/AlertCard'
import AlertCardSkeleton from '../skeletons/AlertCardSkeleton'
import EmptyStatus from '../common/EmptyStatus'
import LoadMoreBtn from '../common/loadermoreBtn/LoadmoreBtn'
import { useGetMarketAlerts, MarketAlertApi } from '@/hooks/queries/useGetMarketAlerts'
import { useTranslation } from '@/hooks/useTranslation'

const dataPerPage = 6

const AlertsPage = () => {

    const { t } = useTranslation()

    const [loadMore, setLoadMore] = useState(false)
    const [data, setData] = useState<MarketAlertApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const { data: alertsQueryData, isLoading, isFetching, isError, error } = useGetMarketAlerts({
        offset: offset * dataPerPage,
        limit: dataPerPage,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof alertsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && alertsQueryData !== prevQueryData) {
        setPrevQueryData(alertsQueryData)
        if (alertsQueryData) {
            const items = alertsQueryData?.data?.data ?? []
            setTotalData(alertsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setData((prev) => [...prev, ...items])
            } else {
                setData(items)
            }
        }
    }

    if (isError && error) {
        console.log('alerts err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('alerts')} />

                <section className='container commonMT'>
                    <div className='grid md:grid-cols-2 lg:grid-cols-3 gap-6'>
                        {
                            isLoading && !loadMore
                                ? [...Array(dataPerPage)].map((_, index) => (
                                    <AlertCardSkeleton key={index} />
                                ))
                                : data?.map((alert) => (
                                    <AlertCard key={alert?.id} data={alert} />
                                ))
                        }
                    </div>

                    <div className='mt-12'>
                        {totalData > dataPerPage && totalData !== data.length ? (
                            <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                        ) : null}
                    </div>

                    {data.length < 1 && !isLoading && <EmptyStatus />}
                </section>
            </>
        </Layout>
    )
}

export default AlertsPage
