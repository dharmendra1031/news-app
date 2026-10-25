import { Skeleton } from '@/components/ui/skeleton'

const PILL_COUNT = 6

const AlertsSectSkeleton = () => {
    return (
        <section className='commonBg'>
            <div className='container'>
                <div className='pt-6 md:hidden'>
                    <Skeleton className='h-6 w-24' />
                </div>
                <div className='flex items-center gap-3 py-3 md:h-25 max-md:pb-6'>
                    <div className='flex-1 min-w-0 flex gap-3 overflow-hidden'>
                        {Array.from({ length: PILL_COUNT }).map((_, index) => (
                            <Skeleton key={index} height={38} width={170} borderRadius={8} />
                        ))}
                    </div>

                    <Skeleton className='shrink-0 hidden md:block h-11 w-36' borderRadius={8} />
                </div>
            </div>
        </section>
    )
}

export default AlertsSectSkeleton
