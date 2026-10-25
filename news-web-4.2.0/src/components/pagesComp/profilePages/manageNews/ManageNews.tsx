'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import { MdOutlineEdit, MdDeleteOutline, MdOutlineTimerOff, MdBlock } from 'react-icons/md'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import Meta from '@/components/common/Meta'
import ImagePreview from '@/components/common/ImagePreview'
import EmptyStatus from '@/components/common/EmptyStatus'
import LocalizedLink from '@/components/common/LocalizeLink'
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { useGetNews, NewsApi } from '@/hooks/queries/useGetNews'
import { useGetUserDraftedNews } from '@/hooks/queries/useGetUserDraftedNews'
import { deleteNewsApi } from '@/api/apiRoutes'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { setNewsToEdit } from '@/redux/reducers/createNewsSlice'
import { webName, truncateText, formatShortDate } from '@/components/utils/helpers'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import WithAuth from '@/components/hoc/WithAuth'
import ManagesNewsSkeleton from '@/components/skeletons/ManagesNewsSkeleton'

type ManageNewsTab = 'all' | 'draft'

const CONTENT_TYPE_LABEL_KEY: Record<string, string> = {
    video_upload: 'videoUploadLbl',
    standard_post: 'stdPostLbl',
    video_youtube: 'videoYoutubeLbl',
    video_other: 'videoOtherUrlLbl',
}

