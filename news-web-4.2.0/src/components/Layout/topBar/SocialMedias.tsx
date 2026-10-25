'use client'
import Link from 'next/link'
import { useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import { socialMediaSelector } from '@/redux/reducers/settingsSlice'
import { useLangCode } from '@/hooks/useLangCode'
import { stripLangPrefix } from '@/lib/localizedUrl'
import ImagePreview from '@/components/common/ImagePreview'

const SocialMedias = () => {
    const router = useRouter()
    const currLangCode = useLangCode()
    const socialMedias = useSelector(socialMediaSelector)

    const isHomePage = stripLangPrefix(router.asPath.split('?')[0], currLangCode) === '/'

    if (!socialMedias || socialMedias.length === 0) return null

    return (
        <div className="flexCenter gap-2">
            {isHomePage && <span className="text-[#A0A0A0] text-3xl">|</span>}
            {socialMedias.map(item => (
                <Link
                    href={item.link}
                    key={item.id}
                    title="social-media-link"
                    target="_blank"
                    className="h-[28px] w-[28px] flexCenter commonRadius transition-all duration-300 hover:primaryBg"
                >
                    <div className='h-4.5 w-4.5'>
                        <ImagePreview src={item.image} alt="socialMediaImg" loading="lazy" />
                    </div>
                </Link>
            ))}
        </div>
    )
}

export default SocialMedias
