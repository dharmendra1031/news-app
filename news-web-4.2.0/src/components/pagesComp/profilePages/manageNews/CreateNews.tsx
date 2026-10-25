'use client'
import { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import Meta from '@/components/common/Meta'
import CreateNewsForm, { CreateNewsFormValues } from './CreateEditNewsForm'
import { setNewsApi, checkSlugAvailabilityApi } from '@/api/apiRoutes'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { useGetGeminiApiKey } from '@/hooks/queries/general/useGetGeminiApiKey'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { languagesListSelector } from '@/redux/reducers/languageSlice'
import { createNewsLanguageSelector, setCreateNewsLanguage } from '@/redux/reducers/createNewsSlice'
import { slugGenerator, validateSlugFormat, webName } from '@/components/utils/helpers'
import { generateContent } from '@/lib/aiCreateNews'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import WithAuth from '@/components/hoc/WithAuth'

const INITIAL_FORM_VALUES: CreateNewsFormValues = {
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

const CreateNews = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const router = useRouter()
    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const userData = useSelector(userDataSelector)
    const settingsData = useSelector(settingsSelector)
    const languagesList = useSelector(languagesListSelector)
    const createNewsLanguage = useSelector(createNewsLanguageSelector)
    const geminiApiKey = useGetGeminiApiKey()

    // Only authors get to create news — bounce anyone else back to where
    // they can request authorship, same gate ManageNews.tsx uses.
    useEffect(() => {
        if (!userData?.id) return
        if (userData.is_author !== 1) {
            toast.error(t('onlyAuthorsCanCreateNews'))
            router.push(withLang('/profile-update', langCode, defaultLangCode))
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [userData?.id])

    const [defaultValue, setDefaultValue] = useState<CreateNewsFormValues>(INITIAL_FORM_VALUES)
    const [images, setImages] = useState<File[]>([])
    const [content, setContent] = useState('')
    const [videoSet, setVideoSet] = useState(false)
    const [isGeneratingContent, setIsGeneratingContent] = useState(false)

    // When the site only has one active language, skip the picker and default
    // straight to it — done once, at render time, when settings actually load.
    const [syncedDefaultLanguage, setSyncedDefaultLanguage] = useState(false)
    if (!syncedDefaultLanguage && settingsData?.default_language && languagesList) {
        if (languagesList.length < 2) {
            setSyncedDefaultLanguage(true)
            const lang = settingsData.default_language
            dispatch(setCreateNewsLanguage({ name: lang.language, code: lang.code, id: lang.id }))
        } else if (languagesList.length > 0) {
            setSyncedDefaultLanguage(true)
        }
    }

    const handleChangeContent = (value: string) => setContent(value)

    const generateAIContent = async () => {
        if (!defaultValue.defaultTitle) {
            toast.error(t('pleaseEnterPromptForAI'))
            return
        }
        if (!geminiApiKey || !createNewsLanguage) {
            toast.error(t('somethingMSg'))
            return
        }

        setIsGeneratingContent(true)
        try {
            const generated = await generateContent({
                apiKey: geminiApiKey,
                title: defaultValue.defaultTitle,
                category: defaultValue.defaultCategory,
                language: createNewsLanguage.name,
                languageCode: createNewsLanguage.code,
                contentType: defaultValue.defaultType,
            })
            handleChangeContent(generated)
            toast.success(t('aiContentGeneratedSuccessfully'))
        } catch (error) {
            console.error('Error generating AI content:', error)
            toast.error(t('failedToGenerateAIContent'))
        } finally {
            setIsGeneratingContent(false)
        }
    }

    // Slug auto-fills from the title, debounced.
    useEffect(() => {
        const timeout = setTimeout(() => {
            setDefaultValue((prev) => ({ ...prev, defaultSlug: slugGenerator(prev.defaultTitle) }))
        }, 500)
        return () => clearTimeout(timeout)
    }, [defaultValue.defaultTitle])

    useEffect(() => {
        if (!defaultValue.defaultSlug) return
        const timeout = setTimeout(async () => {
            if (!validateSlugFormat(defaultValue.defaultSlug)) return
            try {
                const response = await checkSlugAvailabilityApi({ slug: defaultValue.defaultSlug })
                if (response?.error) toast.error(response?.message)
            } catch (error) {
                console.error('Error checking slug availability:', error)
            }
        }, 1500)
        return () => clearTimeout(timeout)
    }, [defaultValue.defaultSlug])

    useEffect(() => {
        if (defaultValue.defaultPublishDate && defaultValue.defaultStartDate && defaultValue.defaultPublishDate > defaultValue.defaultStartDate) {
            toast.error(t('dateConfirmation'))
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [defaultValue.defaultStartDate, defaultValue.defaultPublishDate])

    const finalSubmit = async (e: React.SyntheticEvent, isAddToDraft: 0 | 1 = 0) => {
        e.preventDefault()

        if (!defaultValue.defaultTitle) {
            toast.error(t('titlerequired'))
            return
        }
        if (!defaultValue.defaultSlug) {
            toast.error(t('slugrequired'))
            return
        }
        if (!createNewsLanguage) {
            toast.error(t('selectlanguage'))
            return
        }
        if (!defaultValue.defaultCategoryID) {
            toast.error(t('selectcategory'))
            return
        }
        if (!defaultValue.defaultType) {
            toast.error(t('contentTyperequired'))
            return
        }

        if (isAddToDraft !== 1) {
            if (!validateSlugFormat(defaultValue.defaultSlug)) {
                toast.error(t('slugValid'))
                return
            }
            if (defaultValue.defaultType === 'video_youtube') {
                if (!validateVideoUrl(defaultValue.defaultUrl)) {
                    toast.error(t('urlIsNotYouTubeVideo'))
                    return
                }
            } else if (defaultValue.defaultType === 'video_other') {
                if (validateVideoUrl(defaultValue.defaultUrl)) {
                    toast.error(t('YouTubeVideosNotSupported'))
                    return
                }
            } else if (defaultValue.defaultType === 'video_upload' && !videoSet) {
                toast.error(t('plzUploadVideoLbl'))
                return
            }
            if (!defaultValue.defaultImageData) {
                toast.error(t('uploadMainImageLbl'))
                return
            }
        }

        try {
            const response = await setNewsApi({
                is_draft: isAddToDraft,
                category_id: defaultValue.defaultCategoryID,
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
                language_code: createNewsLanguage.code,
                location_id: defaultValue.defaultLocation || undefined,
                is_short_news: defaultValue.shortNews ? 1 : 0,
            })

            if (!response || response?.error) {
                if (response?.message === 'The slug is already in use. Please choose another.') {
                    toast.error(t('slugUsedAlready'))
                } else {
                    toast.error(response?.message || t('somethingMSg'))
                }
                return
            }

            toast.success(t(isAddToDraft === 1 ? 'draftCreatedSuccessfully' : 'newsCreatedSuccessfully'))
            router.push(withLang('/manage-news', langCode, defaultLangCode))
        } catch (error) {
            console.error('Error creating news:', error)
            toast.error(t('somethingMSg'))
        }
    }

    const validateVideoUrl = (urlData: string) => {
        const videoUrlPattern = /^(?:http(?:s)?:\/\/)?(?:www\.)?(?:m\.)?(?:youtu\.be\/|youtube\.com\/((?:watch)\?(?:.*&)?v(?:i)?=|(?:embed|v|vi|user)\/))([^?&"'>]{11})/
        const shortsUrlPattern = /^(https?:\/\/)?(www\.)?(youtube\.com)\/(shorts)/
        if (videoUrlPattern.test(urlData)) return true
        if (shortsUrlPattern.test(urlData)) {
            toast.error(t('youtubeShortsNotSupported'))
        }
        return false
    }

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('createNewsLbl')}`} />
                <Breadcrumb secondElement={t('manageNewsLbl')} thirdElement={t('createNewsLbl')} manageNews />

                <div className='mt-6 lg:mt-12'>
                    <section className='createNews container'>
                        <CreateNewsForm
                            defaultValue={defaultValue}
                            setDefaultValue={setDefaultValue}
                            images={images}
                            setImages={setImages}
                            createNewsLanguage={createNewsLanguage}
                            setCreateNewsLanguage={(lang) => dispatch(setCreateNewsLanguage(lang))}
                            content={content}
                            handleChangeContent={handleChangeContent}
                            finalSubmit={finalSubmit}
                            isGeneratingContent={isGeneratingContent}
                            generateAIContent={generateAIContent}
                            setVideoSet={setVideoSet}
                        />
                    </section>
                </div>
            </>
        </Layout>
    )
}

export default WithAuth(CreateNews)
