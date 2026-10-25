import { FeatureSectionItem } from '@/hooks/queries/useGetFeatureSections'

/** Every home-page style renders one feature section, fed from HomePage. */
export interface FeatureSectionStyleProps {
    title: string
    link?: string
    /** Only set for rss sections — seeds the RSS page's category filter. */
    feedCateIds?: string
    news?: FeatureSectionItem[]
    isLoading?: boolean
}
