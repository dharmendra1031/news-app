'use client'

import ImagePreview from "./ImagePreview"

interface AdSpaceProps {
    ad_url?: string | null
    ad_img?: string | null
    container?: boolean
    rightSide?: boolean
    marginSpace?: boolean
}

const AdSpace = ({ ad_url, ad_img, container = false, rightSide = false, marginSpace = true }: AdSpaceProps) => {

    const handleOpenAd = () => {
        if (ad_url !== undefined && ad_url !== '' && ad_url !== null) {
            window.open(ad_url, '_blank')
        }
    }


    return (
        <div className={`${container ? 'container mx-auto' : ''}`}>
            <div onClick={handleOpenAd}>
                {ad_img && (

                    <div className={`${ad_url ? 'cursor-pointer' : 'cursor-default!'} ${rightSide ? 'h-auto max-h-[587px] overflow-hidden aspect-526/587 rounded-2xl' : `aspect-1620/220 h-auto max-h-[220px] commonRadius overflow-hidden w-full ${marginSpace ? 'mb-6 md:mb-10' : ''}`}`}>
                        <ImagePreview src={ad_img} alt="ad-space-image" />
                    </div>
                )}
            </div>
        </div>
    )
}

export default AdSpace
