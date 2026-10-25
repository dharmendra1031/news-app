'use client'
import { useState } from 'react'
import { useSpeak } from 'react-text-to-speech'
import ReactPlayer from 'react-player'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import { AiOutlineEye, AiOutlineLike } from 'react-icons/ai'
import { BiLike, BiSolidLike } from 'react-icons/bi'

import Layout from '@/components/Layout/Layout'
import AdSpace from '@/components/common/AdSpace'
import Breadcrumb from '@/components/common/Breadcrumb'
import CategoryBadge from '@/components/common/CategoryBadge'
import EmptyStatus from '@/components/common/EmptyStatus'
import DetailPageSkeleton from '@/components/skeletons/DetailPageSkeleton'
import NewsToolbar from '@/components/pagesComp/NewsDetails/NewsToolbar'
import RelatedNewsSection from '@/components/pagesComp/NewsDetails/RelatedNewsSection'

import { useGetVideoNews } from '@/hooks/queries/useGetVideoNews'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import { useNewsActions } from '@/hooks/useNewsActions'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { extractTextFromHTML, formatShortDate, isLogin } from '@/components/utils/helpers'
import { newsFontSizeSelector } from '@/redux/reducers/helperSlice'
import { webSettingSelector } from '@/redux/reducers/settingsSlice'
import { PiCalendarDots } from 'react-icons/pi'
import RichTextContent from '@/components/common/RichText'
import SurveysSection from '../NewsDetails/SurveysSection'

