import { FiEye } from 'react-icons/fi'
import { formatShortDate, formatViewCount } from '../utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'
import { PiCalendarDots } from 'react-icons/pi'
import { HiOutlineUserCircle } from 'react-icons/hi2'

interface DateNViewsCountProps {
    date?: string | null
    views?: number
    /** RSS rows have an author but no view count — when set, it replaces the views. */
    author?: string | null
    light?: boolean
}

const Divider = () => <span className='w-px h-3.5 bg-current opacity-30' />

const DateNViewsCount = ({ date, views = 0, author, light = false }: DateNViewsCountProps) => {

    const { t } = useTranslation();

    const dateNode = date &&
        <span className='flex items-center gap-1.5 lowercase'>
            <PiCalendarDots size={16} />
            {formatShortDate(date ?? undefined)}
        </span>

    return (
        <div className={`flex items-center flex-wrap gap-2 sm:gap-3 max-sm:text-sm ${light ? 'text-white' : 'textSecondary'}`}>
            {
                author ?
                    <>
                        <span className='flex items-center gap-1.5 min-w-0'>
                            <HiOutlineUserCircle size={18} className='shrink-0' />
                            <span className='line-clamp-1'>{author}</span>
                        </span>
                        {date && <Divider />}
                        {dateNode}
                    </>
                    :
                    <>
                        {dateNode}
                        {date && views > 0 && <Divider />}
                        {
                            views > 0 &&
                            <span className='flex items-center gap-1.5'>
                                <FiEye size={15} />
                                {formatViewCount(views)} {t('read')}
                            </span>
                        }
                    </>
            }
        </div>
    )
}

export default DateNViewsCount
