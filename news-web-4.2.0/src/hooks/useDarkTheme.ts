import { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { setDarkMode, themeSelector } from '@/redux/reducers/checkThemeSlice'

export const useDarkTheme = () => {
    const isDarkMode = useSelector(themeSelector)
    const dispatch = useDispatch()

    useEffect(() => {
        document.documentElement.classList.toggle('dark', isDarkMode)
    }, [isDarkMode])

    const toggleDarkMode = (checked: boolean) => dispatch(setDarkMode(checked))

    return { isDarkMode, toggleDarkMode }
}
