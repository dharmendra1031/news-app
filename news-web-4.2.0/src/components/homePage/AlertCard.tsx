'use client'
import { FaArrowUp, FaArrowDown } from 'react-icons/fa6'
import { MarketAlertApi } from '@/hooks/queries/useGetMarketAlerts'

interface AlertCardProps {
    data: MarketAlertApi
}

export const AlertCard = ({ data }: AlertCardProps) => {
    const isIpo = data?.alert_type === 'IPO'
    const value = isIpo ? data?.ipo_price : data?.current_price ? Number(data.current_price).toFixed(2) : null
    const changePercent = data?.percent_change ? parseFloat(data.percent_change) : 0
    const isUp = data?.direction ? data.direction === 'up' : changePercent >= 0

    return (
        <div className='flex items-center gap-2.5 whitespace-nowrap bodyBg border borderColor rounded-[12px] px-3.5 py-2 bg-white dark:bodyBgColor'>
            <span className='font-bold textPrimary sm:text-xl'>{data?.name}</span>
            {
                !isIpo &&
                <span className={`flex items-center gap-1 sm:text-xl font-medium ${isUp ? 'text-green-500' : 'text-red-500'}`}>
                    {isUp ? <FaArrowUp size={11} /> : <FaArrowDown size={11} />}
                    {changePercent > 0 ? '+' : ''}{changePercent.toFixed(2)}%
                </span>
            }
            {
                value &&
                <span className='textSecondary sm:text-lg'>{value} {data?.currency}</span>
            }
        </div>
    )
}

export default AlertCard
