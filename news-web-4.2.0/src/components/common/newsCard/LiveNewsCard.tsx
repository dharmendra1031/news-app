'use client'
import { useState } from 'react'
import ReactPlayer from 'react-player'
import { CiStreamOn } from 'react-icons/ci'
import LocalizedLink from '../LocalizeLink'
import ImagePreview from '../ImagePreview'
import VideoPlayIcon from '../VideoPlayIcon'
import { useTranslation } from '@/hooks/useTranslation'
import { LiveNewsApi } from '@/hooks/queries/useGetLiveNews'
import NewsTitle from './NewsTitle'

interface LiveNewsCardProps {
    data?: LiveNewsApi | null
    liveNewsPage?: boolean
}

const LiveNewsCard = ({ data, liveNewsPage = false }: LiveNewsCardProps) => {

    const { t } = useTranslation()

    const [isHovering, setIsHovering] = useState(false)

    if (!data) return null

    return (
        <LocalizedLink href={`/video-news/${data?.slug}`}>
            <div
                className='relative w-full h-75 md:h-94 lg:h-101.75 aspect-square rounded-[10px] overflow-hidden'
                onMouseEnter={() => setIsHovering(true)}
                onMouseLeave={() => setIsHovering(false)}
            >
                <ImagePreview
                    src={data?.image}
                    alt={data?.title}
                    className='rounded-[10px] object-cover'
                />

                {
                    isHovering && data?.url &&
                    <ReactPlayer
                        src={data.url}
                        playing={isHovering}
                        muted
                        loop
                        playsInline
                        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}
                    />
                }

                <div className='flexCenter bg-[#ee2934] text-white rounded p-1 w-max font-semibold gap-1 absolute top-3 right-3 z-10'>
                    <CiStreamOn size={18} />
                    <span className='text-sm'>{t('live')}</span>
                </div>

                {!isHovering && <VideoPlayIcon />}
            </div>
            {
                liveNewsPage &&
                <div className='mt-6'>
                    <NewsTitle title={data?.title} />
                </div>
            }
        </LocalizedLink>
    )
}

export default LiveNewsCard
