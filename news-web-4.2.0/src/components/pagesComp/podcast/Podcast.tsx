'use client'
import React, { useEffect, useState } from 'react'
// import Layout from '../../layout/Layout'
// import { translate } from '@/utils/translation'
import LocalizedLink from '@/components/common/LocalizeLink'
// import { currentLangCode, isLogin } from '@/utils/helpers'
import { AiOutlineSearch } from 'react-icons/ai'
import { EpisodeCardSkeleton } from '@/components/skeletons/podcast/EpisodeCardSkeleton'
// import { setLoginModalState } from '@/components/store/reducers/helperReducer'
import { toast } from '@/lib/toast'
import EmptyStatus from '@/components/common/EmptyStatus'
import Breadcrumb from '@/components/common/Breadcrumb'
import { useGetPodcasts } from '@/hooks/queries/podcast/useGetPodcasts'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { useGetMyEpisodes, MyEpisodeApi } from '@/hooks/queries/podcast/useGetMyEpisodes'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import { EpisodeCard } from './EpisodeCard'
import { isLogin } from '@/components/utils/helpers'
import Layout from '@/components/Layout/Layout'
import { useTranslation } from '@/hooks/useTranslation'
import WithPageMode from '@/components/hoc/WithPageMode'
import { useDispatch } from 'react-redux'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'

