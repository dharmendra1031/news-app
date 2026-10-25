'use client'
import { MouseEvent } from 'react'
import { FacebookIcon, FacebookShareButton, TwitterShareButton, WhatsappIcon, WhatsappShareButton, XIcon } from 'react-share'
import { BsLink45Deg } from 'react-icons/bs'
import { useTranslation } from '@/hooks/useTranslation'
import { toast } from '@/lib/toast'

interface MediaShareProps {
    url: string
    title: string
    hashtag?: string
}

const MediaShare = ({ url, title, hashtag = '' }: MediaShareProps) => {
    const { t } = useTranslation()

    let finalUrl = url
    try {
        const currentUrl = new URL(url, typeof window !== 'undefined' ? window.location.origin : 'http://localhost:8000')
        currentUrl.searchParams.set('share', 'true')
        finalUrl = currentUrl.toString()
    } catch {
        finalUrl = url
    }

    const handleCopyUrl = async (e: MouseEvent) => {
        e.preventDefault()
        const textToCopy = `${title}\n\nVisit Website for more details : ${decodeURI(finalUrl)}`
        try {
            if (typeof navigator !== 'undefined' && navigator?.clipboard?.writeText) {
                await navigator.clipboard.writeText(textToCopy)
                toast.success(t('urlCopied') || t('linkCopied') || 'Link copied to clipboard')
                return
            }

            // Fallback for environments without navigator.clipboard
            if (typeof document !== 'undefined') {
                const textArea = document.createElement('textarea')
                textArea.value = textToCopy
                textArea.style.position = 'fixed'
                textArea.style.left = '-999999px'
                textArea.style.top = '-999999px'
                document.body.appendChild(textArea)
                textArea.focus()
                textArea.select()
                const successful = document.execCommand('copy')
                document.body.removeChild(textArea)

                if (successful) {
                    toast.success(t('urlCopied') || t('linkCopied') || 'Link copied to clipboard')
                    return
                }
            }

            toast.error(t('somethingMSg') || 'Failed to copy to clipboard')
        } catch (error) {
            console.error("Error copying to clipboard:", error)
            toast.error(t('somethingMSg') || 'Failed to copy to clipboard')
        }
    }

    return (
        <div className='flex items-center gap-4 flex-wrap'>
            <span className='textPrimary font-semibold uppercase'>{t('shareLbl')}  :</span>
            <div className='flex items-center gap-4 flex-wrap'>
            <FacebookShareButton
                url={decodeURI(finalUrl)}
                title={title}
                hashtag={hashtag}
            >
                <FacebookIcon size={40} round />
            </FacebookShareButton>
            <WhatsappShareButton
                url={decodeURI(finalUrl)}
                title={title}
            >
                <WhatsappIcon size={40} round />
            </WhatsappShareButton>
            <TwitterShareButton
                url={decodeURI(finalUrl)}
                title={title}
                hashtags={hashtag ? [hashtag] : []}
            >
                <XIcon size={40} round />
            </TwitterShareButton>
            <button onClick={handleCopyUrl} className='primaryBg w-[40px] h-[40px] flexCenter text-white rounded-full'>
                <BsLink45Deg size={30} />
            </button>
            </div>

        </div>
    )
}

export default MediaShare
