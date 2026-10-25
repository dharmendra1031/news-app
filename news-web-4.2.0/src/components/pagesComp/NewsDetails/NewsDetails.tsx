'use client'
import { useEffect, useState, useSyncExternalStore } from 'react'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import { useSpeak } from 'react-text-to-speech'
import { AiOutlineLike, AiOutlineEye } from 'react-icons/ai'
import { LuClock3 } from 'react-icons/lu'

import Layout from '@/components/Layout/Layout'
import AdSpace from '@/components/common/AdSpace'
import EmptyStatus from '@/components/common/EmptyStatus'
import ImagePreview from '@/components/common/ImagePreview'
import LocalizedLink from '@/components/common/LocalizeLink'
import NewsToolbar from './NewsToolbar'
import OpenInAppPopUp from '@/components/common/OpenInAppPopUp'
import PhotoGallery from '@/components/common/PhotoGallery'
import RichTextContent from '@/components/common/RichText'
import VideoPlayIcon from '@/components/common/VideoPlayIcon'
import DetailPageSkeleton from '@/components/skeletons/DetailPageSkeleton'
import RelatedNewsSection from './RelatedNewsSection'
import SurveysSection from './SurveysSection'
import TagSection from './TagSection'
import CommnetsSidebar from './comments/CommnetsSidebar'

import { useGetNews } from '@/hooks/queries/useGetNews'
import { useGetBreakingNews } from '@/hooks/queries/useGetBreakingNews'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import { useNewsActions } from '@/hooks/useNewsActions'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { newsFontSizeSelector } from '@/redux/reducers/helperSlice'
import { webSettingSelector } from '@/redux/reducers/settingsSlice'
import { extractTextFromHTML, formatShortDate, isLogin } from '@/components/utils/helpers'
import { BiBookmark, BiComment, BiLike, BiSolidBookmark, BiSolidLike } from 'react-icons/bi'
import CategoryBadge from '@/components/common/CategoryBadge'
import { PiCalendarDots } from 'react-icons/pi'
import { usePageMode } from '@/hooks/usePageMode'

const MOBILE_QUERY = '(max-width: 768px)'

const subscribeToMobile = (onChange: () => void) => {
    const mediaQuery = window.matchMedia(MOBILE_QUERY)
    mediaQuery.addEventListener('change', onChange)
    return () => mediaQuery.removeEventListener('change', onChange)
}

interface NewsDetailsProps {
    breakingNews?: boolean
}

