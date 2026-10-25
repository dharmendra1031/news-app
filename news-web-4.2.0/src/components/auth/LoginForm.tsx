'use client'
import { useState, useEffect } from 'react'
import { IoEye } from 'react-icons/io5'
import { IoMdEyeOff } from 'react-icons/io'
import { FaGoogle } from 'react-icons/fa'
import { MdOutlinePhoneAndroid } from 'react-icons/md'
import FirebaseData from '@/utils/Firebase'
import {
    signInWithPopup,
    GoogleAuthProvider,
    signInWithEmailAndPassword,
    getAuth,
    sendEmailVerification,
    AuthError,
} from 'firebase/auth'
import { firebaseApp } from '@/lib/firebaseApp'
import { userSignUpApi } from '@/api/apiRoutes'
import { useDispatch, useSelector } from 'react-redux'
import { toast } from '@/lib/toast'
import { getAuthErrorMessage } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { useRegisterFcmToken } from '@/hooks/useRegisterFcmToken'
import { useRouter } from 'next/router'
import { setIsNewUser, setToken, userDataSelector } from '@/redux/reducers/userSlice'
import FormLoader from '../common/FormLoader'
import { usePageMode } from '@/hooks/usePageMode'

interface LoginFormProps {
    setRegisterModal: (value: boolean) => void
    setPhoneLogin: (value: boolean) => void
    setLoginModal: (value: boolean) => void
    setForgotPassModal: (value: boolean) => void
    setIsLogout: (value: boolean) => void
    setMainModal: (value: boolean) => void
}

interface FormErrors {
    password?: string
}

