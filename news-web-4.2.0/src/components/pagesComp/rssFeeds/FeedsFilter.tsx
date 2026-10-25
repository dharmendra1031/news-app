'use client'
import { useState } from 'react'
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
import { useLangCode } from '@/hooks/useLangCode'
import {
    Dialog,
    DialogContent,
    DialogTrigger,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog"
import { IoClose, IoFilter } from 'react-icons/io5';
import TabsContent from './TabsContent';
import { toast } from '@/lib/toast';
import { SubCategoryApi } from '@/hooks/queries/general/useGetCategories'
import { useGetRssFeedSources, RssFeedSourceListItemApi } from '@/hooks/queries/useGetRssFeedSources'
import { usePageMode } from '@/hooks/usePageMode'

export interface RssFeedSelectedFilters {
    cateIds: number[]
    subCateIds: number[]
    feedsIds: number[]
}

interface FeedsFilterProps {
    selectedFilters: RssFeedSelectedFilters
    setSelectedFilters: (filters: RssFeedSelectedFilters) => void
    setOffset: (offset: number) => void
    setLoadMore: (loadMore: boolean) => void
}

const FEEDS_PER_PAGE = 10;

const FeedsFilter = ({
    selectedFilters,
    setSelectedFilters,
    setOffset,
    setLoadMore
}: FeedsFilterProps) => {

    const { t } = useTranslation()
    const dispatch = useDispatch()
    const langCode = useLangCode()
    const categoryMode = usePageMode('category_mode');
    const subCategoryMode = usePageMode('subcategory_mode');

    // Modal state
    const [modalOpen, setModalOpen] = useState(false)

    // Categories (Category tab) — fetched once, globally, by Layout.tsx and shared
    // across every page via redux; "load more" here just bumps the shared offset.
    const categories = useSelector(categoriesSelector)
    const cateLimit = useSelector(categoryLimitSelector)
    const cateOffset = useSelector(categoryOffsetSelector)
    const totalCategories = useSelector(totalCategoriesSelector)

    // Feed sources pagination (Feeds tab)
    const [feeds, setFeeds] = useState<RssFeedSourceListItemApi[]>([]);
    const [feedsLoadMore, setFeedsLoadMore] = useState(false)
    const [feedsOffset, setFeedsOffset] = useState(0)
    const [feedsTotal, setFeedsTotal] = useState(0)

    const { data: feedsQueryData } = useGetRssFeedSources({
        language_code: langCode,
        offset: feedsOffset * FEEDS_PER_PAGE,
        limit: FEEDS_PER_PAGE,
    })

    const [prevFeedsQueryData, setPrevFeedsQueryData] = useState<typeof feedsQueryData | symbol>(() => Symbol('initial'))
    if (feedsQueryData !== prevFeedsQueryData) {
        setPrevFeedsQueryData(feedsQueryData)
        if (feedsQueryData) {
            const items = feedsQueryData?.data?.data ?? []
            setFeedsTotal(feedsQueryData?.data?.total ?? 0)
            setFeeds((prev) => (feedsLoadMore ? [...prev, ...items] : items))
        }
    }

    const handleFeedsLoadMore = () => {
        setFeedsLoadMore(true)
        setFeedsOffset((prev) => prev + 1)
    }

    // Tab state
    const [activeTab, setActiveTab] = useState(0)

    // Selection state for each tab (local to the filter modal)
    const [selectedCategories, setSelectedCategories] = useState<Record<string, boolean>>({})
    const [selectedCategoryIds, setSelectedCategoryIds] = useState('')

    const [selectedSubCategories, setSelectedSubCategories] = useState<Record<string, boolean>>({})
    const [selectedSubCategoryIds, setSelectedSubCategoryIds] = useState('')

    const [selectedFeeds, setSelectedFeeds] = useState<Record<string, boolean>>({})
    const [selectedFeedIdsLocal, setSelectedFeedIdsLocal] = useState('')

    // Get subcategories from ALL locally selected categories in the modal
    const localSelectedCatIds = Object.keys(selectedCategories).filter(key => selectedCategories[key])
    const subCategories: SubCategoryApi[] = localSelectedCatIds.flatMap(catId => {
        const catObj = categories.find(cate => String(cate.id) === String(catId))
        return catObj?.sub_categories || []
    })

    const filterTabs = [
        {
            id: 0,
            tab: t('catLbl')
        },
        {
            id: 1,
            tab: t('subcatLbl')
        },
        {
            id: 2,
            tab: t('feeds')
        },
    ];

    const clearFilter = () => {
        setSelectedCategories({})
        setSelectedCategoryIds('')
        setSelectedSubCategories({})
        setSelectedSubCategoryIds('')
        setSelectedFeeds({})
        setSelectedFeedIdsLocal('')
    }

    const applyFilter = (type: 'clear' | 'apply') => {
        setOffset(1)
        setLoadMore(false)
        if (type === 'clear') {
            clearFilter()
            // Also clear parent state
            setSelectedFilters({
                cateIds: [],
                subCateIds: [],
                feedsIds: [],
            })
            setModalOpen(false)
        }
        if (type === 'apply') {
            // Get selected category IDs
            const selectedCatIds = Object.keys(selectedCategories).filter(key => selectedCategories[key]).map(Number)

            // Get selected subcategory IDs
            const selectedSubCatIds = Object.keys(selectedSubCategories).filter(key => selectedSubCategories[key]).map(Number)

            // Get selected feed IDs
            const selectedFeedIdsList = Object.keys(selectedFeeds).filter(key => selectedFeeds[key]).map(Number)

            if (selectedCatIds.length > 0 || selectedSubCatIds.length > 0 || selectedFeedIdsList.length > 0) {
                setSelectedFilters({
                    cateIds: selectedCatIds,
                    subCateIds: selectedSubCatIds,
                    feedsIds: selectedFeedIdsList,
                })
                setModalOpen(false)
            } else {
                toast.error(t('pleaseApplyFilter'))
            }
        }
    }

    const isFilters = selectedFilters.cateIds.length > 0 || selectedFilters.subCateIds.length > 0 || selectedFilters.feedsIds.length > 0;

    return (
        <Dialog open={modalOpen} onOpenChange={setModalOpen}>
            <DialogTrigger className={`text-[#1B2D51] dark:text-white font-semibold md:text-lg border borderColor rounded-[8px] p-2 flexCenter gap-4 h-[40px] sm:h-auto relative ${isFilters ? 'after:absolute after:top-0 after:right-0 after:primaryBg after:h-1.5 after:w-1.5 after:rounded-full' : ''}`}>
                <span className=''>{t('filter')}</span>
                <IoFilter />
            </DialogTrigger>
            <DialogContent className="max-w-[90%] md:max-w-[70%] 2xl:max-w-[50%] max-h-fit bg-white commonRadius p-0 border-none searchModalWrapper overflow-hidden overflow-x-auto">
                <div className='flex flex-col p-3 md:p-6 gap-6'>
                    <DialogHeader className={'border-b pb-3'}>
                        <div className='flex items-center justify-between'>
                            <DialogTitle className='text-[#1B2D51]'>{t('filter')}</DialogTitle>

                            <button className='bg-transparent border borderColor w-[44px] h-[40px] flexCenter commonRadius primaryColor focus:outline-none' onClick={() => setModalOpen(false)}><IoClose size={24} /></button>

                        </div>
                    </DialogHeader>

                    {
                        modalOpen &&
                        <div className='flex flex-col gap-6 max-h-[600px] lg:max-h-[700px] overflow-y-auto customScrollBar'>
                            <div>
                                <div className='bg-[#1B2D511A] commonRadius p-2 max-[1199px]:w-max w-[550px] h-[50px] flex items-center justify-between max-[1199px]:justify-center gap-3'>
                                    {
                                        filterTabs?.map((ele, index) => {
                                            return <span key={index} className={`cursor-pointer h-[35px] w-max px-2 lg:w-[154px] font-medium rounded flexCenter ${activeTab === index ? 'bg-[#1B2D51] text-white' : 'text-[#1B2D51]'} ${index === 0 && !categoryMode ? '!hidden' : ''}`}
                                                onClick={() => setActiveTab(index)}
                                            >
                                                {ele.tab}
                                            </span>
                                        })
                                    }
                                </div>
                            </div>

                            <div>
                                {/* Category Tab */}
                                {
                                    activeTab === 0 && categoryMode &&
                                    <TabsContent
                                        data={categories || []}
                                        selectedIds={selectedCategoryIds}
                                        setSelectedIds={setSelectedCategoryIds}
                                        selectedItems={selectedCategories}
                                        setSelectedItems={setSelectedCategories}
                                        labelKey='category_name'
                                        idKey='id'
                                        showLoadMore={totalCategories > cateLimit && totalCategories !== categories?.length}
                                        onLoadMore={() => {
                                            dispatch(setLoadMoreCategories(true))
                                            dispatch(setCategoryOffset(cateOffset + 1))
                                        }}
                                    />
                                }
                                {/* Subcategory Tab */}
                                {
                                    activeTab === 1 && subCategoryMode &&
                                    <>
                                        {localSelectedCatIds.length > 0 ?
                                            <TabsContent
                                                data={subCategories || []}
                                                selectedIds={selectedSubCategoryIds}
                                                setSelectedIds={setSelectedSubCategoryIds}
                                                selectedItems={selectedSubCategories}
                                                setSelectedItems={setSelectedSubCategories}
                                                labelKey='subcategory_name'
                                                idKey='id'
                                            />
                                            :
                                            <div className="bg-white rounded-[8px] border borderColor p-2 sm:p-4 h-[300px] overflow-y-auto flexCenter dark:text-black">
                                                {t('plzSelCatLbl')}
                                            </div>}
                                    </>
                                }
                                {/* Feeds Tab */}
                                {
                                    activeTab === 2 &&
                                    <TabsContent
                                        data={feeds || []}
                                        selectedIds={selectedFeedIdsLocal}
                                        setSelectedIds={setSelectedFeedIdsLocal}
                                        selectedItems={selectedFeeds}
                                        setSelectedItems={setSelectedFeeds}
                                        labelKey='feed_name'
                                        idKey='id'
                                        showLoadMore={feedsTotal > FEEDS_PER_PAGE && feedsTotal !== feeds?.length}
                                        onLoadMore={handleFeedsLoadMore}
                                    />
                                }
                            </div>

                            <div className='flexCenter !justify-end gap-3'>
                                <button className='!font-medium !h-[40px] max-[360px]:w-max w-[145px] p-[6px_12px] bg-transparent text-[#1B2D51] dark:text-black border borderColor rounded-[8px]' onClick={() => applyFilter('clear')}>{t('clear')}</button>
                                <button className='!font-medium !h-[40px] max-[360px]:w-max w-[145px] commonBtn !rounded-[8px]' onClick={() => applyFilter('apply')}>{t('apply')}</button>
                            </div>

                        </div>
                    }

                </div>
            </DialogContent>
        </Dialog>
    )
}

export default FeedsFilter
