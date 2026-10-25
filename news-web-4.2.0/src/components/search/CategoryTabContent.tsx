'use client'
import React, { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import {
  categoriesSelector,
  categoryLimitSelector,
  categoryOffsetSelector,
  totalCategoriesSelector,
  setCategoryOffset,
  setLoadMoreCategories,
} from '@/redux/reducers/categoriesSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { CategoryApi } from '@/hooks/queries/general/useGetCategories'

interface CategoryTabContentProps {
  selectedCategoryIds: string
  setSelectedCategoryIds: (ids: string) => void
  selectedCategories: Record<string, boolean>
  setSelectedCategories: React.Dispatch<React.SetStateAction<Record<string, boolean>>>
  offset: number
}

const CategoryTabContent: React.FC<CategoryTabContentProps> = ({
  setSelectedCategoryIds,
  selectedCategories,
  setSelectedCategories,
  offset,
}) => {
  const { t } = useTranslation()
  const dispatch = useDispatch()

  const categories = useSelector(categoriesSelector)
  const cateLimit = useSelector(categoryLimitSelector)
  const totalCategories = useSelector(totalCategoriesSelector)
  const cateOffset = useSelector(categoryOffsetSelector)

  // Update the comma-separated string whenever selections change
  useEffect(() => {
    if (offset < 1) {
      const selectedNames = Object.keys(selectedCategories)
        .filter((category) => selectedCategories[category])
        .join(', ')
      setSelectedCategoryIds(selectedNames)
    }
  }, [selectedCategories, setSelectedCategoryIds, offset])

  // Split categories into two halves
  const halfLength = Math.ceil(categories.length / 2)
  const leftCategories = categories.slice(0, halfLength)
  const rightCategories = categories.slice(halfLength)

  // Handle selection/deselection
  const handleCategoryToggle = (category: number) => {
    const key = String(category)
    setSelectedCategories((prev) => ({
      ...prev,
      [key]: !prev[key],
    }))
  }

  const handleLoadMore = () => {
    dispatch(setCategoryOffset(cateOffset + 1))
    dispatch(setLoadMoreCategories(true))
  }

  // Render a single category item
  const renderCategoryItem = (category: CategoryApi) => (
    <div
      key={category?.id}
      className="flex items-center justify-between py-2 cursor-pointer"
      onClick={() => handleCategoryToggle(category?.id)}
    >
      <span className="textPrimary font-medium break-all">{category?.category_name}</span>
      <div
        className={`h-6 w-6 border borderColor rounded flex items-center justify-center ${
          selectedCategories[String(category?.id)] ? 'primaryBg' : 'customBgWhite'
        }`}
      >
        {selectedCategories[String(category?.id)] && (
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

  return categories?.length > 0 ? (
    <div className="bg-white dark:bodyBgColor rounded-[8px] border borderColor p-2 sm:p-4 h-[300px] overflow-y-auto sm:h-max">
      <div className="flex">
        {/* Left Column */}
        <div className="flex-1 ltr:border-r rtl:border-l borderColor rtl:pl-4 ltr:pr-4">
          {leftCategories.map((category) => renderCategoryItem(category))}
        </div>

        {/* Right Column */}
        <div className="flex-1 ltr:pl-4 rtl:pr-4">
          {rightCategories.map((category) => renderCategoryItem(category))}
        </div>
      </div>

      {totalCategories > cateLimit && totalCategories !== categories?.length && (
        <div className="flexCenter gap-2 mt-8">
          <button className="commonBtn !text-sm" onClick={handleLoadMore}>
            {t('loadMore')}
          </button>
        </div>
      )}
    </div>
  ) : (
    <div className="textPrimary flexCenter h-[250px] overflow-hidden font-[600] text-lg">
      {t('nodatafound')}
    </div>
  )
}

export default CategoryTabContent
