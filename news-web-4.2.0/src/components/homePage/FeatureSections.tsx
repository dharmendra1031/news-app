'use client'
import { Fragment, useEffect, useRef, useState } from 'react'
import AdSpace from '../common/AdSpace'
import { useLangCode } from '@/hooks/useLangCode'
import {
    useGetFeatureSections,
    getFeatureSectionContent,
    FEATURE_SECTION_NEWS_LIMIT,
    FEATURE_SECTIONS_PER_PAGE,
    FeatureSectionApi,
    FeatureSectionStyleWeb,
} from '@/hooks/queries/useGetFeatureSections'
import { FeatureSectionStyleProps } from './styles/styleProps'
import StyleOne from './styles/StyleOne'
import StyleTwo from './styles/StyleTwo'
import StyleThree from './styles/StyleThree'
import StyleFour from './styles/StyleFour'
import StyleFive from './styles/StyleFive'
import StyleSix from './styles/StyleSix'
import FeatureSectionSkeleton from '../skeletons/featureSection/FeatureSectionSkeleton'
import PodcastSect from './PodcastSect'
import LiveNewsSect from './LiveNewsSect'
import EmptyStatus from '../common/EmptyStatus'
import { useGetNews } from '@/hooks/queries/useGetNews'
import CommonCardSkeleton from '../skeletons/CommonCardSkeleton'
import VerticalCard from '../common/newsCard/VerticalCard'

const STYLE_COMPONENTS: Record<FeatureSectionStyleWeb, (props: FeatureSectionStyleProps) => React.ReactNode> = {
    style_1: StyleOne,
    style_2: StyleTwo,
    style_3: StyleThree,
    style_4: StyleFour,
    style_5: StyleFive,
    style_6: StyleSix,
}

// RSS sections point at the feeds page (seeded with the section's categories);
// everything else gets the section's own view-all page.
const sectionViewMoreLink = (section: FeatureSectionApi, contentType: string | null) =>
    contentType === 'rss_feeds_news' ? '/rss-feed' : `/view-all/${section?.slug}`

const FeatureSections = () => {

    const langCode = useLangCode()

    const [page, setPage] = useState(0)
    const [sections, setSections] = useState<FeatureSectionApi[]>([])
    const [totalSections, setTotalSections] = useState(0)

    const { data: sectionsQueryData, isLoading, isFetching, isError: isSectionsError } = useGetFeatureSections({
        language_code: langCode,
        offset: 0,
        limit: FEATURE_SECTION_NEWS_LIMIT,
        section_offset: page * FEATURE_SECTIONS_PER_PAGE,
        section_limit: FEATURE_SECTIONS_PER_PAGE,
    })

    const sectionsFailedOrEmpty = !isLoading && (isSectionsError || (sectionsQueryData?.data?.data?.length ?? 0) === 0)

    const { data: newsData, isLoading: subLoading, isError: isNewsError } = useGetNews({
        language_code: langCode ?? '',
        offset: 0,
        limit: 10,
        enabled: sectionsFailedOrEmpty,
    })


    // Reset during render (not in an effect) so the previous language's sections
    // never get a frame to paint after the language switches.
    const [prevLangCode, setPrevLangCode] = useState(langCode)
    if (langCode !== prevLangCode) {
        setPrevLangCode(langCode)
        setPage(0)
        setSections([])
        setTotalSections(0)
    }

    // Synced during render so SSR-hydrated sections paint on the first render
    // rather than only after a post-commit effect.
    const [prevQueryData, setPrevQueryData] = useState<typeof sectionsQueryData | symbol>(() => Symbol('initial'))
    if (sectionsQueryData !== prevQueryData) {
        setPrevQueryData(sectionsQueryData)
        if (sectionsQueryData) {
            const rows = sectionsQueryData?.data?.data ?? []
            setTotalSections(sectionsQueryData?.data?.total ?? 0)
            setSections((prev) => (page > 0 ? [...prev, ...rows] : rows))
        }
    }

    const hasMore = (page + 1) * FEATURE_SECTIONS_PER_PAGE < totalSections

    const sentinelRef = useRef<HTMLDivElement | null>(null)

    useEffect(() => {
        const sentinel = sentinelRef.current
        if (!sentinel || !hasMore || isFetching) return

        // One-shot: disconnect before advancing so a second intersection can't
        // land in the window before `isFetching` flips and skip a section. The
        // effect re-arms it once that fetch settles.
        const observer = new IntersectionObserver(
            (entries) => {
                if (!entries[0]?.isIntersecting) return
                observer.disconnect()
                setPage((prev) => prev + 1)
            },
            { rootMargin: '200px' }
        )

        observer.observe(sentinel)
        return () => observer.disconnect()
    }, [hasMore, isFetching])

    const renderSection = (section: FeatureSectionApi) => {
        const StyleComponent = STYLE_COMPONENTS[section?.style_web]
        if (!StyleComponent) return null

        const { type, items } = getFeatureSectionContent(section)
        if (items.length === 0) return null

        const ad = section?.ad_spaces
        const adBlock = ad?.web_ad_image
            ? <AdSpace ad_img={ad.web_ad_image} ad_url={ad.ad_url} container marginSpace={false} />
            : null

        return (
            <div key={section.id} className='flexCol gap-10 lg:gap-14'>
                {ad?.placement === 'above' && adBlock}

                <StyleComponent
                    title={section?.title}
                    link={sectionViewMoreLink(section, type)}
                    feedCateIds={type === 'rss_feeds_news' ? section?.category_ids : undefined}
                    news={items}
                />

                {ad?.placement === 'below' && adBlock}
            </div>
        )
    }

    if (isLoading && sections.length === 0) {
        return <FeatureSectionSkeleton />
    }

    if (sectionsFailedOrEmpty && subLoading) {
        return <FeatureSectionSkeleton />
    }

    const newsFailedOrEmpty = !subLoading && (isNewsError || (newsData?.data?.data.length ?? 0) === 0)

    if (sectionsFailedOrEmpty && newsFailedOrEmpty) {
        return <EmptyStatus />
    }

    return (
        <div className='py-10 flexCol gap-10 lg:gap-14'>
            {
                sections.map((section, index) => (
                    <Fragment key={section.id}>
                        {renderSection(section)}
                        {index === 3 && <div className='flexCol gap-10 lg:gap-14'>
                            <PodcastSect />
                            <LiveNewsSect />
                        </div>
                        }
                    </Fragment>
                ))
            }
            {isFetching && page > 0 && <FeatureSectionSkeleton />}

            {
                sectionsFailedOrEmpty &&
                <>
                    <LiveNewsSect />
                    {
                        !newsFailedOrEmpty &&

                        <div className="container grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 gap-y-10">
                            {
                                subLoading
                                    ? [...Array(10)].map((_, index) => (
                                        <div key={index}>
                                            <CommonCardSkeleton />
                                        </div>
                                    ))
                                    : newsData?.data?.data?.map((element) => (
                                        <VerticalCard
                                            key={element?.id}
                                            news={element}
                                            showCateBagde={true}
                                        />
                                    ))
                            }
                        </div>
                    }
                    <PodcastSect />
                </>
            }

            <div ref={sentinelRef} />
        </div>
    )
}

export default FeatureSections
