'use client'
import React from 'react'
import { useTranslation } from '@/hooks/useTranslation'

interface DateTabContentProps {
  setDate: React.Dispatch<React.SetStateAction<{ date: string; year: string | number }>>
  setLastNDays: React.Dispatch<React.SetStateAction<number | null>>
  displayDate: Date
  setDisplayDate: React.Dispatch<React.SetStateAction<Date>>
  selectedDate: Date
  setSelectedDate: React.Dispatch<React.SetStateAction<Date>>
  activeDateTab: string | number
  setActiveDateTab: React.Dispatch<React.SetStateAction<string | number>>
  offset?: number
}

interface CalendarDay {
  day: number
  month: number
  year: number
  isCurrentMonth: boolean
}

const DateTabContent: React.FC<DateTabContentProps> = ({
  setDate,
  setLastNDays,
  displayDate,
  selectedDate,
  setSelectedDate,
  activeDateTab,
  setActiveDateTab,
}) => {
  const { t } = useTranslation()
  const currentDate = new Date()

  // Generate days for the calendar
  const generateCalendarDays = (): CalendarDay[] => {
    const year = displayDate.getFullYear()
    const month = displayDate.getMonth()

    // First day of the month
    const firstDay = new Date(year, month, 1).getDay()
    // Adjust for Monday as first day (0 = Monday, 6 = Sunday)
    const adjustedFirstDay = firstDay === 0 ? 6 : firstDay - 1

    // Last day of the month
    const lastDay = new Date(year, month + 1, 0).getDate()

    // Days from previous month
    const prevMonthLastDay = new Date(year, month, 0).getDate()

    const days: CalendarDay[] = []

    // Add days from previous month
    for (let i = adjustedFirstDay - 1; i >= 0; i--) {
      days.push({
        day: prevMonthLastDay - i,
        month: month - 1,
        year: month === 0 ? year - 1 : year,
        isCurrentMonth: false,
      })
    }

    // Add days from current month
    for (let i = 1; i <= lastDay; i++) {
      days.push({
        day: i,
        month,
        year,
        isCurrentMonth: true,
      })
    }

    // Add days from next month
    const remainingDays = 42 - days.length // 6 rows of 7 days
    for (let i = 1; i <= remainingDays; i++) {
      days.push({
        day: i,
        month: month + 1,
        year: month === 11 ? year + 1 : year,
        isCurrentMonth: false,
      })
    }

    return days
  }

  const days = generateCalendarDays()

  // Check if a date is the selected date
  const isSelectedDate = (date: CalendarDay) => {
    return (
      date.day === selectedDate.getDate() &&
      date.month === selectedDate.getMonth() &&
      date.year === selectedDate.getFullYear()
    )
  }

  // Handle date selection
  const handleDateSelect = (date: CalendarDay) => {
    const formattedMonth = String(date.month + 1).padStart(2, '0')
    const formattedDay = String(date.day).padStart(2, '0')
    setDate({
      date: `${date.year}-${formattedMonth}-${formattedDay}`,
      year: date.year,
    })
    setLastNDays(null)
    setSelectedDate(new Date(date.year, date.month, date.day))
    setActiveDateTab('custom')
  }

  // Handle tab selection
  const handleTabSelect = (tab: string | number) => {
    setActiveDateTab(tab)

    const today = new Date()

    switch (tab) {
      case 'today': {
        const formattedMonth = String(today.getMonth() + 1).padStart(2, '0')
        const formattedDay = String(today.getDate()).padStart(2, '0')
        setDate({
          date: `${today.getFullYear()}-${formattedMonth}-${formattedDay}`,
          year: today.getFullYear(),
        })
        setLastNDays(null)
        setSelectedDate(today)
        break
      }
      case 'last7days':
        setDate({ date: '', year: '' })
        setLastNDays(7)
        break
      case 'last30days':
        setDate({ date: '', year: '' })
        setLastNDays(30)
        break
      case 'last90days':
        setDate({ date: '', year: '' })
        setLastNDays(90)
        break
      case currentDate.getFullYear():
        setLastNDays(null)
        setDate({
          date: '',
          year: currentDate.getFullYear(),
        })
        break
      case currentDate.getFullYear() - 1:
        setLastNDays(null)
        setDate({
          date: '',
          year: currentDate.getFullYear() - 1,
        })
        break
      case currentDate.getFullYear() - 2:
        setLastNDays(null)
        setDate({
          date: '',
          year: currentDate.getFullYear() - 2,
        })
        break
      default:
        break
    }
  }

  // Format month and year display
  const monthYearDisplay = () => {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ]
    return `${months[displayDate.getMonth()]}`
  }

  return (
    <div className="flex flex-col md:flex-row rounded-lg bodyBgColor shadow-sm overflow-hidden font-medium h-[300px] overflow-y-auto sm:h-max">
      {/* Left sidebar with quick date options */}
      <div className="w-full md:w-40 p-4 border-r border-gray-200 textprimary">
        <div className="space-y-2">
          <button
            type="button"
            onClick={() => handleTabSelect('today')}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === 'today' ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {t('today')}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect('last7days')}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === 'last7days' ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {t('last7days')}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect('last30days')}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === 'last30days' ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {t('last30days')}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect('last90days')}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === 'last90days' ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {t('last90days')}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect(currentDate.getFullYear())}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === currentDate.getFullYear() ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {currentDate.getFullYear()}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect(currentDate.getFullYear() - 1)}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === currentDate.getFullYear() - 1 ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {currentDate.getFullYear() - 1}
          </button>
          <button
            type="button"
            onClick={() => handleTabSelect(currentDate.getFullYear() - 2)}
            className={`w-full text-left px-3 py-2 rounded-md ${
              activeDateTab === currentDate.getFullYear() - 2 ? 'secondaryBg text-white' : 'hover:secondaryBg hover:text-white'
            }`}
          >
            {currentDate.getFullYear() - 2}
          </button>
        </div>
      </div>

      {/* Calendar view */}
      <div className="flex-1 p-4 textprimary">
        <div className="mb-4 flex justify-between items-center">
          <div className="flex items-center justify-between w-full gap-3">
            <div className="text-lg font-bold py-1 rounded-[6px] customBgWhite w-full text-center">
              {monthYearDisplay()}
            </div>
            <div className="text-lg font-bold py-1 rounded-[6px] customBgWhite w-full text-center">
              {displayDate.getFullYear()}
            </div>
          </div>
        </div>

        {/* Days of week headers */}
        <div className="grid grid-cols-7 mb-2">
          {['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) => (
            <div key={day} className="text-center text-sm font-medium py-2">
              {day}
            </div>
          ))}
        </div>

        {/* Calendar grid */}
        <div className="grid grid-cols-7 gap-2">
          {days.map((date, index) => {
            const isDateAfterToday =
              new Date(date.year, date.month, date.day) >
              new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate())

            return (
              <button
                key={index}
                type="button"
                onClick={() => handleDateSelect(date)}
                disabled={isDateAfterToday}
                className={`h-10 w-full flex items-center justify-center rounded-md text-sm sm:text-base ${
                  !date.isCurrentMonth
                    ? 'textPrimary opacity-30'
                    : isDateAfterToday
                    ? 'cursor-not-allowed customBgWhite'
                    : 'textprimary shadow'
                } ${
                  isSelectedDate(date)
                    ? 'secondaryBg text-white! opacity-100'
                    : isDateAfterToday
                    ? 'customBgWhite cursor-not-allowed!'
                    : 'customBgWhite'
                }`}
              >
                {String(date.day).padStart(2, '0')}
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}

export default DateTabContent
