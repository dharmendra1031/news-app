import React from 'react'
import StyleOneSkeleton from './StyleOneSkeleton'
import StyleTwoSkeleton from './StyleTwoSkeleton'
import StyleThreeSkeleton from './StyleThreeSkeleton'
import StyleFourSkeleton from './StyleFourSkeleton'
import StyleFiveSkeleton from './StyleFiveSkeleton'
import StyleSixSkeleton from './StyleSixSkeleton'

const HomePageSkeleton = () => {
    return (
        <div className='py-10 flexCol gap-10 lg:gap-20'>
            <StyleOneSkeleton />
            <StyleTwoSkeleton />
            <StyleThreeSkeleton />
            <StyleFourSkeleton />
            <StyleFiveSkeleton />
            <StyleSixSkeleton />
        </div>
    )
}

export default HomePageSkeleton