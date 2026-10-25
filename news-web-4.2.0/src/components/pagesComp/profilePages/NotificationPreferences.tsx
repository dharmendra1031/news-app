'use client'
import { useState } from 'react'
import { useDispatch } from 'react-redux'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import CommonCardSkeleton from '@/components/skeletons/CommonCardSkeleton'
import NotificationPrefCard from '@/components/common/NotificationPrefCard'
import { useGetNotificationPrefs, NotificationPrefKey } from '@/hooks/queries/useGetNotificationPrefs'
import { setNotificationPrefApi } from '@/api/apiRoutes'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { isLogin, webName } from '@/components/utils/helpers'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import Meta from '@/components/common/Meta'
import WithAuth from '@/components/hoc/WithAuth'

interface PrefMeta {
    titleKey: string
    descKey: string
}

const NOTIFICATION_PREF_META: Record<NotificationPrefKey, PrefMeta> = {
    news: { titleKey: 'newsNotification', descKey: 'newsNotificationDesc' },
    podcasts: { titleKey: 'podcastNotification', descKey: 'podcastNotificationDesc' },
    alerts: { titleKey: 'marketAlertNotification', descKey: 'marketAlertNotificationDesc' },
    comments: { titleKey: 'commentReplyNotification', descKey: 'commentReplyNotificationDesc' },
    announcements: { titleKey: 'promotionalNotification', descKey: 'promotionalNotificationDesc' },
}

interface PreferenceState {
    id: number
    key: NotificationPrefKey
    checked: boolean
}

const NotificationPreferences = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()

    const { data: prefsData, isLoading } = useGetNotificationPrefs()

    const [preferences, setPreferences] = useState<PreferenceState[]>([])
    const [saving, setSaving] = useState(false)

    // Seed local toggle state from the fetched prefs exactly once per fetch —
    // done at render time (not in an effect), matching this project's other
    // profile pages, so a later re-render doesn't wipe unsent local toggles.
    const [syncedData, setSyncedData] = useState<typeof prefsData | symbol>(() => Symbol('initial'))
    if (prefsData !== syncedData) {
        setSyncedData(prefsData)
        if (prefsData?.data) {
            setPreferences(prefsData.data.map((pref) => ({ id: pref.id, key: pref.key, checked: Boolean(pref.enabled) })))
        }
    }

    const togglePreference = (id: number) => {
        setPreferences((prev) => prev.map((pref) => (pref.id === id ? { ...pref, checked: !pref.checked } : pref)))
    }

    const handleSave = async () => {
        if (!isLogin()) {
            dispatch(setLoginModalOpen(true))
            toast.error(t('loginFirst'))
            setTimeout(() => dispatch(setLoginModalOpen(false)), 2000)
            return
        }

        setSaving(true)
        try {
            const response = await setNotificationPrefApi({
                preferences: preferences.map(({ id, checked }) => ({ notification_type_id: id, status: checked ? 1 : 0 })),
            })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }
            toast.success(t('updateSuccessfully'))
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setSaving(false)
        }
    }

    return (
        <Layout>
            <>

                <Meta title={`${webName()} | ${t('notificationPref')}`} />

                <Breadcrumb secondElement={t('notificationPref')} />

                <section className='commonBg commonPY'>
                    <div className='userBasedCategories container flex flex-col gap-8 md:gap-12'>
                        <div className='customBgWhite border seconadryBorderColor commonRadius flex items-center justify-between py-3 px-4'>
                            <h2 className='font-medium text-lg md:text-xl textPrimary'>{t('notificationPref')}</h2>
                            <button
                                type='button'
                                disabled={saving}
                                onClick={handleSave}
                                className='commonBtn md:text-[18px] uppercase md:!py-4 md:!px-8 disabled:opacity-60'
                            >
                                {t('saveLbl')}
                            </button>
                        </div>

                        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6'>
                            {
                                isLoading
                                    ? [...Array(5)].map((_, index) => (
                                        <div key={index}><CommonCardSkeleton /></div>
                                    ))
                                    : preferences.map((pref) => {
                                        const meta = NOTIFICATION_PREF_META[pref.key]
                                        return (
                                            <NotificationPrefCard
                                                key={pref.id}
                                                title={t(meta.titleKey)}
                                                description={t(meta.descKey)}
                                                checked={pref.checked}
                                                onToggle={() => togglePreference(pref.id)}
                                            />
                                        )
                                    })
                            }
                        </div>
                    </div>
                </section>

            </>
        </Layout>
    )
}

export default WithAuth(NotificationPreferences)
