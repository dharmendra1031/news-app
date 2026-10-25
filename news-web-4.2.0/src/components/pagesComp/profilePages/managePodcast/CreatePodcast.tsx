'use client'
import { useRef, useState, type ChangeEvent, type SyntheticEvent } from 'react'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import DatePicker from 'react-datepicker'
import { AiFillPicture } from 'react-icons/ai'
import { IoIosCloseCircle } from 'react-icons/io'
import { SlCalender } from 'react-icons/sl'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import ImagePreview from '@/components/common/ImagePreview'
import MetaInfoToolTip from '@/components/pagesComp/profilePages/manageNews/MetaInfoToolTip'
import { savePodcastApi } from '@/api/apiRoutes'
import { createdPodcastSelector, podcastCreated } from '@/redux/reducers/createPodcastSlice'
import { slugGenerator, validateSlugFormat } from '@/components/utils/helpers'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import WithAuth from '@/components/hoc/WithAuth'

interface CreatePodcastFormValues {
  defaultTitle: string
  defaultSlug: string
  defaultDescription: string
  defaultPublishDate: Date | null
  defaultImageData: string | null
  defaultImageFile: File | null
  defaultMetaTitle: string
  defaultMetaDescription: string
  defaultMetaKeyword: string
  defaultSchemaMarkup: string
}

const INITIAL_FORM_VALUES: CreatePodcastFormValues = {
  defaultTitle: '',
  defaultSlug: '',
  defaultDescription: '',
  defaultPublishDate: new Date(),
  defaultImageData: null,
  defaultImageFile: null,
  defaultMetaTitle: '',
  defaultMetaDescription: '',
  defaultMetaKeyword: '',
  defaultSchemaMarkup: '',
}

