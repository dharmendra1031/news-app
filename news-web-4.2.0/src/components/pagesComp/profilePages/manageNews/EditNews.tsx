'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import Meta from '@/components/common/Meta'
import CreateNewsForm, { CreateNewsFormValues, ExistingOtherImage } from './CreateEditNewsForm'
import { setNewsApi, deleteImagesApi } from '@/api/apiRoutes'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { newsToEditSelector, createNewsLanguageSelector, setCreateNewsLanguage } from '@/redux/reducers/createNewsSlice'
import { slugGenerator, validateSlugFormat, webName } from '@/components/utils/helpers'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import WithAuth from '@/components/hoc/WithAuth'

const EMPTY_FORM_VALUES: CreateNewsFormValues = {
    defaultTitle: '',
    defaultMetatitle: '',
    defaultMetaDescription: '',
    defaultMetaKeyword: '',
    defaultSlug: '',
    defaultCategory: null,
    defaultCategoryID: null,
    defaultSubCategory: null,
    defaultSubCategoryID: null,
    defaultSelector: '',
    defaultType: 'standard_post',
    defaultTag: '',
    defaultTagName: '',
    defaultSummary: '',
    defaultStartDate: null,
    defaultPublishDate: null,
    defaultUrl: '',
    defaultVideoData: null,
    defaultImageData: null,
    defaultImagefile: null,
    defaultLocation: null,
    shortNews: false,
}

const safelyCreateDate = (dateStr?: string | null): Date | null => {
    if (!dateStr || dateStr === '0000-00-00') return null
    const date = new Date(dateStr)
    return isNaN(date.getTime()) ? null : date
}

