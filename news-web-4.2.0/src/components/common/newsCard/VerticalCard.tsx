'use client'
import LocalizedLink from '@/components/common/LocalizeLink'
import ImagePreview from '@/components/common/ImagePreview'
import DateNViewsCount from '@/components/common/DateNViewsCount'
import NewsTitle from './NewsTitle'
import CategoryBadge from '../CategoryBadge'
import { FeatureSectionItem } from '@/hooks/queries/useGetFeatureSections'
import VideoPlayIcon from '../VideoPlayIcon'
import { BsBookmarkFill } from 'react-icons/bs'

export interface NewsCardProps {
    news: FeatureSectionItem
    isReverse?: boolean
    showCateBagde?: boolean
    style?: '' | 'style_1' | 'style_2' | 'style_3' | 'style_4' | 'style_5' | 'style_6'
    isCateWhiteBg?: boolean
    /** Shows a remove-bookmark button over the image — used on the bookmark listing page. */
    bookmarkCard?: boolean
    onRemoveBookmark?: (newsId: number) => void
}

const VerticalCard = ({ news, isReverse = true, showCateBagde = false, style = '', bookmarkCard = false, onRemoveBookmark }: NewsCardProps) => {
    if (!news) return null

    const newsLink = news?.href || `/news/${news?.slug}`
    const newsDate = news?.published_date || news?.date
    const isInternalNewsLink = /\/(news|breaking-news|video-news)(\/|$)/.test(newsLink)

    const imageClassByStyle: Record<string, string> = {
        style_2: 'aspect-382/230 h-[230px]',
        style_5: 'aspect-327/220 h-[220px]',
        style_6: 'aspect-456/250 h-[250px]',
    }

    const defaultImageClass = 'aspect-440/300 h-[300px]'
    const imageClass = imageClassByStyle[style] ?? defaultImageClass

    return (
        <LocalizedLink
            href={newsLink}
            title={news?.title}
            {...(!isInternalNewsLink ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
        >
            <div className={`flexCol gap-6 w-full ${isReverse ? 'flex-col-reverse!' : ''}`}>
                <div className='flexCol gap-2'>
                    <NewsTitle title={news?.title} />
                    <DateNViewsCount date={newsDate} views={news?.total_views} author={news?.rssAuthor} />
                </div>

                <div className={`relative w-full overflow-hidden commonRadius ${imageClass}`}>
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
                    {
                        showCateBagde &&
                        <CategoryBadge cate={news?.category?.category_name} isFloating={true} />
                    }
                    {
                        bookmarkCard &&
                        <button
                            type='button'
                            title='Remove bookmark'
                            onClick={(e) => {
                                e.preventDefault()
                                e.stopPropagation()
                                onRemoveBookmark?.(news?.id)
                            }}
                            className='absolute top-2 right-2 sm:top-3 sm:right-3 flexCenter bodyBgColor textPrimary rounded-full h-9 w-9 cursor-pointer'
                        >
                            <BsBookmarkFill size={16} />
                        </button>
                    }
                </div>
            </div>
        </LocalizedLink>
    )
}

export default VerticalCard
