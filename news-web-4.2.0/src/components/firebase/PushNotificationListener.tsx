'use client'
import { useEffect } from 'react'
import { useDispatch } from 'react-redux'
import FirebaseData, { initForegroundFcm } from '@/utils/Firebase'
import { setShowNotification } from '@/redux/reducers/helperSlice'
import { setFirebaseToken } from '@/redux/reducers/userSlice'

// Renders nothing — only wires up FCM token fetch and foreground messages.
// Loaded lazily by PushNotification so Firebase isn't in the initial bundle.
const PushNotificationListener = () => {
    const { fetchToken } = FirebaseData()

    const dispatch = useDispatch()

    useEffect(() => {
        fetchToken()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    // Catch permission granted outside NotificationPrompt (e.g. browser site
    // settings after "maybe later"). Token is cleared first so TopBar's
    // registerToken effect fires even if FCM hands back the persisted token.
    useEffect(() => {
        if (!('permissions' in navigator) || !('Notification' in window)) return

        let status: PermissionStatus | undefined
        let cancelled = false

        const onChange = () => {
            if (Notification.permission !== 'granted') return
            dispatch(setFirebaseToken(''))
            fetchToken()
        }

        navigator.permissions
            .query({ name: 'notifications' })
            .then(permissionStatus => {
                if (cancelled) return
                status = permissionStatus
                status.addEventListener('change', onChange)
            })
            .catch(err => console.error('Notification permission query failed:', err))

        return () => {
            cancelled = true
            status?.removeEventListener('change', onChange)
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [dispatch])

    useEffect(() => {
        let unsubscribe: (() => void) | undefined
        let cancelled = false

        initForegroundFcm(() => dispatch(setShowNotification(true)))
            .then(unsub => {
                if (cancelled) unsub()
                else unsubscribe = unsub
            })
            .catch(err => console.error('Error initializing foreground notifications:', err))

        return () => {
            cancelled = true
            unsubscribe?.()
        }
    }, [dispatch])

    return null
}

export default PushNotificationListener
