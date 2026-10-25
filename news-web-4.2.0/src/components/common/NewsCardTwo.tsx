'use client'
import LocalizedLink from './LocalizeLink'
import ImagePreview from './ImagePreview'
import VideoNewsCard from './VideoNewsCard'
import { truncateText } from '@/components/utils/helpers'
import { BreakingNewsApi } from '@/hooks/queries/useGetBreakingNews'
import { VideoNewsApi } from '@/hooks/queries/useGetVideoNews'

interface NewsCardTwoProps {
    element?: BreakingNewsApi | VideoNewsApi
    breakingNews?: boolean
    videoNews?: boolean
}

const NewsCardTwo = ({ element, breakingNews = false, videoNews = false }: NewsCardTwoProps) => {

    if (!element) return null

    if (videoNews) {
        return (
            <div className='relative'>
                <VideoNewsCard element={element as VideoNewsApi} viewAllCard={true} />
            </div>
        )
    }

    return (
        <LocalizedLink href={`${breakingNews ? `/breaking-news/${element?.slug}` : `/news/${element?.slug}`}`}>
            <div>
                <div className='w-full h-auto sm:h-[400px] transition-transform duration-500 hover:-translate-y-2'>
                    <ImagePreview
                        src={element?.image}
                        alt={element?.title}
                        className='rounded-[10px]'
                    />
                </div>
                <div className='mt-4'>
                    <h2 className='textPrimary text-[20px] sm:text-[24px] font-semibold line-clamp-2 first-letter:capitalize'>{truncateText(element?.title, 120)}</h2>
                </div>
            </div>
        </LocalizedLink>
    )
}

export default NewsCardTwo
