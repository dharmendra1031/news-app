'use client'
import { useRef, useState } from 'react'
import Autoplay from 'embla-carousel-autoplay'
import SectionTitle from '../common/SectionTitle'
import CarouselDots from '../common/CarouselDots'
import { EpisodeCard } from '../pagesComp/podcast/EpisodeCard'
import PodcastCardSkeleton from '../skeletons/podcast/PodcastCardSkeleton'
import { useTranslation } from '@/hooks/useTranslation'
import { useGetPodcasts } from '@/hooks/queries/podcast/useGetPodcasts'
import { Carousel, CarouselApi, CarouselContent, CarouselItem } from '@/components/ui/carousel'
import { usePageMode } from '@/hooks/usePageMode'
import LocalizedLink from '../common/LocalizeLink'
import { getDirection } from '@/components/utils/helpers'

const DATA_PER_PAGE = 20

const PodcastSect = () => {

    const showPodcast = usePageMode('podcast_mode');

    const { t } = useTranslation()

    const { data: podcastsQueryData, isLoading } = useGetPodcasts({
        type: 'all',
        offset: 0,
        limit: DATA_PER_PAGE,
        slug: '',
        search: '',
    })

    const data = podcastsQueryData?.data?.data ?? []

    const [api, setApi] = useState<CarouselApi>()
    const [activeIndex, setActiveIndex] = useState(0)
    const autoplay = useRef(Autoplay({ delay: 2500, stopOnInteraction: false, stopOnMouseEnter: true }))

    const handleApi = (carouselApi: CarouselApi) => {
        setApi(carouselApi)
        if (!carouselApi) return

        setActiveIndex(carouselApi.selectedScrollSnap())
        carouselApi.on('select', () => setActiveIndex(carouselApi.selectedScrollSnap()))
    }

    if (!showPodcast) return null
    if (!isLoading && data.length === 0) return null

    return (
        <section className='container'>
            <SectionTitle title={t('podcast')} link='/podcast' showViewMore={data?.length > 3} />

            <Carousel
                opts={{ align: 'start', loop: true, direction: getDirection() }}
                plugins={[autoplay.current]}
                setApi={handleApi}
            >
                <CarouselContent>
                    {
                        isLoading
                            ? Array.from({ length: 2 }).map((_, index) => (
                                <CarouselItem key={index} className='basis-full lg:basis-1/2 ps-7.5'>
                                    <PodcastCardSkeleton />
                                </CarouselItem>
                            ))
                            : data?.map((podcast) => (
                                <CarouselItem key={podcast?.id} className='basis-full lg:basis-[42%] ps-7.5 [&_.customBgWhite]:bg-transparent! [&_.secondaryBorderColor]:borderColor!'>
                                    <LocalizedLink
                                        key={podcast?.id}
                                        href={`/podcast/${podcast?.slug}`}
                                    >
                                        <EpisodeCard data={podcast} podcastCard />
                                    </LocalizedLink>
                                </CarouselItem>
                            ))
                    }
                </CarouselContent>
            </Carousel>

            {
                !isLoading && data?.length > 2 &&
                <CarouselDots count={data.length} activeIndex={activeIndex} onSelect={(i) => api?.scrollTo(i)} />
            }
        </section>
    )
}

export default PodcastSect
