'use client'
import React, { useState, useEffect } from 'react'
import {
  Dialog,
  DialogContent,
  DialogTrigger,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { AiOutlineSearch } from 'react-icons/ai'
import { IoClose, IoFilter } from 'react-icons/io5'
import { useSelector } from 'react-redux'
import { currentLanguageSelector } from '@/redux/reducers/languageSlice'
import { locationSelector } from '@/redux/reducers/settingsSlice'
import { getNewsApi, getTagsApi } from '@/api/apiRoutes'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import { truncateText } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode } from '@/hooks/useLangCode'
import { Skeleton } from '@/components/ui/skeleton'
import LocalizedLink from '@/components/common/LocalizeLink'
import ImagePreview from '@/components/common/ImagePreview'
import CategoryTabContent from './CategoryTabContent'
import TagTabContent from './TagTabContent'
import DateTabContent from './DateTabContent'
import { toast } from '@/lib/toast'
import { NewsApi } from '@/hooks/queries/useGetNews'
import { TagApi } from '@/hooks/queries/useGetTags'
import { usePageMode } from '@/hooks/usePageMode'

interface SearchModalProps {
  onClose?: () => void
}

const SearchModal: React.FC<SearchModalProps> = ({ onClose = () => { } }) => {
  const currLangCode = useLangCode()
  const { t } = useTranslation()

  const [modalOpen, setModalOpen] = useState(false)

  const categoryMode = usePageMode('category_mode');
  const { lat: storedLatitude, long: storedLongitude } = useSelector(locationSelector)
  const currentLanguage = useSelector(currentLanguageSelector)

  const [searchValue, setSearchValue] = useState('')

  const [isLoading, setIsLoading] = useState({
    loading: false,
    loadMoreLoading: false,
  })
  const [loadMore, setLoadMore] = useState(false)
  const [data, setData] = useState<NewsApi[]>([])
  const [offset, setOffset] = useState(0)
  const [totalData, setTotalData] = useState<number | string>('')

  const dataPerPage = 4 // number of posts per page

  // Filter states
  const [isFilter, setIsFilter] = useState(false)
  const [activeTab, setActiveTab] = useState(categoryMode ? 0 : 1)

  const [selectedCategoryIds, setSelectedCategoryIds] = useState('')
  const [selectedTagIds, setSelectedTagIds] = useState('')
  const [selectedCategories, setSelectedCategories] = useState<Record<string, boolean>>({})
  const [selectedTags, setSelectedTags] = useState<Record<string, boolean>>({})

  const [, setApply] = useState(false)

  // Tag related states
  const [isLoadingTags, setIsLoadingTags] = useState({
    loading: false,
    loadMoreLoading: false,
  })
  const [loadMoreTags, setLoadMoreTags] = useState(false)
  const [tagsData, setTagsData] = useState<TagApi[]>([])
  const [tagsOffset, setTagsOffset] = useState(0)
  const [totalTags, setTotalTags] = useState<number | string>('')

  const tagLimit = 20

  const handleLoadMoreTags = () => {
    setLoadMoreTags(true)
    setTagsOffset((prev) => prev + 1)
  }

  const getTags = async () => {
    const langCode = currentLanguage?.code || currLangCode
    if (!langCode) return

    if (!loadMoreTags) {
      setIsLoadingTags({ loading: true, loadMoreLoading: false })
    } else {
      setIsLoadingTags({ loading: false, loadMoreLoading: true })
    }

    try {
      const res = await getTagsApi({
        offset: tagsOffset * tagLimit,
        limit: tagLimit,
        language_code: langCode,
      })

      const tags = res?.data?.data || []

      if (!res?.error) {
        setTotalTags(res?.data?.total || 0)
        if (loadMoreTags) {
          setTagsData((prevData) => [...prevData, ...tags])
        } else {
          setTagsData(tags)
        }
        setIsLoadingTags({ loading: false, loadMoreLoading: false })
      } else {
        setTagsData([])
        console.log('tagsSect error =>', res?.message)
        setIsLoadingTags({ loading: false, loadMoreLoading: false })
      }
    } catch (error) {
      console.log(error)
      setTagsData([])
      setIsLoadingTags({ loading: false, loadMoreLoading: false })
    }
  }

  // Load tags when modal opens or when language/offset changes
  useEffect(() => {
    if ((currentLanguage?.id || currLangCode) && modalOpen) {
      getTags()
      if (typeof window !== 'undefined') {
        const prevLanguageId = sessionStorage.getItem('tagCurentLangId')
        if (currentLanguage?.id && Number(prevLanguageId) !== currentLanguage.id) {
          setTagsOffset(0)
        }
        if (currentLanguage?.id) {
          sessionStorage.setItem('tagCurentLangId', String(currentLanguage.id))
        }
      }
    }
  }, [currentLanguage?.id, currLangCode, tagsOffset, modalOpen])

  const [date, setDate] = useState<{ date: string; year: string | number }>({
    date: '',
    year: '',
  })

  const currentDate = new Date()
  const [displayDate, setDisplayDate] = useState(
    new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate())
  )
  const [selectedDate, setSelectedDate] = useState(new Date())
  const [activeDateTab, setActiveDateTab] = useState<string | number>('custom')
  const [lastNDays, setLastNDays] = useState<number | null>(null)

  const handleLoadMore = () => {
    setLoadMore(true)
    setOffset((prev) => prev + 1)
  }

  const getSearchedNews = async (filterApplied = false) => {
    setApply(filterApplied)
    if (storedLatitude || searchValue || filterApplied) {
      if (!loadMore) {
        setIsLoading({ loading: true, loadMoreLoading: false })
      } else {
        setIsLoading({ loading: false, loadMoreLoading: true })
      }

      try {
        const langCode = currentLanguage?.code || currLangCode
        const res = await getNewsApi({
          offset: offset * dataPerPage,
          limit: dataPerPage,
          language_code: langCode,
          search: searchValue === 'apply' ? '' : searchValue,
          latitude: storedLatitude,
          longitude: storedLongitude,
          category_id: selectedCategoryIds ? selectedCategoryIds : undefined,
          tag_id: selectedTagIds ? selectedTagIds : undefined,
          last_n_days: lastNDays !== null ? lastNDays : undefined,
          date: date?.date ? date.date : undefined,
          year: date?.year ? date.year : undefined,
        })

        const newsData = res?.data?.data || []

        if (res?.error) {
          setIsLoading({ loading: false, loadMoreLoading: false })
          setData([])
          return
        }

        setTotalData(res?.data?.total || 0)
        setIsLoading({ loading: false, loadMoreLoading: false })

        if (loadMore) {
          setData((prevData) => [...prevData, ...newsData])
        } else {
          setData(newsData)
        }
      } catch (error) {
        console.log(error)
        setData([])
        setIsLoading({ loading: false, loadMoreLoading: false })
      }
    }
  }

  useEffect(() => {
    if (searchValue && (currentLanguage?.id || currLangCode) && searchValue !== 'apply') {
      const timeout = setTimeout(() => {
        getSearchedNews()
      }, 1500)
      return () => {
        clearTimeout(timeout)
      }
    }
  }, [currentLanguage?.id, currLangCode, categoryMode, searchValue])

  useEffect(() => {
    if (searchValue && (currentLanguage?.id || currLangCode) && searchValue !== 'apply') {
      getSearchedNews()
    }
  }, [currentLanguage?.id, currLangCode, offset])

  useEffect(() => {
    if (searchValue && (currentLanguage?.id || currLangCode) && searchValue === 'apply') {
      getSearchedNews(true)
    }
  }, [currentLanguage?.id, currLangCode, offset])

  useEffect(() => {
    setLoadMore(false)
    setOffset(0)
    setIsLoading({ loading: true, loadMoreLoading: false })
    setApply(false)
    setIsFilter(false)

    if (searchValue !== 'apply') {
      setData([])
    }
  }, [searchValue])

  const clearFilter = () => {
    setSelectedCategoryIds('')
    setSelectedTagIds('')
    setSelectedCategories({})
    setSelectedTags({})
    setDate({
      date: '',
      year: '',
    })
    setLastNDays(null)
    setSelectedDate(new Date())
    setActiveDateTab('custom')
  }

  useEffect(() => {
    if (!modalOpen) {
      setSearchValue('')
      setIsFilter(false)
      setApply(false)
      setData([])
      clearFilter()
    }

    if (modalOpen) {
      onClose()
    }
  }, [modalOpen])

  useEffect(() => {
    if (isFilter) {
      setData([])
      setIsLoading({ loading: false, loadMoreLoading: false })
      setLoadMore(false)
      setOffset(0)
    }
  }, [isFilter])

  // Handle closing the dialog when clicking outside
  const handleOpenChange = (open: boolean) => {
    setModalOpen(open)
    setIsFilter(false)
  }

  const filterTabs = [
    {
      id: 0,
      tab: t('catLbl'),
    },
    {
      id: 1,
      tab: t('tagLbl'),
    },
    {
      id: 2,
      tab: t('date'),
    },
  ]

  const applyFilter = (type: 'clear' | 'apply') => {
    if (type === 'clear') {
      clearFilter()
    }
    if (type === 'apply') {
      if (selectedCategoryIds || selectedTagIds || lastNDays || date.date || date.year) {
        setSearchValue('apply')
        getSearchedNews(true)
        setIsFilter(false)
      } else {
        toast.error(t('pleaseApplyFilter'))
      }
    }
  }

  return (
    <div className="">
      <Dialog open={modalOpen} onOpenChange={handleOpenChange}>
        <DialogTrigger
          aria-label="Search"
          className="h-9 bg-black dark:bg-white p-2 commonRadius transition-all duration-500 text-white dark:text-black hover:primaryColor!"
          onClick={() => setModalOpen(true)}
        >
          <AiOutlineSearch size={23} />
        </DialogTrigger>
        <DialogContent
          showCloseButton={false}
          className="max-w-[90%] md:max-w-[70%] 2xl:max-w-[50%] max-h-fit customBgWhite commonRadius p-0 border-none searchModalWrapper overflow-hidden overflow-x-auto"
        >
          <div className="flex flex-col p-3 md:p-6 gap-6">
            <DialogHeader className="border-b pb-3 bordercolor">
              <div className="flex items-center justify-between">
                <DialogTitle className="textPrimary">{t('searchNews')}</DialogTitle>

                <button
                  type="button"
                  className="bg-transparent border bordercolor w-[44px] h-[40px] flexCenter commonRadius primaryColor focus:outline-none"
                  onClick={() => setModalOpen(false)}
                >
                  <IoClose size={24} />
                </button>
              </div>
            </DialogHeader>

            <div className="flex items-center gap-3">
              <div className="flex items-center justify-between w-full p-2 sm:p-3 border bordercolor rounded-[8px]">
                <input
                  type="text"
                  placeholder={t('searchNews')}
                  className="max-[360px]:w-[150px] w-full textPrimary focus:outline-none text-[18px]"
                  value={searchValue === 'apply' ? '' : searchValue}
                  onChange={(e) => setSearchValue(e.target.value)}
                />
              </div>
              <div className="textPrimary font-semibold md:text-lg">
                <button
                  type="button"
                  className="border bordercolor rounded-[8px] p-2 sm:p-3 flexCenter gap-2 w-full h-[40px] sm:h-auto"
                  onClick={() => setIsFilter(true)}
                >
                  <span className="hidden sm:block">{t('filter')}</span>
                  <IoFilter />
                </button>
              </div>
            </div>

            {!isFilter && searchValue !== '' && (
              <div className="flex flex-col gap-6 max-h-[450px] pr-2 overflow-hidden searchContentWrapper overflow-y-scroll">
                {isLoading.loading ? (
                  Array.from({ length: 3 }).map((_, index) => (
                    <div key={index} className="flex items-center gap-3">
                      <div className="w-[70px] h-[70px] md:w-[80px] md:h-[80px] lg:w-[100px] lg:h-[100px] object-cover commonRadius shrink-0">
                        <Skeleton className="dark:bg-gray-300! h-full w-full rounded-2xl" />
                      </div>
                      <div className="w-full">
                        <Skeleton className="dark:bg-gray-300! h-10 w-full rounded" />
                      </div>
                    </div>
                  ))
                ) : data && data.length > 0 ? (
                  data.map((element) => {
                    return (
                      <LocalizedLink
                        key={element?.id}
                        href={`/news/${element?.slug}`}
                        title="detail-page"
                        onClick={() => setModalOpen(false)}
                      >
                        <div className="flex items-center gap-3 textPrimary font-[600] text-lg">
                          <div className='hidden lg:block w-[102px] h-[110px] shrink-0'>
                            <ImagePreview
                              src={element?.image}
                              alt={element?.title || 'news-image'}
                              loading="lazy"
                              className="object-cover rounded-2xl"
                            />
                          </div>
                          <div className="border bordercolor p-2 md:p-3 lg:p-4 xl:p-5 rounded-2xl flex flex-col gap-2 w-full">
                            <div className="flex items-center justify-between border-b pb-2">
                              <div className="flex items-center gap-3 font-normal text-sm sm:text-base">
                                {element?.tag_name && (
                                  <div>
                                    <span className="textSecondary">{t('tagLbl')}: </span>
                                    <span className="textPrimary">{element?.tag_name}</span>
                                  </div>
                                )}
                                {element?.category?.category_name && (
                                  <div>
                                    <span className="textSecondary">{t('catLbl')}: </span>
                                    <span className="textPrimary">{element?.category?.category_name}</span>
                                  </div>
                                )}
                              </div>
                              <div className="date text-sm sm:text-base">
                                <span className="textSecondary font-normal">
                                  {new Date(element?.published_date || element?.date).toLocaleString(
                                    'en-us',
                                    {
                                      day: 'numeric',
                                      month: 'short',
                                      year: 'numeric',
                                    }
                                  )}
                                </span>
                              </div>
                            </div>
                            <div>
                              <h1 className="line-clamp-2 text-sm sm:text-base md:text-lg font-medium textPrimary">
                                {truncateText(element?.title, 150)}
                              </h1>
                            </div>
                          </div>
                        </div>
                      </LocalizedLink>
                    )
                  })
                ) : (
                  !isLoading.loading &&
                  searchValue !== '' && (
                    <div className="textPrimary flexCenter h-[450px] overflow-hidden font-[600] text-lg">
                      {t('nodatafound')}
                    </div>
                  )
                )}

                {data &&
                  data.length > 0 &&
                  !isLoading.loading &&
                  searchValue &&
                  Number(totalData) > dataPerPage &&
                  Number(totalData) !== data.length ? (
                  <div className="flexCenter">
                    <LoadMoreBtn
                      handleLoadMore={handleLoadMore}
                      loadMoreLoading={isLoading.loadMoreLoading}
                    />
                  </div>
                ) : null}
              </div>
            )}

            {isFilter && (
              <div className="flex flex-col gap-6 max-h-[600px] lg:max-h-[700px] overflow-auto">
                <div>
                  <div className="bodyBgColor commonRadius p-2 max-[1199px]:w-max w-[550px] h-[50px] flex items-center justify-between max-[1199px]:justify-center gap-3">
                    {filterTabs.map((ele, index) => {
                      return (
                        <button
                          key={ele.id}
                          type="button"
                          className={`cursor-pointer h-[35px] w-max px-2 lg:w-[154px] font-medium rounded flexCenter ${activeTab === index ? 'secondaryBg text-white' : 'textPrimary'
                            } ${index === 0 && !categoryMode ? 'hidden!' : ''}`}
                          onClick={() => setActiveTab(index)}
                        >
                          {ele.tab}
                        </button>
                      )
                    })}
                  </div>
                </div>

                <div>
                  {activeTab === 0 && categoryMode && (
                    <CategoryTabContent
                      selectedCategoryIds={selectedCategoryIds}
                      setSelectedCategoryIds={setSelectedCategoryIds}
                      selectedCategories={selectedCategories}
                      setSelectedCategories={setSelectedCategories}
                      offset={offset}
                    />
                  )}
                  {activeTab === 1 && (
                    <TagTabContent
                      selectedTagIds={selectedTagIds}
                      setSelectedTagIds={setSelectedTagIds}
                      selectedTags={selectedTags}
                      setSelectedTags={setSelectedTags}
                      tagsData={tagsData}
                      isLoadingTags={isLoadingTags}
                      totalTags={totalTags}
                      handleLoadMoreTags={handleLoadMoreTags}
                      offset={offset}
                    />
                  )}
                  {activeTab === 2 && (
                    <DateTabContent
                      setDate={setDate}
                      setLastNDays={setLastNDays}
                      displayDate={displayDate}
                      setDisplayDate={setDisplayDate}
                      selectedDate={selectedDate}
                      setSelectedDate={setSelectedDate}
                      activeDateTab={activeDateTab}
                      setActiveDateTab={setActiveDateTab}
                      offset={offset}
                    />
                  )}
                </div>

                <div className="flexCenter justify-end! gap-3">
                  <button
                    type="button"
                    className="font-medium h-10 max-[360px]:w-max w-36.25 p-[6px_12px] bg-transparent textPrimary dark:textPrimary border bordercolor rounded-[8px]"
                    onClick={() => applyFilter('clear')}
                  >
                    {t('clear')}
                  </button>
                  <button
                    type="button"
                    className="font-medium h-10 max-[360px]:w-max w-36.25 commonBtn rounded-[8px]!"
                    onClick={() => applyFilter('apply')}
                  >
                    {t('apply')}
                  </button>
                </div>
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default SearchModal
