'use client'
import NoDataFoundImg from '@/assets/images/emptyStates/NoDataFound.svg'
import maintenanceModeImg from '@/assets/images/emptyStates/Maintenance_Mode.svg'
import somethingWentWrongImg from '@/assets/images/emptyStates/somethingWrong.svg'
import pageNotFoundImg from '@/assets/images/emptyStates/Page_Not_Found.svg'
import ThemeSvg from './ThemeSvg'
import { useTranslation } from '@/hooks/useTranslation'

interface EmptyStatusProps {
    image?: string
    className?: string
    type?: "noDataFound" | "maintenanceMode" | "somethingWentWrong" | "pageNotFound"
    noEpisodes?: boolean
    catNav?: boolean
}

const EmptyStatus = ({
    className = '',
    type = "noDataFound",
    noEpisodes = false,
    catNav = false
}: EmptyStatusProps) => {

    const { t } = useTranslation();

    const getImage = () => {
        switch (type) {
            case "noDataFound":
                return NoDataFoundImg;
            case "maintenanceMode":
                return maintenanceModeImg;
            case "somethingWentWrong":
                return somethingWentWrongImg;
            case "pageNotFound":
                return pageNotFoundImg;
            default:
                return NoDataFoundImg;
        }
    }

    const getTitle = () => {
        switch (type) {
            case "maintenanceMode":
                return t('underMaintance');
            case "somethingWentWrong":
                return t('somethingwentwrong');
            case "pageNotFound":
                return t('pageNotFoundTitle');
            default:
                return '';
        }
    }

    const getDescription = () => {
        switch (type) {
            case "maintenanceMode":
                return t('pleaseTryagain');
            case "somethingWentWrong":
                return t('somethingwentwrongDesc');
            case "pageNotFound":
                return t('pageNotFoundDesc');
            default:
                return '';
        }
    }

    return (
        type === "noDataFound" ?
            <div className='flexColumnCenter text-center my-5 font-semibold text-2xl textPrimary gap-12' style={{ height: catNav ? '250px' : '50vh' }}>
                <ThemeSvg
                    src={getImage()}
                    alt="empty-course-img"
                    className="w-full h-full object-contain"
                />
                {t(noEpisodes ? 'noEpisodesFound' : 'nodatafound')}
            </div>
            :
            <div className='flexColumnCenter h-screen textPrimary text-xl md:text-2xl lg:text-3xl text-center'>
                <div>
                    <ThemeSvg
                        src={getImage()}
                        alt="empty-state"
                        className='!w-[250px] md:!w-[500px]'
                    />
                </div>
                <div className='mt-[30px]'>
                    <h1 className='font-bold'>
                        {getTitle()}
                    </h1>
                </div>
                <div className='mt-[20px]'>
                    <h2 className='font-semibold w-full sm:w-[62%] m-auto'>
                        {getDescription()}
                    </h2>
                </div>
            </div>
    )
}

export default EmptyStatus
