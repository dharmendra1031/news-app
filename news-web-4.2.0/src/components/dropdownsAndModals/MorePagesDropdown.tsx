'use client'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useDispatch, useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import {
    NavigationMenu,
    NavigationMenuContent,
    NavigationMenuItem,
    NavigationMenuList,
    NavigationMenuTrigger,
} from '@/components/ui/navigation-menu'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { stripLangPrefix } from '@/lib/localizedUrl'
import {
    morePagesLimitSelector,
    morePagesOffsetSelector,
    morePagesSelector,
    setLoadMoreMorePages,
    setMorePagesOffset,
    totalMorePagesSelector,
} from '@/redux/reducers/morePagesSlice'

interface MorePagesDropdownProps {
    onClose?: () => void
}

const EXCLUDED_PAGE_TYPES = ['about-us', 'contact-us', 'terms-condition', 'privacy-policy']

const MorePagesDropdown = ({ onClose }: MorePagesDropdownProps) => {
    const { t } = useTranslation()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()
    const router = useRouter()
    const dispatch = useDispatch()

    const pageData = useSelector(morePagesSelector)
    const totalMorePages = useSelector(totalMorePagesSelector)
    const morePagesOffset = useSelector(morePagesOffsetSelector)
    const morePagesLimit = useSelector(morePagesLimitSelector)

    const filteredData = pageData?.filter(page => !EXCLUDED_PAGE_TYPES.includes(page.page_type))

    const currentPath = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode)
    const isMorePagesActive = currentPath.startsWith('/more-pages')

    const handleLoadMore = () => {
        dispatch(setLoadMoreMorePages(true))
        dispatch(setMorePagesOffset(morePagesOffset + 1))
    }

    return (
        <NavigationMenu className="relative z-2!">
            <NavigationMenuList>
                <NavigationMenuItem>
                    <NavigationMenuTrigger
                        className={`dropdownTrigg cursor-pointer bg-transparent p-0 h-max w-max ${isMorePagesActive ? 'activeLink after:h-[84%]!' : ''} relative after:content-[""] after:absolute after:top-[2px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary! font-semibold! text-base uppercase`}
                    >
                        {t('morePages')}
                    </NavigationMenuTrigger>
                    <NavigationMenuContent>
                        <div className="flex flex-col gap-1 w-max! max-w-full p-1 px-3 customBgWhite textPrimary">
                            <LocalizedLink
                                href="/more-pages/about-us"
                                title={t('aboutus')}
                                className={`${currentPath === '/more-pages/about-us' ? 'activeLink after:h-[88%]' : ''} relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary font-medium my-1 text-[17px]`}
                            >
                                {t('aboutus')}
                            </LocalizedLink>

                            <LocalizedLink
                                href="/more-pages/contact-us"
                                title={t('contactus')}
                                className={`${currentPath === '/more-pages/contact-us' ? 'activeLink after:h-[88%]' : ''} relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary font-medium my-1 text-[17px]`}
                            >
                                {t('contactus')}
                            </LocalizedLink>

                            {filteredData?.map(page => (
                                <LocalizedLink
                                    href={`/more-pages/${page?.slug}/`}
                                    className={`${currentPath === `/more-pages/${page?.slug}` ? 'activeLink after:h-[88%]' : ''} relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary font-medium my-1 text-[17px]`}
                                    title={page.title}
                                    onClick={onClose}
                                    key={page.id}
                                >
                                    {page.title || t('defaultTitle')}
                                </LocalizedLink>
                            ))}

                            {totalMorePages > morePagesLimit && totalMorePages !== pageData?.length && (
                                <span className="primaryColor font-[600] text-center w-max cursor-pointer" onClick={handleLoadMore}>
                                    {t('loadMore')}
                                </span>
                            )}
                        </div>
                    </NavigationMenuContent>
                </NavigationMenuItem>
            </NavigationMenuList>
        </NavigationMenu>
    )
}

export default MorePagesDropdown
