import { Skeleton } from '@/components/ui/skeleton'

const HORIZONTAL_COUNT = 2
const VERTICAL_COUNT = 3

const StyleFiveSkeleton = () => {
  return (
    <section className='container'>
     <Skeleton className='h-12 w-48 mb-4' />

      <div className='grid grid-cols-12 gap-6 lg:commonGap'>
        <div className='col-span-12 lg:col-span-4 flexCol gap-4 sm:gap-6'>
          {Array.from({ length: HORIZONTAL_COUNT }).map((_, index) => (
            <Skeleton key={index} height={90} borderRadius={8} />
          ))}
        </div>

        <div className='col-span-12 lg:col-span-8 grid grid-cols-1 sm:grid-cols-3 gap-6 lg:commonGap'>
          {Array.from({ length: VERTICAL_COUNT }).map((_, index) => (
            <Skeleton key={index} height={220} borderRadius={8} />
          ))}
        </div>
      </div>
    </section>
  )
}

export default StyleFiveSkeleton
