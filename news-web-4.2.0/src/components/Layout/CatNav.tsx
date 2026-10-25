'use client'
import { useEffect, useState } from 'react'
import { FaChevronRight } from 'react-icons/fa'
import NewsCard from '../common/NewsCard'
import { useSelector } from 'react-redux'
import { locationSelector } from '@/redux/reducers/settingsSlice'
import { useRouter } from 'next/router'
import CommonCardSkeleton from '../skeletons/CommonCardSkeleton'
import { useGetNews } from '@/hooks/queries/useGetNews'
import { useGetCategories, CategoryApi } from '@/hooks/queries/general/useGetCategories'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { withLang } from '@/lib/localizedUrl'
import { currentLanguageSelector } from '@/redux/reducers/languageSlice'
import {
    Carousel,
    CarouselApi,
    CarouselContent,
    CarouselItem,
    CarouselNext,
    CarouselPrevious,
} from '@/components/ui/carousel'
import EmptyStatus from '../common/EmptyStatus'
import { PiCaretDownBold, PiCaretUpBold } from 'react-icons/pi'
import { usePageMode } from '@/hooks/usePageMode'
import { getDirection } from '@/components/utils/helpers'

const dataPerPage = 4
const categoriesPerPage = 20

const CatNav = () => {
    const { t } = useTranslation()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()
    const router = useRouter()

    const currentLanguage = useSelector(currentLanguageSelector)
    const categoryMode = usePageMode('category_mode');
    const subCategoryMode = usePageMode('subcategory_mode');

    const location = useSelector(locationSelector)

    const [categories, setCategories] = useState<CategoryApi[]>([])
    const [categoriesOffset, setCategoriesOffset] = useState(0)
    const [totalCategories, setTotalCategories] = useState(0)
    const [carouselApi, setCarouselApi] = useState<CarouselApi>()

    const { data: categoriesData, isFetching: categoriesFetching } = useGetCategories({
        language_code: currentLanguage?.code ?? '',
        offset: categoriesOffset,
        limit: categoriesPerPage,
    })

    useEffect(() => {
        // Accumulates pages from the external react-query result into local state as
        // categoriesOffset advances (infinite-load while sliding the carousel).
        if (categoriesData?.data) {
            const { data, total } = categoriesData.data
            // eslint-disable-next-line react-hooks/set-state-in-effect
            setTotalCategories(total)
            setCategories(prev => (categoriesOffset === 0 ? data : [...prev, ...data]))
        }
        else {
            setTotalCategories(0)
            setCategories([])
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [categoriesData])

    const hasMoreCategories = categories.length < totalCategories

    useEffect(() => {
        if (!carouselApi) return

        const maybeLoadMore = () => {
            if (!carouselApi.canScrollNext() && hasMoreCategories && !categoriesFetching) {
                setCategoriesOffset(prev => prev + categoriesPerPage)
            }
        }

        maybeLoadMore()
        carouselApi.on('select', maybeLoadMore)
        carouselApi.on('settle', maybeLoadMore)
        return () => {
            carouselApi.off('select', maybeLoadMore)
            carouselApi.off('settle', maybeLoadMore)
        }
    }, [carouselApi, hasMoreCategories, categoriesFetching])

    const [catId, setCatId] = useState<number | null>(null)
    const [subCatSlug, setSubCatSlug] = useState('')
    const [subCatDrop, setSubCatDrop] = useState(false)
    const [currentCategory, setCurrentCategory] = useState<CategoryApi | null>(null)

    const { data: newsData, isLoading: subLoading } = useGetNews({
        language_code: currentLanguage?.code ?? '',
        offset: 0,
        limit: dataPerPage,
        get_user_news: 0,
        category_id: catId ?? undefined,
        subcategory_slug: subCatSlug || undefined,
        latitude: location.lat ?? undefined,
        longitude: location.long ?? undefined,
        enabled: !!catId && subCatDrop,
    })

    const currentData = newsData?.data?.data ?? []
    const lengthdata = newsData?.data?.total ?? 0

    const handleCategoryChange = (category: CategoryApi) => {
        if (category.slug) {
            router.push(withLang(`/categories-news/${category.slug}`, currLangCode, defaultLangCode))
            setSubCatDrop(false)
        }
    }

    const handleSubCategoryChange = () => {
        if (subCatSlug) {
            router.push(withLang(`/categories-news/sub-category/${subCatSlug}`, currLangCode, defaultLangCode))
            setSubCatDrop(false)
        }
    }

    const handleSubCatDropdown = (category: CategoryApi) => {
        setCurrentCategory(category)
        setCatId(category.id)
        setSubCatDrop(!subCatDrop)
        setSubCatSlug('')
    }

    const handleSelectSubCate = (slug: string) => {
        setSubCatSlug(slug)
    }

    if (!(categories.length > 0 && categoryMode)) return null

    return (
        <div className="border-b borderColor py-3 hidden xl:flex items-center h-17"
            onMouseLeave={() => setSubCatDrop(false)}
        >
            <div className="container">
                <div className="catSubCatWrapper relative">
                    <Carousel
                        setApi={setCarouselApi}
                        opts={{ align: 'start', dragFree: true, containScroll: 'trimSnaps', direction: getDirection() }}
                        className="px-12"
                    >
                        <CarouselPrevious className="inset-s-0 border-0 shadow-none bg-transparent! textPrimary [&_svg]:size-6!" />
                        <CarouselContent className="-ms-8">
                            {categories.map(element => (
                                <CarouselItem key={element.id} className="basis-auto grow-0 shrink-0 ps-8 relative">
                                    <div className="text-center">
                                        <div className="catNav">
                                            {element?.sub_categories?.length > 0 && subCategoryMode ? (
                                                <div
                                                    className={`flex items-center gap-2 cursor-pointer w-max textPrimary commonRadius px-3 py-1.5 transition-colors duration-300 hover:bg-(--primary-color)/10 hover:primaryColor ${subCatDrop && currentCategory?.id === element.id ? 'activeSubDrop bg-(--primary-color)/10 primaryColor!' : ''}`}
                                                    onClick={() => handleSubCatDropdown(element)}
                                                >
                                                    <b>{element.category_name} </b>
                                                    <span>{subCatDrop && currentCategory?.id === element.id ? <PiCaretUpBold /> : <PiCaretDownBold />}</span>
                                                </div>
                                            ) : (
                                                <span
                                                    className={`textPrimary cursor-pointer block w-max! commonRadius px-3 py-1.5 transition-colors duration-300 hover:bg-(--primary-color)/10 hover:primaryColor ${subCatDrop && currentCategory?.id === element.id ? 'activeSubDrop bg-(--primary-color)/10 primaryColor!' : ''}`}
                                                    onClick={() => handleCategoryChange(element)}
                                                >
                                                    <b>{element.category_name} </b>
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                </CarouselItem>
                            ))}
                        </CarouselContent>
                        <CarouselNext className="inset-e-0 border-0 shadow-none bg-transparent! textPrimary [&_svg]:size-6!" />
                    </Carousel>

                    {subCategoryMode && subCatDrop && currentCategory && (
                        <div
                            className="subCatDrop bodyBgColor absolute inset-s-0 top-13 z-10 h-[390px] w-full commonShadow dark:shadow-white/10!"
                            onMouseLeave={() => setSubCatDrop(false)}
                            onMouseEnter={() => setSubCatDrop(true)}
                        >
                            <div className="grid grid-cols-6">
                                <div className="subCatNamesWrapper border-r borderColor h-[390px] overflow-hidden overflow-y-auto customScrollBar col-span-1">
                                    <div onClick={() => handleSelectSubCate('')} className={`flex items-center justify-between p-5 border-b borderColor font-[600] cursor-pointer ${subCatSlug === '' ? 'primaryColor' : 'textPrimary'}`}>
                                        <span>{t('allLbl')}</span>
                                        <span>{subCatSlug === '' ? <FaChevronRight /> : null}</span>
                                    </div>
                                    {currentCategory?.sub_categories?.map(subCat => (
                                        <div
                                            onClick={() => handleSelectSubCate(subCat?.slug)}
                                            key={subCat?.slug}
                                            className={`flex items-center justify-between p-5 border-b borderColor font-[600] cursor-pointer ${subCatSlug === subCat?.slug ? 'primaryColor' : 'textPrimary'}`}
                                        >
                                            <span>{subCat.subcategory_name}</span>
                                            {subCatSlug === subCat?.slug ? <FaChevronRight /> : null}
                                        </div>
                                    ))}
                                </div>
                                <div className="subCatDataWrappper w-full col-span-5 grid grid-cols-4 h-max gap-6 p-4">
                                    {subLoading
                                        ? [...Array(4)].map((_, index) => (
                                            <div key={index}>
                                                <CommonCardSkeleton subDropCard={true} />
                                            </div>
                                        ))
                                        : currentData.map(newsElement => (
                                            <div key={newsElement?.id}>
                                                <NewsCard element={newsElement} subDropCard={true} />
                                            </div>
                                        ))}

                                    {lengthdata > dataPerPage && (
                                        <div className="grid grid-cols-1 w-full col-span-4 h-full">
                                            {subCatSlug === '' ? (
                                                <div className="flex items-end justify-end">
                                                    <button className="viewAll border-[2px] secondaryBorder textPrimary rounded-[6px] p-2 font-[600] transition-all duration-300 hover:hoverBg hover:text-white dark:border-white" onClick={() => handleCategoryChange(currentCategory)}>{t('viewall')}</button>
                                                </div>
                                            ) : (
                                                <div className="flex items-end justify-end">
                                                    <button className="viewAll border-[2px] secondaryBorder textPrimary rounded-[6px] p-2 font-[600] transition-all duration-300 hover:hoverBg hover:text-white dark:border-white" onClick={() => handleSubCategoryChange()}>{t('viewall')}</button>
                                                </div>
                                            )}
                                        </div>
                                    )}
                                    {currentData.length === 0 && !subLoading && (
                                        <div className="col-span-12 flexCenter h-[300px]!">
                                            <EmptyStatus catNav={true} />
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

export default CatNav
