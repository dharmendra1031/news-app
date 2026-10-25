'use client'
import { toast } from '@/lib/toast'
import { useDispatch } from 'react-redux'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { isLogin } from '@/components/utils/helpers'
import {
    setCommentApi,
    setCommentLikeDislikeApi,
    deleteCommentApi,
    setCommentFlagApi,
} from '@/api/apiRoutes'

export const useCommentActions = () => {
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

    const postComment = async (newsId: number, message: string, languageCode: string, parentId?: number) => {
        if (!newsId || !message.trim() || !requireLogin()) return false

        try {
            const response = await setCommentApi({
                language_code: languageCode,
                parent_id: parentId,
                news_id: newsId,
                message: message.trim(),
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return false
            }
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const likeComment = async (commentId: number, status: boolean, languageCode: string) => {
        if (!commentId || !requireLogin()) return false

        try {
            const response = await setCommentLikeDislikeApi({
                language_code: languageCode,
                comment_id: commentId,
                status: status ? 1 : 0,
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return false
            }
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const dislikeComment = async (commentId: number, status: boolean, languageCode: string) => {
        if (!commentId || !requireLogin()) return false

        try {
            const response = await setCommentLikeDislikeApi({
                language_code: languageCode,
                comment_id: commentId,
                status: status ? 2 : 0,
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return false
            }
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const deleteComment = async (commentId: number) => {
        if (!commentId || !requireLogin()) return false

        try {
            const response = await deleteCommentApi({ comment_id: commentId })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return false
            }
            toast.success(t('comDelSucc'))
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const reportComment = async (commentId: number, newsId: number, message: string) => {
        if (!commentId || !message.trim() || !requireLogin()) return false

        try {
            const response = await setCommentFlagApi({
                comment_id: commentId,
                news_id: newsId,
                message: message.trim(),
            })

            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return false
            }
            toast.success(t('flag'))
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    return { postComment, likeComment, dislikeComment, deleteComment, reportComment, requireLogin }
}
