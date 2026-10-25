'use client'
import { EpisodeCard } from '@/components/pagesComp/podcast/EpisodeCard'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useTranslation } from '@/hooks/useTranslation'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'

interface EpisodeSectProps {
    episodes?: EpisodeApi[]
    isLoading?: boolean
    isFetching?: boolean
    loadMore?: boolean
    totalData?: number
    dataPerPage: number
    handleLoadMore: () => void
    podcastSlug?: string
    manageEpisodeCard?: boolean
    deleteEpisode?: (id: number) => void
    podcastTitle?: string
    podcastId?: number
}

const EpisodeSect = ({
    episodes = [],
    isLoading,
    isFetching,
    loadMore,
    totalData = 0,
    dataPerPage,
    handleLoadMore,
    podcastSlug,
    manageEpisodeCard = false,
    deleteEpisode,
    podcastTitle,
    podcastId,
}: EpisodeSectProps) => {

    const { t } = useTranslation();

    return (
        (isLoading || episodes?.length > 0) ?
            <div className='grid grid-cols-1 gap-4 sm:gap-7'>
                <div className='flex items-center customBgWhite rounded-2xl p-4 sm:py-5 sm:px-9 border seconadryBorderColor'>
                    <h2 className="text-lg sm:text-xl md:text-3xl xl:text-[34px] font-semibold textPrimary line-clamp-2 sm:line-clamp-1">
                        {t('episodes')}
                    </h2>
                </div>
                <div className='grid md:grid-cols-2 lg:grid-cols-3 gap-6'>
                    {
                        isLoading && !loadMore ?
                            Array.from({ length: dataPerPage })?.map((_, index) => (
                                <div key={index} className='h-[112px] sm:h-[140px] rounded-2xl bg-gray-300 border borderColor animate-pulse' />
                            ))
                            :
                            episodes?.map((episode) => (
                                manageEpisodeCard ?
                                    <div key={episode?.id}>
                                        <EpisodeCard
                                            data={episode}
                                            manageEpisodeCard={manageEpisodeCard}
                                            onDelete={deleteEpisode}
                                            podcastTitle={podcastTitle}
                                            podcastId={podcastId}
                                            podcastSlug={podcastSlug}
                                        />
                                    </div>
                                    :
                                    <LocalizedLink key={episode?.id} href={`/podcast/${podcastSlug}/${episode?.slug}`}>
                                        <EpisodeCard
                                            data={episode}
                                            manageEpisodeCard={manageEpisodeCard}
                                            onDelete={deleteEpisode}
                                            podcastTitle={podcastTitle}
                                            podcastId={podcastId}
                                            podcastSlug={podcastSlug}
                                        />
                                    </LocalizedLink>
                            ))
                    }
                </div>
                <div className='mt-6'>
                    {totalData > dataPerPage && totalData !== episodes?.length ? (
                        <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                    ) : null}
                </div>
            </div>
            :
            null
    )
}

export default EpisodeSect
