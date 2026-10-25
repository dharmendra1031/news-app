'use client'
import { formatDuration, formatPlayerTime, formatShortDate, isLogin } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { SyntheticEvent, useEffect, useRef, useState } from 'react'
import ReactPlayer from 'react-player'
import { ClockIcon } from 'lucide-react'
import { LuCalendarDays } from 'react-icons/lu'
import { MdOutlineBookmark, MdOutlineBookmarkBorder, MdOutlineDownload, MdSkipNext, MdSkipPrevious } from 'react-icons/md'
import { FaPauseCircle, FaPlayCircle } from 'react-icons/fa'
import { usePodcastActions } from '@/hooks/usePodcastActions'
import { updateEpisodeDurationApi } from '@/api/apiRoutes'
import { EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import ImagePreview from '@/components/common/ImagePreview'

const SKIP_SECONDS = 10

interface EpisodePlayCardProps {
    data?: EpisodeApi
    podcast?: PodcastApi
    onFollow?: (id: number, status: boolean) => Promise<boolean>
    onProgress?: (seconds: number) => void
}

const EpisodePlayCard = ({
    data,
    podcast,
    onFollow,
    onProgress,
}: EpisodePlayCardProps) => {
    const { t } = useTranslation();
    const { bookmarkEpisode, downloadEpisode } = usePodcastActions()

    const playerRef = useRef<HTMLVideoElement>(null)
    const resumeFromRef = useRef(0)
    const playedSecondsRef = useRef(0)
    const durationRef = useRef(0)
    const episodeIdRef = useRef<number | undefined>(undefined)

    const [isPlaying, setIsPlaying] = useState(false)
    const [playedSeconds, setPlayedSeconds] = useState(0)
    const [duration, setDuration] = useState(data?.duration_seconds || 0)
    const [isBookmarked, setIsBookmarked] = useState(!!data?.is_bookmarked)
    const [isFollowed, setIsFollowed] = useState(!!podcast?.is_followed)

    useEffect(() => {
        playedSecondsRef.current = playedSeconds
    }, [playedSeconds])

    useEffect(() => {
        durationRef.current = duration
    }, [duration])

    const sendPlayDuration = () => {
        if (isLogin()) {
            const episodeId = episodeIdRef.current
            const seconds = Math.floor(playedSecondsRef.current)
            const totalDuration = durationRef.current

            if (!episodeId || seconds <= 0) return

            updateEpisodeDurationApi({
                episode_id: episodeId,
                listened_seconds: seconds,
                completed: totalDuration > 0 && seconds >= totalDuration - 1,
            }).catch((error) => console.error('Error:', error))
        }
    }

    useEffect(() => {
        resumeFromRef.current = Number(data?.listening_history?.listened_seconds) || 0
        setIsPlaying(false)
        setPlayedSeconds(resumeFromRef.current)
        setDuration(data?.duration_seconds || 0)
        setIsBookmarked(!!data?.is_bookmarked)
        episodeIdRef.current = data?.id

        return () => {
            sendPlayDuration()
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [data?.id])

    useEffect(() => {
        setIsFollowed(!!podcast?.is_followed)
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [podcast?.id])

    const handlePlayPause = () => setIsPlaying((prev) => !prev)

    const handlePlay = () => setIsPlaying(true)

    const handlePause = () => {
        setIsPlaying(false)
        sendPlayDuration()
    }

    const handleEnded = () => {
        setIsPlaying(false)
        sendPlayDuration()
    }

    const handleSeek = (seconds: number) => {
        const target = Math.min(Math.max(seconds, 0), duration || Infinity)
        if (playerRef.current) {
            playerRef.current.currentTime = target
        }
        setPlayedSeconds(target)
    }

    const handleReady = () => {
        if (resumeFromRef.current > 0 && playerRef.current) {
            playerRef.current.currentTime = resumeFromRef.current
            resumeFromRef.current = 0
        }
    }

    const handleTimeUpdate = (event: SyntheticEvent<HTMLVideoElement>) => {
        const current = event.currentTarget.currentTime
        setPlayedSeconds(current)
        onProgress?.(Math.floor(current))
    }

    const handleDurationChange = (event: SyntheticEvent<HTMLVideoElement>) => {
        setDuration(event.currentTarget.duration || 0)
    }

    const handleBookmark = async () => {
        const nextStatus = !isBookmarked
        setIsBookmarked(nextStatus)

        const success = await bookmarkEpisode({ podcastId: podcast?.id as number, episodeId: data?.id, status: nextStatus })
        if (!success) {
            setIsBookmarked(!nextStatus)
        }
    }

    const handleDownload = () => {
        if (data?.audio_url) downloadEpisode({ audio_url: data.audio_url, title: data.title })
    }

    const handleFollow = async () => {
        if (!podcast?.id) return

        const nextStatus = !isFollowed
        setIsFollowed(nextStatus)

        const success = await onFollow?.(podcast.id, nextStatus)
        if (!success) {
            setIsFollowed(!nextStatus)
        }
    }


    return (
        <div className="flex flex-col gap-4 rounded-2xl customBgWhite p-3 sm:p-4 border seconadryBorderColor">
            <div className="flex gap-6 max-sm:flex-col">
                {/* Thumbnail */}
                <div className={`relative shrink-0 max-sm:w-auto max-sm:h-[266px] w-24 h-24 sm:w-36 sm:h-36 lg:w-[523px] lg:h-[523px] aspect-[523/523] rounded-[8px] overflow-hidden`}>
                    <ImagePreview
                        src={data?.image ?? ''}
                        alt={data?.title ?? ''}
                        className="w-full h-full object-cover aspect-square"
                    />
                </div>

                {/* Content */}
                <div className="flex flex-col justify-center gap-5 flex-1 min-w-0">

                    <div className='flex flex-col gap-3'>
                        <h2 className="text-lg sm:text-xl md:text-3xl xl:text-[34px] font-semibold textPrimary first-letter:capitalize">
                            {data?.title}
                        </h2>
                        <p className="lg:text-[22px] textPrimary opacity-70 first-letter:capitalize">
                            {data?.description}
                        </p>

                    </div>
                    <div className="flex flex-wrap items-center justify-between gap-2 pt-5 border-t borderColor">
                        <div className="flex items-center gap-4 textPrimary shrink-0">
                            <div className="flex items-center gap-1 textPrimary opacity-80 lg:text-xl">
                                <ClockIcon size={18} />
                                <span className="font-medium">{formatDuration(data?.duration_seconds)}</span>
                            </div>
                            <div className="flex items-center gap-1 textPrimary opacity-80 lg:text-xl">
                                <LuCalendarDays size={18} />
                                <span className="font-medium">{formatShortDate(data?.published_at)}</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-4 textPrimary shrink-0">
                            {
                                data?.source_type !== 'youtube_link' &&
                                <button className="" onClick={handleDownload}>
                                    <MdOutlineDownload size={32} />
                                </button>
                            }
                            <button className="" onClick={handleBookmark}>
                                {isBookmarked ? <MdOutlineBookmark size={30} /> : <MdOutlineBookmarkBorder size={30} />}
                            </button>
                        </div>
                    </div>

                    <div className="flex flex-wrap items-center justify-between gap-3 pt-5 border-t borderColor">
                        {
                            podcast?.user &&
                            <div className="flexCenter gap-2 min-w-0">
                                <div className="w-12 h-12 rounded-full overflow-hidden shrink-0 flexCenter">
                                    <ImagePreview
                                        src={podcast?.user?.profile ?? ''}
                                        alt={podcast?.user?.name ?? ''}
                                        className="w-full h-full object-cover"
                                    />
                                </div>
                                <span className="md:text-xl font-semibold textPrimary truncate">{podcast?.user?.name}</span>
                            </div>
                        }

                        <div className="flex items-center gap-4 shrink-0 ms-auto">
                            <button
                                type="button"
                                onClick={handleFollow}
                                className={`md:text-lg font-semibold py-1 px-6 rounded-[8px] border borderColor textPrimary transition-opacity secondaryBg text-white!`}
                            >
                                {isFollowed ? t('UnfollowLbl') : t('followLbl')}
                            </button>
                        </div>
                    </div>
                    <div className='pt-5 border-t borderColor grid grid-cols-1 gap-6'>
                        <div style={{ position: 'absolute', width: 1, height: 1, overflow: 'hidden', opacity: 0, pointerEvents: 'none' }}>
                            <ReactPlayer
                                ref={playerRef}
                                src={data?.audio_url}
                                playing={isPlaying}
                                onReady={handleReady}
                                onPlay={handlePlay}
                                onPause={handlePause}
                                onTimeUpdate={handleTimeUpdate}
                                onDurationChange={handleDurationChange}
                                onEnded={handleEnded}
                                width="1px"
                                height="1px"
                            />
                        </div>
                        <div
                            className='bodyBgColor h-5 rounded-full overflow-hidden mt-2 cursor-pointer'
                            onClick={(e) => {
                                const { left, width } = e.currentTarget.getBoundingClientRect()
                                const fraction = (e.clientX - left) / width
                                handleSeek(fraction * (duration || 0))
                            }}
                        >
                            <div className='secondaryBg dark:bg-white h-full rounded-full' style={{ width: `${duration ? Math.min((playedSeconds / duration) * 100, 100) : 0}%` }} />
                        </div>
                        <div className='flex items-center justify-between'>
                            <div className='flex items-center gap-1'>
                                <span className='text-lg md:text-xl lg:text-2xl'>{formatPlayerTime(playedSeconds)}</span>
                                <span className='text-lg md:text-xl lg:text-2xl'>/</span>
                                <span className='text-lg md:text-xl lg:text-2xl'>{formatPlayerTime(duration)}</span>
                            </div>
                            <div className='flex items-center gap-4'>
                                <span className='cursor-pointer' onClick={() => handleSeek(playedSeconds - SKIP_SECONDS)}><MdSkipPrevious size={32} /></span>
                                <span className='cursor-pointer' onClick={handlePlayPause}>
                                    {isPlaying ? <FaPauseCircle size={32} /> : <FaPlayCircle size={32} />}
                                </span>
                                <span className='cursor-pointer' onClick={() => handleSeek(playedSeconds + SKIP_SECONDS)}><MdSkipNext size={32} /></span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </div>
    )
}

export default EpisodePlayCard
