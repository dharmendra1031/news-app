'use client'
import { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import {
    Dialog,
    DialogContent,
    DialogTitle,
} from '@/components/ui/dialog'
import { MdCheck } from 'react-icons/md'
import {
    NavigationMenu,
    NavigationMenuContent,
    NavigationMenuItem,
    NavigationMenuList,
    NavigationMenuTrigger,
} from '@/components/ui/navigation-menu'
import ImagePreview from '@/components/common/ImagePreview'
import { defaultLanguageSelector } from '@/redux/reducers/settingsSlice'
import {
    currentLanguageSelector,
    languageChange,
    languagesListSelector,
    setCurrentLanguageLabels,
    setLanguagesList,
} from '@/redux/reducers/languageSlice'
import { setLoginModalOpen } from '@/redux/reducers/helperSlice'
import { setLoadMoreMorePages, setMorePagesOffset } from '@/redux/reducers/morePagesSlice'
import { useGetLanguages } from '@/hooks/queries/useGetLanguages'
import { DefaultLanguage } from '@/hooks/queries/general/useGetSettings'
import { getLanguageJsonDataApi } from '@/api/apiRoutes'
import { useRegisterFcmToken } from '@/hooks/useRegisterFcmToken'
import { stripLangPrefix, withLang } from '@/lib/localizedUrl'
import { useTranslation } from '@/hooks/useTranslation'
import { useQueryClient } from '@tanstack/react-query'

interface LanguageSwitcherProps {
    variant: 'dropdown' | 'modal'
    mobileNav?: boolean
    open?: boolean
    onClose?: () => void
    /** Overrides the post-selection redirect target (unprefixed path). Defaults to the current path. */
    redirectPath?: string
}

const LanguageSwitcher = ({ variant, mobileNav, open = false, onClose = () => { }, redirectPath }: LanguageSwitcherProps) => {

    const router = useRouter()
    const dispatch = useDispatch()
    const { t } = useTranslation();

    const defaultLanguage = useSelector(defaultLanguageSelector)
    const languagesList = useSelector(languagesListSelector)
    const currentLanguage = useSelector(currentLanguageSelector)
    const { registerToken } = useRegisterFcmToken()
    const queryClient = useQueryClient()

    const { data: languagesData } = useGetLanguages()

    const fetchLanguageJsonData = async (code: string) => {
        try {
            const response = await getLanguageJsonDataApi({ language_code: code, platform_type: 'web' })
            dispatch(setCurrentLanguageLabels({ data: response?.data ?? {}, lastFetch: Date.now() }))
        } catch (error) {
            console.error('Error fetching language json data:', error)
        }
    }

    useEffect(() => {
        if (!languagesData?.data) return

        const list = languagesData.data.data ?? []
        dispatch(setLanguagesList(list))

        if (currentLanguage.code == null) {
            const defaultLang = list.find(item => item.code === defaultLanguage?.code) ?? languagesData.data.default_language
            if (defaultLang) {
                dispatch(languageChange(defaultLang))
                fetchLanguageJsonData(defaultLang.code)
            }
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [languagesData, currentLanguage.code, defaultLanguage?.code, dispatch])

    const handleLanguageChange = (lang: DefaultLanguage) => {
        dispatch(languageChange(lang))
        fetchLanguageJsonData(lang.code)
        registerToken()
        onClose()

        // Persist the choice so `src/proxy.ts` honors it on the next full
        // navigation/reload of an unprefixed URL.
        document.cookie = `lang=${lang.code};path=/;max-age=31536000`

        const currentPath = router.asPath.split('?')[0]
        const pathWithoutLangPrefix = redirectPath ?? stripLangPrefix(currentPath, currentLanguage?.code || undefined)
        const nextUrl = withLang(pathWithoutLangPrefix, lang.code, defaultLanguage?.code)
        if (variant === 'modal') {
            router.push(nextUrl)
        } else {
            router.replace(nextUrl)
        }

        if (variant === 'dropdown') {
            dispatch(setMorePagesOffset(0))
            dispatch(setLoadMoreMorePages(false))
        }
        dispatch(setLoginModalOpen(false))
         queryClient.removeQueries({ queryKey: ['categories'] })
         queryClient.removeQueries({ queryKey: ['more-pages'] })
    }

    // set rtl
    const selectedLang = languagesData && languagesData?.data?.data.find(lang => lang.code === currentLanguage?.code)
    useEffect(() => {
        if (selectedLang && selectedLang.isRTL === 1) {
            document.documentElement.dir = 'rtl'
            document.documentElement.lang = `${selectedLang && selectedLang.code}`
        } else {
            document.documentElement.dir = 'ltr'
            document.documentElement.lang = `${selectedLang && selectedLang.code}`
        }
    }, [selectedLang]);

    if (variant === 'modal') {
        return (
            <Dialog open={open}>
                <DialogContent className="w-[90vw]! sm:w-130! max-h-[80vh] p-0 overflow-hidden rounded-2xl border-0 shadow-2xl bodyBgColor loginModal gap-2">
                    <DialogTitle className="hidden" />

                    {/* Header */}
                    <div className="flex items-center justify-between px-5 py-4 border-b borderColor dark:border-gray-800">
                        <h2 className="text-lg font-semibold tracking-tight">{t('chooseLanLbl')}</h2>
                    </div>

                    {/* Language grid */}
                    <div className="overflow-y-auto max-h-[60vh] p-4 pb-6">
                        <div className="flex items-center flex-wrap gap-4 sm:grid grid-cols-3 sm:gap-2">
                            {languagesList?.map(lang => {
                                const isActive = currentLanguage?.code === lang?.code
                                const label = lang?.display_name || lang?.language

                                return (
                                    <button
                                        key={lang.id}
                                        onClick={() => handleLanguageChange(lang)}
                                        className={`first-letter:capitalize flex items-center justify-between gap-2 px-4 py-3 rounded-xl border text-sm font-semibold capitalize text-left transition-all duration-200 ${isActive ? 'primaryBg text-white border-transparent shadow-md scale-[1.02]' : 'borderColor  hover:bg-gray-50 dark:hover:bg-gray-800'}`}>
                                        <span className="truncate">{label}</span>
                                        {isActive && <MdCheck size={16} className="shrink-0" />}
                                    </button>
                                )
                            })}
                        </div>
                    </div>
                </DialogContent>
            </Dialog>
        )
    }

    if (!languagesList || languagesList.length <= 1) return null

    const langLinkClass = (lang: DefaultLanguage) =>
        `${currentLanguage?.code === lang.code ? 'activeLink after:h-[88%]' : ''} block cursor-pointer w-max max-w-full! relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary font-[500] my-1 text-[17px] first-letter:capitalize`

    return (
        <NavigationMenu className={`relative ${mobileNav ? 'z-10!' : 'z-49!'}`}>
            <NavigationMenuList>
                <NavigationMenuItem>
                    <NavigationMenuTrigger className="py-1 px-2 rouded-3xl h-auto dropdownTrigg [&_.triggerIcon]:-ml-1 font-semibold text-base uppercase bg-white text-black! flex gap-1">
                        <div className="w-5 h-5">
                            <ImagePreview src={currentLanguage?.image} alt="langFlag" rounded="full" />
                        </div>
                        {currentLanguage?.display_name ? currentLanguage.display_name : currentLanguage?.language}
                    </NavigationMenuTrigger>
                    <NavigationMenuContent>
                        <div className="flex flex-col gap-1 w-max! max-w-full p-1 px-3 customBgWhite textPrimary">
                            {languagesList.map(lang => (
                                <span key={lang.id} className={langLinkClass(lang)} onClick={() => handleLanguageChange(lang)}>
                                    {lang.display_name ? lang.display_name : lang.language}
                                </span>
                            ))}
                        </div>
                    </NavigationMenuContent>
                </NavigationMenuItem>
            </NavigationMenuList>
        </NavigationMenu>
    )
}

export default LanguageSwitcher
