'use client'
import { useRef, useState } from 'react'
import Autoplay from 'embla-carousel-autoplay'
import SectionTitle from '@/components/common/SectionTitle'
import CarouselDots from '@/components/common/CarouselDots'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import { Skeleton } from '@/components/ui/skeleton'
import { Carousel, CarouselApi, CarouselContent, CarouselItem } from '@/components/ui/carousel'
import { FeatureSectionStyleProps } from './styleProps'
import { getDirection } from '@/components/utils/helpers'

const StyleThree = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {
  const [api, setApi] = useState<CarouselApi>()
  const [activeIndex, setActiveIndex] = useState(0)
  const autoplay = useRef(Autoplay({ delay: 2500, stopOnInteraction: false, stopOnMouseEnter: true }))


  const data = news ?? []

  const handleApi = (carouselApi: CarouselApi) => {
    setApi(carouselApi)
    if (!carouselApi) return

    setActiveIndex(carouselApi.selectedScrollSnap())
    carouselApi.on('select', () => setActiveIndex(carouselApi.selectedScrollSnap()))
  }

  if (!isLoading && data?.length === 0) return null

  return (
    <section className='container styleThree'>
      <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 6} />

      <Carousel
        opts={{ align: 'start', loop: true, direction: getDirection() }}
        plugins={[autoplay.current]}
        setApi={handleApi}
      >
        <CarouselContent>
          {
            isLoading
              ? Array.from({ length: 4 }).map((_, index) => (
                <CarouselItem key={index} className='basis-full sm:basis-1/2 lg:basis-1/3 xl:basis-[28.5714%] 2xl:basis-[22.222%] ps-7.5'>
                  <Skeleton height={220} borderRadius={8} />
                </CarouselItem>
              ))
              : data?.map((news) => (
                <CarouselItem key={news.id} className='basis-full sm:basis-1/2 lg:basis-1/3 xl:basis-[28.5714%] 2xl:basis-[22.222%] ps-7.5'>
                  <VerticalCard news={news} showCateBagde />
                </CarouselItem>
              ))
          }
        </CarouselContent>
      </Carousel>

      {
        !isLoading && data?.length > 6 &&
        <CarouselDots count={data.length} activeIndex={activeIndex} onSelect={(i) => api?.scrollTo(i)} />
      }
    </section>
  )
}

export default StyleThree