const CreatePodcast = () => {
  const { t } = useTranslation()
  const router = useRouter()
  const dispatch = useDispatch()
  const langCode = useLangCode()
  const defaultLangCode = useDefaultLangCode()

  const isEditPodcast = router.pathname?.includes('edit-podcast')
  const createdPodcast = useSelector(createdPodcastSelector)

  const publishDateRef = useRef<DatePicker>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [defaultValue, setDefaultValue] = useState<CreatePodcastFormValues>(INITIAL_FORM_VALUES)

  // Seed the form from the staged podcast exactly once when editing — done
  // at render time (not in an effect), same idiom this project's other
  // profile pages use, so a later re-render doesn't stomp on what's being edited.
  const [syncedPodcastId, setSyncedPodcastId] = useState<number | null>(null)
  if (isEditPodcast && createdPodcast?.id && createdPodcast.id !== syncedPodcastId) {
    setSyncedPodcastId(createdPodcast.id)
    const podcast = createdPodcast as Partial<typeof createdPodcast> & { published_at?: string; description?: string; image?: string; meta_title?: string; meta_description?: string; meta_keyword?: string; schema_markup?: string }
    setDefaultValue({
      defaultTitle: podcast.title || '',
      defaultSlug: podcast.slug || '',
      defaultDescription: podcast.description || '',
      defaultPublishDate: podcast.published_at ? new Date(podcast.published_at.replace(' ', 'T')) : null,
      defaultImageData: podcast.image || null,
      defaultImageFile: null,
      defaultMetaTitle: podcast.meta_title || '',
      defaultMetaDescription: podcast.meta_description || '',
      defaultMetaKeyword: podcast.meta_keyword || '',
      defaultSchemaMarkup: podcast.schema_markup || '',
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

  // Slug auto-fills from the title, debounced — same as create-news.
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
    if (!isEditPodcast && !defaultValue.defaultImageFile) {
      toast.error(t('uploadMainImageLbl'))
      return
    }

    const publishDate = defaultValue.defaultPublishDate
    const formattedPublishDate = `${publishDate.getFullYear()}-${String(publishDate.getMonth() + 1).padStart(2, '0')}-${String(publishDate.getDate()).padStart(2, '0')}`

    setIsSubmitting(true)
    try {
      const response = await savePodcastApi({
        id: isEditPodcast ? createdPodcast?.id : undefined,
        title: defaultValue.defaultTitle,
        slug: defaultValue.defaultSlug,
        description: defaultValue.defaultDescription,
        published_date: formattedPublishDate,
        draft: isAddToDraft,
        image: defaultValue.defaultImageFile || undefined,
        meta_title: defaultValue.defaultMetaTitle,
        meta_description: defaultValue.defaultMetaDescription,
        meta_keyword: defaultValue.defaultMetaKeyword,
        schema_markup: defaultValue.defaultSchemaMarkup,
      })

      if (!response || response?.error) {
        toast.error(response?.message || t('somethingMSg'))
        return
      }

      dispatch(podcastCreated(response?.data))
      toast.success(t(isAddToDraft === 1 ? 'draftCreatedSuccessfully' : (isEditPodcast ? 'podcastUpdatedSuccessfully' : 'podcastCreatedSuccessfully')))
      router.push(withLang('/manage-podcast', langCode, defaultLangCode))
    } catch (error) {
      console.error('Error saving podcast:', error)
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
          thirdElement={t(isEditPodcast ? 'editPodcast' : 'createPodcast')}
          podcastPage
          managePodcast
        />
        <section className='container commonMT'>
          <form className='flex flex-col gap-5'>
            {/* Title */}
            <div>
              <label htmlFor='title' className='text-base md:text-lg font-medium textPrimary'>{t('podcastTitleLbl')}</label>
              <input
                id='title'
                type='text'
                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                placeholder={t('podcastTitleLbl')}
                value={defaultValue.defaultTitle}
                onChange={(e) => handleTitleChange(e.target.value)}
              />
            </div>

            {/* Slug and Publish Date */}
            <div className='grid grid-cols-1 sm:grid-cols-2 gap-6'>
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
                    minDate={isEditPodcast ? undefined : new Date()}
                    onChange={(date: Date | null) => setDefaultValue((prev) => ({ ...prev, defaultPublishDate: date }))}
                  />
                  <SlCalender className='form-calender' />
                </div>
              </div>
            </div>

            {/* Description */}
            <div>
              <label htmlFor='description' className='text-base md:text-lg font-medium textPrimary'>{t('podcastDescriptionLbl')}</label>
              <textarea
                id='description'
                rows={4}
                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                placeholder={t('podcastDescriptionLbl')}
                value={defaultValue.defaultDescription}
                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultDescription: e.target.value }))}
              />
            </div>

            {/* Meta Title */}
            <div>
              <div className='flex items-center gap-2'>
                <label htmlFor='metaTitle' className='text-base md:text-lg font-medium textPrimary'>{t('metaTitleLbl')}</label>
                <MetaInfoToolTip info={t('metaTitleWarningLbl')} />
              </div>
              <input
                id='metaTitle'
                type='text'
                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                placeholder={t('meta-title')}
                value={defaultValue.defaultMetaTitle}
                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultMetaTitle: e.target.value }))}
              />
            </div>

            {/* Meta Keywords and Meta Description */}
            <div className='grid grid-cols-1 md:grid-cols-2 gap-4'>
              <div>
                <div className='flex items-center gap-2'>
                  <label htmlFor='metaKeywords' className='text-base md:text-lg font-medium textPrimary'>{t('meta-keywords')}</label>
                  <MetaInfoToolTip info={t('metaKeywordWarningLbl')} />
                </div>
                <textarea
                  id='metaKeywords'
                  rows={3}
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
                  rows={3}
                  className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                  placeholder={t('meta-description')}
                  value={defaultValue.defaultMetaDescription}
                  onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultMetaDescription: e.target.value }))}
                />
              </div>
            </div>

            {/* Schema Markup */}
            <div>
              <div className='flex items-center gap-2'>
                <label htmlFor='schemaMarkup' className='text-base md:text-lg font-medium textPrimary'>{t('schemaMarkupLbl')}</label>
                <MetaInfoToolTip info={t('schemaMarkupWarningLbl')} />
              </div>
              <textarea
                id='schemaMarkup'
                rows={4}
                className='w-full border borderColor commonRadius px-4 py-2 mt-2 focus:outline-none customBgWhite'
                placeholder={t('schemaMarkupLbl')}
                value={defaultValue.defaultSchemaMarkup}
                onChange={(e) => setDefaultValue((prev) => ({ ...prev, defaultSchemaMarkup: e.target.value }))}
              />
            </div>

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
                className='border borderColor textPrimary px-3 py-2 rounded-md text-[18px] font-semibold w-50 disabled:opacity-50 disabled:cursor-not-allowed'
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
                {t(isEditPodcast ? 'update' : 'publishBtn')}
              </button>
            </div>
          </form>
        </section>
      </>
    </Layout>
  )
}

export default WithAuth(CreatePodcast)
