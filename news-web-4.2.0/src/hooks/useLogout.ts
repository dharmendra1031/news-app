'use client'
import { useRouter } from 'next/router'
import { useDispatch } from 'react-redux'
import { useQueryClient } from '@tanstack/react-query'
import { getFirebaseAuth } from '@/lib/firebaseAuth'
import { toast } from '@/lib/toast'
import { logoutSuccess } from '@/redux/reducers/userSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'

export const useLogout = () => {
    const dispatch = useDispatch()
    const router = useRouter()
    const queryClient = useQueryClient()
    const { t } = useTranslation()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    // Default language is unprefixed — pushing "/en" would hit the proxy's
    // canonicalizing 308 and land on "/?langCode=en".
    const homePath = withLang('/', currLangCode, defaultLangCode)

    const logout = async (successMessageKey?: string) => {
        try {
            const authentication = await getFirebaseAuth()
            await authentication.signOut()
            dispatch(logoutSuccess())
            // Drop the cached user, not just mark it stale — its 5min staleTime
            // means enabling the query again for a different account (login
            // right after logout) would otherwise serve the old account's data
            // instead of refetching.
            queryClient.removeQueries({ queryKey: ['userDetails'] })
            if (successMessageKey) toast.success(t(successMessageKey))
            router.push(homePath)
            return true
        } catch (error) {
            console.error('Error signing out:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    return { logout }
}
