import { Skeleton } from '@/components/ui/skeleton'

const VERTICAL_COUNT = 4
const HORIZONTAL_COUNT = 4

const StyleTwoSkeleton = () => {
  return (
    <section className='container'>
     <Skeleton className='h-12 w-48 mb-4' />

      <div className='grid grid-cols-1 commonGap'>
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 commonGap'>
          {Array.from({ length: VERTICAL_COUNT }).map((_, index) => (
            <Skeleton key={index} height={220} borderRadius={8} />
          ))}
        </div>

        <div className='grid grid-cols-1 sm:grid-cols-2 gap-y-7.5 sm:gap-x-0'>
          {Array.from({ length: HORIZONTAL_COUNT }).map((_, index) => (
            <Skeleton key={index} height={110} borderRadius={8} />
          ))}
        </div>
      </div>
    </section>
  )
}

export default StyleTwoSkeleton
