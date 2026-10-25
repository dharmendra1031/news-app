'use client'
import { useRef, useState, type ChangeEvent, type Dispatch, type SetStateAction, type SyntheticEvent } from 'react'
import { useSelector } from 'react-redux'
import DatePicker from 'react-datepicker'
import { addDays } from 'date-fns'
import Dropzone from 'react-dropzone'
import { Carousel, CarouselContent, CarouselItem } from '@/components/ui/carousel'
import { SlCalender } from 'react-icons/sl'
import { IoIosCloseCircle } from 'react-icons/io'
import { AiFillPicture, AiOutlineUpload } from 'react-icons/ai'
import { BsMagic, BsRobot } from 'react-icons/bs'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import ImagePreview from '@/components/common/ImagePreview'
import TipTapEditor from '@/components/common/TipTapEditor'
import LoadMoreSpinner from '@/components/common/loadermoreBtn/LoaderSpinner'
import MetaInfoToolTip from './MetaInfoToolTip'
import TagSelect from './TagSelect'
import { useTranslation } from '@/hooks/useTranslation'
import { useGetCategories, CategoryApi, SubCategoryApi } from '@/hooks/queries/general/useGetCategories'
import { useGetTags, TagApi } from '@/hooks/queries/useGetTags'
import { useGetLocations } from '@/hooks/queries/useGetLocations'
import { createTagApi } from '@/api/apiRoutes'
import { languagesListSelector } from '@/redux/reducers/languageSlice'
import { useGetGeminiApiKey } from '@/hooks/queries/general/useGetGeminiApiKey'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { CreateNewsLanguage } from '@/redux/reducers/createNewsSlice'
import { extractTextFromHTML, getDirection } from '@/components/utils/helpers'
import { generateMetaInfo, summarizeDescription } from '@/lib/aiCreateNews'
import { toast } from '@/lib/toast'
import WithAuth from '@/components/hoc/WithAuth'

export interface CreateNewsFormValues {
    defaultTitle: string
    defaultMetatitle: string
    defaultMetaDescription: string
    defaultMetaKeyword: string
    defaultSlug: string
    defaultCategory: string | null
    defaultCategoryID: number | null
    defaultSubCategory: string | null
    defaultSubCategoryID: number | null
    defaultSelector: string
    defaultType: string
    defaultTag: string
    defaultTagName: string
    defaultSummary: string
    defaultStartDate: Date | null
    defaultPublishDate: Date | null
    defaultUrl: string
    defaultVideoData: File | null
    defaultImageData: string | null
    defaultImagefile: File | null
    defaultLocation: number | null
    shortNews: boolean
}

interface StandardPostOption {
    id: number
    type: string
    name: string
    param: 'empty' | 'url' | 'file'
}

export interface ExistingOtherImage {
    id: number
    other_image: string
}

interface CreateNewsFormProps {
    /** Edit mode fixes the language, drops the Gemini shortcuts, and lets the
     * summary be typed by hand instead of only generated. */
    mode?: 'create' | 'edit'
    defaultValue: CreateNewsFormValues
    setDefaultValue: Dispatch<SetStateAction<CreateNewsFormValues>>
    images: File[]
    setImages: Dispatch<SetStateAction<File[]>>
    createNewsLanguage: CreateNewsLanguage | null
    setCreateNewsLanguage: (lang: CreateNewsLanguage) => void
    content: string
    handleChangeContent: (html: string) => void
    finalSubmit: (e: SyntheticEvent, isAddToDraft?: 0 | 1) => void
    /** Only used in create mode — the AI-assist buttons don't render in edit mode. */
    isGeneratingContent?: boolean
    generateAIContent?: () => void
    setVideoSet: (value: boolean) => void
    /** Already-uploaded gallery images — edit mode only. */
    existingOtherImages?: ExistingOtherImage[]
    onRemoveExistingImage?: (id: number) => void
    /** Current video_upload file's URL — shown in place of the picker until a new file is chosen. */
    existingVideoUrl?: string | null
}

const TAGS_LIMIT = 20

