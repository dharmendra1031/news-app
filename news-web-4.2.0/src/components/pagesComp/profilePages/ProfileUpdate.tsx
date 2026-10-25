'use client'
import { useState, type ChangeEvent, type SyntheticEvent } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useQueryClient } from '@tanstack/react-query'
import 'react-phone-number-input/style.css'
import PhoneInput, { Country, isValidPhoneNumber, Value } from 'react-phone-number-input'
import { FaCamera } from 'react-icons/fa'
import { IoMdInformationCircleOutline } from 'react-icons/io'
import { MdOutlineVerified } from 'react-icons/md'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import ImagePreview from '@/components/common/ImagePreview'
import profileSectImg from '@/assets/images/Profile.svg'
import { updateProfileApi, becomeAuthorApi } from '@/api/apiRoutes'
import { isNewUserSelector, userDataSelector } from '@/redux/reducers/userSlice'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { isLogin, webName } from '@/components/utils/helpers'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import Meta from '@/components/common/Meta'
import LanguageSwitcher from '@/components/dropdownsAndModals/LanguageSwitcher'
import WithAuth from '@/components/hoc/WithAuth'

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

interface ProfileFormValues {
    name: string
    email: string
    bio: string
    telegram: string
    whatsapp: string
    facebook: string
    linkedin: string
}

interface FormErrors {
    name?: string
    email?: string
    mobile?: string
}

