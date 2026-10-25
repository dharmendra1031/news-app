'use client'
import { useRouter } from 'next/router'
import Layout from '../Layout/Layout'
import Breadcrumb from '../common/Breadcrumb'
import RichTextContent from '../common/RichText'
import EmptyStatus from '../common/EmptyStatus'
import { useGetMorePages } from '@/hooks/queries/useGetMorePages'
import { useLangCode } from '@/hooks/useLangCode'

const MorePageDetails = () => {
    const router = useRouter()
    const slug = typeof router.query.slug === 'string' ? router.query.slug : ''

    const language_code = useLangCode()

    // Static export hydrates with an empty router.query; an empty slug would
    // fetch the first page of the list instead of this one.
    const { data: morePageQueryData, isLoading } = useGetMorePages({
        language_code,
        slug,
        offset: 0,
        limit: 1,
        enabled: !!slug,
    });

    const page = morePageQueryData?.data?.data?.[0]

    return (
        <Layout>
            <Breadcrumb secondElement={page?.title} />
            {
                isLoading || !slug ? (
                    <div className="container mt-8 md:mt-12 pb-1 animate-pulse space-y-4">
                        <div className="h-4 bg-gray-200 rounded w-1/3" />
                        <div className="h-4 bg-gray-200 rounded w-full" />
                        <div className="h-4 bg-gray-200 rounded w-full" />
                        <div className="h-4 bg-gray-200 rounded w-2/3" />
                    </div>
                ) : page?.page_content ? (
                    <section className="morePagesSect container mt-8 md:mt-12 pb-1">
                        <RichTextContent content={page.page_content} />
                    </section>
                ) : (
                    <EmptyStatus type="noDataFound" />
                )
            }
        </Layout>
    )
}

export default MorePageDetails
