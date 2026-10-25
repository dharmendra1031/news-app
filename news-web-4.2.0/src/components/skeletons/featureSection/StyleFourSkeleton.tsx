import { Skeleton } from '@/components/ui/skeleton'

const LIST_COUNT = 4

const StyleFourSkeleton = () => {
    return (
        <section className='container'>
           <Skeleton className='h-12 w-48 mb-4' />

            <div className='grid grid-cols-12 gap-6 lg:commonGap items-stretch'>
                <div className='col-span-12 lg:col-span-5'>
                    <Skeleton height={420} borderRadius={12} />
                </div>

                <div className='col-span-12 lg:col-span-7 flexCol gap-4 sm:gap-6 py-1'>
                    {Array.from({ length: LIST_COUNT }).map((_, index) => (
                        <Skeleton key={index} height={90} borderRadius={8} />
                    ))}
                </div>
            </div>
        </section>
    )
}

export default StyleFourSkeleton
