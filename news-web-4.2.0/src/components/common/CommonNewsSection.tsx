import CommonCardSkeleton from '../skeletons/CommonCardSkeleton'
import EmptyStatus from '../common/EmptyStatus'
import LoadMoreBtn from '../common/loadermoreBtn/LoadmoreBtn'
import VerticalCard from '../common/newsCard/VerticalCard'
import { FeatureSectionItem } from '@/hooks/queries/useGetFeatureSections'

interface CommonNewsSectionProps {
    newsData: FeatureSectionItem[]
    isLoading: boolean
    isFetching: boolean
    loadMore: boolean
    dataPerPage: number
    totalData: number
    handleLoadMore: () => void
    showCateBagde?: boolean
    bookmarkCard?: boolean
    onRemoveBookmark?: (newsId: number) => void
}

const CommonNewsSection = ({
    newsData,
    isLoading,
    isFetching,
    loadMore,
    dataPerPage,
    totalData,
    handleLoadMore,
    showCateBagde,
    bookmarkCard,
    onRemoveBookmark,
}: CommonNewsSectionProps) => {
    return (
        <section className='tagNews container mt-8'>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 gap-y-10">
                {
                    isLoading && !loadMore
                        ? [...Array(dataPerPage)].map((_, index) => (
                            <div key={index}>
                                <CommonCardSkeleton />
                            </div>
                        ))
                        : newsData?.map((element) => (
                            <VerticalCard
                                key={element?.id}
                                news={element}
                                showCateBagde={showCateBagde}
                                bookmarkCard={bookmarkCard}
                                onRemoveBookmark={onRemoveBookmark}
                            />
                        ))
                }
            </div>

            <div className='my-12'>
                {totalData > dataPerPage && totalData !== newsData.length ? (
                    <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                ) : null}
            </div>

            {newsData.length < 1 && !isLoading && <EmptyStatus />}
        </section>
    )
}

export default CommonNewsSection