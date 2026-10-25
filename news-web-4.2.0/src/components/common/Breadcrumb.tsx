import { useTranslation } from '@/hooks/useTranslation';
import LocalizedLink from '@/components/common/LocalizeLink'
import { FaHome } from 'react-icons/fa';

interface BreadcrumbProps {
    secondElement?: string | number
    thirdElement?: string | number
    fourthElement?: string | number
    fifthElement?: string | number
    categorySlug?: string
    podcastPage?: boolean
    managePodcast?: boolean
    manageNews?: boolean
}

const Breadcrumb = ({ secondElement, thirdElement, fourthElement, fifthElement, categorySlug, podcastPage = false, managePodcast = false, manageNews = false }: BreadcrumbProps) => {

    const { t } = useTranslation();


    const formatElement = (element?: string | number) => {
        if (element === undefined || element === null) return element;
        // Check if the element is a number
        if (!isNaN(Number(element))) {
            return element;
        }
        // Otherwise, capitalize the first letter
        const str = element.toString();
        return str.charAt(0).toUpperCase() + str.slice(1);
    };

    return (
        <div className="breadcrumbWrapper commonBg">

            <div className='container flex items-center py-8 flex-wrap  capitalize textPrimary text-[18px] md:text-[20px] font-[600] gap-2'>
                <LocalizedLink href="/" title={t('home')}>
                    <h1 className='flex items-center gap-2'>
                        <FaHome size={25} /> {t('home')}
                    </h1>
                </LocalizedLink>
                <span> | </span>
                {secondElement && (
                    <>
                        {
                            manageNews ?
                                <LocalizedLink href={`/manage-news`}>{formatElement(secondElement)}</LocalizedLink>
                                :
                                podcastPage ?
                                    <LocalizedLink href={`/${managePodcast ? 'manage-podcast' : 'podcast'}`}>{formatElement(secondElement)}</LocalizedLink>
                                    :
                                    categorySlug ?
                                        <LocalizedLink href={`/categories-news/${categorySlug}`}>{formatElement(secondElement)}</LocalizedLink>
                                        :
                                        <span>{formatElement(secondElement)}</span>
                        }
                    </>
                )}

                {thirdElement && (
                    <>
                        <span> | </span>
                        {
                            podcastPage && !managePodcast ?
                                <LocalizedLink href={`/podcast/${thirdElement}`}>{formatElement(thirdElement)}</LocalizedLink>
                                :
                                <span>{formatElement(thirdElement)}</span>
                        }
                    </>
                )}
                {fourthElement && (
                    <>
                        <span> | </span>
                        <span>{formatElement(fourthElement)}</span>
                    </>
                )}
                {fifthElement && (
                    <>
                        <span> | </span>
                        <span>{formatElement(fifthElement)}</span>
                    </>
                )}
            </div>
        </div>
    )
}

export default Breadcrumb