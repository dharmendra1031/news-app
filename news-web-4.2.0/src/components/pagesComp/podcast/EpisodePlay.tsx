'use client'
import { useState } from 'react'
import EpisodeSect from './EpisodeSect'
import { useRouter } from 'next/router'
import { useGetEpisodes, EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'
import { EpisodeCardSkeleton } from '@/components/skeletons/podcast/EpisodeCardSkeleton'
import PodcastCardSkeleton from '@/components/skeletons/podcast/PodcastCardSkeleton'
import Breadcrumb from '@/components/common/Breadcrumb'
import Layout from '@/components/Layout/Layout'
import WithPageMode from '@/components/hoc/WithPageMode'
import EpisodePlayCard from './EpisodePlayCard'
import { useTranslation } from '@/hooks/useTranslation'
import Meta from '@/components/common/Meta'
import { usePodcastActions } from '@/hooks/usePodcastActions'
import EmptyStatus from '@/components/common/EmptyStatus'

const EpisodePlay = () => {

  const { t } = useTranslation();
  const router = useRouter()
  const slug = typeof router.query.slug === 'string' ? router.query.slug : ''
  const episodeSlug = typeof router.query.episode === 'string' ? router.query.episode : ''

  const dataPerPage = 6;

  const [loadMore, setLoadMore] = useState(false)
  const [episodesData, setEpisodesData] = useState<EpisodeApi[]>([])
  const [offset, setOffset] = useState(0)
  const [totalData, setTotalData] = useState(0)
  const [listenedSeconds, setListenedSeconds] = useState(0)

  const { data: episodesQueryData, isLoading, isFetching, isError, error } = useGetEpisodes({
    podcast_slug: slug,
    offset: offset * dataPerPage,
    limit: dataPerPage,
    is_author_check: 0,
    type: "all",
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

  if (isError && error) {
    console.log('episodes err =>', error.message)
  }

  const handleLoadMore = () => {
    setLoadMore(true)
    setOffset((prev) => prev + 1)
  }

  const { followPodcast } = usePodcastActions()

  const podcastData = episodesQueryData?.data
  const selectedEpisode = episodesData?.find((episode) => String(episode?.slug) === String(episodeSlug))
  const otherEpisodes = episodesData?.filter((episode) => String(episode?.slug) !== String(episodeSlug))

  return (
    <>
      <Meta title={selectedEpisode?.title} description={selectedEpisode?.description} pathName={router?.asPath} ogImage={selectedEpisode?.image} />
      <Layout>
        <Breadcrumb secondElement={t('podcast')} thirdElement={slug} fourthElement={selectedEpisode?.title ?? episodeSlug} podcastPage={true} />
        <section className='container commonMT'>
          {
            isLoading ?
              <div className='grid grid-cols-1 gap-4 sm:gap-7'>
                <PodcastCardSkeleton episodePlayCard={true} />
                <div className='grid md:grid-cols-2 lg:grid-cols-3 gap-6'>
                  {
                    Array.from({ length: dataPerPage })?.map((_, index) => (
                      <EpisodeCardSkeleton key={index} />
                    ))
                  }
                </div>
              </div>
              :
              podcastData && selectedEpisode ?
                <div className='grid grid-cols-1 gap-4 sm:gap-7'>
                  <EpisodePlayCard data={selectedEpisode} podcast={podcastData} onFollow={followPodcast} onProgress={setListenedSeconds} />
                  <EpisodeSect
                    episodes={otherEpisodes}
                    isLoading={isLoading}
                    isFetching={isFetching}
                    loadMore={loadMore}
                    totalData={totalData ? totalData - 1 : totalData}
                    dataPerPage={dataPerPage}
                    handleLoadMore={handleLoadMore}
                    podcastSlug={slug}
                  />
                </div>
                :
                !isLoading &&
                <EmptyStatus />
          }
        </section>
      </Layout>
    </>
  )
}

export default WithPageMode('podcast_mode')(EpisodePlay)
