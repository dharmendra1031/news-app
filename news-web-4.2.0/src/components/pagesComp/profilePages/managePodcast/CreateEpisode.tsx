'use client'
import { useRef, useState, type ChangeEvent, type SyntheticEvent } from 'react'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import DatePicker from 'react-datepicker'
import { AiFillAudio, AiFillPicture } from 'react-icons/ai'
import { IoIosCloseCircle } from 'react-icons/io'
import { SlCalender } from 'react-icons/sl'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import ImagePreview from '@/components/common/ImagePreview'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { saveEpisodeApi } from '@/api/apiRoutes'
import { createdPodcastSelector, createdEpisodeSelector, resetCreatedPodcast, resetCreatedEpisode } from '@/redux/reducers/createPodcastSlice'
import { slugGenerator, validateSlugFormat } from '@/components/utils/helpers'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import WithAuth from '@/components/hoc/WithAuth'

type SourceType = 'youtube_link' | 'upload'

const SOURCE_TYPES: { value: SourceType; labelKey: string }[] = [
    { value: 'youtube_link', labelKey: 'youtubeUrlLbl' },
    { value: 'upload', labelKey: 'uploadAudioLbl' },
]

interface CreateEpisodeFormValues {
    defaultEpisodeNo: string
    defaultTitle: string
    defaultSlug: string
    defaultDescription: string
    defaultPublishDate: Date | null
    defaultSourceType: SourceType | ''
    defaultAudioUrl: string
    defaultAudioFile: File | null
    defaultImageData: string | null
    defaultImageFile: File | null
}

const INITIAL_FORM_VALUES: CreateEpisodeFormValues = {
    defaultEpisodeNo: '',
    defaultTitle: '',
    defaultSlug: '',
    defaultDescription: '',
    defaultPublishDate: new Date(),
    defaultSourceType: '',
    defaultAudioUrl: '',
    defaultAudioFile: null,
    defaultImageData: null,
    defaultImageFile: null,
}

