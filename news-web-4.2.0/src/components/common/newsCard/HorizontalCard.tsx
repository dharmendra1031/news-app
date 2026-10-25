'use client'
import LocalizedLink from '@/components/common/LocalizeLink'
import ImagePreview from '@/components/common/ImagePreview'
import DateNViewsCount from '@/components/common/DateNViewsCount'
import NewsTitle from './NewsTitle'
import CategoryBadge from '../CategoryBadge'
import { NewsCardProps } from './VerticalCard'
import VideoPlayIcon from '../VideoPlayIcon'


const HorizontalCard = ({ news, showCateBagde = false, isReverse = false, style = '', isCateWhiteBg = true }: NewsCardProps) => {
    if (!news) return null

    const newsLink = news?.href || `/news/${news?.slug}`
    const newsDate = news?.published_date || news?.date
    const isInternalNewsLink = /\/(news|breaking-news|video-news)(\/|$)/.test(newsLink)

    const imageClassByStyle: Record<string, string> = {
        style_2: 'aspect-200/116 w-[115px] h-[108px] sm:w-50 sm:h-[116px]',
        style_4: 'aspect-115/108 w-[115px] h-[108px]',
    }

    const defaultImageClass = 'aspect-200/164 w-[115px] h-[108px] sm:w-50 sm:h-[164px]'
    const imageClass = imageClassByStyle[style] ?? defaultImageClass

    return (
        <LocalizedLink
            href={newsLink}
            title={news?.title}
            {...(!isInternalNewsLink ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
        >
            <div className={`w-full h-full flex gap-3 sm:gap-4 ${isReverse ? 'flex-row-reverse' : ''}`}>
                <div className={`relative shrink-0 overflow-hidden commonRadius ${imageClass}`}>
                    <ImagePreview
                        src={news?.image}
                        alt={news?.title}
                        objectFit='cover'
                        className='commonRadius'
                    />
                    {
                        news?.isVideo &&
                        <VideoPlayIcon />
                    }
                </div>

                <div className='flex-1 min-w-0 flexCol justify-between h-full'>
                    <div className='flex-1 min-w-0 flexCol gap-1.5 sm:gap-2'>
                        {
                            showCateBagde &&
                            <CategoryBadge cate={news?.category?.category_name} whiteBg={isCateWhiteBg} />
                        }
                        <NewsTitle title={news?.title} />
                    </div>
                    <DateNViewsCount date={newsDate} views={news?.total_views} author={news?.rssAuthor} />
                </div>
            </div>
        </LocalizedLink>
    )
}

export default HorizontalCard
