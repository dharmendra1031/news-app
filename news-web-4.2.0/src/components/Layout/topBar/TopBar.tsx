'use client'
import { useState, useEffect } from 'react'
import ThemeToggler from './ThemeToggler'
import { useDispatch, useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import axios from 'axios'
import { currentLanguageSelector } from '@/redux/reducers/languageSlice'
import { locationSelector, setLocation, settingsSelector } from '@/redux/reducers/settingsSlice'
import {
  locationPermissionCheckedSelector,
  setLocationPermission,
  setLocationPermissionChecked,
  setNotificationPermission,
  setNotificationPermissionChecked,
} from '@/redux/reducers/checkPermissionsSlice'
import { useRegisterFcmToken } from '@/hooks/useRegisterFcmToken'
import { useLangCode, useDefaultLangCode } from '@/hooks/useLangCode'
import { isLogin } from '@/components/utils/helpers'
import { stripLangPrefix } from '@/lib/localizedUrl'
import { LuCalendarDays, LuSun } from 'react-icons/lu'
import LanguageSwitcher from '../../dropdownsAndModals/LanguageSwitcher'
import SocialMedias from './SocialMedias'
import { usePageMode } from '@/hooks/usePageMode'

// Predefine dimensions to prevent layout shifts
const WEATHER_CONTAINER_HEIGHT = '50px'
const SOCIAL_MEDIA_HEIGHT = '32px'

interface WeatherData {
  current?: {
    temp_c?: number
  }
  location?: {
    name?: string
    region?: string
    country?: string
  }
  forecast?: {
    forecastday?: Array<{
      day?: {
        maxtemp_c?: number
        mintemp_c?: number
      }
    }>
  }
}

interface WeatherDisplayProps {
  weatherMode?: boolean
  weather: WeatherData | null
}

const WeatherDisplay = ({ weatherMode, weather }: WeatherDisplayProps) => {
  if (!weatherMode || !weather) return null

  const maxTempC = weather?.forecast?.forecastday?.[0]?.day?.maxtemp_c
  const minTempC = weather?.forecast?.forecastday?.[0]?.day?.mintemp_c
  const cityLine = [weather?.location?.name, weather?.location?.region].filter(Boolean).join(', ')

  return (
    <div className="weather flex flex-col justify-center gap-1" style={{ minHeight: WEATHER_CONTAINER_HEIGHT }}>
      {cityLine && <span className="text-white font-bold text-base">{cityLine}</span>}
      <div className="flex items-center gap-1.5 text-white text-sm font-bold">
        <LuSun size={16} />
        <span>{weather?.current?.temp_c?.toFixed(2)}° C</span>
        {(maxTempC != null || minTempC != null) && <span className='text-[#676767] text-xl -mt-1'>•</span>}
        {maxTempC != null && <span>H: {maxTempC.toFixed(2)}</span>}
        {minTempC != null && <span>L: {minTempC.toFixed(2)}</span>}
      </div>
    </div>
  )
}

const TopBar = () => {

  const router = useRouter()
  const dispatch = useDispatch()
  const { registerToken, firebaseToken } = useRegisterFcmToken()
  const currLangCode = useLangCode()
  const defaultLangCode = useDefaultLangCode();

  const settingsData = useSelector(settingsSelector)
  const location = useSelector(locationSelector)
  const locationPermissionCheckedOnce = useSelector(locationPermissionCheckedSelector)
   const weatherMode = usePageMode('weather_mode');
   const locationWiseNews = usePageMode('location_news_mode');

  const currentLanguage = useSelector(currentLanguageSelector)

  const [weather, setWeather] = useState<WeatherData | null>(null)



  const isHomePage = stripLangPrefix(router.asPath.split('?')[0], currLangCode || defaultLangCode) === '/'

  const fetchWeather = () => {
    if (typeof window === 'undefined' || typeof navigator === 'undefined' || !('geolocation' in navigator)) {
      console.error('Geolocation not supported')
      return
    }

    navigator.geolocation.getCurrentPosition(
      async position => {
        const { latitude, longitude } = position.coords
        dispatch(setLocation(locationWiseNews ? { lat: latitude, long: longitude } : { lat: null, long: null }))
        dispatch(setLocationPermission('granted'))

        try {
          const response = await axios.get(
            `https://api.weatherapi.com/v1/forecast.json?key=${process.env.NEXT_PUBLIC_WEATHER_API_KEY}&q=${latitude},${longitude}&days=1&aqi=no&alerts=no&lang=${currentLanguage?.code}`
          )
          setWeather(response?.data)
        } catch (error) {
          console.error('Weather API error:', error)
        }
      },
      error => {
        console.error('Geolocation error:', error)
        dispatch(setLocationPermission('denied'))
      }
    )
  }

  useEffect(() => {
    if (weatherMode) {
      fetchWeather()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentLanguage, weatherMode])

  // Get today's date
  const today = new Date()
  const dayOfMonth = today.getDate()
  const year = today.getFullYear()
  const month = today.toLocaleString('default', { month: 'long' })

  useEffect(() => {
    if (currLangCode && firebaseToken) {
      registerToken()
      dispatch(setNotificationPermissionChecked(true))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [firebaseToken, currLangCode])

  useEffect(() => {
    if (isLogin() && !locationPermissionCheckedOnce && location.lat != null) {
      registerToken()
      dispatch(setLocationPermissionChecked(true))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location, locationPermissionCheckedOnce])

  useEffect(() => {
    return () => {
      dispatch(setNotificationPermission(''))
    }
  }, [dispatch])

  return (
    <div className={`secondaryBg py-2.5`}>
      <div className="container flex flex-col gap-1.5">
        <div className="grid grid-cols-1 md:grid-cols-2">
          <div className="leftDiv flex items-center gap-2 xl:gap-3 flex-wrap">
            <div className="date flex items-center gap-2 font-semibold commonRadius bg-white w-max py-1 px-2">
              <span><LuCalendarDays /></span>
              <span>{`${month} ${dayOfMonth}, ${year}`}</span>
            </div>
            <span className="text-[#A0A0A0] text-3xl">|</span>
            <WeatherDisplay weatherMode={weatherMode} weather={weather} />
          </div>

          <div className="rightDiv xl:flex items-center justify-end gap-4 hidden">
            <ThemeToggler />
            {isHomePage && settingsData ? (
              <LanguageSwitcher variant="dropdown" />
            ) : (
              <span className="text-[#A0A0A0] text-3xl">|</span>
            )}
            <div style={{ height: SOCIAL_MEDIA_HEIGHT }}>
              <SocialMedias />
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default TopBar
