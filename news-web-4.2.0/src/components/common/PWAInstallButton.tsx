'use client'
import { useEffect, useState } from 'react'
import Cookies from 'js-cookie'
import { Dialog, DialogClose, DialogContent } from '@/components/ui/dialog'
import { MdOutlineClose } from 'react-icons/md'
import { useTranslation } from '@/hooks/useTranslation'
import { toast } from '@/lib/toast'
import { webName } from '@/components/utils/helpers'

// `beforeinstallprompt` isn't in the lib.dom typings yet.
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

const PWA_DISMISSED_COOKIE = 'pwa_install_dismissed'
const PWA_INSTALLED_COOKIE = 'pwa_installed'

/**
 * Floating "Install app" button — shown on mobile only, once the browser
 * signals the PWA is installable (or, on iOS, always — Safari never fires
 * `beforeinstallprompt`, so there's no other way to know).
 * Gated behind `NEXT_PUBLIC_PWA_ENABLED` and remembers a dismissal/install
 * via cookies so it doesn't nag on every visit.
 */
const PWAInstallButton = () => {
  const { t } = useTranslation()

  const [installPrompt, setInstallPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [isIOS, setIsIOS] = useState(false)
  const [isSafari, setIsSafari] = useState(false)
  const [showIOSGuide, setShowIOSGuide] = useState(false)
  const [showInstallButton, setShowInstallButton] = useState(false)

  useEffect(() => {
    if (process.env.NEXT_PUBLIC_PWA_ENABLED !== 'true') return

    let cleanupListeners: (() => void) | undefined

    // Deferred (same trick as NotificationPrompt): the first client render
    // still matches the server's — nothing shown — so this only updates
    // after mount instead of setting state synchronously in the effect body.
    const timer = setTimeout(() => {
      const dismissed = Cookies.get(PWA_DISMISSED_COOKIE) === 'true'
      const installed = Cookies.get(PWA_INSTALLED_COOKIE) === 'true'
      if (dismissed || installed) return

      const userAgent = navigator.userAgent
      const isIOSDevice = /iPad|iPhone|iPod/.test(userAgent) && !('MSStream' in window)
      const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent)
      setIsIOS(isIOSDevice)
      setIsSafari(/^((?!chrome|android).)*safari/i.test(userAgent))

      if (!isMobile) return

      const alreadyStandalone =
        window.matchMedia('(display-mode: standalone)').matches ||
        window.matchMedia('(display-mode: window-controls-overlay)').matches
      if (alreadyStandalone) {
        Cookies.set(PWA_INSTALLED_COOKIE, 'true', { expires: 30 })
        return
      }

      // iOS never fires `beforeinstallprompt` — show the button (it opens the
      // manual "Add to Home Screen" guide instead of the native prompt).
      if (isIOSDevice) {
        setShowInstallButton(true)
        return
      }

      const handleBeforeInstallPrompt = (e: Event) => {
        e.preventDefault()
        setInstallPrompt(e as BeforeInstallPromptEvent)
        setShowInstallButton(true)
      }

      const handleAppInstalled = () => {
        Cookies.set(PWA_INSTALLED_COOKIE, 'true', { expires: 30 })
        setShowInstallButton(false)
      }

      window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
      window.addEventListener('appinstalled', handleAppInstalled)
      cleanupListeners = () => {
        window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
        window.removeEventListener('appinstalled', handleAppInstalled)
      }
    }, 0)

    return () => {
      clearTimeout(timer)
      cleanupListeners?.()
    }
  }, [])

  const handleInstallClick = async () => {
    if (isIOS) {
      setShowIOSGuide(true)
      return
    }

    if (!installPrompt) {
      toast.error(t('installNotAvailable'))
      return
    }

    await installPrompt.prompt()
    const { outcome } = await installPrompt.userChoice
    Cookies.set(outcome === 'accepted' ? PWA_INSTALLED_COOKIE : PWA_DISMISSED_COOKIE, 'true', {
      expires: outcome === 'accepted' ? 30 : 7,
    })
    setInstallPrompt(null)
    setShowInstallButton(false)
  }

  const handleDismiss = () => {
    Cookies.set(PWA_DISMISSED_COOKIE, 'true', { expires: 7 })
    setShowInstallButton(false)
  }

  const handleCloseIOSGuide = () => {
    setShowIOSGuide(false)
    Cookies.set(PWA_DISMISSED_COOKIE, 'true', { expires: 7 })
  }

  if (!showInstallButton) return null

  return (
    <>
      <div className='fixed bottom-20 right-2 z-40 flex items-stretch shadow-lg commonRadius overflow-hidden pwa-pop-up'>
        <button
          onClick={handleInstallClick}
          className='primaryBg text-white text-sm font-medium px-4 py-2'
          aria-label={`${t('install')} ${webName()}`}
        >
          {isIOS ? t('addToHomeScreen') : `${t('install')} ${webName()}`}
        </button>
        <button
          onClick={handleDismiss}
          className='secondaryBg text-white px-3'
          aria-label={t('dismiss')}
        >
          <MdOutlineClose size={16} />
        </button>
      </div>

      <Dialog open={showIOSGuide} onOpenChange={(open) => !open && handleCloseIOSGuide()}>
        <DialogContent showCloseButton={false}>
          <div className='p-6'>
            <div className='flex items-center justify-between mb-4'>
              <h6 className='font-semibold textPrimary'>{t('installOnIOSTitle')}</h6>
              <DialogClose onClick={handleCloseIOSGuide}>
                <MdOutlineClose size={20} className='textSecondary' />
              </DialogClose>
            </div>
            <p className='text-sm mb-3 textSecondary'>{t('installOnIOSDesc')}</p>
            <ol className='mb-4 ml-5 list-decimal space-y-2 text-sm textPrimary'>
              <li>{t('installOnIOSStep1')}</li>
              <li>{t('installOnIOSStep2')}</li>
              <li>{t('installOnIOSStep3')}</li>
            </ol>
            {!isSafari && (
              <p className='mb-4 text-sm text-red-500'>⚠️ {t('installOnIOSSafariOnly')}</p>
            )}
            <button className='commonBtn w-full' onClick={handleCloseIOSGuide}>
              {t('close')}
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}

export default PWAInstallButton
