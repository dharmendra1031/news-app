'use client'
import { useRef, useState } from 'react'
import Autoplay from 'embla-carousel-autoplay'
import SectionTitle from '../common/SectionTitle'
import CarouselDots from '../common/CarouselDots'
import LiveNewsCard from '../common/newsCard/LiveNewsCard'
import { Skeleton } from '@/components/ui/skeleton'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { useGetLiveNews } from '@/hooks/queries/useGetLiveNews'
import { Carousel, CarouselApi, CarouselContent, CarouselItem } from '@/components/ui/carousel'
import { usePageMode } from '@/hooks/usePageMode'
import { getDirection } from '@/components/utils/helpers'

export const LIVE_NEWS_LIMIT = 8

const LiveNewsSect = () => {

  const { t } = useTranslation()
  const langCode = useLangCode()

  const showLiveNews = usePageMode('live_streaming_mode')

  const { data: liveNewsQueryData, isLoading } = useGetLiveNews({
    language_code: langCode,
    offset: 0,
    limit: LIVE_NEWS_LIMIT,
  })

  const data = liveNewsQueryData?.data?.data ?? []

  const [api, setApi] = useState<CarouselApi>()
  const [activeIndex, setActiveIndex] = useState(0)
  const autoplay = useRef(Autoplay({ delay: 2500, stopOnInteraction: false, stopOnMouseEnter: true }))

  const handleApi = (carouselApi: CarouselApi) => {
    setApi(carouselApi)
    if (!carouselApi) return

    setActiveIndex(carouselApi.selectedScrollSnap())
    carouselApi.on('select', () => setActiveIndex(carouselApi.selectedScrollSnap()))
  }

  if (!showLiveNews) return null
  if (!isLoading && data.length === 0) return null

  return (
    <section className='container'>
      <SectionTitle title={t('livenews')} link='/live-news' showViewMore={data?.length > 4} />

      <Carousel
        opts={{ align: 'start', loop: true, direction: getDirection() }}
        plugins={[autoplay.current]}
        setApi={handleApi}
      >
        <CarouselContent>
          {
            isLoading
              ? Array.from({ length: 4 }).map((_, index) => (
                <CarouselItem key={index} className=' sm:basis-1/2 lg:basis-1/3 2xl:basis-1/4 ps-7.5'>
                  <Skeleton className='w-full! aspect-square' borderRadius={10} />
                </CarouselItem>
              ))
              : data?.map((liveNews) => (
                <CarouselItem key={liveNews.id} className=' sm:basis-1/2 lg:basis-1/3 2xl:basis-1/4 ps-7.5'>
                  <LiveNewsCard data={liveNews} />
                </CarouselItem>
              ))
          }
        </CarouselContent>
      </Carousel>

      {
        !isLoading && data?.length > 4 &&
        <CarouselDots count={data.length} activeIndex={activeIndex} onSelect={(i) => api?.scrollTo(i)} />
      }
    </section>
  )
}

export default LiveNewsSect
