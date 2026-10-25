'use client'
import { useDispatch, useSelector } from 'react-redux'
import { FiMinus, FiPlus, FiVolume2 } from 'react-icons/fi'
import { useTranslation } from '@/hooks/useTranslation'
import { newsFontSizeSelector, setNewsFontSize } from '@/redux/reducers/helperSlice'
import MediaShare from '@/components/common/MediaShare'

interface NewsToolbarProps {
    url: string
    title: string
    hashtag?: string
    onSpeak: () => void
    isSpeaking: boolean
}

const NewsToolbar = ({
    url,
    title,
    hashtag = '',
    onSpeak,
    isSpeaking,
}: NewsToolbarProps) => {
    const { t } = useTranslation()
    const dispatch = useDispatch()
    const fontSize = useSelector(newsFontSizeSelector) || 18

    let finalUrl = url
    try {
        const parsed = new URL(url, typeof window !== 'undefined' ? window.location.origin : 'http://localhost:8000')
        parsed.searchParams.set('share', 'true')
        finalUrl = parsed.toString()
    } catch {
        finalUrl = url
    }

    const handleDecreaseFontSize = () => {
        if (fontSize > 10) {
            dispatch(setNewsFontSize(Math.max(10, fontSize - 2)))
        }
    }

    const handleIncreaseFontSize = () => {
        if (fontSize < 30) {
            dispatch(setNewsFontSize(Math.min(30, fontSize + 2)))
        }
    }

    return (
        <div className='commonBg rounded-xl px-4 py-3 sm:px-6 sm:py-3.5 flex flex-wrap items-center justify-between gap-4 border border-gray-200/60 dark:border-gray-800 shadow-xs'>
            {/* Left controls: Font Size & Speak Aloud */}
            <div className='flex items-center gap-3 sm:gap-5 flex-wrap'>
                {/* Font Size Stepper */}
                <div className='flex items-center gap-2.5'>
                    <span className='text-sm sm:text-base font-medium textPrimary select-none whitespace-nowrap'>
                        {t('fontsize') || 'Font Size'}:
                    </span>
                    <div className='bodyBgColor border rounded-md p-1 flex items-center gap-1.5 sm:gap-2 shadow-xs'>
                        <button
                            type='button'
                            onClick={handleDecreaseFontSize}
                            disabled={fontSize <= 12}
                            className='w-7 h-7 sm:w-8 sm:h-8 flex items-center justify-center rounded commonBg textPrimary transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer'
                            aria-label='Decrease font size'
                        >
                            <FiMinus className='w-3.5 h-3.5 stroke-[2.5]' />
                        </button>
                        <span className='text-sm sm:text-base font-medium textPrimary min-w-[42px] text-center select-none'>
                            {fontSize} px
                        </span>
                        <button
                            type='button'
                            onClick={handleIncreaseFontSize}
                            disabled={fontSize >= 26}
                            className='w-7 h-7 sm:w-8 sm:h-8 flex items-center justify-center rounded commonBg textPrimary transition-colors disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer'
                            aria-label='Increase font size'
                        >
                            <FiPlus className='w-3.5 h-3.5 stroke-[2.5]' />
                        </button>
                    </div>
                </div>

                {/* Vertical Divider */}
                <div className='h-6 w-[1px] bg-gray-300 dark:bg-gray-600 hidden sm:block' />

                {/* Speak Aloud Button */}
                <button
                    type='button'
                    onClick={onSpeak}
                    className='flex items-center gap-2 text-sm sm:text-base font-medium text-gray-800 hover:text-black dark:text-gray-200 dark:hover:text-white transition-colors cursor-pointer group select-none whitespace-nowrap'
                    aria-label={isSpeaking ? 'Stop speaking' : 'Speak aloud'}
                >
                    <FiVolume2 className={`w-5 h-5 text-gray-700 dark:text-gray-300 group-hover:text-black dark:group-hover:text-white ${isSpeaking ? 'text-primary animate-pulse' : ''}`} />
                    <span>{isSpeaking ? (t('stopSpeak') || 'Stop Speaking') : (t('speakAloud') || 'Speak Aloud')}</span>
                </button>
            </div>

            {/* Right controls: Share This News */}
            <MediaShare
                url={url}
                title={title}
                hashtag={hashtag}
            />
        </div>
    )
}

export default NewsToolbar
