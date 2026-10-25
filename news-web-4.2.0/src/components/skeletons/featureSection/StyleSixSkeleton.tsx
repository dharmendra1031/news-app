import { Skeleton } from '@/components/ui/skeleton'

const GRID_COUNT = 4
const LIST_COUNT = 4

const StyleSixSkeleton = () => {
  return (
    <section className='container'>
     <Skeleton className='h-12 w-48 mb-4' />

      <div className='grid grid-cols-12 gap-6 lg:commonGap'>
        <div className='col-span-12 lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 commonGap'>
          {Array.from({ length: GRID_COUNT }).map((_, index) => (
            <Skeleton key={index} height={220} borderRadius={8} />
          ))}
        </div>

        <div className='col-span-12 lg:col-span-5 flexCol gap-6 lg:commonGap'>
          {Array.from({ length: LIST_COUNT }).map((_, index) => (
            <Skeleton key={index} height={90} borderRadius={8} />
          ))}
        </div>
      </div>
    </section>
  )
}

export default StyleSixSkeleton
