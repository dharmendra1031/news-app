'use client';
import { useState } from 'react';
import Layout from '@/components/Layout/Layout';
import PdfViewer from './PdfViewer';
import { useGetAdSpaces } from '@/hooks/queries/useGetAdSpaces';
import LoadMoreBtn from '@/components/common/loadermoreBtn/LoadmoreBtn';
import CommonCardSkeleton from '@/components/skeletons/CommonCardSkeleton';
import RichTextContent from '@/components/common/RichText';
import ImagePreview from '@/components/common/ImagePreview';
import Breadcrumb from '@/components/common/Breadcrumb';
import { useTranslation } from '@/hooks/useTranslation';
import EmptyStatus from '@/components/common/EmptyStatus';
import AdSpace from '@/components/common/AdSpace';
import { useLangCode } from '@/hooks/useLangCode';
import { ENewsApi, useGetEnews } from '@/hooks/queries/useGetEnews';
import { PiCalendarDots } from 'react-icons/pi';
import WithPageMode from '@/components/hoc/WithPageMode';

const DATA_PER_PAGE = 6;

const Enews = () => {

    const { t } = useTranslation();
    const langCode = useLangCode();

    const [selectedPdf, setSelectedPdf] = useState<string | null>(null);

    const [loadMore, setLoadMore] = useState(false)
    const [eNewsData, setENewsData] = useState<ENewsApi[]>([])
    const [offset, setOffset] = useState(1)
    const [totalData, setTotalData] = useState(0)

    const { data: eNewsQueryData, isLoading, isFetching, isError, error } = useGetEnews({
        language_code: langCode,
        page: offset,
        per_page: DATA_PER_PAGE,
    });

    const { data: adSpacesQueryData } = useGetAdSpaces({
        language_code: langCode,
        page: 'news_page',
    });

    const adSpacesData = adSpacesQueryData?.data ?? []

    const [prevIsError, setPrevIsError] = useState(isError)
    if (isError !== prevIsError) {
        setPrevIsError(isError)
        if (isError) setENewsData([])
    }

    const [prevQueryData, setPrevQueryData] = useState<typeof eNewsQueryData | symbol>(() => Symbol('initial'))
    if (!isError && eNewsQueryData !== prevQueryData) {
        setPrevQueryData(eNewsQueryData)
        if (eNewsQueryData) {
            const items = eNewsQueryData?.data?.data
                ? [...eNewsQueryData.data.data].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
                : [];
            setTotalData(eNewsQueryData?.data?.total ?? 0)
            if (loadMore) {
                setENewsData((prev) => [...prev, ...items])
            } else {
                setENewsData(items)
            }
        }
    }

    if (isError && error) {
        console.log('eNews err =>', error.message)
    }

    const handleLoadMore = () => {
        setLoadMore(true)
        setOffset((prev) => prev + 1)
    }

    return (
        <Layout>
            <Breadcrumb secondElement={t('e_news')} />
            <div className='mt-8 container flex flex-col gap-6'>
                {/* ad spaces */}
                {
                    adSpacesData?.map((ad) => (
                        ad.placement === 'top' &&
                        <div key={ad?.id}>
                            <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                        </div>
                    ))
                }
                <section className="mb-6 md:mb-10">
                    <div className="grid sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {
                            isLoading && !loadMore ? [...Array(4)].map((_, index) => (
                                <div key={index}>
                                    <CommonCardSkeleton />
                                </div>
                            )) :
                                eNewsData?.map((item) => (
                                    <div className={`w-full rounded-2xl h-max p-4 customBgWhite`} key={item?.id}
                                    >
                                        {/* Image Section */}
                                        <div className="relative w-full h-[250px] md:h-[300px] transition-all duration-500 hover:-translate-y-2">
                                            <ImagePreview
                                                src={item?.thumbnail}
                                                alt={item?.title}
                                                className={`object-cover rounded-[8px]`}
                                            />
                                        </div>

                                        {/* Text Section */}
                                        <div className="p-4 relative text-start">
                                            <div className='h-[100px] md:h-[110px] overflow-hidden'>
                                                <h4 className={`text-[20px] font-[600] mb-2 line-clamp-1 textPrimary`}>
                                                    {item?.title}
                                                </h4>
                                                {
                                                    item?.description &&
                                                    <div className='line-clamp-2 lg:text-lg eNewsPara'>
                                                        <RichTextContent content={item?.description} />
                                                    </div>
                                                }
                                            </div>
                                            <div className='border borderColor my-2.5' />
                                            <div className='flex items-center justify-between mt-3 flex-wrap gap-y-4'>

                                                {
                                                    item?.date &&
                                                    <div className="flex items-center textSecondary">
                                                        <PiCalendarDots className="mr-2 mt-1" size={18} />
                                                        <span className='textSecondary text-[18px] font-[500]'>
                                                            {item?.date}
                                                        </span>
                                                    </div>
                                                }
                                                <button className='commonBtn w-1/2' onClick={() => setSelectedPdf(item?.attachment)}>{t('viewPaper')}</button>
                                            </div>
                                        </div>
                                    </div >
                                ))}
                    </div>
                    {
                        !isLoading && eNewsData?.length < 1 &&
                        <EmptyStatus />
                    }

                    {totalData > DATA_PER_PAGE && totalData !== eNewsData.length ? (
                        <div className='mt-12'>
                            <LoadMoreBtn handleLoadMore={handleLoadMore} loadMoreLoading={isFetching && loadMore} />
                        </div>
                    ) : null}
                </section>

                {/* ad spaces */}
                {
                    adSpacesData?.map((ad) => (
                        ad.placement === 'bottom' &&
                        <div key={ad?.id} className='mt-6'>
                            <AdSpace ad_img={ad?.web_ad_image} ad_url={ad?.ad_url} />
                        </div>
                    ))
                }
            </div>
            {/* PDF Modal */}
            {selectedPdf && (
                <PdfViewer
                    pdf={selectedPdf}
                    onClose={() => setSelectedPdf(null)}
                />
            )}
        </Layout>
    );
};

export default WithPageMode('e_news_mode')(Enews)
