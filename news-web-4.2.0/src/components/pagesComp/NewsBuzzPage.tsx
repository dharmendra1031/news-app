'use client'
import { useState, useEffect, useRef, useCallback, type SyntheticEvent } from 'react'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import { useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import EmptyStatus from '@/components/common/EmptyStatus'
import MediaShare from '@/components/common/MediaShare'
import OpenInAppPopUp from '@/components/common/OpenInAppPopUp'
import ImagePreview from '@/components/common/ImagePreview'
import ReactPlayer from 'react-player'
import { toast } from '@/lib/toast'
import { AiOutlineHeart, AiFillHeart } from 'react-icons/ai'
import { BiShareAlt, BiComment } from 'react-icons/bi'
import { FaTelegramPlane } from 'react-icons/fa'
import { useTranslation } from '@/hooks/useTranslation'
import { useDefaultLangCode, useLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { isLogin } from '@/components/utils/helpers'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { useGetVideoShorts, VideoShortApi } from '@/hooks/queries/useGetVideoShorts'
import {
    setVideoShortLikeDislikeApi,
    setVideoShortViewApi,
    setVideoShortSharesApi,
    getVideoShortCommentApi,
    setVideoShortCommentApi,
} from '@/api/apiRoutes'
import { usePageMode } from '@/hooks/usePageMode'
import WithPageMode from '../hoc/WithPageMode'

const REELS_PER_PAGE = 10

interface VideoShortCommentUser {
    id: number
    name: string
    profile: string | null
}

interface VideoShortComment {
    id: number
    comment: string
    user?: VideoShortCommentUser | null
}

// ─── Comment Panel ────────────────────────────────────────────────────────────
interface CommentPanelProps {
    commentsData: VideoShortComment[]
    isLoading: boolean
    commentText: string
    setCommentText: (text: string) => void
    onSubmit: (e: SyntheticEvent<HTMLFormElement>) => void
    isSubmitting: boolean
    userData: { profile?: string | null } | null
}

const CommentPanel = ({
    commentsData,
    isLoading,
    commentText,
    setCommentText,
    onSubmit,
    isSubmitting,
    userData,
}: CommentPanelProps) => {
    const { t } = useTranslation()

    return (
        <div className='rounded-2xl border borderColor commonBg p-4 flex flex-col gap-3 w-full'>
            {/* Comments list */}
            <div className='flex flex-col gap-3 max-h-full overflow-y-auto pr-1'>
                {isLoading ? (
                    <div className='flex flex-col gap-3'>
                        {[1, 2].map((i) => (
                            <div key={i} className='flex items-start gap-3 animate-pulse'>
                                <div className='w-10 h-10 rounded-full bg-gray-300 shrink-0' />
                                <div className='flex-1'>
                                    <div className='h-3 bg-gray-300 rounded w-24 mb-2' />
                                    <div className='h-3 bg-gray-200 rounded w-48' />
                                </div>
                            </div>
                        ))}
                    </div>
                ) : commentsData?.length > 0 ? (
                    commentsData.map((comment) => (
                        <div key={comment?.id} className='flex items-start gap-3'>
                            <div className='w-10 h-10 rounded-full overflow-hidden shrink-0'>
                                <ImagePreview
                                    src={comment?.user?.profile}
                                    alt={comment?.user?.name || 'user'}
                                    className='object-cover'
                                />
                            </div>
                            <div className='flex-1 min-w-0'>
                                <span className='textPrimary font-semibold text-sm truncate block'>
                                    {comment?.user?.name || t('user')}
                                </span>
                                <p className='text-sm textPrimary mt-0.5 break-words'>{comment?.comment}</p>
                            </div>
                        </div>
                    ))
                ) : (
                    <p className='text-sm textPrimary text-center py-2'>{t('noComments')}</p>
                )}
            </div>

            {
                isLogin() &&
                <form onSubmit={onSubmit} className='flex items-center gap-2 mt-1'>
                    <div className='w-9 h-9 rounded-full overflow-hidden shrink-0'>
                        <ImagePreview
                            src={userData?.profile}
                            alt='me'
                            className='object-cover'
                        />
                    </div>
                    <input
                        type='text'
                        value={commentText}
                        onChange={(e) => setCommentText(e.target.value)}
                        placeholder={t('addComment')}
                        className='flex-1 bg-[#1B2D511A] rounded-lg px-4 py-2 text-sm focus:outline-none textPrimary w-full'
                    />
                    <button
                        type='submit'
                        disabled={isSubmitting}
                        className='w-9 h-9 rounded-lg secondaryBg flexCenter text-white'
                    >
                        <FaTelegramPlane size={20} />

                    </button>
                </form>
            }
        </div >
    )
}

// ─── Single Reel ─────────────────────────────────────────────────────────────
interface ReelItemProps {
    reel: VideoShortApi
    index: number
    isActive: boolean
    // Mount the player only for the active reel and its neighbours, so the
    // next video is already buffered when the user swipes to it.
    shouldLoad: boolean
    liked: boolean
    likeCount: number
    commentCount: number
    onLike: (id: number) => void
    onShare: (reel: VideoShortApi) => void
    onComment: () => void
    reelRef: (el: HTMLDivElement | null) => void
}

const ReelItem = ({
    reel,
    index,
    isActive,
    shouldLoad,
    liked,
    likeCount,
    commentCount,
    onLike,
    onShare,
    onComment,
    reelRef,
}: ReelItemProps) => {
    const { t } = useTranslation()
    const videoUrl = reel?.video_url
    const [isPlaying, setIsPlaying] = useState(false)
    const [playKey, setPlayKey] = useState(0)

    useEffect(() => {
        if (isActive) {
            setPlayKey((prev) => prev + 1)
            setIsPlaying(true)
        } else {
            setIsPlaying(false)
        }
    }, [isActive])

    const [descExpanded, setDescExpanded] = useState(false)
    const [isDescClamped, setIsDescClamped] = useState(false)
    const descRef = useRef<HTMLParagraphElement>(null)

    useEffect(() => {
        const el = descRef.current
        if (el) {
            setIsDescClamped(el.scrollHeight > el.clientHeight)
        }
    }, [reel?.description])

    const handleVideoClick = () => setIsPlaying((prev) => !prev)

    return (
        <div
            ref={reelRef}
            data-index={index}
            className='relative w-full h-full snap-start snap-always shrink-0 bg-black rounded-2xl overflow-hidden'
        >

            {/* Video */}
            {videoUrl && shouldLoad && (
                <ReactPlayer
                    key={playKey}
                    src={videoUrl}
                    playing={isPlaying}
                    loop
                    playsInline
                    style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover' }}
                />
            )}

            {/* Click overlay for play/pause */}
            <div className='absolute inset-0 z-10 cursor-pointer' onClick={handleVideoClick} />

            {/* Gradient overlays */}
            <div className='absolute inset-0 bg-gradient-to-t from-black/100 via-transparent to-transparent pointer-events-none' />

            {/* Right action buttons */}
            <div className='absolute right-3 bottom-24 flex flex-col items-center gap-5 z-20'>
                {/* Like */}
                <button onClick={() => onLike(reel?.id)} className='flex flex-col items-center'>
                    <span className='bg-[#FFFFFF1A] p-1.5 rounded-full'>
                        {liked ? (
                            <AiFillHeart size={22} className='text-red-500' />
                        ) : (
                            <AiOutlineHeart size={22} className='text-white' />
                        )}
                    </span>
                    {
                        likeCount > 0 &&
                        <span className='text-white text-xs font-semibold'>{likeCount}</span>
                    }
                </button>

                {/* Comment */}
                <button onClick={onComment} className='flex flex-col items-center'>
                    <span className='bg-[#FFFFFF1A] p-1.5 rounded-full'>
                        <BiComment
                            size={20}
                            className='text-white'
                        />
                    </span>
                    {commentCount > 0 ? (
                        <span className='text-white text-xs font-semibold'>{commentCount}</span>
                    ) : null}
                </button>

                {/* Share */}
                <button onClick={() => onShare(reel)} className='flex flex-col items-center'>
                    <span className='bg-[#FFFFFF1A] p-1.5 rounded-full'>
                        <BiShareAlt size={20} className='text-white' />
                    </span>
                </button>

            </div>

            {/* Bottom info overlay */}
            <div className='absolute bottom-4 left-3 right-16 z-20'>
                <div className='flex flex-col gap-1'>
                    {reel?.title && (
                        <p className='text-white line-clamp-1 drop-shadow font-semibold'>
                            {reel?.title?.replace(/<[^>]*>/g, '')}
                        </p>
                    )}
                    {reel?.description && (
                        <div className='z-30 relative' onClick={(e) => e.stopPropagation()}>
                            <p
                                ref={descRef}
                                className={`text-white text-sm drop-shadow font-medium break-words ${descExpanded ? '' : 'line-clamp-3'}`}
                            >
                                {reel?.description}
                            </p>
                            {(isDescClamped || descExpanded) && (
                                <button
                                    className='text-red-500 text-sm font-semibold mt-0.5'
                                    onClick={() => setDescExpanded((prev) => !prev)}
                                >
                                    {descExpanded ? t('viewLess') : t('viewMore')}
                                </button>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

// ─── Main Page ────────────────────────────────────────────────────────────────
const NewsBuzzPage = () => {
    const { t } = useTranslation()
    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()
    const dispatch = useDispatch()
    const userData = useSelector(userDataSelector);
    const newsBuzzMode = usePageMode('news_buzz_mode');


    const router = useRouter();

    // Settings load after mount, so only redirect once we actually know the mode.
    useEffect(() => {
        if (newsBuzzMode !== undefined && !newsBuzzMode) {
            router.replace(withLang('/', langCode, defaultLangCode))
        }
    }, [newsBuzzMode, langCode, defaultLangCode, router])

    const queryClient = useQueryClient()

    const [reelsData, setReelsData] = useState<VideoShortApi[]>([])
    const [offset, setOffset] = useState(0)
    const [isAppending, setIsAppending] = useState(false)
    const [totalData, setTotalData] = useState(0)
    const [activeIndex, setActiveIndex] = useState(0)
    const [likeStates, setLikeStates] = useState<Record<number, boolean>>({})
    const [likeCounts, setLikeCounts] = useState<Record<number, number>>({})
    const [commentCounts, setCommentCounts] = useState<Record<number, number>>({})
    const [showComments, setShowComments] = useState(false)
    const [commentsData, setCommentsData] = useState<VideoShortComment[]>([])
    const [isCommentsLoading, setIsCommentsLoading] = useState(false)
    const [commentText, setCommentText] = useState('')
    const [isSubmittingComment, setIsSubmittingComment] = useState(false)
    const [shareReel, setShareReel] = useState<VideoShortApi | null>(null)

    const reelRefs = useRef<(HTMLDivElement | null)[]>([])
    const scrollContainerRef = useRef<HTMLDivElement | null>(null)
    const observerRef = useRef<IntersectionObserver | null>(null)
    const hasScrolledToSlugRef = useRef(false)

    const slugParam = typeof router.query.slug === 'string' ? router.query.slug : ''
    const isShare = !!router?.query?.share;
    const [isOpenInApp, setIsOpenInApp] = useState(false);

    useEffect(() => {
        setIsOpenInApp(isShare && window.innerWidth <= 768)
    }, [isShare])

    const currentURL = `${process.env.NEXT_PUBLIC_WEB_URL}${router?.asPath}`;

    const requireLogin = () => {
        if (isLogin()) return true

        dispatch(setLoginModalOpen(true))
        toast.error(t('loginFirst'))
        setTimeout(() => dispatch(setLoginModalOpen(false)), 2000)
        return false
    }

    // ── Data fetching ──────────────────────────────────────────────────────────
    // Only reset pagination when langCode actually *changes* — a plain
    // `[langCode]` effect also fires once on mount, which wiped out reelsData
    // right after it was synced from the hydrated SSR query data above.
    const prevLangCodeRef = useRef(langCode)
    useEffect(() => {
        if (prevLangCodeRef.current === langCode) return
        prevLangCodeRef.current = langCode
        setOffset(0)
        setIsAppending(false)
        setReelsData([])
    }, [langCode])

    const { data: reelsQueryData, isLoading, isFetching, isError } = useGetVideoShorts({
        language_code: langCode,
        offset: offset * REELS_PER_PAGE,
        limit: REELS_PER_PAGE,
    });

    // Synced during render (not a useEffect) so data already sitting in the
    // hydrated SSR cache paints on the very first render instead of only
    // after a post-commit effect — otherwise the page briefly (or, during
    // SSR, permanently in the emitted HTML) shows the empty state.
    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError && !isAppending) setReelsData([])
    }

    const [prevReelsQueryData, setPrevReelsQueryData] = useState<typeof reelsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && reelsQueryData !== prevReelsQueryData) {
        setPrevReelsQueryData(reelsQueryData)
        if (reelsQueryData) {
            const items = reelsQueryData?.data?.data || []
            setTotalData(reelsQueryData?.data?.total || 0)

            const newLikes: Record<number, boolean> = {}
            const newCounts: Record<number, number> = {}
            const newComments: Record<number, number> = {}
            items.forEach((item) => {
                newLikes[item.id] = item.is_liked === true
                newCounts[item.id] = item.total_like_count || 0
                newComments[item.id] = item.comments_count || 0
            })

            if (isAppending) {
                setReelsData((prev) => [...prev, ...items])
                setLikeStates((prev) => ({ ...prev, ...newLikes }))
                setLikeCounts((prev) => ({ ...prev, ...newCounts }))
                setCommentCounts((prev) => ({ ...prev, ...newComments }))
            } else {
                setReelsData(items)
                setLikeStates(newLikes)
                setLikeCounts(newCounts)
                setCommentCounts(newComments)
            }
        }
    }

    const isFetchingMore = isFetching && isAppending

    // ── IntersectionObserver ───────────────────────────────────────────────────
    useEffect(() => {
        if (observerRef.current) observerRef.current.disconnect()

        observerRef.current = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        const idx = parseInt((entry.target as HTMLElement).dataset.index || '', 10)
                        if (!isNaN(idx)) setActiveIndex(idx)
                    }
                })
            },
            // Observe against the feed itself, not the page viewport — otherwise
            // a feed partly scrolled off-screen never reaches the threshold.
            { root: scrollContainerRef.current, threshold: 0.6 }
        )

        reelRefs.current.forEach((ref) => {
            if (ref) observerRef.current?.observe(ref)
        })

        return () => observerRef.current?.disconnect()
    }, [reelsData]);


    const handleSetView = async (reelId?: number, setView = true) => {
        if (!reelId) return
        try {
            if (setView) {
                await setVideoShortViewApi({ video_shorts_id: reelId })
            } else {
                await setVideoShortSharesApi({ video_shorts_id: reelId })
            }
        } catch {
            console.log('Failed to set view')
        }
    }

    // ── Scroll to slug reel on initial load ───────────────────────────────────
    useEffect(() => {
        if (!slugParam || reelsData.length === 0 || hasScrolledToSlugRef.current) return
        const idx = reelsData.findIndex(r => r.slug === slugParam)
        if (idx !== -1) {
            hasScrolledToSlugRef.current = true
            setActiveIndex(idx)
            reelRefs.current[idx]?.scrollIntoView({ behavior: 'instant', block: 'start' })
            handleSetView(reelsData[idx]?.id)
        } else if (!isFetching && reelsData.length < totalData) {
            // Shared reel isn't in the pages loaded so far — keep paging until found.
            setIsAppending(true)
            setOffset((prev) => prev + 1)
        }
    }, [reelsData, slugParam, isFetching, totalData])

    // ── Load more / loop when near end ────────────────────────────────────────
    // Re-checked when a fetch settles too, not just on activeIndex — otherwise
    // reaching the end mid-fetch skipped the load and the feed dead-ended.
    useEffect(() => {
        if (reelsData.length === 0 || totalData === 0 || isFetching) return
        // The slug effect above owns paging until the shared reel is found.
        if (slugParam && !hasScrolledToSlugRef.current) return
        if (activeIndex >= reelsData.length - 3) {
            setIsAppending(true)
            if (reelsData.length < totalData) {
                setOffset((prev) => prev + 1)
            } else {
                // all pages loaded — invalidate so restarting from page 0 refetches
                // fresh data instead of replaying the cached first page forever.
                queryClient.invalidateQueries({ queryKey: ['video-shorts', langCode] })
                setOffset(0)
            }
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [activeIndex, isFetching, reelsData.length, totalData]);

    // ── Keyboard navigation (desktop) ─────────────────────────────────────────
    useEffect(() => {
        const onKeyDown = (e: KeyboardEvent) => {
            if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return
            const target = e.target as HTMLElement | null
            if (target?.closest('input, textarea, [contenteditable="true"]')) return
            const next = activeIndex + (e.key === 'ArrowDown' ? 1 : -1)
            const el = reelRefs.current[next]
            if (!el) return
            e.preventDefault()
            el.scrollIntoView({ behavior: 'smooth', block: 'start' })
        }
        window.addEventListener('keydown', onKeyDown)
        return () => window.removeEventListener('keydown', onKeyDown)
    }, [activeIndex]);

    // ── Comments ───────────────────────────────────────────────────────────────
    const activeReel = reelsData[activeIndex]

    const loadComments = useCallback(async (newsId?: number, suppressLoading?: boolean) => {
        if (!newsId) return
        setIsCommentsLoading(!suppressLoading)
        try {
            const response = await getVideoShortCommentApi({
                video_shorts_id: newsId,
                offset: 0,
                limit: 10,
            })
            // response.data is `{ total, data: <Laravel paginator> }` — the
            // paginator itself has the page's rows in its own `.data`, so the
            // array sits three levels deep: response.data.data.data.
            const payload = response?.data
            const items: VideoShortComment[] = Array.isArray(payload)
                ? payload
                : Array.isArray(payload?.data?.data)
                    ? payload.data.data
                    : Array.isArray(payload?.data)
                        ? payload.data
                        : []
            setCommentsData(items)
        } catch {
            setCommentsData([])
        } finally {
            setIsCommentsLoading(false)
        }
    }, [])

    useEffect(() => {
        if (showComments && activeReel?.id) {
            setCommentsData([])
            loadComments(activeReel.id)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [activeIndex, showComments])

    const handleToggleComments = () => {
        // Opening is handled by the [activeIndex, showComments] effect above —
        // firing loadComments here too raced two requests for the same
        // comments, and whichever settled second could stomp a good result.
        setShowComments((prev) => !prev)
    }

    const handleLike = async (reelId: number) => {
        if (!requireLogin()) return

        const current = likeStates[reelId]
        setLikeStates((prev) => ({ ...prev, [reelId]: !current }))
        setLikeCounts((prev) => ({ ...prev, [reelId]: current ? (prev[reelId] ?? 0) - 1 : (prev[reelId] ?? 0) + 1 }))

        const response = await setVideoShortLikeDislikeApi({ video_shorts_id: reelId, action: current ? 'dislike' : 'like' })
        if (!response || response?.error) {
            // revert on error
            setLikeStates((prev) => ({ ...prev, [reelId]: current }))
            setLikeCounts((prev) => ({ ...prev, [reelId]: current ? (prev[reelId] ?? 0) + 1 : (prev[reelId] ?? 0) - 1 }))
        }
    }

    const handleShare = (reel: VideoShortApi) => {
        setShareReel(reel)
        handleSetView(reel?.id, false)
    }

    const handleSubmitComment = async (e: SyntheticEvent<HTMLFormElement>) => {
        e.preventDefault()
        if (!requireLogin()) return

        if (!commentText.trim()) {
            toast.error(t('commentRequired'))
            return
        }
        setIsSubmittingComment(true)
        try {
            const response = await setVideoShortCommentApi({
                video_shorts_id: activeReel?.id,
                comment: commentText,
            })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
            } else {
                setCommentText('')
                setCommentCounts((prev) => ({ ...prev, [activeReel?.id]: (prev[activeReel?.id] ?? 0) + 1 }))
                loadComments(activeReel?.id, true)
            }
        } catch (err) {
            console.error(err)
        } finally {
            setIsSubmittingComment(false)
        }
    }

    // ── Skeleton ───────────────────────────────────────────────────────────────
    if (isLoading) {
        return (
            <Layout>
                <Breadcrumb secondElement={t('newsBuzz')} />
                <section className='container mt-8'>
                    <div className='flex justify-center'>
                        <div className='w-full max-w-[360px] aspect-[9/16] bg-gray-300 dark:bg-gray-700 rounded-2xl animate-pulse' />
                    </div>
                </section>
            </Layout>
        )
    }

    if (!isLoading && reelsData.length === 0) {
        return (
            <Layout>
                <Breadcrumb secondElement={t('newsBuzz')} />
                <section className='container mt-8'>
                    <EmptyStatus />
                </section>
            </Layout>
        )
    }

    return (
        <Layout>
            <>
                <Breadcrumb secondElement={t('newsBuzz')} />

                <section className='container mt-6 mb-8'>
                    <div className='flex flex-col lg:flex-row gap-6 items-start justify-center'>

                        {/* ── Reel feed ─────────────────────────────────────────────── */}
                        <div
                            className='w-full max-w-[360px] mx-auto lg:mx-0'
                            style={{ height: 'min(80vh, 640px)' }}
                        >
                            <div
                                ref={scrollContainerRef}
                                className='reel-scroll relative w-full h-full flex flex-col gap-4 overflow-y-scroll overscroll-contain snap-y snap-mandatory rounded-2xl'
                                style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' } as React.CSSProperties}
                            >
                                <style>{`
                                    .reel-scroll::-webkit-scrollbar { display: none; }
                                `}</style>

                                {reelsData.map((reel, index) => (
                                    <ReelItem
                                        // Looping back to page 0 appends reels already in the
                                        // list, so the id alone isn't a unique key.
                                        key={`${reel?.id}-${index}`}
                                        reel={reel}
                                        index={index}
                                        isActive={activeIndex === index}
                                        shouldLoad={Math.abs(activeIndex - index) <= 1}
                                        liked={!!likeStates[reel?.id]}
                                        likeCount={likeCounts[reel?.id] ?? reel?.total_like_count ?? 0}
                                        commentCount={commentCounts[reel?.id] ?? reel?.comments_count ?? 0}
                                        onLike={handleLike}
                                        onShare={handleShare}
                                        onComment={handleToggleComments}
                                        reelRef={(el) => { reelRefs.current[index] = el }}
                                    />
                                ))}

                                {isFetchingMore && (
                                    <div className='flex items-center justify-center h-16 shrink-0 bg-black rounded-2xl'>
                                        <div className='w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin' />
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* ── Comment panel (desktop sidebar) ───────────────────────── */}
                        {showComments && (
                            <div className='hidden lg:block w-full max-w-[300px] shrink-0 sticky top-24'>
                                <CommentPanel
                                    commentsData={commentsData}
                                    isLoading={isCommentsLoading}
                                    commentText={commentText}
                                    setCommentText={setCommentText}
                                    onSubmit={handleSubmitComment}
                                    isSubmitting={isSubmittingComment}
                                    userData={userData}
                                />
                            </div>
                        )}
                    </div>

                    {/* ── Comment panel (mobile bottom sheet) ───────────────────── */}
                    {showComments && (
                        <div className='fixed inset-0 z-50 lg:hidden' onClick={handleToggleComments}>
                            <div className='absolute inset-0 bg-black/50' />
                            <div
                                className='absolute bottom-0 left-0 right-0 bodyBgColor rounded-t-3xl p-4 pb-8'
                                onClick={(e) => e.stopPropagation()}
                            >
                                <div className='w-10 h-1 bg-gray-300 rounded-full mx-auto mb-4' />
                                <CommentPanel
                                    commentsData={commentsData}
                                    isLoading={isCommentsLoading}
                                    commentText={commentText}
                                    setCommentText={setCommentText}
                                    onSubmit={handleSubmitComment}
                                    isSubmitting={isSubmittingComment}
                                    userData={userData}
                                />
                            </div>
                        </div>
                    )}
                </section>

                {/* ── Share Modal ───────────────────────────────────────── */}
                {shareReel && (
                    <div
                        className='fixed inset-0 z-50 flex items-center justify-center'
                        onClick={() => setShareReel(null)}
                    >
                        <div className='absolute inset-0 bg-black/60' />
                        <div
                            className='relative bodyBgColor rounded-2xl p-6 w-full max-w-sm mx-4 flex flex-col gap-4'
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className='flex items-center justify-between absolute top-4 right-4'>
                                <button
                                    onClick={() => setShareReel(null)}
                                    className='textPrimary text-xl leading-none'
                                >
                                    ✕
                                </button>
                            </div>
                            <MediaShare
                                url={`${currentURL}?slug=${shareReel?.slug}`}
                                title={shareReel?.title?.replace(/<[^>]*>/g, '') || ''}
                                hashtag=''
                            />
                        </div>
                    </div>
                )}
            </>
            <OpenInAppPopUp IsOpenInApp={isOpenInApp} OnHide={() => setIsOpenInApp(false)} reelsPage={true} />
        </Layout>
    )
}

export default WithPageMode('news_buzz_mode')(NewsBuzzPage)
