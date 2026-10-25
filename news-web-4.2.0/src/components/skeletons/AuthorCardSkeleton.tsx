'use client'
import { Skeleton } from '@/components/ui/skeleton'

const AuthorCardSkeleton = () => {
    return (
        <div className='flex flex-col gap-8'>
            <div className='flex justify-between items-center'>
                <Skeleton width={100} height={28} />
                <div className='flex gap-2.5'>
                    <Skeleton width={48} height={48} borderRadius={8} />
                    <Skeleton width={48} height={48} borderRadius={8} />
                </div>
            </div>
            <div className='bg-white dark:secondaryBg commonRadius p-5 border borderColor flex flex-col gap-4'>
                <div className='flex items-center gap-3'>
                    <Skeleton circle width={40} height={40} />
                    <div className='flex flex-col justify-center gap-1'>
                        <Skeleton width={60} height={14} />
                        <Skeleton width={120} height={18} />
                    </div>
                </div>
                <div className='border-t borderColor pt-4 flex flex-col gap-2'>
                    <Skeleton width='100%' height={14} />
                    <Skeleton width='80%' height={14} />
                </div>
            </div>
        </div>
    )
}

export default AuthorCardSkeleton
