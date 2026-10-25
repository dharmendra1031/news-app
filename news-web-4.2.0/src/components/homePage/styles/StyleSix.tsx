'use client'
import { Fragment } from 'react'
import SectionTitle from '@/components/common/SectionTitle'
import VerticalCard from '@/components/common/newsCard/VerticalCard'
import HorizontalCard from '@/components/common/newsCard/HorizontalCard'
import { Skeleton } from '@/components/ui/skeleton'
import { FeatureSectionStyleProps } from './styleProps'

const GRID_COUNT = 4
const LIST_COUNT = 4
const TOTAL_COUNT = GRID_COUNT + LIST_COUNT

const StyleSix = ({ title, link, feedCateIds, news, isLoading = false }: FeatureSectionStyleProps) => {


  const data = news ?? []
  const gridNews = data.slice(0, GRID_COUNT)
  const listNews = data.slice(GRID_COUNT, TOTAL_COUNT)

  if (!isLoading && data.length === 0) return null

  return (
    <section className='container styleSix'>
      <SectionTitle title={title} link={link} feedCateIds={feedCateIds} showViewMore={data?.length > 8} />

      <div className='grid grid-cols-12 gap-6 lg:commonGap'>
        <div className='col-span-12 lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 commonGap'>
          {
            isLoading
              ? Array.from({ length: GRID_COUNT }).map((_, index) => (
                <Skeleton key={index} height={220} borderRadius={8} />
              ))
              : gridNews.map((news) => (
                <VerticalCard key={news.id} news={news} showCateBagde style='style_6' />
              ))
          }
        </div>

        <div className='col-span-12 lg:col-span-5 flexCol gap-6 lg:commonGap'>
          {
            isLoading
              ? Array.from({ length: LIST_COUNT }).map((_, index) => (
                <Skeleton key={index} height={90} borderRadius={8} />
              ))
              : listNews.map((news, index) => (
                <Fragment key={news.id}>
                  <HorizontalCard news={news} showCateBagde isCateWhiteBg={false} />
                  {index < listNews.length - 1 && <div className='border-b borderColor' />}
                </Fragment>
              ))
          }
        </div>
      </div>
    </section>
  )
}

export default StyleSix
