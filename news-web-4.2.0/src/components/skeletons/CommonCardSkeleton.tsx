import { Skeleton } from "../ui/skeleton"

interface CommonCardSkeletonProps {
  subDropCard?: boolean
}

const CommonCardSkeleton = ({ subDropCard = false }: CommonCardSkeletonProps) => {
  return (
    <div className='flex flex-col gap-4'>
      <Skeleton height={subDropCard ? 150 : 200} />
      <Skeleton height={subDropCard ? 20 : 30} />
      <Skeleton height={subDropCard ? 20 : 30} />
    </div>
  )
}

export default CommonCardSkeleton
