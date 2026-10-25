'use client'
import { toast } from '@/lib/toast'
import { useDispatch } from 'react-redux'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { isLogin } from '@/components/utils/helpers'
import {
    setBookmarkApi,
    setLikeDislikeApi,
    setNewsViewApi,
    setBreakingNewsViewApi,
} from '@/api/apiRoutes'

export const useNewsActions = () => {
    const dispatch = useDispatch()
    const { t } = useTranslation()

    const requireLogin = () => {
        if (isLogin()) return true

        dispatch(setLoginModalOpen(true))
        toast.error(t('loginFirst'))
        setTimeout(() => {
            dispatch(setLoginModalOpen(false))
        }, 2000)
        return false
    }

    const bookmarkNews = async (newsId: number, status: boolean) => {
        if (!newsId || !requireLogin()) return false

        try {
            const response = await setBookmarkApi({ news_id: newsId, status: status ? 1 : 0 })

            if (!response || response?.error) {
                toast.error(t('somethingMSg'))
                return false
            }
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const likeNews = async (newsId: number, status: boolean) => {
        if (!newsId || !requireLogin()) return false

        try {
            const response = await setLikeDislikeApi({ news_id: newsId, status: status ? 1 : 0 })

            if (!response || response?.error) {
                toast.error(t('somethingMSg'))
                return false
            }
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    // View counters are fire-and-forget — a failure here must never surface to the reader.
    const setNewsView = async (newsId: number) => {
        if (!newsId) return
        try {
            await setNewsViewApi({ news_id: newsId })
        } catch (error) {
            console.error('Error:', error)
        }
    }

    const setBreakingNewsView = async (breakingNewsId: number) => {
        if (!breakingNewsId) return
        try {
            await setBreakingNewsViewApi({ breaking_news_id: breakingNewsId })
        } catch (error) {
            console.error('Error:', error)
        }
    }

    return { bookmarkNews, likeNews, setNewsView, setBreakingNewsView }
}