const CreateEpisode = () => {
    const { t } = useTranslation()
    const router = useRouter()
    const dispatch = useDispatch()
    const langCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const isEditEpisode = router.pathname?.includes('edit-episode')
    const createdPodcast = useSelector(createdPodcastSelector)
    const createdEpisode = useSelector(createdEpisodeSelector)

    const publishDateRef = useRef<DatePicker>(null)
    const [isSubmitting, setIsSubmitting] = useState(false)
    const [defaultValue, setDefaultValue] = useState<CreateEpisodeFormValues>(INITIAL_FORM_VALUES)

    // Seed the form from the staged episode exactly once when editing — done
    // at render time (not in an effect), same idiom this project's other
    // profile pages use, so a later re-render doesn't stomp on what's being edited.
    const [syncedEpisodeId, setSyncedEpisodeId] = useState<number | null>(null)
    if (isEditEpisode && createdEpisode?.id && createdEpisode.id !== syncedEpisodeId) {
        setSyncedEpisodeId(createdEpisode.id)
        setDefaultValue({
            defaultEpisodeNo: createdEpisode.episode_no ? String(createdEpisode.episode_no) : '',
            defaultTitle: createdEpisode.title || '',
            defaultSlug: createdEpisode.slug || '',
            defaultDescription: createdEpisode.description || '',
            defaultPublishDate: createdEpisode.published_at ? new Date(createdEpisode.published_at.replace(' ', 'T')) : null,
            defaultSourceType: (createdEpisode.source_type as SourceType) || '',
            defaultAudioUrl: createdEpisode.audio_url || '',
            defaultAudioFile: null,
            defaultImageData: createdEpisode.image || null,
            defaultImageFile: null,
        })
    }

    const handleMainImage = (e: ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return
        if (!file.type.startsWith('image/')) {
            toast.error(t('pleaseSelectImageFile'))
            return
        }
        setDefaultValue((prev) => ({ ...prev, defaultImageData: URL.createObjectURL(file), defaultImageFile: file }))
    }

    const handleAudioFile = (e: ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return
        if (!file.type.startsWith('audio/')) {
            toast.error(t('audioRequired'))
            return
        }
        setDefaultValue((prev) => ({ ...prev, defaultAudioFile: file }))
    }

    // Slug auto-fills from the title, debounced — same as create-podcast.
    const slugTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
    const handleTitleChange = (title: string) => {
        setDefaultValue((prev) => ({ ...prev, defaultTitle: title }))
        if (slugTimeoutRef.current) clearTimeout(slugTimeoutRef.current)
        slugTimeoutRef.current = setTimeout(() => {
            setDefaultValue((prev) => ({ ...prev, defaultSlug: slugGenerator(title) }))
        }, 500)
    }

    const finalSubmit = async (e: SyntheticEvent, isAddToDraft: 0 | 1 = 0) => {
        e.preventDefault()

        const podcastId = createdPodcast?.id || createdEpisode?.podcast_id
        if (!podcastId) {
            toast.error(t('podcastRequired'))
            return
        }
        if (!defaultValue.defaultEpisodeNo) {
            toast.error(t('episodeNoRequired'))
            return
        }
        if (!defaultValue.defaultTitle) {
            toast.error(t('titlerequired'))
            return
        }
        if (!defaultValue.defaultSlug || !validateSlugFormat(defaultValue.defaultSlug)) {
            toast.error(t('slugValid'))
            return
        }
        if (!defaultValue.defaultDescription) {
            toast.error(t('descriptionisrequire'))
            return
        }
        if (!defaultValue.defaultPublishDate) {
            toast.error(t('publishDateRequired'))
            return
        }
        if (!defaultValue.defaultSourceType) {
            toast.error(t('sourceTypeRequired'))
            return
        }
        if (defaultValue.defaultSourceType === 'youtube_link' && !defaultValue.defaultAudioUrl) {
            toast.error(t('youtubeUrlLbl'))
            return
        }
        if (!isEditEpisode && defaultValue.defaultSourceType === 'upload' && !defaultValue.defaultAudioFile) {
            toast.error(t('audioRequired'))
            return
        }
        if (!isEditEpisode && !defaultValue.defaultImageFile) {
            toast.error(t('uploadMainImageLbl'))
            return
        }

        const publishDate = defaultValue.defaultPublishDate
        const formattedPublishDate = `${publishDate.getFullYear()}-${String(publishDate.getMonth() + 1).padStart(2, '0')}-${String(publishDate.getDate()).padStart(2, '0')}`

        setIsSubmitting(true)
        try {
            const response = await saveEpisodeApi({
                episode_id: isEditEpisode ? createdEpisode?.id : undefined,
                podcast_id: podcastId,
                title: defaultValue.defaultTitle,
                slug: defaultValue.defaultSlug,
                episode_no: Number(defaultValue.defaultEpisodeNo),
                description: defaultValue.defaultDescription,
                published_date: formattedPublishDate,
                is_draft: isAddToDraft,
                source_type: defaultValue.defaultSourceType,
                audio_url: defaultValue.defaultSourceType === 'youtube_link' ? defaultValue.defaultAudioUrl : undefined,
                audio_file: defaultValue.defaultSourceType === 'upload' ? defaultValue.defaultAudioFile || undefined : undefined,
                image: defaultValue.defaultImageFile || undefined,
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }

            toast.success(t(isAddToDraft === 1 ? 'draftCreatedSuccessfully' : (isEditEpisode ? 'episodeUpdatedSuccessfully' : 'episodeCreatedSuccessfully')))
            router.push(withLang(`/manage-podcast/${createdPodcast?.slug}`, langCode, defaultLangCode))
            dispatch(resetCreatedPodcast())
            dispatch(resetCreatedEpisode())
        } catch (error) {
            console.error('Error saving episode:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <Layout>
            <>
                <Breadcrumb
                    secondElement={t('managePodcast')}
                    thirdElement={t(isEditEpisode ? 'editEpisode' : 'createEpisode')}
                    podcastPage
                    managePodcast
                />
                <section className='container commonMT'>
                    <form className='flex flex-col gap-5'>
                        {/* Podcast */}
                        <div>
                            <label htmlFor='podcast' className='text-base md:text-lg font-medium textPrimary'>{t('podcast')}</label>
                            <div className='w-full h-10 customBgWhite text-black mt-2 flex items-center border borderColor commonRadius px-4 py-2'>
                                {createdPodcast?.title}
                            </div>
                        </div>

                        <div className='grid grid-cols-1 sm:grid-cols-2 gap-6'>
                            {/* Episode No */}
                            <div>
                                <label htmlFor='episodeNo' className='text-base md:text-lg font-medium textPrimary'>{t('episodeNoLbl')}</label>
                                <input
                                    id='episodeNo'
                                    type='number'
                                    className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                                    placeholder={t('episodeNoLbl')}
                                    value={defaultValue.defaultEpisodeNo}
                                    onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultEpisodeNo: e.target.value }))}
                                />
                            </div>

                            {/* Episode Title */}
                            <div>
                                <label htmlFor='title' className='text-base md:text-lg font-medium textPrimary'>{t('episodeTitleLbl')}</label>
                                <input
                                    id='title'
                                    type='text'
                                    className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                                    placeholder={t('episodeTitleLbl')}
                                    value={defaultValue.defaultTitle}
                                    onChange={(e) => handleTitleChange(e.target.value)}
                                />
                            </div>
                        </div>

                        {/* Slug */}
                        <div>
                            <label htmlFor='slug' className='text-base md:text-lg font-medium textPrimary'>{t('slugLbl')}</label>
                            <input
                                id='slug'
                                type='text'
                                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                                placeholder={t('slug')}
                                value={defaultValue.defaultSlug}
                                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultSlug: e.target.value }))}
                            />
                        </div>

                        {/* Episode Description */}
                        <div>
                            <label htmlFor='description' className='text-base md:text-lg font-medium textPrimary'>{t('episodeDescriptionLbl')}</label>
                            <textarea
                                id='description'
                                rows={4}
                                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                                placeholder={t('episodeDescriptionLbl')}
                                value={defaultValue.defaultDescription}
                                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultDescription: e.target.value }))}
                            />
                        </div>

                        <div className='grid grid-cols-1 sm:grid-cols-2 gap-6'>
                            {/* Publish Date */}
                            <div>
                                <label htmlFor='publishDate' className='text-base md:text-lg font-medium textPrimary'>{t('publishDate')}</label>
                                <div
                                    className='datePickerWrapper flex items-center justify-between p-2 border borderColor commonRadius customBgWhite mt-2 cursor-pointer'
                                    onClick={() => publishDateRef.current?.setOpen(true)}
                                >
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

                            {/* Source Type */}
                            <div>
                                <label htmlFor='sourceType' className='text-base md:text-lg font-medium textPrimary'>{t('selectSourceTypeLbl')}</label>
                                <Select<SourceType>
                                    value={defaultValue.defaultSourceType || undefined}
                                    onValueChange={(value) => value && setDefaultValue((prev) => ({ ...prev, defaultSourceType: value, defaultAudioUrl: '', defaultAudioFile: null }))}
                                >
                                    <SelectTrigger className={`h-[40px] customBgWhite mt-2 ${defaultValue.defaultSourceType ? 'text-black' : 'text-gray-500'}`}>
                                        <SelectValue placeholder={t('selectSourceTypeLbl')} />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectGroup>
                                            {SOURCE_TYPES.map((elem) => (
                                                <SelectItem key={elem.value} value={elem.value}>{t(elem.labelKey)}</SelectItem>
                                            ))}
                                        </SelectGroup>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>

                        {/* YouTube URL */}
                        {
                            defaultValue.defaultSourceType === 'youtube_link' && (
                                <div>
                                    <label htmlFor='audioUrl' className='text-base md:text-lg font-medium textPrimary'>{t('youtubeUrlLbl')}</label>
                                    <input
                                        id='audioUrl'
                                        type='text'
                                        className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                                        placeholder={t('youtubeUrlLbl')}
                                        value={defaultValue.defaultAudioUrl}
                                        onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultAudioUrl: e.target.value }))}
                                    />
                                </div>
                            )
                        }

                        {/* Upload Audio */}
                        {
                            defaultValue.defaultSourceType === 'upload' && (
                                <div>
                                    <div className='relative h-[100px] customBgWhite border border-dashed borderColor p-4 flexCenter commonRadius text-center cursor-pointer hover:border-red-500 transition'>
                                        <input
                                            type='file'
                                            accept='audio/*'
                                            className='absolute h-full w-full top-0 left-0 bottom-0 right-0 cursor-pointer opacity-0'
                                            onChange={handleAudioFile}
                                        />
                                        <div className='flexCenter flex-col text-gray-400 gap-2'>
                                            <AiFillAudio className='text-2xl' />
                                            <span>{defaultValue.defaultAudioFile?.name || t('uploadAudioLbl')}</span>
                                        </div>
                                    </div>
                                    {
                                        isEditEpisode && !defaultValue.defaultAudioFile && defaultValue.defaultAudioUrl && (
                                            <div className='mt-2 customBgWhite rounded-xl p-4 border'>
                                                <audio controls src={defaultValue.defaultAudioUrl} className='w-full' />
                                            </div>
                                        )
                                    }
                                </div>
                            )
                        }

                        {/* Upload Main Image */}
                        <div>
                            <div className='relative h-[140px] customBgWhite border border-dashed borderColor p-4 flexCenter commonRadius text-center cursor-pointer hover:border-red-500 transition'>
                                <input
                                    type='file'
                                    accept='image/*'
                                    className='absolute h-full w-full top-0 left-0 bottom-0 right-0 cursor-pointer opacity-0'
                                    onChange={handleMainImage}
                                />
                                <div className='flexCenter flex-col text-gray-400 gap-2'>
                                    <AiFillPicture className='text-2xl' />
                                    <span>{t('uploadMainImageLbl')}</span>
                                </div>
                            </div>
                            {
                                defaultValue.defaultImageData && (
                                    <div className='flex items-start justify-start mt-2 w-max relative'>
                                        <span
                                            onClick={() => setDefaultValue((prev) => ({ ...prev, defaultImageData: null, defaultImageFile: null }))}
                                            className='absolute top-0 right-0 bg-black text-white rounded-full cursor-pointer z-1'
                                        >
                                            <IoIosCloseCircle />
                                        </span>
                                        <div className='h-30 w-30 border commonRadius'>
                                            <ImagePreview src={defaultValue.defaultImageData} alt='Main upload' objectFit='cover' className='commonRadius' />
                                        </div>
                                    </div>
                                )
                            }
                        </div>

                        {/* Footer Buttons */}
                        <div className='flex items-center gap-3 flex-wrap justify-end mt-4'>
                            <button
                                type='button'
                                className='border secondaryBorder px-3 py-2 rounded-md text-[18px] font-semibold w-50 disabled:opacity-50 disabled:cursor-not-allowed'
                                onClick={(e) => finalSubmit(e, 1)}
                                disabled={isSubmitting}
                            >
                                {t('saveAsDraft')}
                            </button>
                            <button
                                type='button'
                                className='commonBtn px-3 py-2! text-[18px] font-semibold w-50 disabled:opacity-50 disabled:cursor-not-allowed'
                                onClick={(e) => finalSubmit(e)}
                                disabled={isSubmitting}
                            >
                                {t(isEditEpisode ? 'update' : 'publishBtn')}
                            </button>
                        </div>
                    </form>
                </section>
            </>
        </Layout>
    )
}

export default WithAuth(CreateEpisode)