'use client'
import { useState } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useQueryClient } from '@tanstack/react-query'
import { useRouter } from 'next/router'
import Layout from '@/components/Layout/Layout'
import Breadcrumb from '@/components/common/Breadcrumb'
import CommonCardSkeleton from '@/components/skeletons/CommonCardSkeleton'
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn'
import ImagePreview from '@/components/common/ImagePreview'
import {
    categoriesSelector,
    categoryLimitSelector,
    categoryOffsetSelector,
    totalCategoriesSelector,
    isLoadMoreCategoriesSelector,
    setCategoryOffset,
    setLoadMoreCategories,
} from '@/redux/reducers/categoriesSlice'
import { isNewUserSelector, setIsNewUser, userDataSelector } from '@/redux/reducers/userSlice'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { currentLanguageSelector } from '@/redux/reducers/languageSlice'
import { defaultLanguageSelector } from '@/redux/reducers/settingsSlice'
import { setUserCategoriesApi } from '@/api/apiRoutes'
import { isLogin, webName } from '@/components/utils/helpers'
import { withLang } from '@/lib/localizedUrl'
import { toast } from '@/lib/toast'
import { useTranslation } from '@/hooks/useTranslation'
import Meta from '@/components/common/Meta'
import WithAuth from '@/components/hoc/WithAuth'

