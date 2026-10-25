'use client'
import { MdCheck } from 'react-icons/md'

interface NotificationPrefCardProps {
    title: string
    description: string
    checked?: boolean
    onToggle: () => void
}

const NotificationPrefCard = ({ title, description, checked = false, onToggle }: NotificationPrefCardProps) => {
    return (
        <div
            onClick={onToggle}
            className='flex items-start justify-between gap-4 commonRadius border secondaryBorderColor customBgWhite p-4 cursor-pointer'
        >
            <div className='flex flex-col gap-1'>
                <h3 className='text-lg font-semibold textPrimary'>{title}</h3>
                <p className='text-sm textPrimary'>{description}</p>
            </div>

            <span
                className={`flexCenter shrink-0 w-5 h-5 sm:w-6 sm:h-6 rounded-full border-2 transition-colors ${checked ? 'primaryBg border-transparent' : 'border-[var(--primary-color)]'}`}
            >
                {checked && <MdCheck className='text-white' size={18} />}
            </span>
        </div>
    )
}

export default NotificationPrefCard
