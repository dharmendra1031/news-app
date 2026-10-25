'use client'
import { FaArrowDownLong, FaArrowUpLong } from 'react-icons/fa6'
import { MarketAlertApi } from '@/hooks/queries/useGetMarketAlerts'

interface AlertCardProps {
    data: MarketAlertApi
}

const AlertCard = ({ data }: AlertCardProps) => {
    const isIpo = data?.alert_type === 'IPO'
    const changePercent = data?.percent_change ? parseFloat(data.percent_change) : 0
    const value = isIpo ? data?.ipo_price : data?.current_price ? Number(data.current_price).toFixed(2) : null
    const isNegative = data?.direction ? data.direction === 'down' : changePercent < 0
    const isZero = Number(changePercent.toFixed(2)) === 0

    return (
        <div className='relative w-full rounded-[12px] border borderColor customBgWhite overflow-hidden h-[90px]'>
            <div className='absolute left-0 top-0 h-full w-full rounded-[12px] border-l-4 secondaryBorder dark:border-gray-400' />

            <div className='flex justify-between gap-3 py-5 px-4'>
                <h3 className='min-w-0 flex-1 text-lg md:text-xl lg:text-[22px] font-semibold line-clamp-2'>
                    {data?.name}
                </h3>

                {
                    isIpo ?
                        <div className='flex flex-col items-end gap-0.5'>
                            <span className='text-sm md:text-base lg:text-xl font-bold'>IPO</span>
                            <span className='lg:text-lg textSecondary'>{value ? value : 'IPO'}</span>
                        </div>
                        :
                        <div className='flex flex-col items-end gap-0.5'>
                            <div className={`flex items-center gap-1 ${isZero ? '' : isNegative ? 'text-red-500' : 'text-green-500'}`}>
                                {
                                    !isZero &&
                                    <span className='pr-6'>
                                        {isNegative ? <FaArrowDownLong className='shrink-0' size={14} /> : <FaArrowUpLong className='shrink-0' size={14} />}
                                    </span>
                                }
                                <span className='text-sm md:text-base lg:text-xl font-bold'>
                                    {!isZero && !isNegative ? '+' : ''}
                                    {isZero ? '0.00' : changePercent.toFixed(2)}%
                                </span>
                            </div>
                            <span className='lg:text-lg textSecondary'>{value}</span>
                        </div>
                }
            </div>
        </div>
    )
}

export default AlertCard
