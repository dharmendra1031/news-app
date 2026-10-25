'use client'
import { useGetBreakingNews } from '@/hooks/queries/useGetBreakingNews';
import { useLangCode } from '@/hooks/useLangCode';
import BreakingNewsMarqueSkeleton from '@/components/skeletons/BreakingNewsMarqueSkeleton';
import Marquee from 'react-fast-marquee'
import { getDirection } from '@/components/utils/helpers'

const BreakingNewsMarque = () => {

    const langCode = useLangCode();

    const { data: breakingNewsData, isLoading, isFetching, isError, error } = useGetBreakingNews({
        language_code: langCode,
    });

    const data = breakingNewsData?.data?.data

    if (isLoading) return <BreakingNewsMarqueSkeleton />

    return (
        data && data?.length > 0 &&
        <div className={`secondaryBg dark:bg-white text-white dark:text-black font-medium h-15 flex items-center gap-3`}>
            <Marquee pauseOnHover autoFill direction={getDirection() === 'rtl' ? 'right' : 'left'}>
                {
                    data?.map((item, indx) => (
                        <div className='flex items-center gap-4 me-6' key={indx}>
                            <span className='w-2 h-2 bg-[#DBDBDB] dark:bg-black rounded-full'></span>
                            <span className='font-semibold xl:text-lg'>{item?.title}</span>
                        </div>
                    ))
                }
            </Marquee>
        </div>
    )
}

export default BreakingNewsMarque