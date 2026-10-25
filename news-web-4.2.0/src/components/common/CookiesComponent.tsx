'use client'
import React, { useState, useEffect } from 'react'
import Cookies from 'js-cookie'
import { useSelector } from 'react-redux'
import cookieIconLight from '@/assets/images/CookieIcon.svg'
import cookieIconDark from '@/assets/images/CookieIconDarkTheme.svg'
import { themeSelector } from '@/redux/reducers/checkThemeSlice'
import { userDataSelector, tokenSelector } from '@/redux/reducers/userSlice'
import { isLogin } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import ImagePreview from './ImagePreview'

const EXPIRATION_DAYS = 7

const CookiesComponent = () => {
  const [showPopup, setShowPopup] = useState(false)
  const [isCookiesAccept, setIsCookiesAccept] = useState(false)

  const darkTheme = useSelector(themeSelector)
  const userData = useSelector(userDataSelector)
  const token = useSelector(tokenSelector)
  const isUserLogin = isLogin()
  const { t } = useTranslation()

  const handleSaveData = () => {
    Cookies.set('user-name', userData?.name || '', { expires: EXPIRATION_DAYS })
    Cookies.set('user-email', userData?.email || '', { expires: EXPIRATION_DAYS })
    Cookies.set('user-number', userData?.mobile || '', { expires: EXPIRATION_DAYS })
    Cookies.set('user-token', token || '', { expires: EXPIRATION_DAYS })
    Cookies.set('user-fcmId', userData?.fcm_id || '', { expires: EXPIRATION_DAYS })
    Cookies.set('user-loginType', userData?.type || '', { expires: EXPIRATION_DAYS })
  }

  const handleAccept = () => {
    Cookies.set('cookie-consent', 'accepted', { expires: EXPIRATION_DAYS })
    setShowPopup(false)
    setIsCookiesAccept(true)
    handleSaveData()
  }

  const handleDecline = () => {
    Cookies.set('cookie-consent', 'declined', { expires: EXPIRATION_DAYS })
    setShowPopup(false)
  }

  useEffect(() => {
    const consent = Cookies.get('cookie-consent')
    if (!consent) {
      const timer = setTimeout(() => {
        setShowPopup(true)
      }, 10000)
      return () => clearTimeout(timer)
    }
  }, [])

  useEffect(() => {
    if (isUserLogin && isCookiesAccept) {
      handleSaveData()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isUserLogin, showPopup, userData])

  if (!showPopup) return null

  return (
    <section className='fixed inset-0 h-max z-50'>
      <div className='bodyBgColor dark:secondaryBg flexCenter flex-col gap-6 items-center text-center fixed
        bottom-[10px] right-[10px]
        md:bottom-[20px] md:right-[20px]
        p-[20px] md:p-[50px] lg:py-[185px] lg:px-[60px]
        w-[300px] h-[480px] sm:w-[400px] sm:h-[400px] md:w-[450px] md:h-[450px]
        lg:w-[640px] lg:h-[366px]
        shadow-[0px_0px_50px_#1B2D511A] dark:shadow-[0px_0px_50px_#6c757d2b] z-[49] commonRadius'>
        <div className='h-[70px] w-[70px]'>
          <ImagePreview src={darkTheme ? cookieIconDark : cookieIconLight} alt='cookie-icon' loading='lazy' />
        </div>
        <div className='flex flex-col gap-3'>
          <span className='textPrimary text-lg md:text-xl lg:text-2xl font-[700]'>{t('allCokkies')}</span>
          <span className='textSecondary text-[14px] sm:text-[16px] font-[600]'>{t('weUseCokkies')}</span>
        </div>

        <div className="flex items-center flex-wrap sm:flex-nowrap justify-center gap-4 sm:gap-6 mt-3 sm:mt-8">
          <button onClick={handleDecline} className='bg-transparent border py-2 px-3 secondaryBorder dark:border-white commonRadius textPrimary font-[600]'>{t('declineCokkies')}</button>
          <button onClick={handleAccept} className='secondaryBg dark:bg-white dark:text-black border py-2 px-3 secondaryBorder commonRadius text-white font-[600]'>{t('acceptCokkies')}</button>
        </div>
      </div>
    </section>
  )
}

export default CookiesComponent
