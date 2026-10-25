'use client'
import { useState } from 'react'
import { IoReorderThree } from 'react-icons/io5'
import { FaAngleDown, FaAngleUp } from 'react-icons/fa'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useRouter } from 'next/router'
import { useDispatch, useSelector } from 'react-redux'
import ProfileDropdown from '../dropdownsAndModals/ProfileDropdown'
import LanguageSwitcher from '../dropdownsAndModals/LanguageSwitcher'
import ThemeToggler from './topBar/ThemeToggler'
import MorePagesDropdown from '../dropdownsAndModals/MorePagesDropdown'
import LoginModal from '../auth/LoginModal'
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { languagesListSelector } from '@/redux/reducers/languageSlice'
import { categoriesSelector, categoryLimitSelector, setCategoryOffset, setLoadMoreCategories, totalCategoriesSelector } from '@/redux/reducers/categoriesSlice'
import { isLoginSelector, userDataSelector } from '@/redux/reducers/userSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { stripLangPrefix } from '@/lib/localizedUrl'
import SearchModal from '../search/SearchModal'

interface MobileNavProps {
    userRole?: boolean
    handleAlert: (modal: 'deleteAcc' | 'logoutAcc') => void
}

const MobileNav = ({ userRole, handleAlert }: MobileNavProps) => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()

    const isLogin = useSelector(isLoginSelector)
    const userData = useSelector(userDataSelector)
    const languagesData = useSelector(languagesListSelector)
    const settingsData = useSelector(settingsSelector)

    const showLiveNewsPage = settingsData?.live_streaming_mode === '1'
    const showBreakingNewsPage = settingsData?.breaking_news_mode === '1'
    const showRssFeed = settingsData?.rss_feed_mode === '1'
    const showReelsPage = settingsData?.news_buzz_mode === '1'
    const showeNews = settingsData?.e_news_mode === '1'

    const categories = useSelector(categoriesSelector)
    const cateLimit = useSelector(categoryLimitSelector)
    const totalCategories = useSelector(totalCategoriesSelector)

    const [isMenuOpen, setIsMenuOpen] = useState(true)
    const userName = userData?.name || userData?.email || userData?.mobile || ''

    const router = useRouter()
    const currentPath = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode)
    const isHomePage = currentPath === '/'

    const [open, setOpen] = useState(false)
    const onClose = () => setOpen(false)

    const linkClass = (path: string) =>
        `${currentPath === path ? 'activeLink after:h-[94%]' : ''} relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[94%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary uppercase font-[600] text-base`

    const handleLoadMoreCategories = () => {
        dispatch(setCategoryOffset(1))
        dispatch(setLoadMoreCategories(true))
    }

    return (
        <div>
            <Sheet open={open} onOpenChange={setOpen}>
                <SheetTrigger aria-label="Open navigation menu" className="dark:text-white cursor-pointer bg-transparent" onClick={() => setOpen(true)}>
                    <IoReorderThree size={44} />
                </SheetTrigger>
                <SheetContent className="bodyBgColor! overflow-y-scroll pl-6 pr-1 pt-6">
                    <div className="flex flex-col gap-6 mt-6">
                        <div className="flex items-center gap-6 flex-wrap">
                            {isLogin && userName ? (
                                <ProfileDropdown userName={userName} userRole={userRole} handleAlert={handleAlert} onClose={onClose} mobileNav={true} />
                            ) : (
                                <LoginModal />
                            )}
                            <ThemeToggler mobileNav={true} />
                        </div>
                        <div className="flex items-center gap-6 flex-wrap">
                            {isHomePage && languagesData?.length > 1 && (
                                <LanguageSwitcher variant="dropdown" mobileNav={true} onClose={onClose} />
                            )}
                            <div><SearchModal onClose={onClose} /></div>
                        </div>
                        <div className="navLinks">
                            <ul className="flex flex-col gap-3">
                                <li className="list-none">
                                    <LocalizedLink href="/" title={t('home')} className={linkClass('/')} onClick={onClose}>
                                        {t('home')}
                                    </LocalizedLink>
                                </li>

                                {showLiveNewsPage && (
                                    <li className="list-none">
                                        <LocalizedLink href="/live-news" className={linkClass('/live-news')} onClick={onClose} title={t('livenews')}>
                                            {t('livenews')}
                                        </LocalizedLink>
                                    </li>
                                )}

                                {showBreakingNewsPage && (
                                    <li className="list-none">
                                        <LocalizedLink href="/all-breaking-news" className={linkClass('/all-breaking-news')} onClick={onClose} title={t('breakingnews')}>
                                            {t('breakingnews')}
                                        </LocalizedLink>
                                    </li>
                                )}

                                <li className="list-none">
                                    <LocalizedLink href="/video-news" className={linkClass('/video-news')} onClick={onClose} title={t('videosLbl')}>
                                        {t('videosLbl')}
                                    </LocalizedLink>
                                </li>

                                {showReelsPage && (
                                    <li className="list-none">
                                        <LocalizedLink href="/newsbuzz" className={linkClass('/newsbuzz')} onClick={onClose} title={t('newsBuzz')}>
                                            {t('newsBuzz')}
                                        </LocalizedLink>
                                    </li>
                                )}

                                {showRssFeed && (
                                    <li className="list-none">
                                        <LocalizedLink href="/rss-feed" className={linkClass('/rss-feed')} onClick={onClose} title={t('rssFeed')}>
                                            {t('rssFeed')}
                                        </LocalizedLink>
                                    </li>
                                )}

                                {showeNews && (
                                    <li className="list-none">
                                        <LocalizedLink href="/enews" className={linkClass('/enews')} onClick={onClose} title={t('e_news')}>
                                            {t('e_news')}
                                        </LocalizedLink>
                                    </li>
                                )}

                                <li className="list-none">
                                    <MorePagesDropdown onClose={onClose} />
                                </li>
                            </ul>
                        </div>

                        {categories?.length > 0 && settingsData?.category_mode === '1' && (
                            <div className="relative">
                                <div className="flex items-center justify-between text-lg textPrimary font-[700] cursor-pointer" onClick={() => setIsMenuOpen(!isMenuOpen)}>
                                    <h1>{t('categories')}</h1>
                                    <span className="primaryBg p-2 rounded-full text-white flexCenter">
                                        {isMenuOpen ? <FaAngleUp /> : <FaAngleDown />}
                                    </span>
                                </div>
                                {isMenuOpen && (
                                    <div className="otherCats mobileCates overflow-y-scroll customScrollBar max-h-[344px] pb-6 flex flex-col gap-3 absolute bg-transparent textPrimary w-full mt-[12px]">
                                        {categories?.map(element =>
                                            element?.sub_categories?.length > 0 && settingsData?.subcategory_mode === '1' ? (
                                                <div key={element.id}>
                                                    <DropdownMenu>
                                                        <DropdownMenuTrigger className="bg-transparent dropdownTrigg p-0 h-max w-max flex items-center gap-1 cursor-pointer data-[state=closed]:[&>svg]:rotate-0 data-[state=open]:[&>svg]:rotate-180 transition-all duration-300">
                                                            <span className="textPrimary font-[600] flex items-center gap-1 cursor-pointer">
                                                                {element.category_name}
                                                            </span>
                                                            <span className="opacity-80">
                                                                <FaAngleDown />
                                                            </span>
                                                        </DropdownMenuTrigger>
                                                        <DropdownMenuContent className="w-full bg-white relative h-auto max-h-[180px] sm:max-h-[250px] overflow-y-scroll" side="bottom" align="start">
                                                            <div className="bg-white flex flex-col gap-3 w-full! max-w-full">
                                                                {element.sub_categories.map(data => (
                                                                    <DropdownMenuItem key={data.id} className="hover:bg-transparent!">
                                                                        <LocalizedLink
                                                                            href={`/categories-news/sub-category/${data?.slug}`}
                                                                            title={data.subcategory_name}
                                                                            onClick={() => setIsMenuOpen(false)}
                                                                            className='cursor-pointer w-max max-w-full! relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] text-black font-[600]'
                                                                        >
                                                                            {data.subcategory_name}
                                                                        </LocalizedLink>
                                                                    </DropdownMenuItem>
                                                                ))}
                                                            </div>
                                                        </DropdownMenuContent>
                                                    </DropdownMenu>
                                                </div>
                                            ) : (
                                                <LocalizedLink
                                                    key={element?.slug}
                                                    href={`/categories-news/${element?.slug}`}
                                                    onClick={() => setIsMenuOpen(false)}
                                                    title={element?.category_name}
                                                    className="textPrimary font-[600]"
                                                >
                                                    {element?.category_name}
                                                </LocalizedLink>
                                            )
                                        )}
                                        {totalCategories > cateLimit && totalCategories !== categories?.length && (
                                            <span onClick={handleLoadMoreCategories} className="primaryColor font-[600] text-center cursor-pointer">
                                                {t('loadMore')}
                                            </span>
                                        )}
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                </SheetContent>
            </Sheet>
        </div>
    )
}

export default MobileNav
