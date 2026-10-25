'use client'
import { useState } from 'react'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import { toast } from '@/lib/toast'
import { getFirebaseAuth } from '@/lib/firebaseAuth'
import { deleteAccountApi } from '@/api/apiRoutes'
import { settingsSelector } from '@/redux/reducers/settingsSlice'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { useDarkTheme } from '@/hooks/useDarkTheme'
import { useLogout } from '@/hooks/useLogout'
import { isLogin } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { stripLangPrefix } from '@/lib/localizedUrl'
import ProfileDropdown from '../dropdownsAndModals/ProfileDropdown'
import LoginModal from '../auth/LoginModal'
import MobileNav from './MobileNav'
import MorePagesDropdown from '../dropdownsAndModals/MorePagesDropdown'
import SearchModal from '../search/SearchModal'
import LogoutAlert from '../dropdownsAndModals/LogoutAlert'
import DeleteAccAlert from '../dropdownsAndModals/DeleteAccAlert'
import ImagePreview from '../common/ImagePreview'

const Header = () => {

  const { t } = useTranslation()

  const currLangCode = useLangCode()
  const defaultLangCode = useDefaultLangCode()
  const { isDarkMode: darkThemeMode } = useDarkTheme()

  const [logoutConfrm, setLogoutConfrm] = useState(false)
  const [deleteAccConfrm, setDeleteAccConfrm] = useState(false)

  const router = useRouter()
  const currentPath = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode)

  const settingsData = useSelector(settingsSelector)

  const darkLogo = settingsData?.web_setting?.dark_header_logo
  const lightLogo = settingsData?.web_setting?.light_header_logo

  const showLiveNewsPage = settingsData?.live_streaming_mode === '1'
  const showBreakingNewsPage = settingsData?.breaking_news_mode === '1'
  const showReelsPage = settingsData?.news_buzz_mode === '1'
  const showeNews = settingsData?.e_news_mode === '1'
  const showRssFeed = settingsData?.rss_feed_mode === '1'

  const userData = useSelector(userDataSelector)
  const userRoleStatus = userData?.is_author === 1
  const userName = userData?.name || userData?.email || userData?.mobile || ''
  const { logout } = useLogout()

  const linkClass = (path: string) =>
    `${currentPath === path ? 'activeLink after:h-[94%]' : ''} relative after:content-[""] after:absolute after:top-[1px] min-[1200px]:after:-left-[6px]! 2xl:after:-left-[8px]! after:h-[0%] after:w-[4px] after:rounded-full after:primaryBg hover:primaryColor! transition-all duration-500 hover:after:h-[94%] hover:after:transition-all hover:after:duration-[0.3s] textPrimary uppercase font-semibold navMenusItem`

  const handleAlert = (modal: 'deleteAcc' | 'logoutAcc') => {
    if (modal === 'deleteAcc') {
      if (userData?.email === 'newstester@gmail.com' || userData?.mobile === '+919876543210') {
        toast.error(t('demoAccountCannotBeDeleted'))
        return
      }
      setDeleteAccConfrm(true)
    } else {
      setLogoutConfrm(true)
    }
  }

  const handleSignOut = async (modal: 'deleteAcc' | 'logoutAcc') => {
    const success = await logout(modal === 'deleteAcc' ? 'deletedAcc' : 'loginOutMsg')
    if (success) {
      setLogoutConfrm(false)
      setDeleteAccConfrm(false)
    }
  }

  const deleteUserAccApi = async () => {
    try {
      await deleteAccountApi()
      await handleSignOut('deleteAcc')
    } catch (error) {
      console.error('Error:', error)
    }
  }

  const deleteAccount = async (e: React.MouseEvent) => {
    e.preventDefault()
    try {
      const auth = await getFirebaseAuth()
      const user = auth.currentUser
      if (user) {
        try {
          await user.delete()
          await deleteUserAccApi()
        } catch (error) {
          console.error('Error deleting user account:', error)
          if ((error as { code?: string })?.code === 'auth/requires-recent-login') {
            toast.error(t('loginFirstBeforeDeleteAcc'))
          } else {
            toast.error(t('anErrorOccurredWhileDeletingUserAccount'))
          }
        }
      }
    } catch (error) {
      console.error(error)
    }
  }

  return (
    <header className="sticky top-0 z-48 bodyBgColor border-b borderColor">
      <div className="container py-4">
        <div className="flex items-center justify-between">
          <div className='flex items-center gap-8'>
            <div className="logoDiv">
              <LocalizedLink href="/">
                <div className="h-10 w-36 md:h-15 md:w-45 min-[1200px]:w-[130px] 2xl:w-45">
                  <ImagePreview
                    src={darkThemeMode ? darkLogo || '' : lightLogo || ''}
                    className="object-contain!"
                    alt="web-logo"
                  />
                </div>
              </LocalizedLink>
            </div>

            <div className="navbar hidden min-[1200px]:flex items-center min-[1200px]:gap-2 2xl:gap-6">
              <div className="navLinks">
                <ul className="flexCenter min-[1200px]:gap-4 2xl:gap-6 navMenus">
                  <li className="list-none">
                    <LocalizedLink href="/" title={t('home')} className={linkClass('/')}>{t('home')}</LocalizedLink>
                  </li>

                  {showLiveNewsPage && (
                    <li className="list-none">
                      <LocalizedLink href="/live-news" className={linkClass('/live-news')} title={t('livenews')}>{t('livenews')}</LocalizedLink>
                    </li>
                  )}

                  {showBreakingNewsPage && (
                    <li className="list-none">
                      <LocalizedLink href="/breaking-news" className={linkClass('/breaking-news')} title={t('breakingnews')}>{t('breakingnews')}</LocalizedLink>
                    </li>
                  )}

                  <li className="list-none">
                    <LocalizedLink href="/video-news" className={linkClass('/video-news')} title={t('videosLbl')}> {t('videosLbl')}</LocalizedLink>
                  </li>

                  {showReelsPage && (
                    <li className="list-none">
                      <LocalizedLink href="/newsbuzz" className={linkClass('/newsbuzz')} title={t('newsBuzz')}> {t('newsBuzz')}</LocalizedLink>
                    </li>
                  )}

                  {showRssFeed && (
                    <li className="list-none">
                      <LocalizedLink href="/rss-feed" className={linkClass('/rss-feed')} title={t('rssFeed')}>{t('rssFeed')}</LocalizedLink>
                    </li>
                  )}

                  {showeNews && (
                    <li className="list-none">
                      <LocalizedLink href="/enews" className={linkClass('/enews')} title={t('e_news')}>{t('e_news')}</LocalizedLink>
                    </li>
                  )}

                  <li className="list-none">
                    <MorePagesDropdown />
                  </li>
                </ul>
              </div>

            </div>
          </div>


          <div className="btns hidden min-[1200px]:flex min-[1200px]:gap-1 2xl:gap-3">
            <div>
              <SearchModal />
            </div>
            <div className="authDiv">
              {isLogin() ? (
                <ProfileDropdown userName={userName} userRole={userRoleStatus} handleAlert={handleAlert} />
              ) : (
                <LoginModal />
              )}
              <div>
                <LogoutAlert
                  open={logoutConfrm}
                  onOpenChange={setLogoutConfrm}
                  onConfirm={() => handleSignOut('logoutAcc')}
                />
                <DeleteAccAlert
                  open={deleteAccConfrm}
                  onOpenChange={setDeleteAccConfrm}
                  onConfirm={deleteAccount}
                />
              </div>
            </div>
          </div>
          <div className="min-[1200px]:hidden">
            <MobileNav userRole={userRoleStatus} handleAlert={handleAlert} />
          </div>
        </div>

        <div id="recaptcha-container" className="fixed z-99"></div>
      </div>
    </header>
  )
}

export default Header
