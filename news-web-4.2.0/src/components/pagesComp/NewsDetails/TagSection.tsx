'use client'
import { useState } from 'react'
import LocalizedLink from '@/components/common/LocalizeLink'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { Skeleton } from '@/components/ui/skeleton'
import { useGetTags, TagApi } from '@/hooks/queries/useGetTags'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import SectionTitle from '@/components/common/SectionTitle'

const dataPerPage = 10

const TagSection = () => {

    const { t } = useTranslation()
    const langCode = useLangCode()

    const [loadMore, setLoadMore] = useState(false)
    const [tagsData, setTagsData] = useState<TagApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const { data: tagsQueryData, isLoading, isFetching, isError, error } = useGetTags({
        language_code: langCode,
        offset: offset * dataPerPage,
        limit: dataPerPage,
    })

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setTagsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof tagsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && tagsQueryData !== prevQueryData) {
        setPrevQueryData(tagsQueryData)
        if (tagsQueryData) {
            const items = tagsQueryData?.data?.data ?? []
            setTotalData(tagsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setTagsData((prev) => [...prev, ...items])
            } else {
                setTagsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('tagSection err =>', (error as Error).message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    if (!isLoading && !tagsData.length) return null

    return (
        <section className='tagSect flex flex-col gap-3 border borderColor rounded-xl p-2 md:p-3'>
            <div className='[&_.sectionTitle]:mb-0! [&_.borderColor]:mt-4!'>
                <SectionTitle title={t('tagLbl')} showViewMore={false} />
            </div>

            <div className='tags flex items-center gap-4 flex-wrap p-2'>
                {
                    isLoading && !loadMore
                        ? [...Array(dataPerPage)].map((_, index) => (
                            <Skeleton key={index} height={30} width={50} />
                        ))
                        : tagsData?.map((tag) => (
                            <LocalizedLink
                                key={tag?.id}
                                href={`/tag/${tag?.slug}`}
                                title={tag?.tag_name}
                                className='commonBg textPrimary rounded-3xl border py-1 px-4 first-letter:capitalize'
                            >
                                {tag?.tag_name}
                            </LocalizedLink>
                        ))
                }
            </div>

            {totalData > dataPerPage && totalData !== tagsData.length && (
                <div className='flexCenter pb-4'>
                    <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                </div>
            )}
        </section>
    )
}

export default TagSection
