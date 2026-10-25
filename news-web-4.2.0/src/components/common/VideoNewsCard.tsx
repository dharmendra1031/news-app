'use client'
import { CiStreamOn } from "react-icons/ci";
import LocalizedLink from './LocalizeLink';
import ImagePreview from './ImagePreview';
import VideoPlayIcon from './VideoPlayIcon';
import { useTranslation } from '@/hooks/useTranslation';
import { LiveNewsApi } from '@/hooks/queries/useGetLiveNews';
import { VideoNewsApi } from '@/hooks/queries/useGetVideoNews';

interface VideoNewsCardProps {
    element?: LiveNewsApi | VideoNewsApi
    viewAllCard?: boolean
    liveNewsPage?: boolean
}

const VideoNewsCard = ({ element, viewAllCard = false, liveNewsPage = false }: VideoNewsCardProps) => {

    const { t } = useTranslation();

    if (!element) return null

    // `viewAllCard` feeds in video-news items, which carry the url on
    // `content_value`/`content_type` instead of `url`/`type`.
    const videoUrl = viewAllCard ? (element as VideoNewsApi).content_value : (element as LiveNewsApi).url

    return (
        <LocalizedLink href={`/video-news/${element?.slug}`}>
            <div className='relative'>
                <div className='relative w-full h-[280px]'>
                    <ImagePreview
                        src={element?.image}
                        alt={element?.title}
                        className='rounded-[10px]'
                    />
                    {
                        liveNewsPage &&
                        <div className='flexCenter bg-[#ee2934] text-white rounded p-0.5 w-max font-semibold gap-1 absolute bottom-3 right-3'>
                            <CiStreamOn size={22} />
                            <span>{t('live')}</span>
                        </div>
                    }
                    <VideoPlayIcon />
                </div>
                <div className='mt-4'>
                    <h2 className='textPrimary text-[20px] sm:text-[24px] font-[600] line-clamp-2 first-letter:capitalize'>{element.title}</h2>
                </div>

            </div>
        </LocalizedLink>
    )
}

export default VideoNewsCard
