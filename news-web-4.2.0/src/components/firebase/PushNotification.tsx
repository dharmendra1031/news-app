'use client'
import React, { useEffect, useState } from 'react'
import dynamic from 'next/dynamic'

const PushNotificationListener = dynamic(() => import('./PushNotificationListener'), { ssr: false })

interface PushNotificationLayoutProps {
    children: React.ReactNode
}

const PushNotificationLayout = ({ children }: PushNotificationLayoutProps) => {
    // Firebase messaging isn't needed to render the page — start it once the
    // browser is idle so it doesn't compete with first paint / hydration.
    const [ready, setReady] = useState(false)

    useEffect(() => {
        const start = () => setReady(true)
        if ('requestIdleCallback' in window) {
            const id = window.requestIdleCallback(start, { timeout: 4000 })
            return () => window.cancelIdleCallback(id)
        }
        const id = setTimeout(start, 2000)
        return () => clearTimeout(id)
    }, [])

    return (
        <div>
            {children}
            {ready && <PushNotificationListener />}
        </div>
    )
}

export default PushNotificationLayout
