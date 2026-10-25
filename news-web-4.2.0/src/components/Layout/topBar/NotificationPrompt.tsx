'use client'
import { useEffect, useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { toast } from '@/lib/toast'
import { notificationRequestSelector, setNotificationRequest } from '@/redux/reducers/checkPermissionsSlice'
import { useTranslation } from '@/hooks/useTranslation'

// `checkPermissions` is excluded from redux-persist (browser permission state
// must always reflect the current session), so a "maybe later" dismissal
// stored only in redux is forgotten on reload. Track it in localStorage too
// so the prompt actually stays dismissed once the user has said no.
const DISMISSED_KEY = 'notificationPromptDismissed'

const NotificationPrompt = () => {
  const dispatch = useDispatch()
  const notificationPermission = useSelector(notificationRequestSelector)
  const { t } = useTranslation()

  const [show, setShow] = useState(false)

  useEffect(() => {
    let dismissed = false
    try {
      dismissed = localStorage.getItem(DISMISSED_KEY) === 'true'
    } catch (error) {
      console.error('localStorage error:', error)
    }

    const timer = setTimeout(() => {
      if (Notification.permission !== 'granted' && notificationPermission !== 'rejected' && !dismissed) {
        setShow(true)
      }
    }, 30000)

    return () => clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleAllow = async () => {
    try {
      const permissionRes = await Notification.requestPermission()
      dispatch(setNotificationRequest(permissionRes))
      setShow(false)
    } catch (error) {
      console.error('Permission error:', error)
    }
  }

  const handleLater = () => {
    dispatch(setNotificationRequest('rejected'))
    try {
      localStorage.setItem(DISMISSED_KEY, 'true')
    } catch (error) {
      console.error('localStorage error:', error)
    }
    setShow(false)
    toast.info(t('notificationBlocked'))
  }

  if (!show) return null

  return (
    <div className="fixed inset-0 bg-black/10 backdrop-blur-sm z-50">
      <div className="fixed top-6 left-6 bodyBgColor shadow-xl commonRadius p-4 w-80 z-50">
        <h4 className="font-semibold mb-2 textPrimary">📢 {t('dontMissUpdate')}</h4>
        <p className="text-sm mb-3 font-medium textSecondary">
          {t('allNotification')}
        </p>
        <div className="flex gap-2">
          <button
            onClick={handleAllow}
            className="secondaryBg text-white px-3 py-1 commonRadius"
          >
            {t('enableNotifications')}
          </button>
          <button
            onClick={handleLater}
            className="border secondaryBorder px-3 py-1 commonRadius textPrimary"
          >
            {t('maybeLater')}
          </button>
        </div>
      </div>
    </div>
  )
}

export default NotificationPrompt
