'use client'
import { FaPlay } from 'react-icons/fa'

const VideoPlayIcon = () => {

    return (
        <span
            className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flexCenter drop-shadow-lg bg-white rounded-full w-9 h-9 sm:w-13 sm:h-13`}
        >
            <FaPlay className='sm:text-xl' />
        </span>
    )
}

export default VideoPlayIcon
