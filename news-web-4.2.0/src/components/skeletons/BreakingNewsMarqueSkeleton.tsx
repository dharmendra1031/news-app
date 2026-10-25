import { Skeleton } from '@/components/ui/skeleton'
import { useDarkTheme } from '@/hooks/useDarkTheme'

const BreakingNewsMarqueSkeleton = () => {

    const {isDarkMode} = useDarkTheme();

    return (
        <div className={`secondaryBg h-15 flex items-center gap-6 px-4 overflow-hidden`}>
            <Skeleton className='h-4 w-64 bg-white/20' />
            <Skeleton className='h-4 w-48 bg-white/20' />
            <Skeleton className='h-4 w-56 bg-white/20' />
        </div>
    )
}

export default BreakingNewsMarqueSkeleton
