'use client'
import { Fragment } from 'react'
import SectionTitle from '@/components/common/SectionTitle'
import StyleFiveCard from '@/components/common/newsCard/StyleOneCard'
import HorizontalCard from '@/components/common/newsCard/HorizontalCard'
import { Skeleton } from '@/components/ui/skeleton'
import { FeatureSectionStyleProps } from './styleProps'

const LIST_COUNT = 4
const TOTAL_COUNT = 1 + LIST_COUNT

const StyleFour = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {


    const data = news ?? []
    const featuredNews = data[0]
    const listNews = data.slice(1, TOTAL_COUNT)

    if (!isLoading && data.length === 0) return null

    return (
        <section className='container styleFour'>
            <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 5} />

            <div className='grid grid-cols-12 gap-6 lg:commonGap items-stretch'>
                <div className='col-span-12 lg:col-span-5'>
                    {
                        isLoading
                            ? <Skeleton height={420} borderRadius={12} />
                            : <StyleFiveCard news={featuredNews} large />
                    }
                </div>

                <div className='col-span-12 lg:col-span-7 flexCol gap-4 sm:gap-6 py-1'>
                    {
                        isLoading
                            ? Array.from({ length: LIST_COUNT }).map((_, index) => (
                                <Skeleton key={index} height={90} borderRadius={8} />
                            ))
                            :
                            <div className='flexCol gap-4 lg:commongap'>
                                {listNews.map((news, index) => (
                                    <Fragment key={news.id}>
                                        <HorizontalCard news={news} style='style_4' />
                                        {index < listNews.length - 1 && <div className='border-b borderColor' />}
                                    </Fragment>
                                ))}
                            </div>
                    }
                </div>
            </div>
        </section>
    )
}

export default StyleFour
