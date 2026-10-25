'use client'
import SectionTitle from '@/components/common/SectionTitle'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import HorizontalCard from '@/components/common/newsCard/HorizontalCard'
import { Skeleton } from '@/components/ui/skeleton'
import { FeatureSectionStyleProps } from './styleProps'

const VERTICAL_COUNT = 4
const HORIZONTAL_COUNT = 4

const StyleTwo = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {


  const data = news ?? []
  const verticalNews = data.slice(0, VERTICAL_COUNT)
  const horizontalNews = data.slice(VERTICAL_COUNT, VERTICAL_COUNT + HORIZONTAL_COUNT)

  if (!isLoading && data.length === 0) return null

  return (
    <section className='container styleTwo'>
      <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 8} />

      <div className='grid grid-cols-1 commonGap'>
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 commonGap'>
          {
            isLoading
              ? Array.from({ length: VERTICAL_COUNT }).map((_, index) => (
                <Skeleton key={index} height={220} borderRadius={8} />
              ))
              : verticalNews.map((news) => (
                <VerticalCard key={news.id} news={news} isReverse={false} style='style_2' />
              ))
          }
        </div>

        <div className='grid grid-cols-1 lg:grid-cols-2 gap-y-7.5 sm:gap-x-0'>
          {
            isLoading
              ? Array.from({ length: HORIZONTAL_COUNT }).map((_, index) => (
                <Skeleton key={index} height={110} borderRadius={8} />
              ))
              : horizontalNews.map((news, index) => (
                <div
                  key={news.id}
                  className={`${index % 2 === 0 ? 'lg:border-r lg:border-(--border-color) lg:pr-7.5' : 'lg:pl-7.5'}`}
                >
                  <HorizontalCard news={news} isReverse style='style_2' />
                </div>
              ))
          }
        </div>
      </div>

    </section>
  )
}

export default StyleTwo
