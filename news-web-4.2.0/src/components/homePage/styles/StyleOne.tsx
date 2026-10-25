'use client'
import SectionTitle from '@/components/common/SectionTitle'
import StyleOneCard from '@/components/common/newsCard/StyleOneCard'
import { Skeleton } from '@/components/ui/skeleton'
import { FeatureSectionStyleProps } from './styleProps'

const GRID_COUNT = 4
const TOTAL_COUNT = 1 + GRID_COUNT

const StyleOne = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {


  const data = news ?? []
  const featuredNews = data[0]
  const gridNews = data.slice(1, TOTAL_COUNT)

  if (!isLoading && data.length === 0) return null

  return (
    <section className='container styleOne'>
      <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 5} />

      <div className='grid grid-cols-12 gap-6 lg:commonGap'>
        <div className='col-span-12 lg:col-span-5'>
          {
            isLoading
              ? <Skeleton height={420} borderRadius={12} />
              : <StyleOneCard news={featuredNews} styleFive showCateBagde />
          }
        </div>

        <div className='col-span-12 lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 commonGap'>
          {
            isLoading
              ? Array.from({ length: GRID_COUNT }).map((_, index) => (
                <Skeleton key={index} height={190} borderRadius={12} />
              ))
              : gridNews.map((news) => (
                <StyleOneCard key={news.id} news={news} showCateBagde />
              ))
          }
        </div>
      </div>
    </section>
  )
}

export default StyleOne
