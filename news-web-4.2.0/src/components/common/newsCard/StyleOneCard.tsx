'use client'
import LocalizedLink from '@/components/common/LocalizeLink'
import ImagePreview from '@/components/common/ImagePreview'
import DateNViewsCount from '@/components/common/DateNViewsCount'
import { FeatureSectionItem } from '@/hooks/queries/useGetFeatureSections'
import CategoryBadge from '../CategoryBadge'
import VideoPlayIcon from '../VideoPlayIcon'

interface StyleOneProps {
    news?: FeatureSectionItem
    large?: boolean
    showCateBagde?: boolean
    whiteBg?: boolean
    styleFive?: boolean
}

const StyleOneCard = ({ news, large = false, showCateBagde = false, styleFive = false }: StyleOneProps) => {
    if (!news) return null

    const newsLink = news?.href || `/news/${news?.slug}`
    const newsDate = news?.published_date || news?.date
    const isInternalNewsLink = /\/(news|breaking-news|video-news)(\/|$)/.test(newsLink)

    return (
        <LocalizedLink
            href={newsLink}
            title={news?.title}
            className='h-max'
            {...(!isInternalNewsLink ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
        >
            <div className={`relative w-full ${styleFive ? 'h-75.5 md:h-95.5 lg:h-201.75' : large ? 'h-75.5 md:h-95.5 lg:h-137' : 'h-75.5 md:h-95.5'} rounded-xl overflow-hidden`}>
                <ImagePreview
                    src={news?.image}
                    alt={news?.title}
                    objectFit='cover'
                    containerClassName='absolute inset-0'
                />

                <div className='absolute inset-0 bg-linear-to-t from-black/90 via-black/30 to-transparent pointer-events-none' />

                {
                    news?.isVideo &&
                    <VideoPlayIcon />
                }

                <div className='absolute inset-x-0 bottom-0 p-4 sm:p-5'>
                    {
                        showCateBagde &&
                        <div className='mb-2 sm:mb-3'>
                            <CategoryBadge cate={news?.category?.category_name} whiteBg />
                        </div>
                    }
                    <h2 className={`max-[399px]:text-lg text-xl font-semibold line-clamp-3 first-letter:capitalize text-white`}>
                        {news?.title}
                    </h2>
                    <DateNViewsCount date={newsDate} views={news?.total_views} author={news?.rssAuthor} light />
                </div>
            </div>
        </LocalizedLink >
    )
}

export default StyleOneCard
