'use client'
import { isSupported } from 'firebase/messaging'
import { getAuth } from 'firebase/auth'
import { firebaseApp } from '@/lib/firebaseApp'
import { useDispatch, useSelector } from 'react-redux'
import { useEffect } from 'react'
import { setFirebaseToken } from '@/redux/reducers/userSlice'
import { notificationRequestSelector, setNotificationPermission } from '@/redux/reducers/checkPermissionsSlice'

const SW_PATH = '/firebase-messaging-sw.js'

const getMessagingRegistration = async (): Promise<ServiceWorkerRegistration> => {
    return (await navigator.serviceWorker.getRegistration(SW_PATH)) ?? (await navigator.serviceWorker.register(SW_PATH))
}

// Permission is asked by NotificationPrompt — this only fetches a token once
// the browser already reports 'granted'.
export const getFcmToken = async (): Promise<string | null> => {
    if (typeof window === 'undefined') return null

    const supported = await isSupported().catch(() => false)
    if (!supported) return null

    const vapidKey = process.env.NEXT_PUBLIC_VAPID_KEY
    if (!vapidKey) {
        console.warn('NEXT_PUBLIC_VAPID_KEY is not set — skipping FCM token fetch')
        return null
    }

    if (Notification.permission !== 'granted') return null

    try {
        const [{ getMessaging, getToken }, registration] = await Promise.all([
            import('firebase/messaging'),
            navigator.serviceWorker.register(SW_PATH),
        ])

        const messaging = getMessaging(firebaseApp)
        const token = await getToken(messaging, { vapidKey, serviceWorkerRegistration: registration })
        return token || null
    } catch (error) {
        console.error('Error fetching FCM token:', error)
        return null
    }
}

// Foreground messages don't reach the service worker's 'push' handler, so
// show them through the same registration. Returns an unsubscribe function.
export const initForegroundFcm = async (onReceived?: () => void): Promise<() => void> => {
    if (typeof window === 'undefined') return () => {}

    const supported = await isSupported().catch(() => false)
    if (!supported) return () => {}

    const registration = await getMessagingRegistration()

    const { getMessaging, onMessage } = await import('firebase/messaging')
    const messaging = getMessaging(firebaseApp)

    return onMessage(messaging, payload => {
        const notification = payload.notification || {}
        const data = payload.data || {}
        const title = notification.title || notification.body || ''
        const url = data.news_slug
            ? `/${data.language_code}/news/${data.news_slug}`
            : data.podcast_slug
                ? `/${data.language_code}/podcast/${data.podcast_slug}`
                : '/'

        registration.showNotification(title, {
            body: notification.body || '',
            icon: notification.icon || data.image || '/favicon.png',
            data: { url, id: data.news_id },
        })

        onReceived?.()
    })
}

const FirebaseData = () => {
    const dispatch = useDispatch()

    const notificationRequest = useSelector(notificationRequestSelector)

    const authentication = getAuth(firebaseApp)

    const fetchToken = async () => {
        if (typeof window === 'undefined' || !('Notification' in window)) return

        const permission = Notification.permission
        if (permission === 'denied') {
            dispatch(setNotificationPermission('denied'))
            return
        }
        if (permission !== 'granted') return

        dispatch(setNotificationPermission('granted'))
        const token = await getFcmToken()
        if (token) {
            dispatch(setFirebaseToken(token))
        }
    }

    // Re-run after NotificationPrompt records the user's choice.
    useEffect(() => {
        if (notificationRequest) {
            fetchToken()
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [notificationRequest])

    const signOut = () => {
        return authentication.signOut()
    }

    return { authentication, fetchToken, signOut }
}

export default FirebaseData
