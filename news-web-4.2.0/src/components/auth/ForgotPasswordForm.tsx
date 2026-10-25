'use client'
import { useState } from 'react'
import { getAuth, sendPasswordResetEmail, AuthError } from 'firebase/auth'
import { firebaseApp } from '@/lib/firebaseApp'
import { toast } from '@/lib/toast'
import { getAuthErrorMessage } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'

interface ForgotPasswordFormProps {
    setForgotPassModal: (value: boolean) => void
    setLoginModal: (value: boolean) => void
}

const ForgotPasswordForm = ({ setForgotPassModal, setLoginModal }: ForgotPasswordFormProps) => {

    const { t } = useTranslation()

    const initialValues = { email: '' }
    const [formValues, setFormValues] = useState(initialValues)

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target
        setFormValues({ ...formValues, [name]: value })
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        const auth = getAuth(firebaseApp)
        try {
            await sendPasswordResetEmail(auth, formValues.email)
            toast.success(t('passReset'))
            setForgotPassModal(false)
            setLoginModal(true)
        } catch (error) {
            toast.error(getAuthErrorMessage((error as AuthError)?.code))
        }
    }

    return (
        <div className="p-6 pt-2">
            <div className="border-b borderColor py-3">
                <h2 className="text-[22px] md:text-3xl font-bold textPrimary">{t('forgotPassLbl')}</h2>
            </div>

            <div className="my-6 xl:mt-[130px]">
                <h5 className="text-[16px] md:text-[28px] font-[700] textPrimary">{t('enteremail')}</h5>
            </div>

            <form onSubmit={handleSubmit} className="flex flex-col gap-2">

                <div className="mb-4 border borderColor  p-2 commonRadius">
                    <label htmlFor="email" className="block font-[600] textSecondary">{t('emailaddress')}</label>
                    <input
                        type="email"
                        id="email"
                        className="mt-1 block w-full textPrimary font-[600] bg-transparent focus:outline-none"
                        placeholder="name@example.com"
                        name="email"
                        value={formValues.email}
                        onChange={handleChange}
                        required
                    />
                </div>

                <button type="submit" className="commonBtn w-full text-[18px] md:text-[24px] mt-4">
                    {t('submitBtn')}
                </button>
            </form>

        </div>
    )
}

export default ForgotPasswordForm
