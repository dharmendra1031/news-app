'use client'
import { useEffect, type ComponentType } from 'react'
import { useRouter } from 'next/router'
import { usePageMode, type ModeKey } from '@/hooks/usePageMode'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'

// Curried so the mode key can be supplied at the call site: WithPageMode('live_streaming_mode')(Component).
const WithPageMode = (mode: ModeKey) => <P extends object>(Component: ComponentType<P>) => {
    const PageModeGuarded = (props: P) => {
        const router = useRouter()
        const isModeEnabled = usePageMode(mode)
        const currLangCode = useLangCode()
        const defaultLangCode = useDefaultLangCode()

        useEffect(() => {
            // Settings load after mount on a hard reload — only redirect once the mode is known.
            if (isModeEnabled === false) {
                router.replace(withLang('/', currLangCode, defaultLangCode))
            }
        }, [isModeEnabled, currLangCode, defaultLangCode, router])

        if (!isModeEnabled) return null

        return <Component {...props} />
    }

    PageModeGuarded.displayName = `WithPageMode(${Component.displayName || Component.name || 'Component'})`

    return PageModeGuarded
}

export default WithPageMode
