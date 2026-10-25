'use client'
import { FiCalendar } from 'react-icons/fi'
import { BsBookmark } from 'react-icons/bs'
import LocalizedLink from './LocalizeLink'
import ImagePreview from './ImagePreview'
import { formatShortDate } from '@/components/utils/helpers'
import { NewsApi } from '@/hooks/queries/useGetNews'
import CategoryBadge from './CategoryBadge'

interface NewsCardProps {
    element?: NewsApi
    subDropCard?: boolean
    bookmarkCard?: boolean
    tagCard?: boolean
    setbookmarkApi?: (newsId: number) => void
    categorySlug?: string
    subCateSlug?: string
}

const NewsCard = ({ subDropCard, bookmarkCard, element, tagCard, setbookmarkApi, categorySlug, subCateSlug }: NewsCardProps) => {
    if (!element) return null

    const newsDate = element?.published_date || element?.date

    const newsLink = categorySlug
        ? `/categories-news/${categorySlug}/${element?.slug}`
        : subCateSlug
            ? `/categories-news/sub-category/${subCateSlug}/${element?.slug}`
            : `/news/${element?.slug}`

    return (
        <div className={`w-full rounded-lg h-max ${subDropCard ? 'bg-transparent' : 'bg-white dark:secondaryBg'}`}>
            {/* Image Section */}
            <div className="relative">
                <LocalizedLink href={newsLink} title="detail-pae">
                    <div className={`object-cover w-full ${subDropCard ? 'h-[194px]' : 'h-[250px] md:h-[300px]'} commonRadius transition-all duration-500 hover:-translate-y-2`}>

                        <ImagePreview
                            src={element?.image}
                            alt={element?.title}
                            className={`commonRadius`}
                        />
                    </div>
                </LocalizedLink>
                <CategoryBadge cate={tagCard ? element?.tag_name : bookmarkCard ? element?.category?.category_name : element?.category?.category_name} isFloating={true} whiteBg />
                {/* <div className="absolute top-2 left-2 categoryTag primaryBg! text-white!">
                    {tagCard ? element?.tag_name : bookmarkCard ? element?.category?.category_name : element?.category?.category_name}
                </div> */}
            </div>

            {/* Text Section */}
            <div className="p-4 relative text-start">
                {bookmarkCard && (
                    <span
                        className="secondaryBg text-white flexCenter rounded-full h-[40px] w-[40px] absolute -top-4 right-4 mb-4 border-[4px] border-white cursor-pointer"
                        onClick={() => setbookmarkApi?.(element.id)}
                    >
                        <BsBookmark size={18} />
                    </span>
                )}
                <LocalizedLink href={newsLink} title="detail-pae">
                    <h4 className={`${subDropCard ? 'font-medium' : 'text-[20px] font-semibold'} first-letter:capitalize mb-2 line-clamp-2 textPrimary ${bookmarkCard ? 'mt-4' : ''}`}>
                        {element?.title}
                    </h4>
                </LocalizedLink>
                {!subDropCard && (
                    <LocalizedLink href={newsLink} title="detail-pae">
                        <div className="flex items-center textSecondary">
                            <FiCalendar className="mr-2 mt-1" size={18} />
                            <span className="textSecondary text-[18px] font-[500]">
                                {formatShortDate(newsDate ?? undefined)}
                            </span>
                        </div>
                    </LocalizedLink>
                )}
            </div>
        </div>
    )
}

export default NewsCard
