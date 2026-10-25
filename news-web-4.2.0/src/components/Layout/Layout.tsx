import React, { useEffect } from 'react'
import Script from 'next/script'
import { useDispatch, useSelector } from 'react-redux'
import { toast } from '@/lib/toast'
import Header from './Header'
import Footer from './Footer'
import { useGetSettings } from '@/hooks/queries/general/useGetSettings';
import { useGetCategories } from '@/hooks/queries/general/useGetCategories';
import { useGetMorePages } from '@/hooks/queries/useGetMorePages';
import { useGetUserDetails } from '@/hooks/queries/useGetUserDetails';
import { useLangCode } from '@/hooks/useLangCode';
import { useTranslation } from '@/hooks/useTranslation';
import { useLogout } from '@/hooks/useLogout';
import { setUserData, tokenSelector } from '@/redux/reducers/userSlice';
import {
  appendCategories,
  categoryLimitSelector,
  categoryOffsetSelector,
  setCategories,
  setLoadMoreCategories,
  setTotalCategories,
} from '@/redux/reducers/categoriesSlice';
import {
  appendMorePages,
  morePagesLimitSelector,
  morePagesOffsetSelector,
  setMorePages,
  setLoadMoreMorePages,
  setTotalMorePages,
} from '@/redux/reducers/morePagesSlice';
import { setSettings } from '@/redux/reducers/settingsSlice';
import MainLoader from '../common/MainLoader';
import CookiesComponent from '../common/CookiesComponent';
import PWAInstallButton from '../common/PWAInstallButton';
import NotificationPrompt from './topBar/NotificationPrompt';
import TopBar from './topBar/TopBar';
import CatNav from './CatNav';
import { useDarkTheme } from '@/hooks/useDarkTheme';
import EmptyStatus from '../common/EmptyStatus'
import { getAdsenseSrc } from '@/lib/adsense';
import { isStaticExport } from '@/lib/staticExport';

