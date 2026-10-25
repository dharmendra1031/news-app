'use client'
import Lightbox from 'yet-another-react-lightbox'
import 'yet-another-react-lightbox/styles.css'
import { FaChevronLeft, FaChevronRight } from 'react-icons/fa'

interface LightBoxProps {
    images: string[]
    isOpen: boolean
    currentIndex: number
    setCurrentIndex: (index: number) => void
    onClose: () => void
}

const LightBox = ({ images, isOpen, currentIndex, setCurrentIndex, onClose }: LightBoxProps) => {
    if (!images?.length) return null

    const isSingleSlide = images.length <= 1

    return (
        <Lightbox
            open={isOpen}
            close={onClose}
            index={currentIndex}
            slides={images.map((src) => ({ src }))}
            on={{ view: ({ index }) => setCurrentIndex(index) }}
            carousel={{ finite: isSingleSlide }}
            render={{
                iconPrev: () => <FaChevronLeft className='text-[26px]' />,
                iconNext: () => <FaChevronRight className='text-[26px]' />,
                ...(isSingleSlide && { buttonPrev: () => null, buttonNext: () => null }),
            }}
            styles={{ container: { backgroundColor: '#000000b3' } }}
        />
    )
}

export default LightBox