const ManageNews = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const router = useRouter()
    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const userData = useSelector(userDataSelector)

    const [activeTab, setActiveTab] = useState<ManageNewsTab>('all')
    const [deleteItemId, setDeleteItemId] = useState<number | null>(null)
    const [allNewsData, setAllNewsData] = useState<NewsApi[]>([])
    const [draftNewsData, setDraftNewsData] = useState<NewsApi[]>([])

    // Only authors get to manage news — bounce anyone else back to where
    // they can request authorship. Runs once the user record actually
    // arrives, not before (userData starts empty while it's loading).
    useEffect(() => {
        if (!userData?.id) return
        if (userData.is_author !== 1) {
            toast.error(t('onlyAuthorEditNews'))
            router.push(withLang('/profile-update', langCode, defaultLangCode))
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [userData?.id])

    const { data: allNewsQueryData, isLoading: isAllNewsLoading } = useGetNews({
        get_user_news: 1,
        enabled: activeTab === 'all',
        requireLanguageCode: false,
    })

    const [prevAllNewsData, setPrevAllNewsData] = useState<typeof allNewsQueryData | symbol>(() => Symbol('initial'))
    if (allNewsQueryData !== prevAllNewsData) {
        setPrevAllNewsData(allNewsQueryData)
        if (allNewsQueryData) {
            setAllNewsData(allNewsQueryData?.data?.data ?? [])
        }
    }

    const { data: draftNewsQueryData, isLoading: isDraftNewsLoading } = useGetUserDraftedNews({
        author_id: userData?.id,
        enabled: activeTab === 'draft',
    })

    const [prevDraftNewsData, setPrevDraftNewsData] = useState<typeof draftNewsQueryData | symbol>(() => Symbol('initial'))
    if (draftNewsQueryData !== prevDraftNewsData) {
        setPrevDraftNewsData(draftNewsQueryData)
        if (draftNewsQueryData) {
            setDraftNewsData(draftNewsQueryData?.data?.news?.data ?? [])
        }
    }

    const isLoading = activeTab === 'all' ? isAllNewsLoading : isDraftNewsLoading
    const listData = activeTab === 'all' ? allNewsData : draftNewsData

    const confirmDelete = async () => {
        if (!deleteItemId) return
        try {
            const response = await deleteNewsApi({ id: deleteItemId })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }
            toast.success(t('newsDeletedSuccessfully'))
            setAllNewsData((prev) => prev.filter((item) => item?.id !== deleteItemId))
            setDraftNewsData((prev) => prev.filter((item) => item?.id !== deleteItemId))
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setDeleteItemId(null)
        }
    }

    // Stash the article in redux and navigate — same flow as news-tailwind's
    // loadManageToEdit, so EditNews.tsx reads it back without a second fetch.
    const editNews = (item: NewsApi) => {
        dispatch(setNewsToEdit(item))
        router.push(withLang('/manage-news/edit-news', langCode, defaultLangCode))
    }

    const tabButtonClass = (tab: ManageNewsTab) =>
        `min-w-[200px] font-semibold rounded-lg py-2.5 px-6 transition-all cursor-pointer ${activeTab === tab ? 'secondaryBg text-white' : 'textPrimary'}`

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('manageNewsLbl')}`} />
                <Breadcrumb secondElement={t('manageNewsLbl')} />

                <section className='commonBg'>
                    <div className='manageNews container commonPY'>
                        <div className='flex flex-wrap justify-between items-center gap-3 bg-white dark:bodyBgColor commonRadius p-3 mb-6'>
                            <div className='flex flex-wrap gap-3'>
                                <button type='button' className={tabButtonClass('all')} onClick={() => setActiveTab('all')}>
                                    {t('allNewsLbl')}
                                </button>
                                <button type='button' className={tabButtonClass('draft')} onClick={() => setActiveTab('draft')}>
                                    {t('draftNewsLbl')}
                                </button>
                            </div>

                            <LocalizedLink href='/manage-news/create-news' title={t('createNewsLbl')} className='commonBtn font-semibold! flexCenter'>
                                {t('createNewsLbl')}
                            </LocalizedLink>
                        </div>

                        {
                            isLoading ? (
                                <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'>
                                    {[...Array(3)].map((_, index) => (
                                        <div key={index}><ManagesNewsSkeleton /></div>
                                    ))}
                                </div>
                            ) : listData.length > 0 ? (
                                <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6'>
                                    {listData.map((element) => (
                                        <div
                                            key={element?.id}
                                            className='manageNewsCard flex flex-col gap-3 customBgWhite border seconadryBorderColor py-4 commonRadius overflow-hidden '
                                        >
                                            <div className='flex items-center justify-between w-full px-3 sm:px-4 flex-wrap gap-4'>
                                                <div className='flex items-center gap-4'>
                                                    <div className='h-[60px] w-[60px] sm:h-[80px] sm:w-[80px]'>
                                                        <ImagePreview
                                                            src={element?.image}
                                                            alt={element?.title || 'news'}
                                                            objectFit='cover'
                                                            rounded='full'
                                                        />
                                                    </div>
                                                    <div>
                                                        <h2 className='textPrimary text-lg font-bold'>{element?.category?.category_name}</h2>
                                                        <time className='textSecondary font-medium text-sm'>{formatShortDate(element?.created_at || undefined)}</time>
                                                    </div>
                                                </div>
                                                {element?.tag_name && (
                                                    <span className='categoryTag !p-1 sm:!p-2 text-sm sm:text-base first-letter:capitalize'>{truncateText(element?.tag_name, 16)}</span>
                                                )}
                                            </div>

                                            <hr className='divider' />

                                            <div className='flex flex-col gap-2 px-3 sm:px-4'>
                                                <h3 className='textPrimary text-lg sm:text-xl font-bold leading-snug'>{truncateText(element?.title, 70)}</h3>
                                                {element?.sub_category && (
                                                    <div className='flex items-center gap-3 text-sm sm:text-base'>
                                                        <h4 className='textPrimary font-semibold'>{t('subcatLbl')}:</h4>
                                                        <p className='textSecondary font-semibold'>{element?.sub_category?.subcategory_name}</p>
                                                    </div>
                                                )}
                                                <div className='flex items-center gap-3 text-sm sm:text-base'>
                                                    <h5 className='textPrimary font-semibold'>{t('contentTypeLbl')}:</h5>
                                                    <p className='textSecondary font-semibold'>
                                                        {t(CONTENT_TYPE_LABEL_KEY[element?.content_type] || element?.content_type)}
                                                    </p>
                                                </div>

                                                {(element?.is_expired === 1 || element?.status === 0) && (
                                                    <>
                                                        <hr className='!mt-2 !mb-0 divider' />
                                                        <div className='flex flex-wrap items-center gap-4 sm:gap-12 mt-2 font-semibold text-base sm:text-lg text-[#E42B2B]'>
                                                            {element?.is_expired === 1 && (
                                                                <div className='flex items-center gap-2'>
                                                                    <MdOutlineTimerOff size={18} />
                                                                    <span>{t('expireNews')}</span>
                                                                </div>
                                                            )}
                                                            {element?.status === 0 && (
                                                                <div className='flex items-center gap-2'>
                                                                    <MdBlock size={18} />
                                                                    <span>{t('deactiveNews')}</span>
                                                                </div>
                                                            )}
                                                        </div>
                                                    </>
                                                )}
                                            </div>

                                            <hr className='divider' />

                                            <div className='flex items-center justify-end px-3 sm:px-4 mt-auto'>
                                                <div className='flex items-center gap-4 font-semibold'>
                                                    <button
                                                        type='button'
                                                        onClick={() => editNews(element)}
                                                        title={t('editLbl')}
                                                        className='flexCenter gap-1 py-1.5 px-4 secondaryBg border borderColor text-white rounded-md hover:opacity-90 transition-opacity'
                                                    >
                                                        <MdOutlineEdit size={16} />
                                                        {t('editLbl')}
                                                    </button>
                                                    <button
                                                        type='button'
                                                        onClick={() => setDeleteItemId(element?.id)}
                                                        className='flexCenter gap-1 py-1.5 px-4 bg-transparent border borderColor textPrimary rounded-md hover:bg-secondary/10 transition-colors'
                                                    >
                                                        <MdDeleteOutline size={16} />
                                                        {t('deleteTxt')}
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <EmptyStatus />
                            )
                        }

                        <AlertDialog open={deleteItemId !== null} onOpenChange={(open) => !open && setDeleteItemId(null)}>
                            <AlertDialogContent className='bg-white dark:bg-gray-900'>
                                <AlertDialogHeader>
                                    <AlertDialogTitle className='textPrimary'>{t('doYouReallyNewsLbl')}</AlertDialogTitle>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                    <AlertDialogCancel onClick={() => setDeleteItemId(null)} className='textPrimary'>{t('cancelBtn')}</AlertDialogCancel>
                                    <AlertDialogAction onClick={confirmDelete} className='primaryBg hover:hoverBg'>
                                        {t('deleteTxt')}
                                    </AlertDialogAction>
                                </AlertDialogFooter>
                            </AlertDialogContent>
                        </AlertDialog>
                    </div>
                </section>
            </>
        </Layout>
    )
}

export default WithAuth(ManageNews)