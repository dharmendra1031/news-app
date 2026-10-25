'use client'
import { currentLangCode, defaultLanguageCode, formatDuration, formatShortDate } from '@/components/utils/helpers'
import { useState } from 'react'
import { FaRegCirclePlay } from 'react-icons/fa6'
import { HiMiniUsers } from 'react-icons/hi2'
import { ClockIcon } from 'lucide-react'
import { LuCalendarDays } from 'react-icons/lu'
import { BsThreeDotsVertical } from 'react-icons/bs'
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
} from "@/components/ui/navigation-menu"
import { MdDeleteOutline, MdOutlineBookmark, MdOutlineBookmarkBorder, MdOutlineCreateNewFolder, MdOutlineDownload, MdOutlineEdit } from 'react-icons/md'
import { usePodcastActions } from '@/hooks/usePodcastActions'
import { withLang } from '@/lib/localizedUrl'
import { useRouter } from 'next/router'
import { useDispatch } from 'react-redux'
import { podcastCreated, episodeCreated } from '@/redux/reducers/createPodcastSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import { EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'
import ImagePreview from '@/components/common/ImagePreview'
import NewsTitle from '@/components/common/newsCard/NewsTitle'

export const deactivateIcon = <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g clipPath="url(#clip0_510_4769)">
    <path fillRule="evenodd" clipRule="evenodd" d="M0.499756 8C0.499756 3.85787 3.85763 0.5 7.99976 0.5C12.1419 0.5 15.4998 3.85787 15.4998 8C15.4998 12.1421 12.1419 15.5 7.99976 15.5C3.85763 15.5 0.499756 12.1421 0.499756 8ZM11.1462 11.8535C11.3415 12.0488 11.6581 12.0488 11.8533 11.8535C12.0486 11.6583 12.0486 11.3417 11.8533 11.1464L4.78223 4.07535C4.58698 3.8801 4.27041 3.8801 4.07513 4.07535C3.87988 4.27062 3.87988 4.5872 4.07513 4.78247L11.1462 11.8535Z" fill="#BE151E" />
  </g>
  <defs>
    <clipPath id="clip0_510_4769">
      <rect width="16" height="16" fill="white" />
    </clipPath>
  </defs>
</svg>

interface EpisodeCardProps {
  data: EpisodeApi | PodcastApi
  podcastCard?: boolean
  managePodcastCard?: boolean
  manageEpisodeCard?: boolean
  onDelete?: (id: number) => void
  podcastTitle?: string
  podcastId?: number
  podcastSlug?: string
  myEpisodesCard?: boolean
}

