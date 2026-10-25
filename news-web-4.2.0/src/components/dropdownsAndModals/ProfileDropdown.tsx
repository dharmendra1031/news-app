'use client'
import {
    NavigationMenu,
    NavigationMenuContent,
    NavigationMenuItem,
    NavigationMenuList,
    NavigationMenuTrigger,
} from '@/components/ui/navigation-menu'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import profileImg from '@/assets/images/user.svg'
import { truncateText } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { stripLangPrefix } from '@/lib/localizedUrl'
import { userDataSelector } from '@/redux/reducers/userSlice'
import ImagePreview from '../common/ImagePreview'

interface ProfileDropdownProps {
    userName?: string
    userRole?: boolean
    handleAlert: (modal: 'deleteAcc' | 'logoutAcc') => void
    onClose?: () => void
    mobileNav?: boolean
}

const ProfileDropdown = ({ userName, userRole, handleAlert, onClose, mobileNav }: ProfileDropdownProps) => {
    
    const { t } = useTranslation()
    const currLangCode = useLangCode()
    const defaultLangCode = useDefaultLangCode()
    const router = useRouter()
    const userData = useSelector(userDataSelector)

    const currentPath = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode)

    const linkClass = (path: string) =>
        `${currentPath === path ? 'activeLink after:h-[88%]' : ''} relative after:content-[""] after:absolute after:top-[1px] after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[88%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary font-[500] my-1 text-[17px]`

    return (
        <NavigationMenu className={`relative ${mobileNav ? 'z-12!' : 'z-10!'}`}>
            <NavigationMenuList>
                <NavigationMenuItem>
                    <NavigationMenuTrigger className={"flexCenter rtl:flex-row-reverse h-10 gap-1 dropdownTrigg commonRadius dark:secondaryBg commonBg w-max font-semibold border borderColor text-[17px]"}>
                        <div className='w-7 h-7'>
                            <ImagePreview
                                src={userData?.profile || profileImg}
                                alt="profile"
                                className="rounded-full me-1 object-cover"
                                loading="lazy"
                            />
                        </div>
                        {truncateText(userData?.name || userName, 10)}
                    </NavigationMenuTrigger>
                    <NavigationMenuContent>
                        <div className="flex flex-col gap-1 w-max! max-w-full p-1 px-3 customBgWhite textPrimary">
                            <LocalizedLink href="/bookmark" title={t('bookmark')} className={linkClass('/bookmark')} onClick={onClose}>
                                {t('bookmark')}
                            </LocalizedLink>

                            <LocalizedLink href="/category-preferences" title={t('categoryPreferences')} className={linkClass('/category-preferences')} onClick={onClose}>
                                {t('categoryPreferences')}
                            </LocalizedLink>

                            <LocalizedLink href="/profile-update" title={t('update-profile')} className={linkClass('/profile-update')} onClick={onClose}>
                                {t('update-profile')}
                            </LocalizedLink>

                            <LocalizedLink href="/notification-preferences" title={t('notificationPref')} className={linkClass('/notification-preferences')} onClick={onClose}>
                                {t('notificationPref')}
                            </LocalizedLink>

                            {userRole && (
                                <>
                                    <LocalizedLink href="/manage-news" title={t('manageNewsLbl')} className={linkClass('/manage-news')} onClick={onClose}>
                                        {t('manageNewsLbl')}
                                    </LocalizedLink>
                                    <LocalizedLink href="/manage-podcast" title={t('managePodcast')} className={linkClass('/manage-podcast')} onClick={onClose}>
                                        {t('managePodcast')}
                                    </LocalizedLink>
                                </>
                            )}

                            <span className={`cursor-pointer ${linkClass('')}`} onClick={() => handleAlert('deleteAcc')}>
                                {t('deleteAcc')}
                            </span>

                            <span className={`cursor-pointer ${linkClass('')}`} onClick={() => handleAlert('logoutAcc')}>
                                {t('logout')}
                            </span>
                        </div>
                    </NavigationMenuContent>
                </NavigationMenuItem>
            </NavigationMenuList>
        </NavigationMenu>
    )
}

export default ProfileDropdown
