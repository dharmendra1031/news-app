'use client'
import { formatShortDate, truncateText } from '@/components/utils/helpers'
import ImagePreview from '@/components/common/ImagePreview'
import { FiCalendar, FiClock } from 'react-icons/fi'
import { RssFeedItemApi } from '@/hooks/queries/useGetRssFeeds'

interface FeedCardProps {
    data: RssFeedItemApi
    selectedCate?: boolean
}

const FeedCard = ({ data, selectedCate = false }: FeedCardProps) => {

    return (
        <a href={data?.url} title='detail-page' target='_blank' rel='noopener noreferrer'>
            <div className={`w-full h-max customBgWhite p-4 rounded-[6px] grid grid-cols-12 gap-6`}>
                {
                    data?.image_url &&
                    <div className='col-span-12 sm:col-span-3'>
                        <div className='w-full h-auto sm:h-full sm:aspect-[153/140] object-cover'>
                            <ImagePreview
                                src={data?.image_url}
                                alt={data?.title}
                                className='commonRadius'
                            />
                        </div>
                    </div>
                }
                <div className={`flex flex-col gap-2 ${data?.image_url ? 'col-span-12 sm:col-span-9' : 'col-span-12'}`}>
                    {
                        !selectedCate &&
                        <div className='flex items-center p-3.5 rounded-2xl w-max max-h-5 text-sm font-medium gap-1 secondaryBg text-white'>
                            <span className=''>
                                {data?.source?.category?.category_name}
                            </span>
                        </div>
                    }
                    <div className='flex flex-col gap-2 lg:h-[88px]'>

                        <h2 className='textPrimary font-semibold text-base md:text-2xl line-clamp-1'>{data?.title}</h2>
                        {
                            data?.description &&
                            <h3 className='textSecondary line-clamp-2'>{truncateText(data?.description, 120)}</h3>
                        }
                    </div>
                    <div className='flex items-center justify-between flex-wrap lg:flex-nowrap w-full border-t-2 pt-2 gap-y-3 dark:borderColor'>
                        {
                            data?.author &&
                            <div className='flex items-center gap-1 lg:w-[60%] xl:w-[70%]'>
                                <span className='textPrimary font-semibold line-clamp-1'>
                                    {data?.author}
                                </span>
                            </div>
                        }
                        <div className="flex items-center gap-1 textPrimary font-semibold">
                            {
                                data?.published_at_human?.includes('hours ago') ?
                                    <FiClock className="" size={18} />
                                    :
                                    <FiCalendar className="" size={18} />

                            }
                            <span className=''>
                                {
                                    data?.published_at_human?.includes('hours ago') ?
                                        data?.published_at_human :
                                        formatShortDate(data?.published_at)
                                }
                            </span>
                        </div>
                    </div>

                </div>
            </div>
        </a>
    )
}

export default FeedCard
