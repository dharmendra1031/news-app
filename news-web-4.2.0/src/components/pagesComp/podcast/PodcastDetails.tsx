'use client'
import { useState } from 'react'
import { useRouter } from 'next/router'
import { toast } from '@/lib/toast'
import Breadcrumb from '@/components/common/Breadcrumb'
import Layout from '@/components/Layout/Layout'
import WithPageMode from '@/components/hoc/WithPageMode'
import EmptyStatus from '@/components/common/EmptyStatus'
import { useTranslation } from '@/hooks/useTranslation'
import PodcastCard from './PodcastCard'
import EpisodeSect from './EpisodeSect'
import { useGetEpisodes, EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'
import { EpisodeCardSkeleton } from '@/components/skeletons/podcast/EpisodeCardSkeleton'
import PodcastCardSkeleton from '@/components/skeletons/podcast/PodcastCardSkeleton'
import { deleteEpisodeApi } from '@/api/apiRoutes'

interface PodcastDetailsProps {
    managePodcast?: boolean
}

const PodcastDetails = ({ managePodcast = false }: PodcastDetailsProps) => {
    const router = useRouter()
    const slug = typeof router.query.slug === 'string' ? router.query.slug : ''

    const { t } = useTranslation();

    const dataPerPage = 6;

    const [loadMore, setLoadMore] = useState(false)
    const [episodesData, setEpisodesData] = useState<EpisodeApi[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)
    const [activeTab, setActiveTab] = useState(0)

    const tabs = [
        {
            id: 0,
            label: t('allLbl'),
            type: 'all',
        },
        {
            id: 1,
            label: t('draft'),
            type: 'draft',
        },
    ]

    const [prevActiveTab, setPrevActiveTab] = useState(activeTab)
    if (activeTab !== prevActiveTab) {
        setPrevActiveTab(activeTab)
        setLoadMore(false)
        setOffset(0)
        setEpisodesData([])
    }

    const { data: episodesQueryData, isLoading, isFetching, isError, error } = useGetEpisodes({
        podcast_slug: slug,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        type: tabs.find((tab) => tab.id === activeTab)?.type,
        is_author_check: managePodcast ? 1 : 0,
        enabled: !!slug,
    });

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setEpisodesData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof episodesQueryData | symbol>(() => Symbol('initial'))
    if (!isError && episodesQueryData !== prevQueryData) {
        setPrevQueryData(episodesQueryData)
        if (episodesQueryData) {
            const items = episodesQueryData?.data?.episodes ?? []
            setTotalData(episodesQueryData?.data?.episode_count ?? 0)
            if (loadMore) {
                setEpisodesData((prev) => [...prev, ...items])
            } else {
                setEpisodesData(items)
            }
        }
    }

    const podcastDetails = episodesQueryData?.data ?? null

    if (isError && error) {
        console.log('episodes err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const deleteEpisode = async (id: number) => {
        try {
            const response = await deleteEpisodeApi({ episode_id: id })
            if (!response || response?.error) {
                toast.error(response?.message || t('somethingMSg'))
            } else {
                toast.success(t('deletedSuccessfully'))
                setEpisodesData((prev) => prev.filter((item) => item.id !== id))
            }
        } catch (err) {
            console.error(err)
        }
    };

    return (
        <Layout>
            <Breadcrumb secondElement={t(managePodcast ? 'managePodcast' : 'podcast')} thirdElement={slug} podcastPage={true} managePodcast={managePodcast} />
            <section className='container commonMT'>

                {
                    managePodcast &&
                    <div className='flex items-center customBgWhite rounded-2xl p-3 border seconadryBorderColor gap-3 overflow-x-auto customScrollbar commonMT'>
                        <div className="grid grid-rows-1 grid-flow-col gap-3 w-fit">
                            {
                                tabs?.map((tab) => {
                                    return <div key={tab?.id} className={`w-28 md:w-[200px] rounded-[8px] p-3 flexCenter font-bold cursor-pointer ${tab.id === activeTab ? 'secondaryBg dark:bodyBgColor text-white' : 'opacity-70'}`}
                                        onClick={() => setActiveTab(tab?.id)}
                                    >
                                        {tab?.label}
                                    </div>
                                })
                            }
                        </div>
                    </div>
                }

                {
                    isLoading && !loadMore ?
                        <div className={`grid grid-cols-1 gap-4 sm:gap-7 ${managePodcast ? 'commonMT' : ''}`}>
                            <PodcastCardSkeleton />
                            <div className='grid md:grid-cols-2 lg:grid-cols-3 gap-6'>
                                {
                                    Array.from({ length: dataPerPage })?.map((_, index) => (
                                        <EpisodeCardSkeleton key={index} podcastCard={true} />
                                    ))
                                }
                            </div>
                        </div>
                        :
                        <div className={`grid grid-cols-1 gap-4 sm:gap-7 ${managePodcast ? 'commonMT' : ''}`}>
                            <PodcastCard data={podcastDetails} />
                            {
                                episodesData?.length > 0 ?
                                    <EpisodeSect
                                        episodes={episodesData}
                                        isLoading={isLoading}
                                        isFetching={isFetching}
                                        loadMore={loadMore}
                                        totalData={totalData}
                                        dataPerPage={dataPerPage}
                                        handleLoadMore={handleLoadMore}
                                        podcastSlug={slug || podcastDetails?.slug}
                                        manageEpisodeCard={managePodcast}
                                        deleteEpisode={deleteEpisode}
                                        podcastTitle={podcastDetails?.title}
                                        podcastId={podcastDetails?.id}
                                    />
                                    :
                                    <div>
                                        <EmptyStatus noEpisodes={true}/>
                                    </div>
                            }
                        </div>
                }
            </section>
        </Layout>
    )
}

export default WithPageMode('podcast_mode')(PodcastDetails)
