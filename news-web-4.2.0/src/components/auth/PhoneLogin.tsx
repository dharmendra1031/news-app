'use client'
import { useState } from 'react'
import 'react-phone-number-input/style.css'
import PhoneInput, { Country, isValidPhoneNumber, Value } from 'react-phone-number-input'
import { toast } from '@/lib/toast'
import { useSelector } from 'react-redux'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { useTranslation } from '@/hooks/useTranslation'
import OtpModal from './OtpModal'

interface PhoneLoginProps {
    setMainModal: (value: boolean) => void
    mainModal: boolean
}

const PhoneLogin = ({ setMainModal, mainModal }: PhoneLoginProps) => {

    const { t } = useTranslation()
    const settingsData = useSelector(settingsSelector)

    const [phonenum, setPhonenum] = useState<string | null>(null)
    const [otpModal, setOtpModal] = useState(false)

    const [value, setValue] = useState<Value | undefined>(process.env.NEXT_PUBLIC_DEMO === 'true' ? '+919876543210' : undefined)

    const handleGetOtp = (e: React.FormEvent) => {
        e.preventDefault()
        if (value === undefined) {
            toast.error(t('mblRequired'))
        } else if (isValidPhoneNumber(value)) {
            setPhonenum(value)
            setOtpModal(true)
        } else {
            toast.error(t('mblValid'))
        }
    }

    return !otpModal ? (
        <div className="p-6 pt-2">
            <div className="border-b borderColor py-3">
                <h2 className="text-[22px] md:text-3xl font-bold textPrimary">{t('loginTxt')}</h2>
            </div>

            <div className="my-6 xl:mt-24">
                <h5 className="text-[18px] md:text-[22px] font-[700] textPrimary">{t('enter-your-mobile-number')}</h5>
                <p className="text-[14px] md:text-[16px] textPrimary font-[600]">{t('six-didgit-code')}</p>
            </div>

            <div className="flex flex-col gap-2">

                <div className="mb-4 border borderColor md:p-1 commonRadius">
                    <PhoneInput
                        className="py-2 phoneInput"
                        placeholder="Enter your phone number"
                        defaultCountry={(settingsData?.country_code || process.env.NEXT_PUBLIC_DEFAULT_COUNTRY) as Country}
                        international
                        value={value}
                        onChange={setValue}
                    />
                </div>
            </div>

            <form onSubmit={handleGetOtp}>
                <button className="commonBtn w-full text-[18px] md:text-[24px] mt-4">
                    {t('reqOtpLbl')}
                </button>
            </form>
        </div>
    ) : (
        <OtpModal
            setPhonenum={setPhonenum}
            setValue={setValue}
            phonenum={phonenum}
            setMainModal={setMainModal}
            mainModal={mainModal}
        />
    )
}

export default PhoneLogin