const Layout = ({ children }: { children: React.ReactNode }) => {

  const dispatch = useDispatch();
  const language_code = useLangCode();
  const { t } = useTranslation();
  const { logout } = useLogout();

  const token = useSelector(tokenSelector);

  const cateLimit = useSelector(categoryLimitSelector);
  const cateOffset = useSelector(categoryOffsetSelector);

  const morePagesLimit = useSelector(morePagesLimitSelector);
  const morePagesOffset = useSelector(morePagesOffsetSelector);

  const { data: settingsData, isLoading: settingsLoading } = useGetSettings();
  const isSettingsError = settingsData?.error;

  const maintenanceMode = settingsData?.data?.maintenance_mode === '1';
  const cookiesMode = settingsData?.data?.web_setting?.accept_cookie;
  const { isDarkMode: darkThemeMode } = useDarkTheme();
  const categoryMode = settingsData?.data?.category_mode;

  // Fetched here (not per-page) so every page shares one settings/category
  // snapshot — components elsewhere read these via `settingsSelector` etc,
  // not by calling useGetSettings()/useGetCategories() again themselves.

  useEffect(() => {
    if (!settingsData?.data) return
    dispatch(setSettings(settingsData.data))
  }, [settingsData, dispatch]);

  // Extract web_setting values to use in dependency array
  const webSetting = settingsData?.data?.web_setting;

  // SEO mode renders AdSense in _document's server HTML; static export has
  // no server, so it's loaded here from the live settings instead.
  const adsenseSrc = isStaticExport ? getAdsenseSrc(webSetting?.google_adsense) : null;

  useEffect(() => {
    document.documentElement.style.setProperty('--loader-color', process.env.NEXT_PUBLIC_LOADER_COLOR || '#EE2934');
    if (darkThemeMode) {
      document.documentElement.style.setProperty('--secondary-color', webSetting && webSetting?.dark_secondary_color || '#1a2e51')
      document.documentElement.style.setProperty('--body-color', webSetting && webSetting?.dark_body_color || '#f5f5f5')
      document.documentElement.style.setProperty('--primary-color', webSetting && webSetting?.dark_primary_color || '#ee2934')
      document.documentElement.style.setProperty('--hover--color', webSetting && webSetting?.dark_hover_color || '#122342')
      document.documentElement.style.setProperty('--text-primary-color', webSetting && webSetting?.dark_text_primary_color || '#0f1f40')
      document.documentElement.style.setProperty('--text-secondary-color', webSetting && webSetting?.dark_text_secondary_color || '#65686d')
    }
    else {
      document.documentElement.style.setProperty('--secondary-color', webSetting && webSetting?.light_secondary_color || '#EE2934')
      document.documentElement.style.setProperty('--body-color', webSetting && webSetting?.light_body_color || '#061024')
      document.documentElement.style.setProperty('--primary-color', webSetting && webSetting?.light_primary_color || '#ce2b2b')
      document.documentElement.style.setProperty('--hover--color', webSetting && webSetting?.light_hover_color || '#15346d')
      document.documentElement.style.setProperty('--text-primary-color', webSetting && webSetting?.light_text_primary_color || '#ffffff')
      document.documentElement.style.setProperty('--text-secondary-color', webSetting && webSetting?.light_text_secondary_color || '#98a2b3')
    }
  }, [webSetting, darkThemeMode]);


  useEffect(() => {
    if (isSettingsError) {
      console.log('settings error => ', settingsData?.message)
    }

  }, [isSettingsError]);

  const { data: categoriesData, isError } = useGetCategories({
    offset: cateOffset * cateLimit,
    limit: cateLimit,
    language_code,
  });

  useEffect(() => {
    if (categoryMode !== '1') return

    if (categoriesData?.data) {
      const { data, total } = categoriesData.data
      dispatch(setTotalCategories(total))
      dispatch(cateOffset === 0 ? setCategories(data) : appendCategories(data))
      dispatch(setLoadMoreCategories(false))
    }
    if (isError) {
      dispatch(setTotalCategories(0))
      dispatch(setCategories([]))
      dispatch(setLoadMoreCategories(false))
    }
  }, [categoriesData, categoryMode, isError]);

  const { data: morePagesData } = useGetMorePages({
    offset: morePagesOffset * morePagesLimit,
    limit: morePagesLimit,
    language_code,
  });

  useEffect(() => {
    if (morePagesData?.data) {
      const { data, total } = morePagesData.data
      dispatch(setTotalMorePages(total))
      dispatch(morePagesOffset === 0 ? setMorePages(data) : appendMorePages(data))
      dispatch(setLoadMoreMorePages(false))
    }
    else {
      dispatch(setTotalMorePages(0))
      dispatch(setMorePages([]))
      dispatch(setLoadMoreMorePages(false))
    }

  }, [morePagesData]);

  const { data: userDetailsData } = useGetUserDetails({ enabled: !!token });

  useEffect(() => {
    if (!userDetailsData?.data) return

    if (userDetailsData.data.status === 0) {
      toast.error(t('deactiveMsg'))
      logout()
      return
    }

    dispatch(setUserData(userDetailsData.data))
    // `logout`/`t` are recreated every render (useRouter()/useTranslation()
    // aren't referentially stable) — keeping them out of the deps array so
    // this only re-runs when new user details actually arrive, not on every
    // Layout render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userDetailsData]);

  return (
    settingsLoading ?
      <MainLoader />
      :
      isSettingsError ?
        <EmptyStatus type={'somethingWentWrong'} />
        :
        maintenanceMode ?
          <EmptyStatus type={'maintenanceMode'} />
          :
          <div>
            <>
              <TopBar />
              <Header />
              <CatNav />
              <main className={`version-${process.env.NEXT_PUBLIC_WEB_VERSION} seo-${process.env.NEXT_PUBLIC_SEO}`} >
                {children}
              </main>
              <PWAInstallButton />
              <NotificationPrompt />
              <Footer />
              {cookiesMode === '1' && <CookiesComponent />}
              {adsenseSrc && (
                <Script
                  id="google-adsense"
                  src={adsenseSrc}
                  strategy="afterInteractive"
                  crossOrigin="anonymous"
                />
              )}
            </>
          </div>
  )
}

export default Layout