const LoginForm = ({ setRegisterModal, setPhoneLogin, setLoginModal, setForgotPassModal, setMainModal }: LoginFormProps) => {

    const { t } = useTranslation()
    const dispatch = useDispatch()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const isMobileLoginEnable = usePageMode('mobile_login_mode');
    const userData = useSelector(userDataSelector)

    const navigate = useRouter()
    const [isPasswordVisible, setPasswordVisible] = useState(false)

    const initialValues = {
        email: process.env.NEXT_PUBLIC_DEMO === 'true' ? 'newstester@gmail.com' : '',
        password: process.env.NEXT_PUBLIC_DEMO === 'true' ? '123456' : '',
    }
    const [formValues, setFormValues] = useState(initialValues)
    const [formErrors, setFormErrors] = useState<FormErrors>({})
    const [isLoggingIn, setIsLoggingIn] = useState(false)

    const { registerToken } = useRegisterFcmToken()

    useEffect(() => {
        if (!formErrors.password) return
        const timer = setTimeout(() => setFormErrors({}), 5000)
        return () => clearTimeout(timer)
    }, [formErrors])

    const togglePasswordVisibility = () => {
        setPasswordVisible(!isPasswordVisible)
    }

    const handleOpenRegisterModal = () => {
        setLoginModal(false)
        setRegisterModal(true)
    }

    const handleOpenForgotPassModal = () => {
        setLoginModal(false)
        setForgotPassModal(true)
    }

    const handleOpenPhoneLogin = () => {
        setLoginModal(false)
        setForgotPassModal(false)
        setPhoneLogin(true)
    }

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target
        setFormValues({ ...formValues, [name]: value })
    }

    const validate = (values: typeof formValues): FormErrors => {
        const errors: FormErrors = {}
        if (!values.password) {
            errors.password = t('pwdRequired')
        } else if (values.password.length < 6) {
            errors.password = t('pwdLength')
        }
        return errors
    }

    const registerUser = async (
        idToken: string,
        displayName: string | null | undefined,
        email: string | null | undefined,
        type: string
    ) => {

        try {
            const response = await userSignUpApi({
                id_token: idToken,
                name: displayName ?? undefined,
                email: email ?? undefined,
                type,
                status: '1',
            })

            if (response?.error) {
                toast.error(response?.message)
                setMainModal(false)
                return
            }

            toast.success(t('loginMsg'))
            if (response?.data?.token) dispatch(setToken(response?.data?.token))
            registerToken()

            if (response?.data?.is_login === '0') {
                // If new user then show the Update Profile screen
                dispatch(setIsNewUser(true))
                navigate.push(withLang('/profile-update', currLangCode, defaultLangCode))
            }
            setMainModal(false)
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('deactiveMsg'))
        }
    }

    const { authentication } = FirebaseData()
    const auth = getAuth(firebaseApp)

    const signInWithGoogle = async () => {
        const provider = new GoogleAuthProvider()
        await signInWithPopup(authentication, provider)
            .then(async response => {
                setLoginModal(false)
                await registerUser(await response.user.getIdToken(), response?.user?.displayName, response?.user?.email, 'google')
            })
            .catch(err => {
                console.error(err.message)
            })
    }

    const signInWithEmail = async () => {
        if (!formValues.email || !formValues.password) return

        await signInWithEmailAndPassword(auth, formValues.email, formValues.password)
            .then(async userCredential => {

                const user = userCredential.user
                if (user.emailVerified || user?.email === 'newstester@gmail.com') {
                    await registerUser(await user.getIdToken(), userData?.name || user?.displayName, formValues?.email, 'email')
                } else {
                    toast.error(t('verifyEmailMsg'))
                    if (auth.currentUser) sendEmailVerification(auth.currentUser)
                }
                setMainModal(false)
            })
            .catch((error: AuthError) => {
                console.error(error)
                toast.error(getAuthErrorMessage(error.code))
            })
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        const errors = validate(formValues)
        setFormErrors(errors)
        if (Object.keys(errors).length > 0) return
        setIsLoggingIn(true)
        try {
            await signInWithEmail()
        } finally {
            setIsLoggingIn(false)
        }
    }

    return (
        <div className="p-6 pt-2">
            <div className="border-b borderColor py-3">
                <h2 className="text-[22px] md:text-3xl font-bold textPrimary">{t('loginTxt')}</h2>
            </div>

            <div className="my-4 md:my-6">
                <h5 className="text-[18px] md:text-[22px] font-bold">{t('welcomeback')}</h5>
                <p className="text-[14px] md:text-[16px] textPrimary font-semibold"> {t('enter-email-password')}</p>
            </div>

            <div className="flex flex-col gap-2">
                <form onSubmit={handleSubmit}>
                    {/* Email Address */}
                    <div className="mb-4 border borderColor p-2 commonRadius">
                        <label htmlFor="email" className="block font-semibold textSecondary">{t('emailaddress')}</label>
                        <input
                            type="email"
                            id="email"
                            className="mt-1 block w-full textPrimary font-semibold bg-transparent focus:outline-none"
                            value={formValues.email}
                            onChange={handleChange}
                            required
                            name="email"
                            placeholder="name@example.com"
                            aria-describedby="emailHelp"
                        />
                    </div>

                    {/* Password */}
                    <div className="mb-1 relative border borderColor p-2 commonRadius">
                        <label htmlFor="password" className="block text-sm font-medium textSecondary">{t('passLbl')}</label>
                        <input
                            type={isPasswordVisible ? 'text' : 'password'}
                            id="password"
                            className="mt-1 block w-full textPrimary font-semibold bg-transparent focus:outline-none"
                            name="password"
                            value={formValues.password}
                            onChange={handleChange}
                            placeholder={t('passLbl')}
                            required
                        />
                        <button
                            type="button"
                            onClick={togglePasswordVisibility}
                            className="absolute inset-y-0 ltr:right-0 rtl:left-0 flex items-center px-2 text-gray-500"
                        >
                            {isPasswordVisible ? <IoEye size={24} /> : <IoMdEyeOff size={24} />}
                        </button>
                    </div>
                    {formErrors.password && <p className="text-red-600 text-sm my-0"> {formErrors.password}</p>}

                    {/* Forgot Password */}
                    <div className="flex justify-end mb-5">
                        <span className="font-medium text-[#fa3232] cursor-pointer" onClick={handleOpenForgotPassModal}>{t('forgotPassLbl')}</span>
                    </div>
                    {/* Login Button */}
                    <button
                        type="submit"
                        disabled={isLoggingIn}
                        className={`commonBtn flexCenter w-full text-[18px] md:text-[24px] md:mt-4 ${isLoggingIn ? 'opacity-70 cursor-not-allowed' : ''}`}
                    >
                        {isLoggingIn ? (
                            <FormLoader />
                        ) : (
                            t('loginTxt')
                        )}
                    </button>
                </form>
            </div>

            {/* OR Divider */}
            <div className="relative my-2 md:my-4">
                <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border borderColor mt-px"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                    <span className="px-2 md:p-2 bodyBgColor textPrimary text-[18px] font-semibold">{t('or')}</span>
                </div>
            </div>
            <div className={`grid grid-cols-1 ${isMobileLoginEnable ? 'md:grid-cols-2' : 'md:grid-cols-1'} gap-4`}>
                {/* Google Sign-In Button */}
                <button className="w-full text-white py-2 commonRadius primaryBg font-bold" onClick={signInWithGoogle}>
                    <span className="inline-block align-middle mr-1"><FaGoogle size={12} /></span> {t('signin-with-google')}
                </button>

                {/* PhoneLogin Button */}
                {isMobileLoginEnable && (
                    <button className="w-full text-white py-2 commonRadius secondaryBg dark:bg-black font-bold" onClick={handleOpenPhoneLogin}>
                        <span className="inline-block align-middle mr-1"><MdOutlinePhoneAndroid size={16} /></span> {t('signin-with-phone')}
                    </button>
                )}
            </div>

            {/* Register */}
            <div className="flexCenter flex-col mt-4 md:mt-8 text-[18px]">
                <span className="font-semibold textPrimary"> {t('donthaveacc_lbl')}</span>
                <span className="font-bold text-[#3b5998] cursor-pointer" onClick={handleOpenRegisterModal}> {t('register')}</span>
            </div>
        </div>
    )
}

export default LoginForm