const ProfileUpdate = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const queryClient = useQueryClient()

    const userData = useSelector(userDataSelector)
    const settingsData = useSelector(settingsSelector)
    const isNewUser = useSelector(isNewUserSelector)

    const [languageModalOpen, setLanguageModalOpen] = useState(false)
    const [previewImage, setPreviewImage] = useState<string | null>(null)
    const [selectedImageFile, setSelectedImageFile] = useState<File | null>(null)
    const [pendingAuthorRequest, setPendingAuthorRequest] = useState(false)
    const [saving, setSaving] = useState(false)
    const [formErrors, setFormErrors] = useState<FormErrors>({})
    const [mobileValue, setMobileValue] = useState<Value | undefined>(undefined)

    const emptyValues: ProfileFormValues = {
        name: '',
        email: '',
        bio: '',
        telegram: '',
        whatsapp: '',
        facebook: '',
        linkedin: '',
    }

    const [formValues, setFormValues] = useState<ProfileFormValues>(emptyValues)
    // Snapshot of what's actually saved server-side — diffed against
    // `formValues`/`mobileValue` on submit so only edited fields go out,
    // instead of resubmitting the whole form on every save.
    const [initialValues, setInitialValues] = useState<ProfileFormValues & { mobile: string }>({ ...emptyValues, mobile: '' })

    // Seed the form from redux exactly once per user — done at render time
    // (not in an effect), matching this project's other profile pages, so a
    // later re-render doesn't stomp on what the user's currently typing.
    const [syncedUserId, setSyncedUserId] = useState<number | null>(null)
    if (userData?.id && userData.id !== syncedUserId) {
        setSyncedUserId(userData.id)
        const seeded: ProfileFormValues = {
            name: userData.name || '',
            email: userData.email || '',
            bio: userData.author?.bio || '',
            telegram: userData.author?.telegram_link || '',
            whatsapp: userData.author?.whatsapp_link || '',
            facebook: userData.author?.facebook_link || '',
            linkedin: userData.author?.linkedin_link || '',
        }
        setFormValues(seeded)
        setInitialValues({ ...seeded, mobile: userData.mobile || '' })
        setMobileValue((userData.mobile as Value) || undefined)
    }

    const isAuthor = userData?.is_author === 1
    const authorStatus = userData?.author?.status
    const showAuthorFields = isAuthor || pendingAuthorRequest || authorStatus === 'pending'

    // Email/mobile are the identifiers tied to the sign-in method, so the one
    // used to authenticate can't be changed from here — only the other one.
    const isEmailLocked = userData?.type === 'email' || userData?.type === 'google'
    const isMobileLocked = userData?.type === 'mobile'

    const requireLogin = () => {
        if (isLogin()) return true
        dispatch(setLoginModalOpen(true))
        toast.error(t('loginFirst'))
        setTimeout(() => dispatch(setLoginModalOpen(false)), 2000)
        return false
    }

    const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target
        setFormValues((prev) => ({ ...prev, [name]: value }))
    }

    const validate = (values: ProfileFormValues): FormErrors => {
        const errors: FormErrors = {}
        if (!values.name.trim()) {
            errors.name = t('nameRequired')
        }
        if (!isEmailLocked && values.email && !EMAIL_PATTERN.test(values.email)) {
            errors.email = t('emailValid')
        }
        if (!isMobileLocked && mobileValue && !isValidPhoneNumber(mobileValue)) {
            errors.mobile = t('mblValid')
        }
        return errors
    }

    const handleImageChange = (e: ChangeEvent<HTMLInputElement>) => {
        const selectedFile = e.target.files?.[0]
        if (!selectedFile) return

        if (!selectedFile.type.startsWith('image/')) {
            toast.error(t('pleaseSelectImageFile'))
            return
        }

        setPreviewImage(URL.createObjectURL(selectedFile))
        setSelectedImageFile(selectedFile)
    }

    const handleBecomeAuthorReq = () => {
        setPendingAuthorRequest(true)
        toast.info(t('fillBioAndSocialMsg'))
    }

    const handleSubmit = async (e: SyntheticEvent<HTMLFormElement>) => {
        e.preventDefault()
        if (!requireLogin()) return

        const errors = validate(formValues)
        setFormErrors(errors)
        if (Object.keys(errors).length > 0) return

        const currentMobile = mobileValue || ''

        // Only send fields that actually changed — the API updates whatever
        // it's given, so submitting the whole form on every save would blow
        // away unrelated fields as a side effect of e.g. swapping the avatar.
        const payload: Parameters<typeof updateProfileApi>[0] = {}
        if (formValues.name !== initialValues.name) payload.name = formValues.name
        if (!isEmailLocked && formValues.email !== initialValues.email) payload.email = formValues.email
        if (!isMobileLocked && currentMobile !== initialValues.mobile) payload.mobile = currentMobile
        if (selectedImageFile) payload.profile = selectedImageFile
        if (showAuthorFields) {
            if (formValues.bio !== initialValues.bio) payload.bio = formValues.bio
            if (formValues.telegram !== initialValues.telegram) payload.telegram_link = formValues.telegram
            if (formValues.whatsapp !== initialValues.whatsapp) payload.whatsapp_link = formValues.whatsapp
            if (formValues.facebook !== initialValues.facebook) payload.facebook_link = formValues.facebook
            if (formValues.linkedin !== initialValues.linkedin) payload.linkedin_link = formValues.linkedin
        }

        // if (Object.keys(payload).length === 0 && !pendingAuthorRequest) return

        setSaving(true)
        try {
            if (Object.keys(payload).length > 0) {
                const response = await updateProfileApi(payload)

                if (!response || response?.error) {
                    toast.error(response?.message || t('somethingMSg'))
                    return
                }

                toast.success(t('profileUpdateMsg'))
                setInitialValues({ ...formValues, mobile: currentMobile })
                setSelectedImageFile(null)
                setPreviewImage(null)
                queryClient.invalidateQueries({ queryKey: ['userDetails'] })

                // New signups land here first — once their profile is saved,
                // walk them into picking a language and category preferences.
            }

            if (pendingAuthorRequest) {
                const authorResponse = await becomeAuthorApi()
                if (!authorResponse || authorResponse?.error) {
                    toast.error(authorResponse?.message || t('somethingMSg'))
                } else {
                    toast.success(t('authorRequestSuccessMsg'))
                    setPendingAuthorRequest(false)
                    queryClient.invalidateQueries({ queryKey: ['userDetails'] })
                }
            }
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            if (isNewUser) setLanguageModalOpen(true)
            setSaving(false)
        }
    }

    const renderAuthorStatus = () => {
        if (authorStatus === 'pending') {
            return (
                <div className='border text-sm text-[#017A80] font-normal border-[#017A80] bg-[#E7FFFF] w-fit flex items-center justify-center gap-1 p-1 rounded'>
                    <IoMdInformationCircleOutline color='#017A80' size={22} />
                    {t('pendingReview')}
                </div>
            )
        }
        if (isAuthor && authorStatus === 'approved') {
            return (
                <div className='w-fit text-[#060F72] py-1 px-4 bg-[#E7EEFF] flex items-center gap-1 border border-[#060F72] text-sm font-medium p-1 rounded mb-4'>
                    <MdOutlineVerified size={22} />
                    {t('author')}
                </div>
            )
        }
        return (
            <button
                type='button'
                className='border border-[#1B2D51] rounded px-2 py-1 text-sm font-normal textPrimary'
                onClick={handleBecomeAuthorReq}
            >
                {t('becomeAnAuthor')}
            </button>
        )
    }

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('update-profile')}`} />
                <Breadcrumb secondElement={t('update-profile')} />

                <section className='updateProfile container mt-8 md:mt-12 pb-12'>
                    <div className='grid grid-cols-1 lg:grid-cols-2 gap-8'>
                        <div className='flexCenter w-auto h-auto'>
                            <ImagePreview
                                src={profileSectImg}
                                alt='update-profile'
                                objectFit='contain'
                            />
                        </div>

                        <form className='flex items-center justify-center' onSubmit={handleSubmit}>
                            <div className='w-full max-w-2xl p-6 border borderColor commonRadius'>
                                <div className='flex flex-col items-center'>
                                    {/* Profile Image */}
                                    <div className='flex self-start w-full border borderColor commonRadius p-3'>
                                        <div className='flex flex-wrap self-start justify-center gap-6'>
                                            <div className='relative w-24 h-24'>
                                                <ImagePreview
                                                    src={previewImage || userData?.profile}
                                                    alt='profile'
                                                    objectFit='cover'
                                                    rounded='full'
                                                    bordered
                                                />
                                                <label
                                                    htmlFor='profileImageInput'
                                                    className='absolute bottom-0 left-1/2 md:left-16 primaryBg h-8 w-8 flexCenter rounded-full p-1 text-white cursor-pointer'
                                                >
                                                    <FaCamera />
                                                </label>
                                            </div>
                                            <input
                                                type='file'
                                                id='profileImageInput'
                                                accept='image/*'
                                                className='hidden'
                                                disabled={saving}
                                                onChange={handleImageChange}
                                            />
                                            <div className='flex flex-col items-center md:items-start gap-3'>
                                                <div className='flex flex-col items-center md:items-start gap-1'>
                                                    <div className='textPrimary font-medium text-base'>{userData?.name}</div>
                                                    <div className='font-normal textPrimary text-sm text-wrap'>{userData?.email}</div>
                                                </div>
                                                {renderAuthorStatus()}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Profile Info */}
                                    <div className='mt-8 flex flex-col gap-6 w-full'>
                                        <div>
                                            <div className='border borderColor commonRadius p-2 textPrimary'>
                                                <label htmlFor='name' className='block text-[14px] font-normal'>{t('your-name')}</label>
                                                <input
                                                    type='text'
                                                    name='name'
                                                    id='name'
                                                    className='w-full font-semibold bg-transparent px-2 mt-2 focus:outline-none'
                                                    value={formValues.name}
                                                    onChange={handleChange}
                                                    required
                                                />
                                            </div>
                                            {formErrors.name && <p className='text-red-600 text-sm mt-1'>{formErrors.name}</p>}
                                        </div>

                                        <div>
                                            <div className='border borderColor commonRadius p-2 textPrimary'>
                                                <label htmlFor='email' className='block text-[14px] font-normal'>{t('emailLbl')}</label>
                                                <input
                                                    type='email'
                                                    name='email'
                                                    id='email'
                                                    className='w-full font-semibold bg-transparent px-2 mt-2 focus:outline-none disabled:opacity-60 disabled:cursor-not-allowed'
                                                    value={formValues.email}
                                                    onChange={handleChange}
                                                    disabled={isEmailLocked}
                                                />
                                            </div>
                                            {formErrors.email && <p className='text-red-600 text-sm mt-1'>{formErrors.email}</p>}
                                        </div>

                                        <div>
                                            <div className={`border borderColor commonRadius p-2 textPrimary ${isMobileLocked ? 'cursor-not-allowed!' : ''}`}>
                                                <label htmlFor='mobile' className='block text-[14px] font-normal'>{t('mobileLbl')}</label>
                                                <PhoneInput
                                                    className={`phoneInput mt-2 disabled:opacity-60 ${isMobileLocked ? 'cursor-not-allowed!' : ''}`}
                                                    id='mobile'
                                                    placeholder={t('mobileLbl')}
                                                    defaultCountry={(settingsData?.country_code || process.env.NEXT_PUBLIC_DEFAULT_COUNTRY) as Country}
                                                    international
                                                    limitMaxLength
                                                    value={mobileValue}
                                                    onChange={setMobileValue}
                                                    disabled={isMobileLocked}
                                                />
                                            </div>
                                            {formErrors.mobile && <p className='text-red-600 text-sm mt-1'>{formErrors.mobile}</p>}
                                        </div>

                                        {showAuthorFields && (
                                            <div className='border borderColor commonRadius p-2 textPrimary'>
                                                <label htmlFor='bio' className='block text-[14px] font-normal'>{t('bio')}</label>
                                                <input
                                                    type='text'
                                                    name='bio'
                                                    id='bio'
                                                    className='w-full font-semibold bg-transparent px-2 mt-2 focus:outline-none'
                                                    placeholder={t('addYourBio')}
                                                    value={formValues.bio}
                                                    onChange={handleChange}
                                                />
                                            </div>
                                        )}
                                    </div>

                                    {showAuthorFields && (
                                        <div className='w-full flex flex-col gap-6 mt-8'>
                                            <div className='text-base font-semibold textPrimary'>{t('socialMediaLinks')}</div>

                                            {([
                                                { name: 'telegram', label: t('telegram') },
                                                { name: 'whatsapp', label: t('whatsapp') },
                                                { name: 'facebook', label: t('facebook') },
                                                { name: 'linkedin', label: t('linkedin') },
                                            ] as const).map((field) => (
                                                <div key={field.name} className='border borderColor commonRadius p-2 textPrimary'>
                                                    <label htmlFor={field.name} className='block text-[14px] font-normal'>{field.label}</label>
                                                    <input
                                                        type='url'
                                                        name={field.name}
                                                        id={field.name}
                                                        className='w-full font-semibold bg-transparent px-2 mt-2 focus:outline-none'
                                                        placeholder={t('addLinkHere')}
                                                        value={formValues[field.name]}
                                                        onChange={handleChange}
                                                    />
                                                </div>
                                            ))}
                                        </div>
                                    )}

                                    <button
                                        type='submit'
                                        disabled={saving}
                                        className='commonBtn m-auto w-full text-[18px] !py-3 mt-8 disabled:opacity-60'
                                    >
                                        {t('update-profile')}
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </section>

                <LanguageSwitcher
                    variant='modal'
                    open={languageModalOpen}
                    onClose={() => setLanguageModalOpen(false)}
                    redirectPath='/category-preferences'
                />
            </>
        </Layout>
    )
}

export default WithAuth(ProfileUpdate)
