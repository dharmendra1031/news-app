'use client'
import { useEffect, useState } from 'react'
import { FaArrowRight } from 'react-icons/fa'
import {
    Carousel,
    CarouselContent,
    CarouselItem,
    CarouselPrevious,
    CarouselNext,
    type CarouselApi,
} from '@/components/ui/carousel'
import ImagePreview from './ImagePreview'
import LightBox from './LightBox'
import { useTranslation } from '@/hooks/useTranslation'
import { NewsImageApi } from '@/hooks/queries/useGetNews'
import { getDirection } from '@/components/utils/helpers'

interface PhotoGalleryProps {
    galleryPhotos?: NewsImageApi[]
    titleImage?: string
}

// 5+ images collapse into 4 thumbnails, the last one acting as a "view all" tile.
const getThumbnailCount = (total: number) => (total <= 1 ? 0 : Math.min(total - 1, 4))

const PhotoGallery = ({ galleryPhotos, titleImage }: PhotoGalleryProps) => {

    const { t } = useTranslation()

    const [api, setApi] = useState<CarouselApi>()
    const [activeIndex, setActiveIndex] = useState(0)

    const [lightboxOpen, setLightboxOpen] = useState(false)
    const [currentImage, setCurrentImage] = useState(0)

    const allImages = [titleImage || '']
        .concat(galleryPhotos?.map((photo) => photo?.other_image) ?? [])
        .filter(Boolean)

    const totalImages = allImages.length
    const thumbnailCount = getThumbnailCount(totalImages)

    const openLightbox = (index: number) => {
        setCurrentImage(index)
        setLightboxOpen(true)
    }

    useEffect(() => {
        if (!api) return

        const onSelect = () => setActiveIndex(api.selectedScrollSnap())
        onSelect()
        api.on('select', onSelect)

        return () => {
            api.off('select', onSelect)
        }
    }, [api])

    if (!totalImages) return null

    return (
        <div className='photoGallery w-full'>
            <div className='relative w-full commonRadius overflow-hidden'>
                <Carousel
                    setApi={setApi}
                    opts={{
                        loop: totalImages > 1,
                        align: 'center',
                        direction: getDirection(),
                    }}
                >
                    <CarouselContent className='-ml-0'>
                        {allImages.map((image, index) => (
                            <CarouselItem key={index} className='pl-0 basis-full'>
                                <div
                                    className='h-44 sm:h-100 lg:h-148.75 cursor-pointer aspect-1082/595'
                                    onClick={() => openLightbox(index)}
                                >
                                    <ImagePreview src={image} alt={`news-image-${index + 1}`} className='commonRadius' />
                                </div>
                            </CarouselItem>
                        ))}
                    </CarouselContent>

                    {totalImages > 1 && (
                        <>
                            <CarouselPrevious className='inset-s-2 z-9 h-12! w-8! rounded-none bg-white/80! text-black! sm:h-16! sm:w-10!' />
                            <CarouselNext className='inset-e-2 z-9 h-12! w-8! rounded-none bg-white/80! text-black! sm:h-16! sm:w-10!' />
                        </>
                    )}
                </Carousel>
            </div>

            {thumbnailCount > 0 && (
                <div className='hidden md:flex relative bottom-14 z-9 mx-auto justify-center gap-4'>
                    {allImages.slice(0, thumbnailCount + 1).map((image, index) => {
                        // The 4th tile stands in for every remaining image, so it jumps to the last one.
                        const isViewAllTile = thumbnailCount === 4 && index === 4 && totalImages > 5

                        return (
                            <div
                                key={index}
                                className={`relative h-[60px] w-[110px] md:h-[100px] lg:w-[150px] cursor-pointer rounded-xl ring-4 ring-offset-2 transition-all ${activeIndex === index ? 'ring-white' : 'ring-transparent'}`}
                                onClick={() => openLightbox(isViewAllTile ? totalImages - 1 : index)}
                            >
                                <ImagePreview src={image} alt={`news-thumbnail-${index + 1}`} className='rounded-xl' />

                                {isViewAllTile && (
                                    <div className='absolute inset-0 flexCenter bg-black/50 rounded-xl'>
                                        <span className='rounded-lg py-2 px-3 text-sm bg-white text-black font-medium flex items-center gap-1'>
                                            <span className='hidden md:block'>{t('viewall')}</span>
                                            <FaArrowRight />
                                        </span>
                                    </div>
                                )}
                            </div>
                        )
                    })}
                </div>
            )}

            <LightBox
                images={allImages}
                isOpen={lightboxOpen}
                currentIndex={currentImage}
                setCurrentIndex={setCurrentImage}
                onClose={() => setLightboxOpen(false)}
            />
        </div>
    )
}

export default PhotoGallery
