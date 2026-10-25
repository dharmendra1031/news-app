'use client'
import Meta from '@/components/common/Meta'
import CreatePodcast from '@/components/pagesComp/profilePages/managePodcast/CreatePodcast'
import { webName } from '@/components/utils/helpers'
import { useTranslation } from '@/hooks/useTranslation'

const Index = () => {
    const { t } = useTranslation()

    return (
        <>
            <Meta title={`${webName()} | ${t('editPodcast')}`} />
            <CreatePodcast />
        </>
    )
}

export default Index