const Podcast = () => {

    const { t } = useTranslation();
    const dispatch = useDispatch();

    const dataPerPage = 4;

    const [loadMore, setLoadMore] = useState(false)
    const [data, setData] = useState<(MyEpisodeApi | PodcastApi)[]>([])
    const [offset, setOffset] = useState(0)
    const [totalData, setTotalData] = useState(0)

    const [searchValue, setSearchValue] = useState<string | null>(null)
    const [debouncedSearch, setDebouncedSearch] = useState<string | null>(null)

    const [activeTab, setActiveTab] = useState(0)

    const tabs = [
        {
            id: 0,
            label: t('allLbl'),
            type: 'all',
        },
        {
            id: 1,
            label: t('history'),
            type: 'history',
        },
        {
            id: 2,
            label: t('bookmark'),
            type: 'bookmark',
        },
    ]

    useEffect(() => {
        const timeout = setTimeout(() => {
            setDebouncedSearch(searchValue)
        }, 500);
        return () => clearTimeout(timeout)
    }, [searchValue]);

    const [prevActiveTab, setPrevActiveTab] = useState(activeTab)
    const [prevDebouncedSearch, setPrevDebouncedSearch] = useState(debouncedSearch)
    if (activeTab !== prevActiveTab || debouncedSearch !== prevDebouncedSearch) {
        setPrevActiveTab(activeTab)
        setPrevDebouncedSearch(debouncedSearch)
        setLoadMore(false)
        setOffset(0)
        setData([])
    }

    const activeTabType = tabs.find((tab) => tab.id === activeTab)?.type
    const isEpisodesTab = activeTabType === 'history' || activeTabType === 'bookmark'

    const { data: podcastsQueryData, isLoading: isPodcastsLoading, isFetching: isPodcastsFetching, isError: isPodcastsError, error: podcastsError } = useGetPodcasts({
        type: activeTabType,
        search: debouncedSearch ?? undefined,
        offset: offset * dataPerPage,
        limit: dataPerPage,
        enabled: !isEpisodesTab,
    });

    const { data: episodesQueryData, isLoading: isEpisodesLoading, isFetching: isEpisodesFetching, isError: isEpisodesError, error: episodesError } = useGetMyEpisodes({
        type: activeTabType || 'all',
        offset: offset * dataPerPage,
        limit: dataPerPage,
        enabled: isEpisodesTab,
    });

    const queryData = isEpisodesTab ? episodesQueryData : podcastsQueryData
    const isLoading = isEpisodesTab ? isEpisodesLoading : isPodcastsLoading
    const isFetching = isEpisodesTab ? isEpisodesFetching : isPodcastsFetching
    const isError = isEpisodesTab ? isEpisodesError : isPodcastsError
    const error = isEpisodesTab ? episodesError : podcastsError

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof queryData | symbol>(() => Symbol('initial'))
    if (!isError && queryData !== prevQueryData) {
        setPrevQueryData(queryData)
        if (queryData) {
            const items: (MyEpisodeApi | PodcastApi)[] = isEpisodesTab
                ? episodesQueryData?.data?.episodes ?? []
                : podcastsQueryData?.data?.data ?? []
            setTotalData(isEpisodesTab ? episodesQueryData?.data?.total ?? 0 : podcastsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setData((prev) => [...prev, ...items])
            } else {
                setData(items)
            }
        }
    }

    useEffect(() => {
        if (isError) {
            console.log('podcasts err =>', error?.message)
        }
    }, [isError, error]);

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    const handleTabChange = (id: number) => {
        if (id === 0) {
            setActiveTab(id)
        }
        else {
            if (isLogin()) {
                setActiveTab(id)
            }
            else {
                dispatch(setLoginModalOpen(true))
                setTimeout(() => {
                    dispatch(setLoginModalOpen(false))
                }, 2000)
                return false
            }
        }
    }

    return (
        <Layout>
            <Breadcrumb secondElement={('podcast')} />
            <section className='container commonMT'>

                <div className='flex items-center justify-between md:hidden w-full p-2 sm:p-3 border borderColor rounded-[8px] customBgWhite'>
                    <input type="text" placeholder={t('searchPodcast')} className='max-[360px]:w-[150px] w-full text-black focus:outline-none text-[18px] bg-transparent' onChange={(e) => setSearchValue(e.target.value)} />
                    <button aria-label="Search" className='primaryColor'><AiOutlineSearch size={23} /></button>
                </div>

                <div className='flex items-center customBgWhite rounded-2xl p-3 border seconadryBorderColor gap-3 overflow-x-auto customScrollbar commonMT'>
                    <div className="grid grid-rows-1 grid-flow-col gap-3 w-fit">
                        {
                            tabs?.map((tab) => {
                                return <div key={tab?.id} className={`w-28 md:w-[200px] rounded-[8px] p-3 flexCenter font-bold cursor-pointer ${tab.id === activeTab ? 'secondaryBg dark:bodyBgColor text-white' : 'opacity-70'}`}
                                    onClick={() => handleTabChange(tab?.id)}
                                >
                                    {tab?.label}
                                </div>
                            })
                        }
                    </div>

                    {
                        !isEpisodesTab &&
                        <div className='hidden md:flex items-center justify-between w-full p-2 sm:p-3 border borderColor rounded-[8px] customBgWhite'>
                            <input type="text" placeholder={t('searchPodcast')} className='max-[360px]:w-[150px] w-full focus:outline-none text-[18px] bg-transparent' onChange={(e) => setSearchValue(e.target.value)} />
                            <button aria-label="Search" className='primaryColor'><AiOutlineSearch size={23} /></button>
                        </div>
                    }

                </div>
                <div className='grid md:grid-cols-2 2xl:grid-cols-3 gap-6 commonMT'>
                    {
                        isLoading && !loadMore ?
                            Array.from({ length: dataPerPage })?.map((_, index) => (
                                <EpisodeCardSkeleton podcastCard={true} key={index} />
                            ))
                            :
                            data?.map((item) => (
                                <LocalizedLink
                                    key={item?.id}
                                    href={
                                        isEpisodesTab
                                            ? `/podcast/${(item as MyEpisodeApi)?.podcast?.slug}/${item?.slug}`
                                            : `/podcast/${item?.slug}`
                                    }
                                >
                                    <EpisodeCard
                                        podcastCard={!isEpisodesTab}
                                        data={item}
                                        myEpisodesCard={isEpisodesTab}
                                    />
                                </LocalizedLink>
                            ))
                    }
                </div>

                {
                    !isLoading && data?.length < 1 &&
                    <div>
                        <EmptyStatus />
                    </div>
                }
                <div className='mt-12'>
                    {totalData > dataPerPage && totalData !== data?.length && data?.length > 0 ? (
                        <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                    ) : null}
                </div>
            </section>
        </Layout>
    )
}

export default WithPageMode('podcast_mode')(Podcast)