const CreateNewsForm = ({
    mode = 'create',
    defaultValue,
    setDefaultValue,
    images,
    setImages,
    createNewsLanguage,
    setCreateNewsLanguage,
    content,
    handleChangeContent,
    finalSubmit,
    isGeneratingContent = false,
    generateAIContent = () => {},
    setVideoSet,
    existingOtherImages = [],
    onRemoveExistingImage,
    existingVideoUrl,
}: CreateNewsFormProps) => {
    const { t } = useTranslation()

    const settingsData = useSelector(settingsSelector)
    const languagesList = useSelector(languagesListSelector)
    const geminiApiKey = useGetGeminiApiKey()

    const [isGeneratingMeta, setIsGeneratingMeta] = useState(false)
    const [isSummarizing, setIsSummarizing] = useState(false)

    const publishDateRef = useRef<DatePicker>(null)
    const showTillDateRef = useRef<DatePicker>(null)

    const standardPost: StandardPostOption[] = [
        { id: 1, type: t('stdPostLbl'), name: 'standard_post', param: 'empty' },
        { id: 2, type: t('videoYoutubeLbl'), name: 'video_youtube', param: 'url' },
        { id: 3, type: t('videoOtherUrlLbl'), name: 'video_other', param: 'url' },
        { id: 4, type: t('videoUploadLbl'), name: 'video_upload', param: 'file' },
    ]

    // Categories — fetched per selected language; subcategories come embedded
    // on each category row (`sub_categories`), same as FeedsFilter.tsx already
    // relies on, so there's no separate subcategory fetch/endpoint needed.
    const { data: categoriesData } = useGetCategories({
        language_code: createNewsLanguage?.code || '',
        limit: 70,
    })
    const categories: CategoryApi[] = categoriesData?.data?.data ?? []
    const subCategories: SubCategoryApi[] = categories.find((cat) => cat.id === defaultValue.defaultCategoryID)?.sub_categories ?? []

    // Locations — only needed when the site has location-tagged news enabled.
    const { data: locationsData } = useGetLocations({ limit: 10000, enabled: settingsData?.location_news_mode === '1' })
    const locations = locationsData?.data?.data ?? []

    // Tags — paginated, reset back to page one whenever the language changes.
    const [tagsOffset, setTagsOffset] = useState(0)
    const [tagsData, setTagsData] = useState<TagApi[]>([])
    const [syncedTagsLangCode, setSyncedTagsLangCode] = useState<string | null>(null)
    if (createNewsLanguage?.code && createNewsLanguage.code !== syncedTagsLangCode) {
        setSyncedTagsLangCode(createNewsLanguage.code)
        setTagsOffset(0)
        setTagsData([])
    }

    const { data: tagsQueryData } = useGetTags({
        language_code: createNewsLanguage?.code || '',
        limit: TAGS_LIMIT,
        offset: tagsOffset,
    })
    const [prevTagsQueryData, setPrevTagsQueryData] = useState<typeof tagsQueryData | symbol>(() => Symbol('initial'))
    if (tagsQueryData !== prevTagsQueryData) {
        setPrevTagsQueryData(tagsQueryData)
        if (tagsQueryData?.data) {
            const items = tagsQueryData.data.data ?? []
            setTagsData((prev) => (tagsOffset === 0 ? items : [...prev, ...items.filter((item) => !prev.some((p) => p.id === item.id))]))
        }
    }
    const hasMoreTags = (tagsQueryData?.data?.total ?? 0) > tagsData.length
    const handleLoadMoreTags = () => setTagsOffset((prev) => prev + TAGS_LIMIT)

    const handleCreateTag = async (newTagName: string) => {
        if (!createNewsLanguage?.code) throw new Error(t('selectlanguage'))
        const response = await createTagApi({ tag_name: newTagName, language_code: createNewsLanguage.code })
        if (response?.error) throw new Error(response?.message || t('failedToCreateTag'))
        return response?.data
    }

    const languageSelector = (lang: CreateNewsLanguage) => {
        setCreateNewsLanguage(lang)
        setDefaultValue((prev) => ({ ...prev, defaultCategoryID: null, defaultCategory: null, defaultSubCategoryID: null, defaultSubCategory: null }))
    }

    const categorySelector = (category: CategoryApi) => {
        setDefaultValue((prev) => ({
            ...prev,
            defaultCategoryID: category.id,
            defaultCategory: category.category_name,
            defaultSubCategoryID: null,
            defaultSubCategory: null,
        }))
    }

    const subcategorySelector = (subCategory: SubCategoryApi) => {
        setDefaultValue((prev) => ({ ...prev, defaultSubCategoryID: subCategory.id, defaultSubCategory: subCategory.subcategory_name }))
    }

    const handleTagChange = (values: string[], tagIds: (number | string)[]) => {
        setDefaultValue((prev) => ({ ...prev, defaultTag: tagIds.join(','), defaultTagName: values.join(',') }))
    }

    const handleVideo = (e: ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (file && !file.type.includes('video')) {
            toast.error(t('pleaseSelectVideoFormat'))
            return
        }
        setDefaultValue((prev) => ({ ...prev, defaultVideoData: file || null }))
        setVideoSet(true)
    }

    const postSelector = (contentType: StandardPostOption) => {
        if (defaultValue.defaultType === 'video_upload' && contentType.name !== 'video_upload') {
            setDefaultValue((prev) => ({ ...prev, defaultVideoData: null, defaultSelector: contentType.type, defaultType: contentType.name, defaultUrl: '' }))
            setVideoSet(false)
        } else {
            setDefaultValue((prev) => ({ ...prev, defaultSelector: contentType.type, defaultType: contentType.name, defaultUrl: '' }))
        }
    }

    const handleMainImage = (e: ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return
        if (!file.type.startsWith('image/')) {
            toast.error(t('pleaseSelectImageFile'))
            return
        }
        setDefaultValue((prev) => ({ ...prev, defaultImageData: URL.createObjectURL(file), defaultImagefile: file }))
    }

    const handleDrop = (acceptedFiles: File[]) => {
        const imageFiles = acceptedFiles.filter((file) => file.type.startsWith('image/'))
        if (acceptedFiles.length !== imageFiles.length) {
            toast.error(t('onlyImageFilesAllowed'))
            return
        }
        setImages((prev) => [...prev, ...imageFiles])
    }

    const handleRemoveOtherImage = (indexToRemove: number) => {
        setImages((prev) => prev.filter((_, index) => index !== indexToRemove))
    }

    const generateMetaInfoHandler = async (e: SyntheticEvent) => {
        e.preventDefault()
        if (!defaultValue.defaultTitle) {
            toast.error(t('addTitleToAutoGenerateMetaInfo'))
            return
        }
        if (!createNewsLanguage?.code) {
            toast.error(t('selectlanguage'))
            return
        }
        if (!geminiApiKey) {
            toast.error(t('somethingMSg'))
            return
        }

        setIsGeneratingMeta(true)
        try {
            const data = await generateMetaInfo({
                apiKey: geminiApiKey,
                title: defaultValue.defaultTitle,
                language: createNewsLanguage.name,
                languageCode: createNewsLanguage.code,
            })
            setDefaultValue((prev) => ({
                ...prev,
                defaultMetatitle: data.meta_title || '',
                defaultMetaDescription: data.meta_description || '',
                defaultMetaKeyword: data.meta_keywords || '',
                defaultSlug: data.slug || prev.defaultSlug,
            }))
            toast.success(t('metaInformationApplied'))
        } catch (error) {
            console.error('Error generating meta information:', error)
            toast.error(t('failedToGenerateMetaInfo'))
        } finally {
            setIsGeneratingMeta(false)
        }
    }

    const handleGenerateAIContent = (e: SyntheticEvent) => {
        e.preventDefault()
        if (!createNewsLanguage?.code) {
            toast.error(t('selectlanguage'))
            return
        }
        generateAIContent()
    }

    const handleSummarizeContent = async (e: SyntheticEvent) => {
        e.preventDefault()
        if (!content?.trim()) {
            toast.error(t('addContentToSummarize'))
            return
        }
        if (!geminiApiKey) {
            toast.error(t('somethingMSg'))
            return
        }

        setIsSummarizing(true)
        try {
            const summary = await summarizeDescription(geminiApiKey, content, createNewsLanguage?.name || 'English', createNewsLanguage?.code || 'en')
            if (summary) {
                setDefaultValue((prev) => ({ ...prev, defaultSummary: summary }))
                toast.success(t('summaryGenerated'))
            } else {
                toast.error(t('failedToGenerateSummary'))
            }
        } catch (error) {
            console.error('Error generating summary:', error)
            toast.error(t('failedToGenerateSummary'))
        } finally {
            setIsSummarizing(false)
        }
    }

    const contentText = extractTextFromHTML(content)

    const showUrl = defaultValue.defaultType === 'video_youtube'
    const otherUrl = defaultValue.defaultType === 'video_other'
    const videoUrl = defaultValue.defaultType === 'video_upload'

    return (
        <div>
            <div className='flex items-center justify-between mb-8'>
                <h1 className='text-[18px] md:text-2xl font-semibold textPrimary'>{t(mode === 'edit' ? 'editNewsLbl' : 'createNewsLbl')}</h1>
            </div>

            <form className='flex flex-col gap-2.5'>
                {/* Title */}
                <div>
                    <label htmlFor='title' className='text-base md:text-lg font-medium textPrimary'>{t('titleLbl')}</label>
                    <input
                        type='text'
                        id='title'
                        className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                        placeholder={t('titleLbl')}
                        value={defaultValue.defaultTitle}
                        onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultTitle: e.target.value }))}
                    />
                    {
                        mode === 'create' && (
                            <div className='flex items-center justify-between flex-wrap max-[450px]:mt-2'>
                                <span className='text-sm textPrimary font-medium'>{t('addTitleToAutoGenerateMetaInfo')}</span>
                                <button
                                    type='button'
                                    className={`${isGeneratingMeta || !defaultValue.defaultTitle ? 'py-1.5 px-3 bg-gray-500 rounded-[6px] text-gray-300 cursor-not-allowed!' : 'commonBtn'} mt-2 flexCenter text-sm`}
                                    onClick={generateMetaInfoHandler}
                                    disabled={isGeneratingMeta || !defaultValue.defaultTitle}
                                >
                                    {isGeneratingMeta ? t('generating') : <><BsMagic className='me-1' /> {t('autoGenerateMetaInfo')}</>}
                                </button>
                            </div>
                        )
                    }
                </div>

                {/* Language and Slug */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                    <div className=''>
                        <div className='flex flex-col gap-2'>
                            <label htmlFor='language' className='text-base md:text-lg font-medium textPrimary'>{t('language')}</label>
                            {
                                mode === 'create' && languagesList?.length > 1 ? (
                                    <Select<CreateNewsLanguage>
                                        value={createNewsLanguage || undefined}
                                        onValueChange={(lang) => lang && languageSelector(lang)}
                                        isItemEqualToValue={(a, b) => a?.code === b?.code}
                                        itemToStringLabel={(lang) => lang?.name || ''}
                                    >
                                        <SelectTrigger className={`h-10.5 customBgWhite ${createNewsLanguage ? 'text-black' : 'text-gray-500'}`}>
                                            <SelectValue placeholder={t('chooseLanLbl')} />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectGroup>
                                                {languagesList?.map((elem) => (
                                                    <SelectItem key={elem.id} value={{ name: elem.language, code: elem.code, id: elem.id }}>{elem.language}</SelectItem>
                                                ))}
                                            </SelectGroup>
                                        </SelectContent>
                                    </Select>
                                ) : (
                                    <div className='w-full h-10.5 customBgWhite text-black flex items-center border borderColor commonRadius px-4 py-2'>
                                        {mode === 'edit' ? createNewsLanguage?.name : settingsData?.default_language?.language}
                                    </div>
                                )
                            }
                        </div>
                    </div>

                    <div className='relative'>
                        <div className='flex items-center gap-2'>
                            <label htmlFor='slug' className='text-base md:text-lg font-medium textPrimary'>{t('slugLbl')}</label>
                            <MetaInfoToolTip info={t('slugWarningLbl')} />
                            <span className='text-sm textPrimary font-medium'>({t('englishOnly')})</span>
                        </div>
                        <input
                            type='text'
                            id='slug'
                            className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                            placeholder={t('slug')}
                            value={defaultValue.defaultSlug}
                            onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultSlug: e.target.value }))}
                        />
                    </div>
                </div>

                {/* Categories */}
                {
                    createNewsLanguage?.code && (
                        <div className={`grid grid-cols-1 ${subCategories.length > 0 ? 'md:grid-cols-2' : ''} gap-4`}>
                            <div className='mt-1'>
                                <div className='flex flex-col gap-2'>
                                    <label htmlFor='category' className='text-base md:text-lg font-medium textPrimary'>{t('catLbl')}</label>
                                    <Select<CategoryApi>
                                        value={categories.find((cat) => cat.id === defaultValue.defaultCategoryID)}
                                        onValueChange={(category) => category && categorySelector(category)}
                                        isItemEqualToValue={(a, b) => a?.id === b?.id}
                                        itemToStringLabel={(category) => category?.category_name || ''}
                                    >
                                        <SelectTrigger className={`h-[40px] customBgWhite ${defaultValue.defaultCategory ? 'text-black' : 'text-gray-500'}`}>
                                            <SelectValue placeholder={t('catLbl')} />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectGroup>
                                                {categories.map((elem) => (
                                                    <SelectItem key={elem.id} value={elem}>{elem.category_name}</SelectItem>
                                                ))}
                                            </SelectGroup>
                                        </SelectContent>
                                    </Select>
                                </div>
                            </div>

                            {
                                subCategories.length > 0 && (
                                    <div className='mt-1'>
                                        <div className='flex flex-col gap-2'>
                                            <label htmlFor='subcategory' className='text-base md:text-lg font-medium textPrimary'>{t('subcatLbl')}</label>
                                            <Select<SubCategoryApi>
                                                value={subCategories.find((sub) => sub.id === defaultValue.defaultSubCategoryID)}
                                                onValueChange={(subCategory) => subCategory && subcategorySelector(subCategory)}
                                                isItemEqualToValue={(a, b) => a?.id === b?.id}
                                                itemToStringLabel={(subCategory) => subCategory?.subcategory_name || ''}
                                            >
                                                <SelectTrigger className={`h-[40px] customBgWhite ${defaultValue.defaultSubCategory ? 'text-black' : 'text-gray-500'}`}>
                                                    <SelectValue placeholder={t('subcatLbl')} />
                                                </SelectTrigger>
                                                <SelectContent>
                                                    <SelectGroup>
                                                        {subCategories.map((elem) => (
                                                            <SelectItem key={elem.id} value={elem}>{elem.subcategory_name}</SelectItem>
                                                        ))}
                                                    </SelectGroup>
                                                </SelectContent>
                                            </Select>
                                        </div>
                                    </div>
                                )
                            }
                        </div>
                    )
                }

                {/* Tags and Post Type */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                    <div className='mt-1'>
                        <div className='flex flex-col gap-2'>
                            <label htmlFor='tags' className='text-base md:text-lg font-medium textPrimary'>{t('tagLbl')}</label>
                            <TagSelect
                                tagsData={tagsData}
                                defaultTag={defaultValue.defaultTag}
                                defaultTagName={defaultValue.defaultTagName}
                                handleTagChange={handleTagChange}
                                onCreateTag={handleCreateTag}
                                onLoadMore={handleLoadMoreTags}
                                hasMore={hasMoreTags}
                            />
                        </div>
                    </div>

                    <div className='mt-1'>
                        <div className='flex flex-col gap-2'>
                            <label htmlFor='postType' className='text-base md:text-lg font-medium textPrimary'>{t('postType')}</label>
                            <Select<StandardPostOption>
                                value={standardPost.find((post) => post.name === defaultValue.defaultType) || standardPost[0]}
                                onValueChange={(option) => option && postSelector(option)}
                                isItemEqualToValue={(a, b) => a?.id === b?.id}
                                itemToStringLabel={(option) => option?.type || ''}
                            >
                                <SelectTrigger className='h-[40px] customBgWhite text-black'>
                                    <SelectValue placeholder={t('stdPostLbl')} />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectGroup>
                                        {standardPost.map((elem) => (
                                            <SelectItem key={elem.id} value={elem}>{elem.type}</SelectItem>
                                        ))}
                                    </SelectGroup>
                                </SelectContent>
                            </Select>
                        </div>
                    </div>

                    {
                        showUrl && (
                            <input
                                type='text'
                                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none'
                                placeholder={t('youtubeUrlLbl')}
                                value={defaultValue.defaultUrl}
                                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultUrl: e.target.value }))}
                                required
                            />
                        )
                    }
                    {
                        otherUrl && (
                            <input
                                type='text'
                                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none'
                                placeholder={t('otherUrlLbl')}
                                value={defaultValue.defaultUrl}
                                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultUrl: e.target.value }))}
                                required
                            />
                        )
                    }
                    {
                        videoUrl && (
                            <div className='flex flex-col gap-2'>
                                {
                                    mode === 'edit' && existingVideoUrl && !defaultValue.defaultVideoData && (
                                        <a href={existingVideoUrl} target='_blank' rel='noreferrer' className='text-sm primaryColor underline break-all'>
                                            {existingVideoUrl}
                                        </a>
                                    )
                                }
                                <div className='relative customBgWhite border-2 border-dashed borderColor p-3 flexCenter commonRadius text-center cursor-pointer'>
                                    <input
                                        type='file'
                                        accept='video/*'
                                        className='absolute h-full w-full top-0 left-0 bottom-0 right-0 cursor-pointer opacity-0'
                                        onChange={handleVideo}
                                    />
                                    <div className='flexCenter text-gray-400 gap-2 justify-between! w-full'>
                                        {
                                            defaultValue.defaultVideoData?.name ? defaultValue.defaultVideoData.name : (
                                                <>
                                                    <span>{t('uploadVideoLbl')}</span>
                                                    <AiOutlineUpload />
                                                </>
                                            )
                                        }
                                    </div>
                                </div>
                            </div>
                        )
                    }
                </div>

                {/* Location */}
                {
                    settingsData?.location_news_mode === '1' && (
                        <div className='mt-1'>
                            <div className='flex flex-col gap-2'>
                                <label htmlFor='location' className='text-base md:text-lg font-medium textPrimary'>{t('location')}</label>
                                <Select<number>
                                    value={defaultValue.defaultLocation ?? undefined}
                                    onValueChange={(locationId) => setDefaultValue((prev) => ({ ...prev, defaultLocation: locationId }))}
                                >
                                    <SelectTrigger className={`h-[40px] customBgWhite ${defaultValue.defaultLocation ? 'text-black' : 'text-gray-500'}`}>
                                        <SelectValue placeholder={t('selLocationLbl')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectGroup>
                                            {locations.map((elem) => (
                                                <SelectItem key={elem.id} value={elem.id}>{elem.location_name}</SelectItem>
                                            ))}
                                        </SelectGroup>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>
                    )
                }

                {/* Publish Date and Show Till Date */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4 mb-2 mt-1'>
                    <div className='flex flex-col gap-2'>
                        <label htmlFor='publishDate' className='text-base md:text-lg font-medium textPrimary'>{t('publishDate')}</label>
                        <div className='datePickerWrapper flex items-center p-2 border borderColor commonRadius customBgWhite cursor-pointer' onClick={() => publishDateRef.current?.setOpen(true)}>
                            <DatePicker
                                ref={publishDateRef}
                                dateFormat='yyyy-MM-dd'
                                selected={defaultValue.defaultPublishDate}
                                placeholderText={t('publishDate')}
                                minDate={new Date()}
                                onChange={(date: Date | null) => setDefaultValue((prev) => ({ ...prev, defaultPublishDate: date }))}
                            />
                            <SlCalender className='form-calender' />
                        </div>
                    </div>

                    <div className='flex flex-col gap-2'>
                        <label htmlFor='showTilledDate' className='text-base md:text-lg font-medium textPrimary'>{t('showTilledDate')}</label>
                        <div className='datePickerWrapper flex items-center p-2 border borderColor commonRadius customBgWhite cursor-pointer' onClick={() => showTillDateRef.current?.setOpen(true)}>
                            <DatePicker
                                ref={showTillDateRef}
                                dateFormat='yyyy-MM-dd'
                                selected={defaultValue.defaultStartDate}
                                placeholderText={t('showTilledDate')}
                                minDate={addDays(new Date(), 1)}
                                onChange={(date: Date | null) => setDefaultValue((prev) => ({ ...prev, defaultStartDate: date }))}
                            />
                            <SlCalender className='form-calender' />
                        </div>
                    </div>
                </div>

                {/* Short News and Meta Title */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4 mb-2 mt-1'>
                    <div className='relative'>
                        <label htmlFor='shortNews' className='text-base md:text-lg font-medium textPrimary'>{t('shortNews')}</label>
                        <div className='w-full border borderColor commonRadius px-4 py-2 mt-2 customBgWhite flex items-center justify-between'>
                            <span className='text-gray-400'>{t('checkForShortNews')}</span>
                            <input
                                id='shortNews'
                                type='checkbox'
                                checked={defaultValue.shortNews}
                                onChange={(e) => setDefaultValue((prev) => ({ ...prev, shortNews: e.target.checked }))}
                            />
                        </div>
                    </div>
                    <div className='relative'>
                        <div className='flex items-center gap-2'>
                            <label htmlFor='metaTitle' className='text-base md:text-lg font-medium textPrimary'>{t('metaTitleLbl')}</label>
                            <MetaInfoToolTip info={t('metaTitleWarningLbl')} />
                        </div>
                        <input
                            type='text'
                            id='metaTitle'
                            className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                            placeholder={t('meta-title')}
                            value={defaultValue.defaultMetatitle}
                            onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultMetatitle: e.target.value }))}
                        />
                    </div>
                </div>

                {/* Meta Keywords and Description */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                    <div className='relative'>
                        <div className='flex items-center gap-2'>
                            <label htmlFor='metaKeywords' className='text-base md:text-lg font-medium textPrimary'>{t('meta-keywords')}</label>
                            <MetaInfoToolTip info={t('metaKeywordWarningLbl')} />
                        </div>
                        <textarea
                            id='metaKeywords'
                            className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                            placeholder={t('meta-keywords')}
                            value={defaultValue.defaultMetaKeyword}
                            onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultMetaKeyword: e.target.value }))}
                        />
                    </div>
                    <div>
                        <div className='flex items-center gap-2'>
                            <label htmlFor='metaDescription' className='text-base md:text-lg font-medium textPrimary'>{t('metaDescriptionLbl')}</label>
                            <MetaInfoToolTip info={t('metaDescriptionWarningLbl')} />
                        </div>
                        <textarea
                            id='metaDescription'
                            className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                            placeholder={t('meta-description')}
                            value={defaultValue.defaultMetaDescription}
                            onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultMetaDescription: e.target.value }))}
                        />
                    </div>
                </div>

                {/* Image Upload */}
                <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
                    <div className='mb-2'>
                        <div className='relative h-[100px] customBgWhite border borderColor p-4 flexCenter commonRadius text-center cursor-pointer hover:border-red-500 transition'>
                            <input
                                type='file'
                                accept='image/*'
                                className='absolute h-full w-full top-0 left-0 bottom-0 right-0 cursor-pointer opacity-0'
                                onChange={handleMainImage}
                            />
                            <div className='flexCenter text-gray-400 gap-2'>
                                <AiFillPicture />
                                <span>{t('uploadMainImageLbl')}</span>
                            </div>
                        </div>
                        {
                            defaultValue.defaultImageData && (
                                <div className='flex items-start justify-start mt-2 w-max relative'>
                                    <span
                                        onClick={() => setDefaultValue((prev) => ({ ...prev, defaultImageData: null, defaultImagefile: null }))}
                                        className='absolute top-0 right-0 bg-black text-white rounded-full cursor-pointer z-10'
                                    >
                                        <IoIosCloseCircle color='white'/>
                                    </span>
                                    <div className='h-24 w-24 border'>
                                    <ImagePreview src={defaultValue.defaultImageData} alt='Main upload' objectFit='cover' className='commonRadius' />
                                    </div>
                                </div>
                            )
                        }
                    </div>

                    <div>
                        <div className='relative h-[100px] flexCenter customBgWhite border borderColor p-4 commonRadius text-center cursor-pointer hover:border-red-500 transition'>
                            <Dropzone onDrop={handleDrop} multiple>
                                {({ getRootProps, getInputProps }) => (
                                    <div {...getRootProps()} className='dropzone'>
                                        <input {...getInputProps()} accept='image/*' />
                                        <div className='flexCenter text-gray-400 gap-2'>
                                            <AiFillPicture />
                                            <span>{t('uploadOtherImageLbl')}</span>
                                        </div>
                                    </div>
                                )}
                            </Dropzone>
                        </div>
                        {
                            (existingOtherImages.length > 0 || images.length > 0) && (
                                <div className='mt-3'>
                                    <Carousel opts={{ align: 'start', dragFree: true, containScroll: 'trimSnaps', direction: getDirection() }}>
                                        <CarouselContent className='-ms-2.5'>
                                            {existingOtherImages.map((image) => (
                                                <CarouselItem key={`existing-${image.id}`} className='basis-auto grow-0 shrink-0 ps-2.5'>
                                                    <div className='relative border borderColor commonRadius overflow-hidden h-[100px] w-[100px]'>
                                                        <span onClick={() => onRemoveExistingImage?.(image.id)} className='absolute top-0 right-0 bg-black text-white rounded-full cursor-pointer z-10'>
                                                            <IoIosCloseCircle />
                                                        </span>
                                                        <ImagePreview src={image.other_image} alt='Uploaded' objectFit='cover' />
                                                    </div>
                                                </CarouselItem>
                                            ))}
                                            {images.map((file, index) => (
                                                <CarouselItem key={index} className='basis-auto grow-0 shrink-0 ps-2.5'>
                                                    <div className='relative border borderColor commonRadius overflow-hidden h-[100px] w-[100px]'>
                                                        <span onClick={() => handleRemoveOtherImage(index)} className='absolute top-0 right-0 bg-black text-white rounded-full cursor-pointer z-10'>
                                                            <IoIosCloseCircle />
                                                        </span>
                                                        <ImagePreview src={URL.createObjectURL(file)} alt={`Uploaded ${index}`} objectFit='cover' />
                                                    </div>
                                                </CarouselItem>
                                            ))}
                                        </CarouselContent>
                                    </Carousel>
                                </div>
                            )
                        }
                    </div>
                </div>

                {/* Description */}
                <div className='flex flex-col gap-2 mt-4'>
                    <div className='flex items-center justify-between'>
                        <h2 className='text-[18px] font-[600] textPrimary'>{t('description')}</h2>
                        {
                            mode === 'create' && (
                                <button
                                    type='button'
                                    onClick={handleGenerateAIContent}
                                    disabled={isGeneratingContent || !defaultValue.defaultTitle}
                                    className={`${isGeneratingContent || !defaultValue.defaultTitle ? 'py-1.5 px-3 bg-gray-500 rounded-[6px] text-gray-300 cursor-not-allowed!' : 'commonBtn'} mt-2 flexCenter text-sm`}
                                >
                                    {isGeneratingContent ? t('generating') : <><BsRobot className='me-1' /> {t('generate')} {t('description')}</>}
                                </button>
                            )
                        }
                    </div>

                    <div className='detailPage flex flex-col gap-10'>
                        <TipTapEditor value={content} onChange={handleChangeContent} />
                        {
                            mode === 'edit' ? (
                                <div className='space-y-1'>
                                    <span className='text-lg textPrimary font-semibold'>{t('summarizedDescription')}</span>
                                    <textarea
                                        className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none'
                                        value={defaultValue.defaultSummary}
                                        onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultSummary: e.target.value }))}
                                    />
                                </div>
                            ) : contentText && (
                                <div className='flex flex-col gap-4'>
                                    <div className='space-y-1'>
                                        <span className='text-lg textPrimary font-semibold'>{t('summarizedDescription')} :</span>
                                        <div className='border borderColor p-3'>
                                            <p className='font-medium'>
                                                {
                                                    isSummarizing
                                                        ? <span className='text-gray-400 italic'>{t('generatingSummary')}</span>
                                                        : defaultValue.defaultSummary
                                                            ? defaultValue.defaultSummary
                                                            : <span className='text-gray-400'>{t('clickSummarizeDescription')}</span>
                                                }
                                            </p>
                                        </div>
                                    </div>

                                    <div className='flex justify-end'>
                                        <button
                                            type='button'
                                            className={`${isSummarizing ? 'cursor-not-allowed!' : ''} commonBtn w-max flex items-center gap-2`}
                                            onClick={handleSummarizeContent}
                                            disabled={isSummarizing}
                                        >
                                            {
                                                isSummarizing
                                                    ? <><LoadMoreSpinner /> {t('generatingSummary')}</>
                                                    : <><BsRobot className='text-sm' /> {t('summarizedDescription')}</>
                                            }
                                        </button>
                                    </div>
                                </div>
                            )
                        }
                    </div>

                    <div className='flex items-center gap-3 flex-wrap justify-end mt-6 md:mt-8'>
                        <button type='button' className='border borderColor textPrimary px-3 py-2 rounded-md text-[18px] font-semibold w-50' onClick={(e) => finalSubmit(e, 1)}>
                            {t('saveAsDraft')}
                        </button>
                        <button type='button' className='commonBtn px-3 py-2! text-[18px] font-semibold w-50' onClick={(e) => finalSubmit(e)}>
                            {t('submitBtn')}
                        </button>
                    </div>
                </div>
            </form>
        </div>
    )
}

export default WithAuth(CreateNewsForm)