const VideoDetails = () => {

    const { t } = useTranslation()
    const router = useRouter()
    const langCode = useLangCode()
    const webSetting = useSelector(webSettingSelector)
    const fontSize = useSelector(newsFontSizeSelector)

    const slug = typeof router.query.slug === 'string' ? router.query.slug : undefined

    const { likeNews } = useNewsActions()

    const { data: videoQueryData, isLoading } = useGetVideoNews({
        language_code: langCode,
        slug,
        enabled: !!slug,
    })

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'news_details',
    })

    const adSpacesData = adSpacesQueryData?.data ?? []

    const details = videoQueryData?.data?.data?.[0]

    const { speak, stop: stopSpeak, speechStatus } = useSpeak({})
    const isSpeaking = speechStatus === 'started' || speechStatus === 'queued'

    const [like, setLike] = useState(false)
    const [extraLikes, setExtraLikes] = useState(0)

    // Server sends the viewer's own like state with the article — seed on arrival.
    const [prevDetails, setPrevDetails] = useState<typeof details | symbol>(() => Symbol('initial'))
    if (details !== prevDetails) {
        setPrevDetails(details)
        setLike(!!details?.like)
        setExtraLikes(0)
    }

    const handleLike = async () => {
        if (!details?.id) return
        const nextState = !like
        if (await likeNews(details.id, nextState)) {
            setLike(nextState)
            setExtraLikes(nextState ? 1 : 0)
        }
    }

    const handleSpeak = () => {
        if (isSpeaking) {
            stopSpeak()
            return
        }
        speak(extractTextFromHTML(details?.description), { lang: langCode })
    }

    const shareUrl = decodeURI(`${process.env.NEXT_PUBLIC_WEB_URL}${router?.asPath}`)
    const videoDate = details?.published_date || details?.date

    if (isLoading) {
        return (
            <Layout>
                <section className='detailPage'>
                    <DetailPageSkeleton />
                </section>
            </Layout>
        )
    }

    if (!details) {
        return (
            <Layout>
                <section className='detailPage'>
                    <EmptyStatus />
                </section>
            </Layout>
        )
    }

    return (
        <Layout>
            <Breadcrumb secondElement={t('videoDetails')} thirdElement={details?.title} />
            <section className='detailPage'>

                {/* ad spaces */}
                {adSpacesData.map((ad) => (
                    ad.placement === 'news_details_top' &&
                    <div className='mt-8 md:mt-12' key={ad?.id}>
                        <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} container={true} />
                    </div>
                ))}


                <section className='container commonMT'>
                    <div className='grid grid-cols-12 gap-y-10 lg:gap-8'>

                        <div className='col-span-12 lg:col-span-8'>
                            <div className='flex flex-col gap-7.5'>
                                <div>
                                    <CategoryBadge cate={details?.category_name} whiteBg={false} />
                                    <h2 className='text-[22px] md:text-[34px] lg:text-4xl font-bold capitalize textPrimary mt-2'>
                                        {details?.title}
                                    </h2>
                                </div>

                                <div className='flex items-center justify-between flex-wrap gap-6 border-y borderColor py-4 sm:py-6'>
                                    <div className='flex items-center gap-4 sm:gap-8 flex-wrap'>
                                        {videoDate && (
                                            <div className='flex items-center gap-1 textPrimary font-semibold'>
                                                <PiCalendarDots size={18} />
                                                <span>{formatShortDate(videoDate)}</span>
                                            </div>
                                        )}

                                        <div className='flex items-center gap-1 textPrimary font-semibold'>
                                            <span className='h-1.5 w-1.5 rounded-full bg-(--border-color) mr-2'></span>
                                            <AiOutlineEye size={18} />
                                            <span>{details?.total_views}</span>
                                        </div>

                                        {
                                            details?.source_type !== 'live_streaming' && details && (details?.total_like > 0 || extraLikes === 1) &&
                                            <div className='flex items-center gap-1 textPrimary font-semibold'>
                                                <span className='h-1.5 w-1.5 rounded-full bg-(--border-color) mr-2'></span>
                                                <AiOutlineLike size={18} />
                                                <span>{(details?.total_like ?? 0) + extraLikes} {t('likes')}</span>
                                            </div>
                                        }
                                    </div>
                                    {details?.source_type !== 'live_streaming' && (
                                        <div className='col-span-12 sm:col-span-3 flex items-center justify-around textPrimary gap-4'>
                                            <div className='border p-2 rounded-lg border-black dark:border-white cursor-pointer font-semibold' onClick={handleLike}>
                                                {like && isLogin() ? <BiSolidLike size={23} /> : <BiLike size={23} />}
                                            </div>
                                        </div>
                                    )}
                                </div>
                                <div className='relative rounded-2xl overflow-hidden aspect-video bg-black'>
                                    {details?.content_value && (
                                        <ReactPlayer
                                            src={details.content_value}
                                            controls
                                            width='100%'
                                            height='100%'
                                        />
                                    )}
                                </div>

                                {
                                    details?.description &&
                                    <div className='pt-7.5 border-t borderColor'>
                                        <NewsToolbar
                                            url={shareUrl}
                                            title={`${details?.title} - ${webSetting?.web_name ?? ''}`}
                                            hashtag={webSetting?.web_name}
                                            onSpeak={handleSpeak}
                                            isSpeaking={isSpeaking}
                                        />
                                    </div>
                                }

                                <div className='textPrimary newsDesc' style={{ fontSize: `${fontSize}px` }}>
                                    <RichTextContent content={details?.description ?? ''} />
                                </div>

                            </div>

                            {/* ad spaces */}
                            {adSpacesData.map((ad) => (
                                ad.placement === 'news_details_bottom' &&
                                <div className='mt-8 md:mt-16' key={ad?.id}>
                                    <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} container={true} />
                                </div>
                            ))}

                            {details?.category_slug && (
                                <RelatedNewsSection
                                    newsSlug={slug}
                                    categorySlug={details.category_slug}
                                    categoryId={details.category_id ?? undefined}
                                    videoPage
                                />
                            )}
                        </div>

                        <div className='col-span-12 lg:col-span-4 flex flex-col gap-6'>
                            {/* ad spaces */}
                            {adSpacesData.map((ad) => (
                                ad.placement === 'right_side' &&
                                <div key={ad?.id}>
                                    <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} rightSide={true} />
                                </div>
                            ))}

                            {/* Keyed by slug: navigating between articles reuses this page component,
                                so without a remount the survey list and answered state carry over. */}
                            {isLogin() && <SurveysSection key={slug} />}

                        </div>
                    </div>
                </section>
            </section>
        </Layout>
    )
}

export default VideoDetails
