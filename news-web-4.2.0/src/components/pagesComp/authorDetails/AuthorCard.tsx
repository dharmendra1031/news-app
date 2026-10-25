'use client'
import Link from 'next/link'
import ImagePreview from '@/components/common/ImagePreview'
import AuthorCardSkeleton from '@/components/skeletons/AuthorCardSkeleton'
import { FaLinkedin, FaWhatsapp } from 'react-icons/fa'
import { FiFacebook } from 'react-icons/fi'
import { MdList, MdOutlineGridView } from 'react-icons/md'
import { LiaTelegram } from 'react-icons/lia'
import { userDetailsType } from '@/types/GlobalTypes'
import { useTranslation } from '@/hooks/useTranslation'

export type AuthorViewType = 'grid' | 'list'

interface AuthorCardProps {
    authorDetails?: userDetailsType | null
    viewType: AuthorViewType
    setViewType: (view: AuthorViewType) => void
    isLoading?: boolean
}

const AuthorCard = ({ authorDetails, viewType, setViewType, isLoading = false }: AuthorCardProps) => {
    const { t } = useTranslation()

    if (isLoading) return <AuthorCardSkeleton />

    const author = authorDetails?.author
    const hasSocialLinks = !!(author?.telegram_link || author?.facebook_link || author?.whatsapp_link || author?.linkedin_link)

    return (
        <div className='flex flex-col gap-8'>
            <div className='flex justify-between items-center'>
                <h2 className='text-2xl font-semibold textPrimary'>{t('author')}</h2>
                <div className='flex gap-2.5'>
                    <button
                        type='button'
                        className={`rounded p-3 textPrimary ${viewType === 'grid' ? 'bg-[#1B2D511A] dark:bg-white/10' : ''}`}
                        onClick={() => setViewType('grid')}
                    >
                        <MdOutlineGridView size={24} />
                    </button>
                    <button
                        type='button'
                        className={`rounded p-3 textPrimary ${viewType === 'list' ? 'bg-[#1B2D511A] dark:bg-white/10' : ''}`}
                        onClick={() => setViewType('list')}
                    >
                        <MdList size={24} />
                    </button>
                </div>
            </div>

            <div className='customBgWhite rounded-2xl p-5 border secondaryBorderColor flex flex-col gap-4'>
                <div className='flex items-center gap-3'>
                    <div className='w-10 h-10 rounded-full overflow-hidden shrink-0'>
                        <ImagePreview src={authorDetails?.profile} alt={authorDetails?.name || 'author'} objectFit='cover' />
                    </div>
                    <div className='flex flex-col justify-center gap-1'>
                        <h3 className='text-sm font-medium textPrimary opacity-79'>{t('author')}</h3>
                        <p className='text-base textPrimary font-semibold'>{authorDetails?.name}</p>
                    </div>
                </div>

                {
                    author?.bio && (
                        <div className='textPrimary border-t borderColor pt-4'>
                            {author.bio}
                        </div>
                    )
                }

                {
                    hasSocialLinks && (
                        <div className='flex flex-col md:flex-row md:items-center gap-4 border-t borderColor pt-4'>
                            <div className='font-normal text-base textPrimary'>{t('followMe')} :</div>
                            <div className='flex gap-3 items-center'>
                                {author?.telegram_link && (
                                    <Link href={author.telegram_link} target='_blank' className='commonBg dark:bodyBgColor p-2 rounded-full'>
                                        <LiaTelegram size={22} />
                                    </Link>
                                )}
                                {author?.facebook_link && (
                                    <Link href={author.facebook_link} target='_blank' className='commonBg dark:bodyBgColor p-2 rounded-full'>
                                        <FiFacebook size={22} />
                                    </Link>
                                )}
                                {author?.whatsapp_link && (
                                    <Link href={author.whatsapp_link} target='_blank' className='commonBg dark:bodyBgColor p-2 rounded-full'>
                                        <FaWhatsapp size={22} />
                                    </Link>
                                )}
                                {author?.linkedin_link && (
                                    <Link href={author.linkedin_link} target='_blank' className='commonBg dark:bodyBgColor p-2 rounded-full'>
                                        <FaLinkedin size={22} />
                                    </Link>
                                )}
                            </div>
                        </div>
                    )
                }
            </div>
        </div>
    )
}

export default AuthorCard
