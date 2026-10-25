'use client'
import { toast } from '@/lib/toast'
import { useDispatch } from 'react-redux'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { isLogin } from '@/components/utils/helpers'
import { bookmarkPodcastApi, followPodcastApi } from '@/api/apiRoutes'
import { EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'

export const usePodcastActions = () => {
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

    const followPodcast = async (id: number, status: boolean) => {
        if (!id || !requireLogin()) return false

        try {
            const response = await followPodcastApi({
                podcast_id: id,
                status: status ? 1 : 0,
            })

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

    const bookmarkEpisode = async ({ podcastId, episodeId, status }: { podcastId: number; episodeId?: number; status: boolean }) => {
        if (!requireLogin()) return false

        try {
            const response = await bookmarkPodcastApi({
                podcast_id: podcastId,
                episode_id: episodeId,
                status: status ? 1 : 0,
            })

            if (!response || response?.error) {
                toast.error(t('somethingMSg'))
                return false
            }
            toast.success(t(status ? 'bookmarkSuccess' : 'bookmarkRemoved'))
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    const downloadEpisode = async (episode: Pick<EpisodeApi, 'audio_url' | 'title'>) => {
        if (!episode?.audio_url) return false

        try {
            const response = await fetch(episode.audio_url)
            const blob = await response.blob()
            const objectUrl = window.URL.createObjectURL(blob)
            const extension = episode.audio_url.split('?')[0].match(/\.([a-zA-Z0-9]+)$/)?.[1] || 'mp3'

            const link = document.createElement('a')
            link.href = objectUrl
            link.download = `${episode?.title || 'episode'}.${extension}`
            document.body.appendChild(link)
            link.click()
            link.remove()
            window.URL.revokeObjectURL(objectUrl)
            return true
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
            return false
        }
    }

    return { followPodcast, bookmarkEpisode, downloadEpisode }
}
