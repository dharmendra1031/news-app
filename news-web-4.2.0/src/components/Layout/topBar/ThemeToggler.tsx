'use client'
import { LuSun, LuMoon } from 'react-icons/lu'
import { Switch as SwitchPrimitive } from '@base-ui/react/switch'
import { useDarkTheme } from '@/hooks/useDarkTheme'

interface ThemeTogglerProps {
    mobileNav?: boolean
}

const ThemeToggler = ({ mobileNav }: ThemeTogglerProps) => {
    const { isDarkMode: darkThemeMode, toggleDarkMode } = useDarkTheme()

    return (
        <SwitchPrimitive.Root
            aria-label="Toggle dark mode"
            checked={darkThemeMode}
            onCheckedChange={toggleDarkMode}
            className={`inline-flex items-center gap-3 rounded-full bg-[#1E1E1E] pl-4 pr-1 py-1 cursor-pointer ${mobileNav ? 'textPrimary' : ''}`}
        >
            <span className="text-sm font-medium text-white">{darkThemeMode ? 'Dark' : 'Light'}</span>
            <SwitchPrimitive.Thumb className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#CECECE]">
                {darkThemeMode ? <LuMoon size={16} /> : <LuSun size={16} />}
            </SwitchPrimitive.Thumb>
        </SwitchPrimitive.Root>
    )
}

export default ThemeToggler