const CategoryPreferences = () => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const queryClient = useQueryClient()
    const router = useRouter()

    // Categories are fetched once, globally, by Layout.tsx and shared across
    // every page via redux — "load more" here just bumps the shared offset.
    const categories = useSelector(categoriesSelector)
    const cateLimit = useSelector(categoryLimitSelector)
    const cateOffset = useSelector(categoryOffsetSelector)
    const totalCategories = useSelector(totalCategoriesSelector)
    const loadMoreCategories = useSelector(isLoadMoreCategoriesSelector)
    const userData = useSelector(userDataSelector)
    const isNewUser = useSelector(isNewUserSelector)
    const currentLanguage = useSelector(currentLanguageSelector)
    const defaultLanguage = useSelector(defaultLanguageSelector)

    const [selectedIds, setSelectedIds] = useState<Set<number> | null>(null)
    const [saving, setSaving] = useState(false)

    // Seed the toggle state from the user's saved preferences exactly once —
    // re-running this on every categories/userData change (e.g. on load more)
    // would wipe out toggles the user made before hitting save.
    const [syncedUserId, setSyncedUserId] = useState<number | null>(null)
    if (userData?.id && userData.id !== syncedUserId) {
        setSyncedUserId(userData.id)
        const categoryIdString = userData?.user_category?.category_id
        const ids = categoryIdString
            ? categoryIdString.split(',').map((id) => Number(id.trim())).filter((id) => !Number.isNaN(id))
            : []
        setSelectedIds(new Set(ids))
    }

    const toggleCategory = (id: number) => {
        setSelectedIds((prev) => {
            const next = new Set(prev ?? [])
            if (next.has(id)) next.delete(id)
            else next.add(id)
            return next
        })
    }

    const handleLoadMore = () => {
        dispatch(setLoadMoreCategories(true))
        dispatch(setCategoryOffset(cateOffset + 1))
    }

    const handleSave = async () => {
        if (!isLogin()) {
            dispatch(setLoginModalOpen(true))
            toast.error(t('loginFirst'))
            setTimeout(() => dispatch(setLoginModalOpen(false)), 2000)
            return
        }

        const idsArray = Array.from(selectedIds ?? [])
        if (idsArray.length === 0) {
            toast.error(t('selectcategory'))
            return
        }

        setSaving(true)
        try {
            const response = await setUserCategoriesApi({ category_id: idsArray.join(',') })
            if (!response || response?.error) {
                toast.error(t('somethingMSg'))
                return
            }
            toast.success(t('updateSuccessfully'))
            queryClient.invalidateQueries({ queryKey: ['userDetails'] })

            // New-user flow ends here — send them to the homepage now that
            // profile, language, and categories are all set up.
            if (isNewUser) {
                dispatch(setIsNewUser(false))
                router.push(withLang('/', currentLanguage?.code ?? '', defaultLanguage?.code))
            }
        } catch (error) {
            console.error('Error:', error)
            toast.error(t('somethingMSg'))
        } finally {
            setSaving(false)
        }
    }

    return (
        <Layout>
            <>

                <Meta title={`${webName()} | ${t('categoryPreferences')}`} />

                <Breadcrumb secondElement={t('categoryPreferences')} />

                <section className='commonBg commonPY'>
                    <div className='userBasedCategories container flex flex-col gap-8 md:gap-12'>
                        <div className='customBgWhite commonRadius flex items-center justify-between py-3 px-4'>
                            <h2 className='font-medium text-lg md:text-xl textPrimary'>{t('categoryPreferences')}</h2>
                            <button
                                type='button'
                                disabled={saving}
                                onClick={handleSave}
                                className='commonBtn md:text-[18px] uppercase md:!py-4 md:!px-8 disabled:opacity-60'
                            >
                                {t('saveLbl')}
                            </button>
                        </div>

                        {
                            categories?.length ? (
                                <>
                                    <div className='grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6'>
                                        {categories.map((category) => {
                                            const isChecked = selectedIds?.has(category.id) ?? false
                                            return (
                                                <div
                                                    key={category.id}
                                                    className='flex items-center justify-between customBgWhite border seconadryBorderColor commonRadius p-4 gap-3'
                                                >
                                                    <div className='h-[60px] w-[60px] sm:h-[80px] sm:w-[80px] shrink-0'>
                                                        <ImagePreview
                                                            src={category.image}
                                                            alt={category.category_name}
                                                            objectFit='cover'
                                                            rounded='lg'
                                                        />
                                                    </div>
                                                    <h3 className='textPrimary text-[18px] lg:text-[20px] font-[600] flex-1 px-3'>
                                                        {category.category_name}
                                                    </h3>
                                                    <div
                                                        onClick={() => toggleCategory(category.id)}
                                                        className={`relative w-[80px] sm:w-[100px] md:w-[80px] lg:w-[100px] h-[40px] flex items-center commonRadius cursor-pointer transition-all duration-300 ${isChecked ? 'bg-[#4CAF50]' : 'bg-[#f44336]'}`}
                                                    >
                                                        <div
                                                            className={`absolute ltr:left-1 rtl:right-1 top-1 h-[80%] w-[26px] commonRadius bg-white border-2 transition-transform duration-300 transform ${isChecked ? 'ltr:translate-x-[46px] rtl:-translate-x-[46px] ltr:sm:translate-x-[65px] rtl:sm:-translate-x-[65px] ltr:md:translate-x-[46px] rtl:md:-translate-x-[46px] ltr:lg:translate-x-[65px] rtl:lg:-translate-x-[65px]' : 'translate-x-0'}`}
                                                        ></div>
                                                        <span className={`absolute ltr:right-[12px] rtl:left-[12px] font-semibold text-white text-sm transition-opacity duration-300 ${isChecked ? 'opacity-0' : 'opacity-100'}`}>{t('off')}</span>
                                                        <span className={`absolute ltr:left-[12px] rtl:right-[12px] font-semibold text-white text-sm transition-opacity duration-300 ${isChecked ? 'opacity-100' : 'opacity-0'}`}>{t('on')}</span>
                                                    </div>
                                                </div>
                                            )
                                        })}
                                    </div>
                                    {totalCategories > cateLimit && totalCategories !== categories.length && (
                                        <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={loadMoreCategories} />
                                    )}
                                </>
                            ) : (
                                <div className='grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6'>
                                    {[...Array(6)].map((_, index) => (
                                        <div key={index}><CommonCardSkeleton /></div>
                                    ))}
                                </div>
                            )
                        }
                    </div>
                </section>
            </>
        </Layout>
    )
}

export default WithAuth(CategoryPreferences)
