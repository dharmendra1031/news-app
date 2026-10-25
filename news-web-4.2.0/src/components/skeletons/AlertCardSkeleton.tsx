import { Skeleton } from '@/components/ui/skeleton'

const AlertCardSkeleton = () => {
    return (
        <div className='relative w-full rounded-[12px] border borderColor bg-white dark:secondaryBg overflow-hidden h-[90px]'>
            <div className='absolute left-0 top-0 h-full border-l-4 secondaryBorder dark:border-gray-400 rounded-l-[12px]' />

            <div className='flex justify-between gap-3 py-4 pl-6 pr-4 sm:py-5 sm:pl-7 sm:pr-5'>
                <Skeleton width={150} height={28} />

                <div className='flex flex-col items-end gap-2'>
                    <Skeleton width={60} height={22} />
                    <Skeleton width={60} height={18} />
                </div>
            </div>
        </div>
    )
}

export default AlertCardSkeleton
