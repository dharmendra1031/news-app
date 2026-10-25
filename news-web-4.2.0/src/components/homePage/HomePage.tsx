'use client'
import Layout from '../Layout/Layout'
import BreakingNewsMarque from './BreakingNewsMarque'
import AlertsSect from './AlertsSect'
import FeatureSections from './FeatureSections'
import AdSpace from '../common/AdSpace'
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces'
import { useLangCode } from '@/hooks/useLangCode'

const HomePage = () => {
    const langCode = useLangCode()

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'home_page',
    })

    const adSpacesData = adSpacesQueryData?.data ?? []

    return (
        <Layout>
            {
                adSpacesData.map((ad) => (
                    ad?.placement === 'top' &&
                    <div className='mt-6 md:mt-10'>
                        <AdSpace key={ad?.id} ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} container />
                    </div>
                ))
            }
            <AlertsSect />
            <BreakingNewsMarque />
            <FeatureSections />
            {
                adSpacesData.map((ad) => (
                    ad?.placement === 'bottom' &&
                    <AdSpace key={ad?.id} ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} container />
                ))
            }
        </Layout>
    )
}

export default HomePage
