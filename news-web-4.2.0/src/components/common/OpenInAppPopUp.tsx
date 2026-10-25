'use client'
import {
  Dialog,
  DialogClose,
  DialogContent,
} from "@/components/ui/dialog"
import { useTranslation } from '@/hooks/useTranslation'
import { useSelector } from 'react-redux'
import { webSettingSelector } from '@/redux/reducers/settingsSlice'
import { useRouter } from 'next/router'
import { MdOutlineClose } from "react-icons/md";

interface OpenInAppPopUpProps {
  IsOpenInApp: boolean
  OnHide: () => void
  reelsPage?: boolean
}

const OpenInAppPopUp = ({ IsOpenInApp, OnHide, reelsPage = false }: OpenInAppPopUpProps) => {

  const { t } = useTranslation();

  const webSetting = useSelector(webSettingSelector);

  const router = useRouter();

  const companyName = webSetting?.web_name;

  function openInApp() {
    if (typeof window === 'undefined') return;

    const fullPath = window.location.pathname + window.location.search;
    const pathForReels = fullPath.replace('?slug=', '/slug=');
    const appScheme = `${'news'}://${window.location.hostname}${reelsPage ? pathForReels : router.asPath}`;

    const androidAppStoreLink = webSetting?.android_app_link;
    const iosAppStoreLink = webSetting?.ios_app_link;
    const userAgent = (typeof navigator !== 'undefined' ? (navigator.userAgent || (navigator as unknown as { vendor?: string }).vendor) : '') || '';
    const isAndroid = /android/i.test(userAgent);
    const isIOS = /iPad|iPhone|iPod/.test(userAgent);
    const appStoreLink = isAndroid ? androidAppStoreLink : (isIOS ? iosAppStoreLink : androidAppStoreLink);

    // Close the popup first, then attempt to open the app
    OnHide();

    if (isIOS) {
      // Flag the attempt so the timeout below can tell whether the app took over
      sessionStorage.setItem('appRedirectAttempt', Date.now().toString());

      window.location.href = appScheme;

      setTimeout(function () {
        const redirectAttempt = sessionStorage.getItem('appRedirectAttempt');
        const now = Date.now();
        // Less than 2 seconds passed, so the app never opened
        if (redirectAttempt && (now - parseInt(redirectAttempt)) < 2000) {
          if (iosAppStoreLink && confirm(`${t('appNotInstalled')}`)) {
            window.location.href = iosAppStoreLink;
          }
        }
        sessionStorage.removeItem('appRedirectAttempt');
      }, 2000);
    } else {
      window.location.href = appScheme;
      setTimeout(function () {
        if (!document.hidden) {
          if (appStoreLink && confirm(`${t('appNotInstalled')} `)) {
            window.location.href = appStoreLink;
          }
        }
      }, 1000);
    }
  }

  return (
    <div className='openInAppPopUp'>
      <Dialog open={IsOpenInApp} onOpenChange={OnHide}>
        <DialogContent showCloseButton={false}>
          <div className='flex items-center justify-between py-4 px-6'>
            <div className='flex items-center gap-3'>
              <DialogClose>
                <MdOutlineClose size={22} color='gray' />
              </DialogClose>
              <div>
                <h6 className='font-semibold'>{`${t('viewIn')} ${companyName} ${t('app')}`}</h6>
              </div>
            </div>
            <div>
              <button className='commonBtn' onClick={openInApp}>{t('open')}</button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default OpenInAppPopUp
