'use client'
import { useState } from 'react'
import { IoEye } from 'react-icons/io5'
import { IoMdEyeOff } from 'react-icons/io'
import { FaArrowLeft } from 'react-icons/fa6'
import { getAuth, createUserWithEmailAndPassword, sendEmailVerification, AuthError } from 'firebase/auth'
import { firebaseApp } from '@/lib/firebaseApp'
import { toast } from '@/lib/toast'
import { useDispatch } from 'react-redux'
import { getAuthErrorMessage } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { setUserName } from '@/redux/reducers/userSlice'

interface RegisterFormProps {
    setLoginModal: (value: boolean) => void
    setRegisterModal: (value: boolean) => void
}

interface FormErrors {
    username?: string
    password?: string
    confirmPassword?: string
}

const RegisterForm = ({ setLoginModal, setRegisterModal }: RegisterFormProps) => {

    const { t } = useTranslation()
    const dispatch = useDispatch()

    const [isPasswordVisible, setPasswordVisible] = useState({
        pass: false,
        confPass: false,
    })

    const togglePasswordVisibility = (input: 'pass' | 'confPass') => {
        setPasswordVisible(prev => ({ ...prev, [input]: !prev[input] }))
    }

    const initialValues = {
        username: '',
        email: '',
        password: '',
        confirmpassword: '',
    }
    const [formValues, setFormValues] = useState(initialValues)
    const [formErrors, setFormErrors] = useState<FormErrors>({})

    const auth = getAuth(firebaseApp)

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target
        setFormValues({ ...formValues, [name]: value })
    }

    const validate = (values: typeof formValues): FormErrors => {
        const errors: FormErrors = {}
        if (!values.username) {
            errors.username = t('nameRequired')
        }
        if (!values.password) {
            errors.password = t('pwdRequired')
        } else if (values.password.length < 6) {
            errors.password = t('pwdLength')
        }
        if (!values.confirmpassword) {
            errors.confirmPassword = t('confPassRequired')
        } else if (values.confirmpassword !== values.password) {
            errors.confirmPassword = t('confPassNotMatch')
        }
        return errors
    }

    const handleSignup = async (email: string, password: string) => {
        try {
            const userCredential = await createUserWithEmailAndPassword(auth, email, password)
            sendEmailVerification(userCredential.user)

            toast.success(`${t('verifSentMail')}${formValues.email}`)
            dispatch(setUserName(formValues.username))
            setRegisterModal(false)
            setLoginModal(true)
        } catch (error) {
            toast.error(getAuthErrorMessage((error as AuthError)?.code))
        }
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        const errors = validate(formValues)
        setFormErrors(errors)
        if (Object.keys(errors).length > 0) return

        if (formValues.password !== formValues.confirmpassword) {
            toast.error(t('confPassNotMatch'))
            return
        }

        await handleSignup(formValues.email, formValues.password)
    }

    const handleBackToLogin = () => {
        setRegisterModal(false)
        setLoginModal(true)
    }

    return (
        <div className="p-6 pt-2">
            <div className="border-b borderColor py-3">
                <h2 className="text-[22px] md:text-3xl font-bold textPrimary">{t('createAccLbl')}</h2>
            </div>

            <div className="my-4 md:my-6">
                <h5 className="text-[18px] md:text-[22px] font-[700]">{t('Welcome')}</h5>
                <p className="text-[14px] md:text-[16px] textPrimary font-[600]">{t('register-daily-news')}</p>
            </div>

            <form className="flex flex-col gap-4" onSubmit={handleSubmit}>

                {/* UserName */}
                <div className="mb border borderColor p-2 commonRadius">
                    <label htmlFor="username" className="block font-[600] textSecondary">{t('username')}</label>
                    <input
                        type="text"
                        id="username"
                        className="mt-1 block w-full textPrimary font-[600] bg-transparent focus:outline-none"
                        placeholder={t('nameLbl')}
                        name="username"
                        value={formValues.username}
                        onChange={handleChange}
                        required
                    />
                </div>
                {formErrors.username && <p className="text-red-600 text-sm mt-[-12px] mb-0"> {formErrors.username}</p>}

                {/* Email Address */}
                <div className="mb border borderColor  p-2 commonRadius">
                    <label htmlFor="email" className="block font-[600] textSecondary">{t('emailaddress')}</label>
                    <input
                        type="email"
                        id="email"
                        className="mt-1 block w-full textPrimary font-[600] bg-transparent focus:outline-none"
                        name="email"
                        placeholder="name@example.com"
                        value={formValues.email}
                        onChange={handleChange}
                        required
                    />
                </div>

                {/* Password */}
                <div className="mb relative border borderColor  p-2 commonRadius">
                    <label htmlFor="password" className="block text-sm font-medium textSecondary">{t('passLbl')}</label>
                    <input
                        type={isPasswordVisible.pass ? 'text' : 'password'}
                        id="password"
                        className="mt-1 block w-full textPrimary font-[600] bg-transparent focus:outline-none"
                        placeholder={t('passLbl')}
                        name="password"
                        value={formValues.password}
                        onChange={handleChange}
                        required
                    />

                    <button
                        type="button"
                        onClick={() => togglePasswordVisibility('pass')}
                        className="absolute inset-y-0 ltr:right-0 rtl:left-0 flex items-center px-2 text-gray-500"
                    >
                        {isPasswordVisible.pass ? <IoEye size={24} /> : <IoMdEyeOff size={24} />}
                    </button>
                </div>
                {formErrors.password && <p className="text-red-600 text-sm mt-[-12px] mb-0"> {formErrors.password}</p>}

                {/* Confirm Password */}
                <div className="mb relative border borderColor  p-2 commonRadius">
                    <label htmlFor="confirmpassword" className="block text-sm font-medium textSecondary">{t('confpassLbl')}</label>
                    <input
                        type={isPasswordVisible.confPass ? 'text' : 'password'}
                        id="confirmpassword"
                        className="mt-1 block w-full textPrimary font-[600] bg-transparent focus:outline-none"
                        placeholder={t('confpassLbl')}
                        name="confirmpassword"
                        value={formValues.confirmpassword}
                        onChange={handleChange}
                        required
                    />
                    <button
                        type="button"
                        onClick={() => togglePasswordVisibility('confPass')}
                        className="absolute inset-y-0 ltr:right-0 rtl:left-0 flex items-center px-2 text-gray-500"
                    >
                        {isPasswordVisible.confPass ? <IoEye size={24} /> : <IoMdEyeOff size={24} />}
                    </button>
                </div>
                {formErrors.confirmPassword && <p className="text-red-600 text-sm mt-[-12px] mb-0"> {formErrors.confirmPassword}</p>}

                <button className="commonBtn w-full text-[18px] md:text-[24px] mt-1 md:mt-3">
                    {t('signupLbl')}
                </button>
            </form>

            <div className="font-[600] text-lg mt-4 md:mt-7 flexCenter gap-2 cursor-pointer" onClick={handleBackToLogin}>
                <FaArrowLeft size={16} className="mt-[2px]" />
                <span>{t('backToLogin')}</span>
            </div>

        </div>
    )
}

export default RegisterForm
