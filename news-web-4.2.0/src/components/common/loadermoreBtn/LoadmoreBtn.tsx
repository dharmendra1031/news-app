'use client'
import { useTranslation } from '@/hooks/useTranslation'
import LoadMoreSpinner from './LoaderSpinner'

interface LoadMoreBtnProps {
    handleLoadMore: () => void
    loadMoreLoading?: boolean
    searchModal?: boolean
}

const LoadMoreBtn = ({ handleLoadMore, loadMoreLoading, searchModal }: LoadMoreBtnProps) => {

    const {t} = useTranslation();

    return (
        <div className='mt-2 flexCenter w-full'>
            {
                loadMoreLoading ? <LoadMoreSpinner /> :
                    <button onClick={handleLoadMore} className={`loadMoreBtn commonBtn ${searchModal ? 'text-sm' : ''}`}>{t('loadMore')}</button>
            }
        </div>
    )
}

export default LoadMoreBtn
