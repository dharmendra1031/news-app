'use client'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { useSelector } from 'react-redux'
import playstore from '@/assets/images/playStore.svg'
import appleStore from '@/assets/images/appleStore.svg'
import LocalizedLink from '@/components/common/LocalizeLink'
import { useTranslation } from '@/hooks/useTranslation'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { useDarkTheme } from '@/hooks/useDarkTheme'
import { stripLangPrefix } from '@/lib/localizedUrl'
import { settingsSelector, webSettingSelector, socialMediaSelector } from '@/redux/reducers/settingsSlice'
import { categoriesSelector } from '@/redux/reducers/categoriesSlice'
import ImagePreview from '../common/ImagePreview'

const Footer = () => {

  const { t } = useTranslation();
  const currLangCode = useLangCode();
  const defaultLangCode = useDefaultLangCode();
  const router = useRouter();

  const { isDarkMode: darkThemeMode } = useDarkTheme();
  const settingsData = useSelector(settingsSelector);
  const webSetting = useSelector(webSettingSelector);
  const socialMedias = useSelector(socialMediaSelector);
  const categories = useSelector(categoriesSelector);

  const currentPath = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode);
  const marginNotIncludeClass = currentPath === '/' || currentPath.includes('/author-details/') || currentPath === '/manage-news' || currentPath === '/manage-podcast' || currentPath.includes('preferences');

  const darkLogo = webSetting?.dark_footer_logo;
  const lightLogo = webSetting?.light_footer_logo;

  const catData = Math.ceil((categories?.length ?? 0) / 2);

  const footerDesc = webSetting?.web_footer_description;

  return (
    <footer className={`secondaryBg text-white pt-10 ${marginNotIncludeClass ? '' : 'commonMT'}`}>
      <div className="container">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          <div className="flex flex-col gap-8">
            <LocalizedLink href="/">
              <div className="w-45 h-15">
                <ImagePreview src={darkThemeMode ? darkLogo || '' : lightLogo || ''} alt="logo" loading="lazy" className="object-contain!" />
              </div>
            </LocalizedLink>
            <div>
              <p className="text-sm font-medium">
                {footerDesc || ''}
              </p>
            </div>

            {socialMedias && socialMedias.length > 0 && (
              <div>
                <span className="font-bold text-[18px]">{t('followus')}</span>
                <div className="flex items-center gap-4 mt-3">
                  {socialMedias.map(item => (
                    <Link href={item.link} target="_blank" className="bg-[#57657dc4] transition-all duration-300 hover:primaryBg hover:shadow-[0_6px_24px_-5px] hover:shadow-gray-500 h-8 w-8 block rounded-full flexCenter" key={item.id}>
                      <div className="h-4 w-4">
                        <ImagePreview src={item.image} alt="social-medias" loading="lazy" />
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}

          </div>

          <div className="lg:pl-12 flex flex-col gap-8">
            <div>
              <span className="font-semibold text-[18px] border-b-2 border-white pb-1.5">{t('navigations')}</span>
            </div>
            <div className="flex flex-col gap-3">
              <LocalizedLink href="/" className="transition-all duration-300 hover:primaryColor font-medium" title={t('home')}>{t('home')}</LocalizedLink>

              <LocalizedLink href="/more-pages/about-us" className="transition-all duration-300 hover:primaryColor font-medium" title={t('aboutus')}>{t('aboutus')}</LocalizedLink>

              {settingsData?.live_streaming_mode === '1' && (
                <LocalizedLink href="/live-news" className="transition-all duration-300 hover:primaryColor font-medium" title={t('livenews')}>{t('livenews')}</LocalizedLink>
              )}

              {settingsData?.breaking_news_mode === '1' && (
                <LocalizedLink href="/breaking-news" className="transition-all duration-300 hover:primaryColor font-medium" title={t('breakingnews')}>{t('breakingnews')}</LocalizedLink>
              )}

              <LocalizedLink href="/video-news" className="transition-all duration-300 hover:primaryColor font-medium" title={t('videosLbl')}>{t('videosLbl')}</LocalizedLink>

              <LocalizedLink href="/more-pages/contact-us" className="transition-all duration-300 hover:primaryColor font-medium" title={t('contactus')}>{t('contactus')}</LocalizedLink>

              <LocalizedLink href="/rss-feed" className="transition-all duration-300 hover:primaryColor font-medium" title={t('rssFeed')}>{t('rssFeed')}</LocalizedLink>

              <LocalizedLink href="/enews" className="transition-all duration-300 hover:primaryColor font-medium" title={t('e_news')}>{t('e_news')}</LocalizedLink>
            </div>
          </div>

          {settingsData?.category_mode === '1' && categories && categories.length > 0 && (
            <div className="flex flex-col gap-8">
              <div>
                <span className="font-semibold text-[18px] border-b-2 border-white pb-1.5">{t('categories')}</span>
              </div>

              <div className="flex items-center gap-16">
                <div className="flex flex-col gap-3">
                  {(categories.length > 10 ? categories.slice(0, catData) : categories).map(item => (
                    <LocalizedLink href={`/categories-news/${item.slug}`} title={item.category_name} className="transition-all duration-300 hover:primaryColor font-medium cursor-pointer" key={item.id}>{item.category_name}</LocalizedLink>
                  ))}
                </div>
                {categories.length > 10 && (
                  <div className="flex flex-col gap-3">
                    {categories.slice(catData).map(item => (
                      <LocalizedLink href={`/categories-news/${item.slug}`} title={item.category_name} className="transition-all duration-300 hover:primaryColor font-medium cursor-pointer" key={item.id}>{item.category_name}</LocalizedLink>
                    ))}
                  </div>
                )}
              </div>

            </div>
          )}

          {(webSetting?.android_app_link || webSetting?.ios_app_link) && (
            <div className="flex flex-col gap-8">
              <div>
                <span className="font-semibold text-[18px] border-b-2 border-white pb-1.5">{t('downloadapp')}</span>
              </div>
              <div>
                <span>{t('magicofapp')}</span>
              </div>
              <div className="flex items-center flex-wrap 2xl:flex-nowrap -ml-3">
                {webSetting?.android_app_link && (
                  <Link href={webSetting.android_app_link} target="_blank" title="play-store">
                    <div className="w-41 h-auto">
                      <ImagePreview src={playstore} alt="playstore" loading="lazy" />
                    </div>
                  </Link>
                )}
                {webSetting?.ios_app_link && (
                  <Link href={webSetting.ios_app_link} target="_blank" title="apple-store">
                    <div className="w-41 h-auto">
                      <ImagePreview src={appleStore} alt="appleStore" loading="lazy" />
                    </div>
                  </Link>
                )}
              </div>
            </div>
          )}

        </div>
      </div>

      <div className="border-t border-[#ffffff29] text-white font-normal py-6 mt-8 md:mt-12">
        <div className="container flex items-center justify-between flex-wrap gap-3 sm:flex-nowrap sm:gap-0">
          <div> {t('copyright')} © {new Date().getFullYear()} {t('allrights')}{' '} <span className="font-bold">{webSetting?.web_name}</span></div>
          <div className="flex items-center gap-2">
            <LocalizedLink href="/more-pages/terms-condition" className="transition-all duration-300 hover:primaryColor font-medium" title={t('termsandcondition')}>{t('termsandcondition')}</LocalizedLink>
            <span>|</span>
            <LocalizedLink href="/more-pages/privacy-policy" className="transition-all duration-300 hover:primaryColor font-medium" title={t('priPolicy')}>{t('priPolicy')}</LocalizedLink>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer
