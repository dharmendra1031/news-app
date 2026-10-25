'use client'
import { useState } from 'react'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import CommonNewsSection from '@/components/common/CommonNewsSection'
import { useGetBookmark, BookmarkItem } from '@/hooks/queries/useGetBookmark'
import { useNewsActions } from '@/hooks/useNewsActions'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import Meta from '@/components/common/Meta'
import { webName } from '@/components/utils/helpers'
import WithAuth from '@/components/hoc/WithAuth'

const dataPerPage = 9

const Bookmark = () => {
    const { t } = useTranslation()
    const langCode = useLangCode()
    const { bookmarkNews } = useNewsActions()

    const [loadMore, setLoadMore] = useState(false)
    const [bookmarkData, setBookmarkData] = useState<BookmarkItem[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const { data: bookmarkQueryData, isLoading, isFetching, isError, error } = useGetBookmark({
        language_code: langCode,
        offset: offset * dataPerPage,
        limit: dataPerPage,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setBookmarkData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof bookmarkQueryData | symbol>(() => Symbol('initial'))
    if (!isError && bookmarkQueryData !== prevQueryData) {
        setPrevQueryData(bookmarkQueryData)
        if (bookmarkQueryData) {
            const items = bookmarkQueryData?.data?.data ?? []
            setTotalData(bookmarkQueryData?.data?.total ?? 0)
            if (loadMore) {
                setBookmarkData((prev) => [...prev, ...items])
            } else {
                setBookmarkData(items)
            }
        }
    }

    if (isError && error) {
        console.log('bookmark err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const handleRemoveBookmark = async (newsId: number) => {
        const success = await bookmarkNews(newsId, false)
        if (success) {
            setBookmarkData((prev) => prev.filter((item) => item?.id !== newsId))
            setTotalData((prev) => prev - 1)
        }
    }

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('bookmark')}`} />
                <Breadcrumb secondElement={t('bookmark')} />
                <CommonNewsSection
                    newsData={bookmarkData}
                    isLoading={isLoading}
                    isFetching={isFetching}
                    loadMore={loadMore}
                    dataPerPage={dataPerPage}
                    totalData={totalData}
                    handleLoadMore={handleLoadMore}
                    bookmarkCard
                    onRemoveBookmark={handleRemoveBookmark}
                    showCateBagde={true}
                />
            </>
        </Layout>
    )
}

export default WithAuth(Bookmark)
