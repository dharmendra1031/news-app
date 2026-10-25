import { Skeleton } from '@/components/ui/skeleton'

const SLIDE_COUNT = 4

const StyleThreeSkeleton = () => {
  return (
    <section className='container'>
     <Skeleton className='h-12 w-48 mb-4' />

      <div className='flex gap-7.5 overflow-hidden'>
        {Array.from({ length: SLIDE_COUNT }).map((_, index) => (
          <div key={index} className='basis-full sm:basis-1/2 lg:basis-1/3 xl:basis-[28.5714%] 2xl:basis-[22.222%] shrink-0'>
            <Skeleton height={220} borderRadius={8} />
          </div>
        ))}
      </div>
    </section>
  )
}

export default StyleThreeSkeleton
