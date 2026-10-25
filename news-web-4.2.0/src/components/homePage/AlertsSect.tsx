'use client'
import { useRef } from 'react'
import Autoplay from 'embla-carousel-autoplay'
import { AlertCard } from './AlertCard'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useTranslation } from '@/hooks/useTranslation'
import { useGetMarketAlerts } from '@/hooks/queries/useGetMarketAlerts'
import { Carousel, CarouselContent, CarouselItem } from '@/components/ui/carousel'
import SectionTitle from '../common/SectionTitle'
import AlertsSectSkeleton from '@/components/skeletons/AlertsSectSkeleton'
import { getDirection } from '../utils/helpers'

const DATA_PER_PAGE = 10

const AlertsSect = () => {

    const { t } = useTranslation();
    const { data: alertsQueryData, isLoading } = useGetMarketAlerts({
        offset: 0,
        limit: DATA_PER_PAGE,
    });

    const data = alertsQueryData?.data?.data ?? []

    const autoplay = useRef(Autoplay({ delay: 2500, stopOnInteraction: false, stopOnMouseEnter: true }))

    if (isLoading) return <AlertsSectSkeleton />

    if (data.length === 0) return null

    return (
        <section className='commonBg'>
            <div className='container'>
                <div className='pt-6 md:hidden'>
                    <SectionTitle title={t('alerts')} link='/alerts' />
                </div>
                <div className='flex items-center gap-3 py-3 md:h-25 max-md:pb-6'>
                    <Carousel
                        plugins={[autoplay.current]}
                        opts={{ align: 'start', dragFree: true, containScroll: 'trimSnaps', loop: true, direction: getDirection() }}
                        className='flex-1 min-w-0'
                    >
                        <CarouselContent className='-ms-3'>
                            {
                                data?.map((alert) => (
                                    <CarouselItem key={alert?.id} className='basis-auto grow-0 shrink-0 ps-3'>
                                        <AlertCard data={alert} />
                                    </CarouselItem>
                                ))
                            }
                        </CarouselContent>
                    </Carousel>

                    <LocalizedLink href='/alerts' className='shrink-0 hidden md:block'>
                        <button className={`secondaryBtn commonRadius px-5 py-2.5 text-sm font-medium whitespace-nowrap md:text-lg lg:text-xl`}>
                            {t('showAllAlerts')}
                        </button>
                    </LocalizedLink>
                </div>
            </div>
        </section>
    )
}

export default AlertsSect