const NewsDetails = ({ breakingNews = false }: NewsDetailsProps) => {

    const { t } = useTranslation()
    const router = useRouter()

    const langCode = useLangCode()
    const webSetting = useSelector(webSettingSelector);
    const fontSize = useSelector(newsFontSizeSelector);
    const newsAuthMode = usePageMode('views_auth_mode');

    // The detail page is reachable from three routes — the news slug is the
    // deepest segment of whichever one was matched.
    const { slug, cateSlug, subCateSlug, share } = router.query
    const newsSlug = (subCateSlug || cateSlug || slug) as string | undefined

    const { bookmarkNews, likeNews, setNewsView, setBreakingNewsView } = useNewsActions()

    const { data: newsQueryData, isLoading: newsLoading } = useGetNews({
        language_code: langCode,
        slug: newsSlug,
        enabled: !!newsSlug && !breakingNews,
    })

    const { data: breakingQueryData, isLoading: breakingLoading } = useGetBreakingNews({
        language_code: langCode,
        slug: newsSlug,
        enabled: !!newsSlug && breakingNews,
    })

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'news_details',
    })

    const adSpacesData = adSpacesQueryData?.data ?? []

    const newsItem = newsQueryData?.data?.data?.[0]
    const breakingItem = breakingQueryData?.data?.data?.[0]
    const details = breakingNews ? breakingItem : newsItem

    const isLoading = breakingNews ? breakingLoading : newsLoading

    const [bookmark, setBookmark] = useState(false)
    const [like, setLike] = useState(false)
    const [extraLikes, setExtraLikes] = useState(0)
    const [appPromptDismissed, setAppPromptDismissed] = useState(false)
    const [commentsOpen, setCommentsOpen] = useState(false)

    // Shared links carry ?share=true — prompt phone readers to open the app.
    const isMobile = useSyncExternalStore(
        subscribeToMobile,
        () => window.matchMedia(MOBILE_QUERY).matches,
        () => false
    )
    const isOpenInApp = share === 'true' && isMobile && !appPromptDismissed

    const { speak, stop: stopSpeak, speechStatus } = useSpeak({})
    const isSpeaking = speechStatus === 'started' || speechStatus === 'queued'

    // Server sends the viewer's own bookmark/like state with the article.
    const [prevNewsItem, setPrevNewsItem] = useState<typeof newsItem | symbol>(() => Symbol('initial'))
    if (newsItem !== prevNewsItem) {
        setPrevNewsItem(newsItem)
        setBookmark(!!newsItem?.bookmark)
        setLike(!!newsItem?.like)
        setExtraLikes(0)
    }

    // Count the view once the article itself has arrived.
    useEffect(() => {
        if (!details?.id) return
        if (newsAuthMode && !isLogin()) return
        if (breakingNews) {
            setBreakingNewsView(details.id)
        } else {
            setNewsView(details.id)
        }

        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [details?.id, breakingNews])

    const handleSpeak = () => {
        if (isSpeaking) {
            stopSpeak()
            return
        }
        speak(extractTextFromHTML(details?.description), { lang: langCode })
    }

    const handleBookmark = async () => {
        if (!newsItem?.id) return
        const nextState = !bookmark
        if (await bookmarkNews(newsItem.id, nextState)) {
            setBookmark(nextState)
        }
    }

    const handleLike = async () => {
        if (!newsItem?.id) return
        const nextState = !like
        if (await likeNews(newsItem.id, nextState)) {
            setLike(nextState)
            setExtraLikes(nextState ? 1 : 0)
        }
    }

    const readTime = details?.read_time ?? 0
    const shareUrl = decodeURI(`${process.env.NEXT_PUBLIC_WEB_URL}${router?.asPath}`)
    const newsDate = newsItem?.published_date || newsItem?.date

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
                                    {breakingNews
                                        ? null
                                        : newsItem?.category?.category_name && <CategoryBadge cate={newsItem?.category?.category_name} whiteBg={false} />
                                    }
                                    <h2 className='text-[22px] md:text-[34px] lg:text-4xl font-bold capitalize textPrimary mt-5'>
                                        {details?.title}
                                    </h2>
                                </div>

                                <div className='flex items-center justify-between flex-wrap gap-6 border-y borderColor py-4 sm:py-6'>
                                    <div className='flex items-center gap-4 flex-wrap'>

                                        {newsItem?.user?.is_author === 1 && (
                                            <LocalizedLink href={`/author-details/${newsItem?.user?.slug}`} title={newsItem?.user?.name}>
                                                <div className='flexCenter gap-2'>
                                                    <div className='w-9 h-9'>
                                                        <ImagePreview src={newsItem?.user?.profile} alt={newsItem?.user?.name} rounded='full' />
                                                    </div>
                                                    <div className='flex flex-col gap-1'>
                                                        <div className='font-semibold text-base textPrimary'>{newsItem?.user?.name}</div>
                                                    </div>
                                                </div>
                                            </LocalizedLink>
                                        )}

                                        <div className='flex items-center gap-1 textPrimary font-semibold'>
                                            <LuClock3 />
                                            <span>{readTime} {t(readTime > 1 ? 'minutes' : 'minute')} {t('read')}</span>
                                        </div>

                                        {
                                            details?.total_views > 0 &&
                                            <div className='flex items-center gap-1 textPrimary font-semibold'>
                                                <span className='h-1.5 w-1.5 rounded-full bg-(--border-color) mr-2'></span>
                                                <AiOutlineEye size={18} />
                                                <span>{details?.total_views}</span>
                                            </div>
                                        }

                                        {!breakingNews && (
                                            <>
                                                <div className='flex items-center gap-1 textPrimary font-semibold'>
                                                    <span className='h-1.5 w-1.5 rounded-full bg-(--border-color) mr-2'></span>
                                                    <PiCalendarDots size={18} />
                                                    <span>{formatShortDate(newsDate ?? undefined)}</span>
                                                </div>
                                                {
                                                    newsItem && (newsItem?.total_like > 0 || extraLikes === 1) &&
                                                    <div className='flex items-center gap-1 textPrimary font-semibold'>
                                                        <span className='h-1.5 w-1.5 rounded-full bg-(--border-color) mr-2'></span>
                                                        <AiOutlineLike size={18} />
                                                        <span>{(newsItem?.total_like ?? 0) + extraLikes} {t('likes')}</span>
                                                    </div>
                                                }
                                            </>
                                        )}
                                    </div>

                                    {!breakingNews && (
                                        <div className='col-span-12 sm:col-span-3 flex items-center justify-around textPrimary gap-4'>
                                            <button className='border p-2 rounded-lg border-black dark:border-white cursor-pointer font-semibold flex items-center gap-2' onClick={() => setCommentsOpen(true)}>
                                                <span className='mt-1'>
                                                    <BiComment size={23} />
                                                </span>
                                                {t('comsLbl')}
                                            </button>
                                            <div className='border p-2 rounded-lg border-black dark:border-white cursor-pointer font-semibold' onClick={handleBookmark}>
                                                {bookmark && isLogin() ? <BiSolidBookmark size={23} /> : <BiBookmark size={23} />}
                                            </div>
                                            <div className='border p-2 rounded-lg border-black dark:border-white cursor-pointer font-semibold' onClick={handleLike}>
                                                {like && isLogin() ? <BiSolidLike size={23} /> : <BiLike size={23} />}
                                            </div>
                                        </div>
                                    )}
                                </div>

                                <div className='relative'>
                                    <PhotoGallery galleryPhotos={newsItem?.images} titleImage={details?.image} />
                                    {details?.content_value && (
                                        <LocalizedLink href={`/video-news/${details?.slug}`} title={details?.title}>
                                            <VideoPlayIcon />
                                        </LocalizedLink>
                                    )}
                                </div>

                                <div className='pt-7.5 border-t borderColor'>
                                    <NewsToolbar
                                        url={shareUrl}
                                        title={`${details?.title} - ${webSetting?.web_name ?? ''}`}
                                        hashtag={webSetting?.web_name}
                                        onSpeak={handleSpeak}
                                        isSpeaking={isSpeaking}
                                    />
                                </div>

                                {!breakingNews && !!newsItem?.tag?.length && (
                                    <div className='border-y borderColor flex flex-col gap-2 py-4'>
                                        <div className='flex items-center gap-2 textPrimary lg:text-xl font-semibold'>
                                            {t('tagLbl')}
                                        </div>
                                        <div className='flex items-center gap-4 flex-wrap'>
                                            {newsItem?.tag?.map((tag) => (
                                                <LocalizedLink
                                                    key={tag?.id}
                                                    href={`/tag/${tag?.slug}`}
                                                    title={tag?.tag_name}
                                                    className='commonBg textPrimary rounded-3xl border py-1 px-4 first-letter:capitalize'
                                                >
                                                    {tag?.tag_name}
                                                </LocalizedLink>
                                            ))}
                                        </div>
                                    </div>
                                )}

                                <div className='textPrimary newsDesc' style={{ fontSize: `${fontSize}px` }}>
                                    <RichTextContent content={details?.description ?? ''} />
                                </div>

                            </div>

                            {/* ad spaces */}
                            {adSpacesData.map((ad) => (
                                ad.placement === 'news_details_bottom' &&
                                <div className='mt-8 md:mt-12' key={ad?.id}>
                                    <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} container={true} />
                                </div>
                            ))}

                            {!breakingNews && newsItem?.category?.slug && (
                                <RelatedNewsSection newsSlug={newsSlug} categorySlug={newsItem?.category?.slug} />
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
                            {isLogin() && <SurveysSection key={newsSlug} />}

                            {!breakingNews && <TagSection />}

                        </div>
                    </div>
                </section>

                <OpenInAppPopUp IsOpenInApp={isOpenInApp} OnHide={() => setAppPromptDismissed(true)} />
            </section>

            <CommnetsSidebar
                open={commentsOpen}
                onOpenChange={setCommentsOpen}
                newsId={details?.id}
                languageCode={langCode}
                isCommentEnabled={breakingNews ? undefined : (details as typeof newsItem)?.is_comment}
            />
        </Layout>
    )
}

export default NewsDetails
