'use client'

import { Skeleton } from '@/components/ui/skeleton'

const PodcastCardSkeleton = ({ episodePlayCard = false }) => {
  return (
    <div className="flex flex-col gap-4 rounded-2xl customBgWhite p-3 sm:p-4 border borderColor">
      <div className="flex gap-6 max-sm:flex-col">
        {/* Thumbnail */}
        <div
          className={`relative shrink-0 ${
            episodePlayCard
              ? 'max-sm:w-auto max-sm:h-[266px] w-24 h-24 sm:w-36 sm:h-36 lg:w-[523px] lg:h-[523px] aspect-[523/523]'
              : 'max-sm:w-auto max-sm:h-[266px] w-24 h-24 sm:w-36 sm:h-36 lg:w-[266px] lg:h-[266px] aspect-[266/266]'
          } rounded-lg overflow-hidden`}
        >
          <Skeleton className="!w-full !h-full" />
        </div>

        {/* Content */}
        <div className="flex flex-col justify-center gap-5 flex-1 min-w-0">
          {/* Stats */}
          {!episodePlayCard && (
            <div className="flex justify-end gap-6">
              <div className="flex items-center gap-2">
                <Skeleton circle width={20} height={20} />
                <Skeleton width={40} height={18} />
              </div>

              <div className="flex items-center gap-2">
                <Skeleton circle width={20} height={20} />
                <Skeleton width={40} height={18} />
              </div>
            </div>
          )}

          {/* Title & Description */}
          <div className="flex flex-col gap-3">
            <Skeleton height={34} width="80%" />
            <Skeleton height={20} width="100%" />
            <Skeleton height={20} width="75%" />
          </div>

          {/* Episode footer */}
          {episodePlayCard && (
            <div className="flex flex-wrap items-center justify-between gap-3 pt-5 border-t borderColor">
              <div className="flex gap-6">
                <div className="flex items-center gap-2">
                  <Skeleton circle width={20} height={20} />
                  <Skeleton width={40} height={18} />
                </div>

                <div className="flex items-center gap-2">
                  <Skeleton circle width={20} height={20} />
                  <Skeleton width={60} height={18} />
                </div>
              </div>

              <div className="flex gap-4">
                <Skeleton circle width={28} height={28} />
                <Skeleton circle width={24} height={24} />
              </div>
            </div>
          )}

          {/* Author & Buttons */}
          <div className="flex flex-wrap items-center justify-between gap-3 pt-5 border-t borderColor">
            <div className="flex items-center gap-3 min-w-0">
              <Skeleton circle width={48} height={48} />
              <Skeleton width={120} height={22} />
            </div>

            <div className="flex gap-3 ms-auto">
              <Skeleton
                width={110}
                height={42}
                borderRadius={8}
              />

              {!episodePlayCard && (
                <Skeleton
                  width={110}
                  height={42}
                  borderRadius={8}
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default PodcastCardSkeleton
