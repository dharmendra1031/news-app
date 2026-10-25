'use client'
import { useDispatch } from 'react-redux'
import LocalizedLink from './LocalizeLink'
import { useTranslation } from '@/hooks/useTranslation'
import { FaAngleLeft, FaAngleRight, FaArrowRight, FaArrowRightLong } from 'react-icons/fa6'
import { setRssFeedViewCategory } from '@/redux/reducers/helperSlice'

interface SectionTitleProps {
    title: string
    link?: string
    feedCateIds?: string
    showViewMore?: boolean
}

const SectionTitle = ({ title, link, feedCateIds, showViewMore = true }: SectionTitleProps) => {

    const { t } = useTranslation()
    const dispatch = useDispatch()

    const handleViewAllCateIds = () => {
        if (feedCateIds) dispatch(setRssFeedViewCategory(feedCateIds))
    }

    return (
        <div className='mb-4 sm:mb-7 sectionTitle'>
            <div className='flex items-center justify-between gap-3'>
                <div className='flex items-center gap-2 min-w-0'>
                    <span className='w-1 h-4 md:h-10 primaryBg rounded-full shrink-0' />
                    <h2 className='textPrimary text-lg md:text-xl font-bold truncate'>{title}</h2>
                </div>

                {
                    showViewMore &&
                    <div className='shrink-0' onClick={handleViewAllCateIds}>
                        <LocalizedLink
                            href={link || ''}
                            title={t('viewMore')}
                        >
                            <button className='flex items-center gap-1.5 border border-black dark:border-white bg-transparent hover:hoverBg transition-all duration-300 hover:text-white commonRadius font-medium max-sm:py-1 max-sm:px-2 py-2 px-4 textPrimary'>{t('viewMore')} <FaArrowRight className='rtl:rotate-180' /></button>
                        </LocalizedLink>
                    </div>
                }
            </div>

            <div className='w-full h-px borderColor border-b mt-6 sm:mt-7' />
        </div>
    )
}

export default SectionTitle
