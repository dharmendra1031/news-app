import { Skeleton } from "../ui/skeleton"

const CommentsCardSkeleton = () => {
    return (
        <div className="border borderColor rounded-xl p-3 md:p-4">
            <div className="flex items-center justify-between border-b pb-2 borderColor">
                <div className="flex items-center gap-2">
                    <Skeleton circle width={40} height={40} />
                    <div className="flex flex-col gap-1">
                        <Skeleton width={100} height={14} />
                        <Skeleton width={60} height={12} />
                    </div>
                </div>
            </div>

            <div className="flex flex-col gap-2 mt-2">
                <Skeleton width="100%" height={14} />
                <Skeleton width="70%" height={14} />
            </div>

            <div className="flex items-center gap-4 mt-3">
                <Skeleton width={32} height={16} />
                <Skeleton width={32} height={16} />
                <Skeleton width={50} height={16} />
            </div>
        </div>
    )
}

export default CommentsCardSkeleton
