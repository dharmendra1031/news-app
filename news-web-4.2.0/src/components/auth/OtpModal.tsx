'use client'
import { useState, useEffect } from 'react'
import OTPInput from 'react-otp-input'
import FirebaseData from '@/utils/Firebase'
import { RecaptchaVerifier, signInWithPhoneNumber, AuthError } from 'firebase/auth'
import { toast } from '@/lib/toast'
import { useDispatch } from 'react-redux'
import { useRouter } from 'next/router'
import { userSignUpApi } from '@/api/apiRoutes'
import { useRegisterFcmToken } from '@/hooks/useRegisterFcmToken'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { useTranslation } from '@/hooks/useTranslation'
import { setIsNewUser, setToken } from '@/redux/reducers/userSlice'

interface OtpModalProps {
    phonenum: string | null
    setPhonenum: (value: string | null) => void
    setValue: (value: string | undefined) => void
    setMainModal: (value: boolean) => void
    mainModal: boolean
}

const OtpModal = ({ phonenum, setMainModal, mainModal }: OtpModalProps) => {

    const { t } = useTranslation()
    const dispatch = useDispatch()
    const navigate = useRouter()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const demoUser = phonenum === '+919876543210'

    const [OTP, setOTP] = useState(demoUser ? '123456' : '')
    const { authentication } = FirebaseData()
    const { registerToken } = useRegisterFcmToken()

    const [resendTimer, setResendTimer] = useState(60)

    useEffect(() => {
        if (resendTimer <= 0) return
        const intervalId = setInterval(() => {
            setResendTimer(prev => prev - 1)
        }, 1000)
        return () => clearInterval(intervalId)
    }, [resendTimer])

    const generateRecaptcha = () => {
        if (typeof window === 'undefined') return
        if (!window.recaptchaVerifier) {
            window.recaptchaVerifier = new RecaptchaVerifier(authentication, 'recaptcha-container', {
                size: 'invisible',
                callback: () => {},
            })
        }
    }

    const generateOTP = async (phone: string) => {
        generateRecaptcha()
        const appVerifier = window.recaptchaVerifier
        if (!appVerifier) return
        try {
            window.confirmationResult = await signInWithPhoneNumber(authentication, phone, appVerifier)
            toast.success(`${t('otpSentLbl')} ${phone}`)
        } catch (error) {
            const code = (error as AuthError)?.code
            let errorMessage = 'An error occurred. Please try again.'
            if (code === 'auth/too-many-requests') {
                errorMessage = 'Too many requests. Please try again later.'
            } else if (code === 'auth/invalid-phone-number') {
                errorMessage = 'Invalid phone number. Please enter a valid phone number.'
            }
            toast.error(errorMessage)
        }
    }

    useEffect(() => {
        generateRecaptcha()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    useEffect(() => {
        if (phonenum !== null) {
            generateOTP(phonenum)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [phonenum])

    const resendOTP = (e: React.MouseEvent) => {
        e.preventDefault()
        if (phonenum !== null) {
            generateOTP(phonenum)
            setResendTimer(60)
        }
    }

    const recaptchaClear = () => {
        const recaptchaContainer = document.getElementById('recaptcha-container')
        if (recaptchaContainer) {
            recaptchaContainer.innerHTML = ''
        }
        window.recaptchaVerifier?.clear()
        window.recaptchaVerifier = undefined
    }

    const handleAuthenticationError = (errorCode?: string) => {
        switch (errorCode) {
            case 'auth/missing-verification-code':
                toast.error('Missing verification code. Please enter the code.')
                break
            case 'auth/code-expired':
                toast.error('The verification code has expired. Please generate a new one.')
                break
            case 'auth/invalid-verification-code':
                toast.error('Invalid verification code. Please enter a valid code.')
                break
            case 'auth/invalid-verification-id':
                toast.error('Invalid verification ID. Please try again with a valid ID.')
                break
            case 'auth/session-expired':
                toast.error('The session has expired. Please sign in again.')
                break
            case 'auth/quota-exceeded':
                toast.error('Quota exceeded. Please wait before sending a new verification code.')
                break
            default:
                toast.error('An unknown authentication error occurred.')
                break
        }
    }

    const registerUser = async (idToken: string, mobile: string | null) => {
        try {
            const response = await userSignUpApi({
                id_token: idToken,
                mobile: mobile ?? undefined,
                type: 'mobile',
                status: '1',
            })

            if (response?.error) {
                toast.error(response?.message)
                setMainModal(false)
                return
            }

            toast.success(t('loginMsg'))
            if (response?.data?.token) dispatch(setToken(response.data.token))
            registerToken()

            if (response?.data?.is_login === '0') {
                // If new user then show the Update Profile screen
                dispatch(setIsNewUser(true))
                navigate.push(withLang('/profile-update', currLangCode, defaultLangCode))
            }
            setMainModal(false)
            recaptchaClear()
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('deactiveMsg'))
        }
    }

    const submitOTP = async (e: React.FormEvent) => {
        e.preventDefault()

        const confirmationResult = window.confirmationResult
        if (!confirmationResult) return

        try {
            const response = await confirmationResult.confirm(OTP)
            setMainModal(false)
            recaptchaClear()
            await registerUser( await response.user.getIdToken(), response.user.phoneNumber)
        } catch (error) {
            handleAuthenticationError((error as AuthError)?.code)
        }
    }

    useEffect(() => {
        if (!mainModal) {
            recaptchaClear()
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [mainModal])

    return (
        <div className="p-6 pt-2">
            <div className="border-b borderColor py-3">
                <h2 className="text-[22px] md:text-3xl font-bold textPrimary">{t('opt-verify')}</h2>
            </div>

            <div className="my-6 xl:mt-24">
                <h5 className="text-[18px] md:text-[22px] font-[700] textPrimary">{t('otp-sent')} </h5>
                <p className="text-[14px] md:text-[16px] textPrimary font-[600]">{phonenum}</p>
            </div>

            <div className="flex flex-col gap-2">

                <div className="mb-4 md:p-1 commonRadius otp-content">
                    <OTPInput
                        value={OTP}
                        onChange={setOTP}
                        shouldAutoFocus
                        numInputs={6}
                        containerStyle="otpbox"
                        renderSeparator={<span className="space"></span>}
                        renderInput={props => <input {...props} className="custom-input-class"></input>}
                    />
                </div>
                {resendTimer > 0 ? (
                    <div className="flex items-center gap-1 font-[500]">
                        <span className="textPrimary"> {t('resendCodeIn')}</span>
                        <span className="text-[red]">
                            {' '}
                            {resendTimer} {t('seconds')}
                        </span>
                    </div>
                ) : (
                    <button onClick={resendOTP} className="text-start textPrimary font-[500]">
                        {t('resendLbl')}
                    </button>
                )}
            </div>

            <form onSubmit={submitOTP}>
                <button className="commonBtn w-full text-[18px] md:text-[24px] mt-4">
                    {t('submitBtn')}
                </button>
            </form>
            <div id="recaptcha-container" style={{ display: 'none' }}></div>
        </div>
    )
}

export default OtpModal
