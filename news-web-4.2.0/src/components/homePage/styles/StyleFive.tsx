'use client'
import SectionTitle from '@/components/common/SectionTitle'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import HorizontalCard from '@/components/common/newsCard/HorizontalCard'
import { Skeleton } from '@/components/ui/skeleton'
import { FeatureSectionStyleProps } from './styleProps'

const HORIZONTAL_COUNT = 2
const VERTICAL_COUNT = 3
const TOTAL_COUNT = HORIZONTAL_COUNT + VERTICAL_COUNT

const StyleFive = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {


  const data = news ?? []
  const horizontalNews = data.slice(0, HORIZONTAL_COUNT)
  const verticalNews = data.slice(HORIZONTAL_COUNT, TOTAL_COUNT)

  if (!isLoading && data.length === 0) return null

  return (
    <section className='container styleFive'>
      <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 5} />

      <div className='grid grid-cols-12 gap-6 lg:commonGap'>
        <div className='col-span-12 min-1200:col-span-4 flexCol gap-4 sm:gap-6'>
          {
            isLoading
              ? Array.from({ length: HORIZONTAL_COUNT }).map((_, index) => (
                <Skeleton key={index} height={90} borderRadius={8} />
              ))
              : horizontalNews.map((news) => (
                <HorizontalCard key={news.id} news={news} />
              ))
          }
        </div>

        <div className='col-span-12 min-1200:col-span-8 grid grid-cols-1 sm:grid-cols-3 gap-6 lg:commonGap'>
          {
            isLoading
              ? Array.from({ length: VERTICAL_COUNT }).map((_, index) => (
                <Skeleton key={index} height={220} borderRadius={8} />
              ))
              : verticalNews.map((news) => (
                <VerticalCard key={news.id} news={news} style='style_5' />
              ))
          }
        </div>
      </div>
    </section>
  )
}

export default StyleFive
