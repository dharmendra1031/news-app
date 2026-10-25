'use client'
import { useSelector } from 'react-redux'
import { firebaseTokenSelector, userDataSelector } from '@/redux/reducers/userSlice'
import { locationSelector } from '@/redux/reducers/settingsSlice'
import { registertokenApi } from '@/api/apiRoutes'
import { useLangCode } from '@/hooks/useLangCode'

export const useRegisterFcmToken = () => {
    const firebaseToken = useSelector(firebaseTokenSelector)
    const userData = useSelector(userDataSelector)
    const location = useSelector(locationSelector)
    const languageCode = useLangCode()

    const registerToken = async () => {
        if (!firebaseToken || !languageCode) return
        try {
            await registertokenApi({
                language_code: languageCode,
                token: firebaseToken,
                latitude: location.lat ?? undefined,
                longitude: location.long ?? undefined,
                user_id: userData?.id,
            })
        } catch (error) {
            console.error('registerTokenApi Error:', error)
        }
    }

    return { registerToken, firebaseToken }
}