export const EpisodeCard = ({
  data,
  podcastCard = false,
  managePodcastCard = false,
  manageEpisodeCard = false,
  onDelete = () => { },
  podcastTitle,
  podcastId,
  podcastSlug,
  myEpisodesCard = false
}: EpisodeCardProps) => {

  const { t } = useTranslation();

  const router = useRouter()
  const dispatch = useDispatch()

  const langCode = currentLangCode() || 'en';
  const defaultLangCode = defaultLanguageCode() || 'en';

  const { bookmarkEpisode, downloadEpisode } = usePodcastActions()

  const episode = data as EpisodeApi
  const podcast = data as PodcastApi

  const [isBookmarked, setIsBookmarked] = useState(!!episode?.is_bookmarked)

  const isDeavtive = data?.status === '0';

  const [prevDataId, setPrevDataId] = useState(data?.id)
  if (data?.id !== prevDataId) {
    setPrevDataId(data?.id)
    setIsBookmarked(!!episode?.is_bookmarked)
  }

  const handleBookmark = async (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()

    const nextStatus = !isBookmarked
    setIsBookmarked(nextStatus)

    const success = await bookmarkEpisode({ podcastId: episode?.podcast_id, episodeId: episode?.id, status: nextStatus })
    if (!success) {
      setIsBookmarked(!nextStatus)
    }
  }

  const handleDownload = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    downloadEpisode(episode)
  }

  const handleCreateEpisode = (e: React.MouseEvent, podcast: PodcastApi) => {
    e.preventDefault()
    e.stopPropagation()
    router.push(withLang('/manage-podcast/create-episode', langCode, defaultLangCode))
    dispatch(podcastCreated(podcast))
  }

  const handleEditPodcast = (e: React.MouseEvent, podcast: PodcastApi) => {
    e.preventDefault()
    e.stopPropagation()
    dispatch(podcastCreated(podcast))
    router.push(withLang('/manage-podcast/edit-podcast', langCode, defaultLangCode))
  }

  const handleEditEpisode = (e: React.MouseEvent, episode: EpisodeApi) => {
    e.preventDefault()
    e.stopPropagation()
    dispatch(episodeCreated(episode))
    dispatch(podcastCreated({ id: podcastId, title: podcastTitle, slug: podcastSlug } as Pick<PodcastApi, 'id' | 'title' | 'slug'>))
    router.push(withLang('/manage-podcast/edit-episode', langCode, defaultLangCode))
  }

  const handleDeletePodcast = (e: React.MouseEvent, id: number) => {
    e.preventDefault()
    e.stopPropagation()
    onDelete(id)
  }

  return (
    <div className="flex gap-4 lg:gap-6 rounded-xl p-3 border seconadryBorderColor relative customBgWhite h-full">
      {/* Thumbnail */}
      <div className={`relative shrink-0 overflow-hidden commonRadius aspect-200/184 w-[115px] sm:w-38 lg:w-51  ${isDeavtive ? 'h-full!' : 'h-30 sm:h-full lg:h-46'}`}>
        <ImagePreview
          src={data?.image}
          alt={data?.title}
          objectFit='cover'
          className='commonRadius'
        />
      </div>

      {/* Content */}
      <div className="flex flex-col gap-2">
        <div className=''>
          {
            !podcastCard &&
            <NavigationMenu className={`absolute top-2 right-2`}>
              <NavigationMenuList>
                <NavigationMenuItem>
                  <NavigationMenuTrigger className="[&_.triggerIcon]:hidden dark:secondaryBg">
                    <span className='p-1 rounded-md border borderColor sm:text-xl absolute top-1 right-1'>
                      <BsThreeDotsVertical />
                    </span>
                  </NavigationMenuTrigger>
                  <NavigationMenuContent className='w-full customBgWhite z-10 rounded-xl'>
                    <div className='flex flex-col gap-1 w-full max-w-full p-0'>
                      {
                        episode?.source_type !== 'youtube_link' &&
                        <>
                          <NavigationMenuLink onClick={handleDownload} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'><MdOutlineDownload size={20} />{t('download')}</NavigationMenuLink>
                          <div className='h-[1px] border'>

                          </div>
                        </>
                      }
                      <NavigationMenuLink onClick={handleBookmark} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'>
                        {isBookmarked ? <MdOutlineBookmark /> : <MdOutlineBookmarkBorder />}
                        {t('bookmark')}
                      </NavigationMenuLink>
                    </div>

                  </NavigationMenuContent>
                </NavigationMenuItem>
              </NavigationMenuList>
            </NavigationMenu>
          }
          {
            managePodcastCard &&
            <NavigationMenu className={`absolute top-2 right-2`}>
              <NavigationMenuList>
                <NavigationMenuItem>
                  <NavigationMenuTrigger className="[&_.triggerIcon]:hidden dark:secondaryBg">
                    <span className='p-1 rounded-md border borderColor sm:text-xl absolute
                     top-1 right-1'>
                      <BsThreeDotsVertical />
                    </span>
                  </NavigationMenuTrigger>
                  <NavigationMenuContent className='w-full customBgWhite z-10 rounded-xl'>
                    <div className='flex flex-col gap-1 w-full max-w-full p-0'>

                      <>
                        <NavigationMenuLink onClick={(e) => handleEditPodcast(e, podcast)} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'><MdOutlineEdit size={20} />{t('editLbl')}</NavigationMenuLink>
                        <div className='h-[1px] border'>
                        </div>
                      </>
                      <>
                        <NavigationMenuLink onClick={(e) => handleDeletePodcast(e, data?.id)} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'>
                          <MdDeleteOutline size={20} />
                          {t('deleteTxt')}
                        </NavigationMenuLink>

                        <div className='h-[1px] border'>
                        </div>

                      </>
                      <NavigationMenuLink onClick={(e) => handleCreateEpisode(e, podcast)} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'>
                        <MdOutlineCreateNewFolder size={20} />
                        {t('createEpisode')}
                      </NavigationMenuLink>
                    </div>

                  </NavigationMenuContent>
                </NavigationMenuItem>
              </NavigationMenuList>
            </NavigationMenu>
          }
          {
            manageEpisodeCard &&
            <NavigationMenu className={`absolute top-2 right-2`}>
              <NavigationMenuList>
                <NavigationMenuItem>
                  <NavigationMenuTrigger className="[&_.triggerIcon]:hidden dark:secondaryBg">
                    <span className='p-1 rounded-md border borderColor sm:text-xl absolute top-1 right-1'>
                      <BsThreeDotsVertical />
                    </span>
                  </NavigationMenuTrigger>
                  <NavigationMenuContent className='w-full customBgWhite z-10'>
                    <div className='flex flex-col gap-1 w-full max-w-full p-2 pb-3 px-4'>

                      <>
                        <NavigationMenuLink onClick={(e) => handleEditEpisode(e, episode)} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'><MdOutlineEdit size={20} />{t('editLbl')}</NavigationMenuLink>
                        <div className='h-[1px] border'>
                        </div>
                      </>
                      <>
                        <NavigationMenuLink onClick={(e) => handleDeletePodcast(e, data?.id)} className='w-max cursor-pointer font-medium flex items-center gap-2 hover:primaryColor transition-all duration-300 pointer-events-auto'>
                          <MdDeleteOutline size={20} />
                          {t('deleteTxt')}
                        </NavigationMenuLink>
                      </>
                    </div>

                  </NavigationMenuContent>
                </NavigationMenuItem>
              </NavigationMenuList>
            </NavigationMenu>
          }
          {
            !podcastCard && <span className='textPrimary opacity-70 text-sm'>{t('episode')}-{episode?.episode_no}</span>
          }

          <div className={`[&_h4]:w-[90%] max-575:[&_.commonTitle]:line-clamp-2 max-575:[&_.commonTitle]:h-15 ${podcastCard ? '' : '[&_.commonTitle]:line-clamp-2 [&_.commonTitle]:h-15'}`}>
            <NewsTitle title={data?.title} />
          </div>
          {
            data?.description &&
            <p className="textPrimary opacity-70 line-clamp-2 w-[90%] break-all first-letter:capitalize lg:text-lg">
              {data?.description}
            </p>
          }
        </div>

        {
          podcastCard ?
            <div className="flex items-center gap-4 textPrimary mt-auto">
              <div className="flex items-center gap-1.5 opacity-70">
                <HiMiniUsers />
                <span className="font-medium">{podcast?.follower_count}</span>
              </div>
              <div className="flex items-center gap-1.5 opacity-70">
                <FaRegCirclePlay />
                <span className="font-medium">{podcast?.episode_count}</span>
              </div>
            </div>
            :
            <div>
              <div className="flex items-center gap-4 textPrimary flex-wrap">
                <div className="flex items-center gap-1.5 opacity-70">
                  <ClockIcon size={18} />
                  <span className="font-medium">{formatDuration(episode?.duration_seconds)}</span>
                </div>
                <div className="flex items-center gap-1.5 opacity-70">
                  <LuCalendarDays size={18} />
                  <span className="font-medium">{formatShortDate(episode?.published_at)}</span>
                </div>
              </div>
              {
                episode?.listening_history && myEpisodesCard &&
                <div className='bodyBgColor h-2.5 rounded-full overflow-hidden mt-2'>
                  <div className='secondaryBg dark:bg-white h-full rounded-full' style={{ width: `${episode?.duration_seconds ? Math.min((episode.listening_history.listened_seconds / episode.duration_seconds) * 100, 100) : 0}%` }} />
                </div>
              }
            </div>
        }

        {
          isDeavtive &&
          <div className='flex items-center gap-2 managePodcastCard text-red-500 font-semibold text-lg' role="status" aria-label="Deactivated news">
            <span className='statusIcon' aria-hidden="true">{deactivateIcon}</span>
            <span>{t('deactiveNews')}</span>
          </div>

        }
      </div>
    </div>
  )
}
