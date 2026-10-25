'use client'
import Meta from '@/components/common/Meta';
import PodcastDetails from '@/components/pagesComp/podcast/PodcastDetails';
import { webName } from '@/components/utils/helpers';
import { useTranslation } from '@/hooks/useTranslation';

const Index = () => {

    const { t } = useTranslation();

    return (
        <>
            <Meta title={`${webName()} | ${t('managePodcast')}`} />
            <PodcastDetails managePodcast={true} />
        </>
    )
}

export default Index