const EditNews = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const router = useRouter()
    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const userData = useSelector(userDataSelector)

    // Only authors get to edit news — same gate ManageNews.tsx/CreateNews.tsx use.
    useEffect(() => {
        if (!userData?.id) return
        if (userData.is_author !== 1) {
            toast.error(t('onlyAuthorEditNews'))
            router.push(withLang('/profile-update', langCode, defaultLangCode))
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [userData?.id])

    // The article to edit is stashed in redux by ManageNews.tsx's Edit button
    // (setNewsToEdit) — same flow as news-tailwind's loadManageToEdit /
    // selectManageNews, no separate fetch here.
    const newsItem = useSelector(newsToEditSelector)
    const createNewsLanguage = useSelector(createNewsLanguageSelector)

    const [defaultValue, setDefaultValue] = useState<CreateNewsFormValues>(EMPTY_FORM_VALUES)
    const [images, setImages] = useState<File[]>([])
    const [existingOtherImages, setExistingOtherImages] = useState<ExistingOtherImage[]>([])
    const [content, setContent] = useState('')
    const [videoSet, setVideoSet] = useState(false)

    // Seed the form from the staged article exactly once — done at render
    // time (not in an effect), same idiom the rest of this project's profile
    // pages use, so a later re-render doesn't stomp on what's being edited.
    const [syncedNewsId, setSyncedNewsId] = useState<number | null>(null)
    if (newsItem?.id && newsItem.id !== syncedNewsId) {
        setSyncedNewsId(newsItem.id)
        setDefaultValue({
            defaultTitle: newsItem.title || '',
            defaultMetatitle: newsItem.meta_title || '',
            defaultMetaDescription: newsItem.meta_description || '',
            defaultMetaKeyword: newsItem.meta_keyword || '',
            defaultSlug: newsItem.slug || '',
            defaultCategory: newsItem.category?.category_name || null,
            defaultCategoryID: newsItem.category_id ?? null,
            defaultSubCategory: newsItem.sub_category?.subcategory_name || null,
            defaultSubCategoryID: newsItem.subcategory_id || null,
            defaultSelector: '',
            defaultType: newsItem.content_type || 'standard_post',
            defaultTag: newsItem.tag_id || '',
            defaultTagName: newsItem.tag_name || '',
            defaultSummary: newsItem.summarized_description || '',
            defaultStartDate: safelyCreateDate(newsItem.show_till),
            defaultPublishDate: safelyCreateDate(newsItem.published_date),
            defaultUrl: newsItem.content_type !== 'video_upload' ? (newsItem.content_value || '') : '',
            defaultVideoData: null,
            defaultImageData: newsItem.image || null,
            defaultImagefile: null,
            defaultLocation: newsItem.location_id || null,
            shortNews: newsItem.is_short_news === 1,
        })
        setContent(newsItem.description || '')
        setExistingOtherImages((newsItem.images || []).map((img) => ({ id: img.id, other_image: img.other_image })))
        dispatch(setCreateNewsLanguage({ name: newsItem.language?.language || '', code: newsItem.language_code, id: newsItem.language_id }))
    }

    const handleChangeContent = (value: string) => setContent(value)

    const handleRemoveExistingImage = async (id: number) => {
        try {
            const response = await deleteImagesApi({ id })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }
            setExistingOtherImages((prev) => prev.filter((img) => img.id !== id))
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        }
    }

    // Slug auto-fills from the title, debounced — same as create.
    useEffect(() => {
        const timeout = setTimeout(() => {
            setDefaultValue((prev) => ({ ...prev, defaultSlug: slugGenerator(prev.defaultTitle) }))
        }, 500)
        return () => clearTimeout(timeout)
    }, [defaultValue.defaultTitle])

    useEffect(() => {
        if (defaultValue.defaultPublishDate && defaultValue.defaultStartDate && defaultValue.defaultPublishDate > defaultValue.defaultStartDate) {
            toast.error(t('dateConfirmation'))
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [defaultValue.defaultStartDate, defaultValue.defaultPublishDate])

    const validateVideoUrl = (urlData: string) => {
        const videoUrlPattern = /^(?:http(?:s)?:\/\/)?(?:www\.)?(?:m\.)?(?:youtu\.be\/|youtube\.com\/((?:watch)\?(?:.*&)?v(?:i)?=|(?:embed|v|vi|user)\/))([^?&"'>]{11})/
        const shortsUrlPattern = /^(https?:\/\/)?(www\.)?(youtube\.com)\/(shorts)/
        if (videoUrlPattern.test(urlData)) return true
        if (shortsUrlPattern.test(urlData)) {
            toast.error(t('youtubeShortsNotSupported'))
        }
        return false
    }

    const finalSubmit = async (e: React.SyntheticEvent, isAddToDraft: 0 | 1 = 0) => {
        e.preventDefault()
        if (!newsItem?.id) return

        if (!defaultValue.defaultTitle) {
            toast.error(t('titlerequired'))
            return
        }
        if (!defaultValue.defaultSlug) {
            toast.error(t('slugrequired'))
            return
        }

        if (isAddToDraft !== 1) {
            if (!validateSlugFormat(defaultValue.defaultSlug)) {
                toast.error(t('slugValid'))
                return
            }
            if (defaultValue.defaultType === 'video_youtube') {
                if (defaultValue.defaultUrl && !validateVideoUrl(defaultValue.defaultUrl)) {
                    toast.error(t('urlIsNotYouTubeVideo'))
                    return
                }
            } else if (defaultValue.defaultType === 'video_other') {
                if (defaultValue.defaultUrl && validateVideoUrl(defaultValue.defaultUrl)) {
                    toast.error(t('YouTubeVideosNotSupported'))
                    return
                }
            } else if (defaultValue.defaultType === 'video_upload' && !videoSet && !newsItem.content_value) {
                toast.error(t('plzUploadVideoLbl'))
                return
            }
        }

        try {
            const response = await setNewsApi({
                id: newsItem.id,
                is_draft: isAddToDraft,
                category_id: defaultValue.defaultCategoryID as number,
                subcategory_id: defaultValue.defaultSubCategoryID || undefined,
                tag_id: defaultValue.defaultTag || undefined,
                title: defaultValue.defaultTitle,
                meta_title: defaultValue.defaultMetatitle,
                meta_description: defaultValue.defaultMetaDescription,
                meta_keyword: defaultValue.defaultMetaKeyword,
                slug: defaultValue.defaultSlug,
                content_type: defaultValue.defaultType,
                content_data: defaultValue.defaultType === 'video_upload' ? undefined : defaultValue.defaultUrl,
                description: content,
                summarized_description: defaultValue.defaultSummary,
                image: defaultValue.defaultImagefile || undefined,
                otherImages: images,
                show_till: defaultValue.defaultStartDate?.toISOString().split('T')[0],
                published_date: defaultValue.defaultPublishDate?.toISOString().split('T')[0] || null,
                language_code: createNewsLanguage?.code,
                location_id: defaultValue.defaultLocation || undefined,
                is_short_news: defaultValue.shortNews ? 1 : 0,
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }

            toast.success(t('newsUpdatedSuccessfully'))
            router.push(withLang('/manage-news', langCode, defaultLangCode))
        } catch (error) {
            console.error('Error updating news:', error)
            toast.error(t('somethingMSg'))
        }
    }

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('editNewsLbl')}`} />
                <Breadcrumb secondElement={t('manageNewsLbl')} thirdElement={t('editNewsLbl')} manageNews />

                <div className='mt-6 lg:mt-12'>
                    <section className='createNews container'>
                        {
                            newsItem && (
                                <CreateNewsForm
                                    mode='edit'
                                    defaultValue={defaultValue}
                                    setDefaultValue={setDefaultValue}
                                    images={images}
                                    setImages={setImages}
                                    createNewsLanguage={createNewsLanguage}
                                    setCreateNewsLanguage={(lang) => dispatch(setCreateNewsLanguage(lang))}
                                    content={content}
                                    handleChangeContent={handleChangeContent}
                                    finalSubmit={finalSubmit}
                                    setVideoSet={setVideoSet}
                                    existingOtherImages={existingOtherImages}
                                    onRemoveExistingImage={handleRemoveExistingImage}
                                    existingVideoUrl={newsItem.content_type === 'video_upload' ? newsItem.content_value : null}
                                />
                            )
                        }
                    </section>
                </div>
            </>
        </Layout>
    )
}

export default WithAuth(EditNews)
