'use client'
import React, { useEffect } from 'react'
import { useTranslation } from '@/hooks/useTranslation'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { Skeleton } from '@/components/ui/skeleton'
import { TagApi } from '@/hooks/queries/useGetTags'

interface TagTabContentProps {
  selectedTagIds: string
  setSelectedTagIds: (ids: string) => void
  selectedTags: Record<string, boolean>
  setSelectedTags: React.Dispatch<React.SetStateAction<Record<string, boolean>>>
  tagsData: TagApi[]
  isLoadingTags: {
    loading: boolean
    loadMoreLoading: boolean
  }
  totalTags: number | string
  handleLoadMoreTags: () => void
  offset: number
}

const TagTabContent: React.FC<TagTabContentProps> = ({
  setSelectedTagIds,
  selectedTags,
  setSelectedTags,
  tagsData,
  isLoadingTags,
  totalTags,
  handleLoadMoreTags,
  offset,
}) => {
  const { t } = useTranslation()

  // Array of tags
  const allTags = tagsData

  // Split tags into two halves
  const halfLength = Math.ceil(allTags?.length / 2)
  const leftTags = allTags?.slice(0, halfLength)
  const rightTags = allTags?.slice(halfLength)

  useEffect(() => {
    if (offset < 1) {
      const selectedNames = Object.keys(selectedTags)
        .filter((tag) => selectedTags[tag])
        .join(', ')
      setSelectedTagIds(selectedNames)
    }
  }, [selectedTags, setSelectedTagIds, offset])

  // Handle selection/deselection
  const handleTagToggle = (tagId: number) => {
    const key = String(tagId)
    setSelectedTags((prev) => ({
      ...prev,
      [key]: !prev[key],
    }))
  }

  // Render a single tag item
  const renderTagItem = (tag: TagApi) => (
    <div
      key={tag?.id}
      className="flex items-center justify-between py-2 cursor-pointer"
      onClick={() => handleTagToggle(tag?.id)}
    >
      <span className="textPrimary font-medium break-all first-letter:capitalize">{tag?.tag_name}</span>
      <div
        className={`h-6 w-6 border bordercolor rounded flex items-center justify-center ${
          selectedTags[String(tag?.id)] ? 'primaryBg' : 'customBgWhite'
        }`}
      >
        {selectedTags[String(tag?.id)] && (
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-4 w-4 text-white"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fillRule="evenodd"
              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
              clipRule="evenodd"
            />
          </svg>
        )}
      </div>
    </div>
  )

  return allTags?.length > 0 || isLoadingTags?.loading ? (
    <div className="bg-white dark:bodyBgColor rounded-[8px] border bordercolor p-2 sm:p-4 h-[300px] overflow-y-auto sm:h-max">
      {isLoadingTags?.loading ? (
        <div className="flex">
          {/* Left Column Skeleton */}
          <div className="flex-1 ltr:border-r rtl:border-l bordercolor rtl:pl-4 ltr:pr-4">
            {Array.from({ length: 7 }).map((_, index) => (
              <div key={index} className="flex items-center justify-between py-2">
                <Skeleton className="h-5 w-24 bg-gray-300 rounded" />
                <Skeleton className="h-6 w-6 bg-gray-300 rounded" />
              </div>
            ))}
          </div>

          {/* Right Column Skeleton */}
          <div className="flex-1 pl-4">
            {Array.from({ length: 7 }).map((_, index) => (
              <div key={index} className="flex items-center justify-between py-2">
                <Skeleton className="h-5 w-24 bg-gray-300 rounded" />
                <Skeleton className="h-6 w-6 bg-gray-300 rounded" />
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="flex">
          {/* Left Column */}
          <div className="flex-1 ltr:border-r rtl:border-l bordercolor rtl:pl-4 ltr:pr-4">
            {leftTags?.map((tag) => renderTagItem(tag))}
          </div>

          {/* Right Column */}
          <div className="flex-1 ltr:pl-4 rtl:pr-4">
            {rightTags?.map((tag) => renderTagItem(tag))}
          </div>
        </div>
      )}

      {!isLoadingTags.loading && Number(totalTags) > 10 && Number(totalTags) !== tagsData?.length && (
        <div className="flexCenter gap-2 mt-8">
          <LoadMoreBtn
            handleLoadMore={handleLoadMoreTags}
            loadMoreLoading={isLoadingTags.loadMoreLoading}
            searchModal={true}
          />
        </div>
      )}
    </div>
  ) : (
    <div className="text-[#1B2D51] flexCenter h-[250px] overflow-hidden font-[600] text-lg">
      {t('nodatafound')}
    </div>
  )
}

export default TagTabContent
