'use client'

import { Skeleton } from '@/components/ui/skeleton'

export const EpisodeCardSkeleton = ({ podcastCard = false }) => {
  return (
    <div className="flex gap-3 rounded-2xl customBgWhite p-3 border borderColor relative">
      {/* Thumbnail */}
      <div className="relative shrink-0 w-24 h-24 sm:w-32 sm:h-32 rounded-lg overflow-hidden">
        <Skeleton className="!w-full !h-full" />
      </div>

      {/* Content */}
      <div className="flex flex-col flex-1 gap-2">
        {!podcastCard && (
          <>
            {/* Menu */}
            <div className="absolute top-3 right-3">
              <Skeleton circle width={28} height={28} />
            </div>

            {/* Episode */}
            <Skeleton width={70} height={14} />
          </>
        )}

        {/* Title */}
        <Skeleton
          height={24}
          width={podcastCard ? '90%' : '80%'}
        />

        {/* Description */}
        <Skeleton height={16} width="100%" />
        <Skeleton height={16} width="75%" />

        {podcastCard ? (
          <div className="flex items-center gap-6 mt-2">
            <div className="flex items-center gap-2">
              <Skeleton circle width={18} height={18} />
              <Skeleton width={35} height={16} />
            </div>

            <div className="flex items-center gap-2">
              <Skeleton circle width={18} height={18} />
              <Skeleton width={35} height={16} />
            </div>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-6 mt-2">
              <div className="flex items-center gap-2">
                <Skeleton circle width={18} height={18} />
                <Skeleton width={70} height={16} />
              </div>

              <div className="flex items-center gap-2">
                <Skeleton circle width={18} height={18} />
                <Skeleton width={90} height={16} />
              </div>
            </div>

            {/* Progress Bar */}
            <Skeleton
              height={10}
              borderRadius={9999}
              className="mt-2"
            />
          </>
        )}
      </div>
    </div>
  )
}
