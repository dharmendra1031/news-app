'use client'

import Meta from "@/components/common/Meta";
import CreateEpisode from "@/components/pagesComp/profilePages/managePodcast/CreateEpisode";
import { webName } from "@/components/utils/helpers";
import { useTranslation } from "@/hooks/useTranslation";

const Index = () => {

    const { t } = useTranslation();

    return (
        <>
            <Meta title={`${webName()} | ${t('createEpisode')}`} />
            <CreateEpisode />
        </>
    )
}

export default Index