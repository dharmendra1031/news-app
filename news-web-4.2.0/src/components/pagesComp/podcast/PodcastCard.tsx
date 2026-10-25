'use client'
import { useEffect, useState } from 'react'
import { FaRegCirclePlay } from 'react-icons/fa6'
import { HiMiniUsers } from 'react-icons/hi2'
import { useRouter } from 'next/router'
import { usePodcastActions } from '@/hooks/usePodcastActions'
import { useTranslation } from '@/hooks/useTranslation'
import MediaShare from '@/components/common/MediaShare'
import OpenInAppPopUp from '@/components/common/OpenInAppPopUp'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import ImagePreview from '@/components/common/ImagePreview'

interface PodcastCardProps {
    data?: PodcastApi | null
}

const PodcastCard = ({ data }: PodcastCardProps) => {

    const { t } = useTranslation()
    const router = useRouter()

    const isAuthorPage = router?.pathname?.includes('manage-podcast')
    const isShare = router?.query?.share

    const { followPodcast } = usePodcastActions()

    const currentUrL = `${process.env.NEXT_PUBLIC_WEB_URL}${router?.asPath}`

    const [isFollowed, setIsFollowed] = useState(!!data?.is_followed)
    const [followerCount, setFollowerCount] = useState(Number(data?.follower_count) || 0)
    const [share, setShare] = useState(false)
    const [IsOpenInApp, setIsOpenInApp] = useState(false)

    useEffect(() => {
        setIsOpenInApp(!!isShare && window.innerWidth <= 768)
    }, [isShare])

    const [prevId, setPrevId] = useState(data?.id)
    if (data?.id !== prevId) {
        setPrevId(data?.id)
        setIsFollowed(!!data?.is_followed)
        setFollowerCount(Number(data?.follower_count) || 0)
    }

    const handleFollow = async () => {
        if (!data?.id) return

        const nextStatus = !isFollowed
        setIsFollowed(nextStatus)
        setFollowerCount((prev) => nextStatus ? prev + 1 : Math.max(0, prev - 1))

        const success = await followPodcast(data.id, nextStatus)
        if (!success) {
            setIsFollowed(!nextStatus)
            setFollowerCount((prev) => nextStatus ? Math.max(0, prev - 1) : prev + 1)
        }
    }

    if (!data) return null

    return (
        <div className="flex flex-col gap-4 rounded-2xl customBgWhite p-3 sm:p-4 border seconadryBorderColor">
            <div className="flex gap-6 max-sm:flex-col">
                {/* Thumbnail */}
                <div className={`relative shrink-0 max-sm:w-auto max-sm:h-[266px] w-24 h-24 sm:w-36 sm:h-36 lg:w-[266px] lg:h-[266px] aspect-[266/266] rounded-[8px] overflow-hidden`}>
                    <ImagePreview
                        src={data?.image}
                        alt={data?.title}
                        className="w-full h-full object-cover aspect-square"
                    />
                </div>

                {/* Content */}
                <div className="flex flex-col justify-center gap-5 flex-1 min-w-0">
                    <div className="flex flex-wrap items-center justify-between gap-2">
                        <div className="flex items-center gap-4 textPrimary shrink-0 ms-auto">
                            <div className="flex items-center gap-1 textPrimary opacity-80 lg:text-xl">
                                <HiMiniUsers />
                                <span className="font-medium">{followerCount}</span>
                            </div>
                            <div className="flex items-center gap-1 textPrimary opacity-80 lg:text-xl">
                                <FaRegCirclePlay />
                                <span className="font-medium">{data?.episode_count}</span>
                            </div>
                        </div>
                    </div>
                    <div className='flex flex-col gap-3'>
                        <h2 className="text-lg sm:text-xl md:text-3xl xl:text-[34px] font-semibold textPrimary break-all first-letter:capitalize">
                            {data?.title}
                        </h2>
                        <p className="lg:text-[22px] textPrimary opacity-70 break-all first-letter:capitalize">
                            {data?.description}
                        </p>

                    </div>

                    <div className="flex flex-wrap items-center justify-between gap-3 pt-5 border-t borderColor">
                        {
                            data?.user && !isAuthorPage &&
                            <div className="flexCenter gap-2 min-w-0">
                                <div className="w-12 h-12 rounded-full overflow-hidden shrink-0 flexCenter">
                                    <ImagePreview
                                        src={data?.user?.profile ?? ''}
                                        alt={data?.user?.name ?? ''}
                                        className="w-full h-full object-cover"
                                    />
                                </div>
                                <span className="md:text-xl font-semibold textPrimary truncate first-letter:capitalize">{data?.user?.name}</span>
                            </div>
                        }

                        <div className="flex items-center gap-4 shrink-0 ms-auto">
                            {
                                !isAuthorPage &&
                                <button
                                    type="button"
                                    onClick={handleFollow}
                                    className={`md:text-lg font-semibold py-1 px-6 rounded-[8px] border borderColor textPrimary transition-opacity`}
                                >
                                    {isFollowed ? t('UnfollowLbl') : t('followLbl')}
                                </button>
                            }
                            <button
                                type="button"
                                onClick={() => setShare(true)}
                                className="md:text-lg font-semibold py-1 px-6 rounded-[8px] secondaryBg dark:bodyBgColor text-white transition-opacity"
                            >
                                {t('shareLbl')}
                            </button>

                        </div>
                    </div>
                </div>

            </div>

            {/* ── Share Modal ───────────────────────────────────────── */}
            {share && (
                <div
                    className='fixed inset-0 z-50 flex items-center justify-center'
                    onClick={() => setShare(false)}
                >
                    <div className='absolute inset-0 bg-black/60' />
                    <div
                        className='relative bodyBgColor rounded-2xl p-6 w-full max-w-sm mx-4 flex flex-col gap-4'
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className='flex items-center justify-between absolute top-4 right-4'>
                            <button
                                onClick={() => setShare(false)}
                                className='textPrimary text-xl leading-none'
                            >
                                ✕
                            </button>
                        </div>
                        <MediaShare
                            url={currentUrL}
                            title={data?.title?.replace(/<[^>]*>/g, '') || ''}
                            hashtag=''
                        />
                    </div>
                </div>
            )}

            <OpenInAppPopUp IsOpenInApp={IsOpenInApp} OnHide={() => setIsOpenInApp(false)} />
        </div>
    )
}

export default PodcastCard
