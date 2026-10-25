import { Skeleton } from "@/components/ui/skeleton"

const FeedCardSkeleton = () => {
  return (
    <div className='w-full h-max customBgWhite p-4 rounded-[6px] grid grid-cols-12 gap-6'>
      <div className='col-span-12 sm:col-span-3'>
        <Skeleton className='w-full h-auto sm:h-full aspect-[153/140] !rounded-[6px]' />
      </div>
      <div className='flex flex-col gap-2 col-span-12 sm:col-span-9'>
        <Skeleton width={90} height={24} borderRadius={16} />
        <div className='flex flex-col gap-2 lg:h-[88px]'>
          <Skeleton height={22} width="80%" />
          <Skeleton height={16} width="100%" />
          <Skeleton height={16} width="60%" />
        </div>
        <div className='flex items-center justify-between flex-wrap lg:flex-nowrap w-full border-t-2 pt-2 gap-y-3 dark:borderColor'>
          <Skeleton height={18} width={120} />
          <Skeleton height={18} width={90} />
        </div>
      </div>
    </div>
  )
}

export default FeedCardSkeleton
