'use client'
import { useState } from 'react'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import Meta from '@/components/common/Meta'
import EmptyStatus from '@/components/common/EmptyStatus'
import LocalizedLink from '@/components/common/LocalizeLink'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { EpisodeCard } from '@/components/pagesComp/podcast/EpisodeCard'
import { EpisodeCardSkeleton } from '@/components/skeletons/podcast/EpisodeCardSkeleton'
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { useGetMyPodcasts } from '@/hooks/queries/podcast/useGetMyPodcasts'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import { deletePodcastApi } from '@/api/apiRoutes'
import { webName } from '@/components/utils/helpers'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import WithAuth from '@/components/hoc/WithAuth'

type ManagePodcastTab = 'all' | 'draft'

const DATA_PER_PAGE = 6

const ManagePodcast = () => {
    const { t } = useTranslation()

    const [activeTab, setActiveTab] = useState<ManagePodcastTab>('all')
    const [deleteItemId, setDeleteItemId] = useState<number | null>(null)
    const [loadMore, setLoadMore] = useState(false)
    const [podcastsData, setPodcastsData] = useState<PodcastApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const tabs: { id: ManagePodcastTab; label: string }[] = [
        { id: 'all', label: t('allLbl') },
        { id: 'draft', label: t('draft') },
    ]

    const handleTabChange = (tab: ManagePodcastTab) => {
        setActiveTab(tab)
        setLoadMore(false)
        setOffset(0)
        setPodcastsData([])
    }

    const { data: podcastsQueryData, isLoading, isFetching } = useGetMyPodcasts({
        type: activeTab,
        offset: offset * DATA_PER_PAGE,
        limit: DATA_PER_PAGE,
    })

    const [prevQueryData, setPrevQueryData] = useState<typeof podcastsQueryData | symbol>(() => Symbol('initial'))
    if (podcastsQueryData !== prevQueryData) {
        setPrevQueryData(podcastsQueryData)
        if (podcastsQueryData) {
            const items = podcastsQueryData?.data?.data ?? []
            setTotalData(podcastsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setPodcastsData((prev) => [...prev, ...items])
            } else {
                setPodcastsData(items)
            }
        }
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const confirmDelete = async () => {
        if (!deleteItemId) return
        try {
            const response = await deletePodcastApi({ id: deleteItemId })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
                return
            }
            toast.success(t('deletedSuccessfully'))
            setPodcastsData((prev) => prev.filter((item) => item?.id !== deleteItemId))
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setDeleteItemId(null)
        }
    }

    return (
        <Layout>
            <>
                <Meta title={`${webName()} | ${t('managePodcast')}`} />
                <Breadcrumb secondElement={t('managePodcast')} />

                <section className='commonBg commonPY'>
                    <div className='container'>
                        <div className='flex items-center justify-between max-sm:gap-y-6 max-sm:flex-wrap customBgWhite rounded-2xl p-3 border seconadryBorderColor dark:borderColor gap-3 overflow-x-auto customScrollbar'>
                            <div className='grid grid-rows-1 grid-flow-col gap-3 w-fit'>
                                {tabs.map((tab) => (
                                    <div
                                        key={tab.id}
                                        className={`w-28 md:w-[200px] rounded-[8px] p-3 flexCenter font-bold cursor-pointer ${tab.id === activeTab ? 'secondaryBg dark:bodyBgColor text-white' : 'opacity-70'}`}
                                        onClick={() => handleTabChange(tab.id)}
                                    >
                                        {tab.label}
                                    </div>
                                ))}
                            </div>

                            <LocalizedLink href='/manage-podcast/create-podcast' title={t('createPodcast')} className='commonBtn font-semibold! flexCenter'>
                                {t('createPodcast')}
                            </LocalizedLink>
                        </div>

                        <div className='grid md:grid-cols-2 lg:grid-cols-3 gap-6 commonMT'>
                            {
                                isLoading && !loadMore
                                    ? Array.from({ length: DATA_PER_PAGE }).map((_, index) => (
                                        <EpisodeCardSkeleton podcastCard key={index} />
                                    ))
                                    : podcastsData.map((podcast) => (
                                        <LocalizedLink key={podcast?.id} href={`/manage-podcast/${podcast?.slug}`}>
                                            <EpisodeCard
                                                podcastCard
                                                managePodcastCard
                                                data={podcast}
                                                onDelete={(id) => setDeleteItemId(id)}
                                            />
                                        </LocalizedLink>
                                    ))
                            }
                        </div>

                        {!isLoading && podcastsData.length < 1 && <EmptyStatus />}

                        <div className='mt-12'>
                            {totalData > DATA_PER_PAGE && totalData !== podcastsData.length && podcastsData.length > 0 && (
                                <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                            )}
                        </div>
                    </div>
                </section>

                <AlertDialog open={deleteItemId !== null} onOpenChange={(open) => !open && setDeleteItemId(null)}>
                    <AlertDialogContent className='bg-white dark:bg-gray-900'>
                        <AlertDialogHeader>
                            <AlertDialogTitle className='textPrimary'>{t('doYouReallyNewsLbl')}</AlertDialogTitle>
                        </AlertDialogHeader>
                        <AlertDialogFooter>
                            <AlertDialogCancel onClick={() => setDeleteItemId(null)} className='textPrimary'>{t('cancelBtn')}</AlertDialogCancel>
                            <AlertDialogAction onClick={confirmDelete} className='primaryBg hover:hoverBg'>
                                {t('deleteTxt')}
                            </AlertDialogAction>
                        </AlertDialogFooter>
                    </AlertDialogContent>
                </AlertDialog>
            </>
        </Layout>
    )
}

export default WithAuth(ManagePodcast)
