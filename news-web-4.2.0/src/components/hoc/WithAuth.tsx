'use client'
import { useEffect, type ComponentType } from 'react'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import { isLoginSelector, userDataSelector } from '@/redux/reducers/userSlice'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import type { RootState } from '@/redux/store'
import { withLang } from '@/lib/localizedUrl'

// redux-persist rehydrates `user` from storage async and there's no PersistGate,
// so on first render isLogin is always false — gate the redirect on this flag
// or a logged-in user gets bounced home on every hard refresh.
const rehydratedSelector = (state: RootState) =>
    (state as unknown as { _persist?: { rehydrated?: boolean } })._persist?.rehydrated ?? false

// Pages under these path segments are author-only — a logged-in non-author gets
// sent home same as a logged-out user, they just fail the extra author check.
const AUTHOR_ONLY_PATHS = ['manage-news', 'manage-podcast']

const WithAuth = <P extends object>(Component: ComponentType<P>) => {
    const AuthGuarded = (props: P) => {
        const router = useRouter()
        const isLogin = useSelector(isLoginSelector)
        const userData = useSelector(userDataSelector)
        const rehydrated = useSelector(rehydratedSelector)
        const currLangCode = useLangCode()
        const defaultLangCode = useDefaultLangCode()

        const isAuthorOnlyPath = AUTHOR_ONLY_PATHS.some(path => router.pathname.includes(path))
        const isAuthor = userData?.is_author === 1
        const canAccess = isLogin && (!isAuthorOnlyPath || isAuthor)

        useEffect(() => {
            if (rehydrated && !canAccess) {
                router.replace(withLang('/', currLangCode, defaultLangCode))
            }
        }, [rehydrated, canAccess, currLangCode, defaultLangCode, router])

        if (!rehydrated || !canAccess) return null

        return <Component {...props} />
    }

    AuthGuarded.displayName = `WithAuth(${Component.displayName || Component.name || 'Component'})`

    return AuthGuarded
}

export default WithAuth
