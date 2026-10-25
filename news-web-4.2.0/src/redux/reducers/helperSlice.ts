import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'

interface HelperState {
    loginModalOpen: boolean
    notificationDataLength: number
    showNotification: boolean
    isLangChange: boolean
    rssFeedViewCategory: string | null
    newsFontSize: number
}

const initialState: HelperState = {
    loginModalOpen: false,
    notificationDataLength: 0,
    showNotification: false,
    isLangChange: false,
    rssFeedViewCategory: null,
    newsFontSize: 18,
}

export const helperSlice = createSlice({
    name: 'helper',
    initialState,
    reducers: {
        setLoginModalOpen: (state, action: PayloadAction<boolean>) => {
            state.loginModalOpen = action.payload
        },
        setNotificationDataLength: (state, action: PayloadAction<number>) => {
            state.notificationDataLength = action.payload
        },
        setShowNotification: (state, action: PayloadAction<boolean>) => {
            state.showNotification = action.payload
        },
        setIsLangChange: (state, action: PayloadAction<boolean>) => {
            state.isLangChange = action.payload
        },
        setRssFeedViewCategory: (state, action: PayloadAction<string | null>) => {
            state.rssFeedViewCategory = action.payload
        },
        setNewsFontSize: (state, action: PayloadAction<number>) => {
            state.newsFontSize = action.payload
        },
    },
})

export const {
    setLoginModalOpen,
    setNotificationDataLength,
    setShowNotification,
    setIsLangChange,
    setRssFeedViewCategory,
    setNewsFontSize,
} = helperSlice.actions
export default helperSlice.reducer

export const dataSelector = (state: RootState) => state.helper

export const loginModalOpenSelector = createSelector(dataSelector, state => state.loginModalOpen)
export const notificationDataLengthSelector = createSelector(dataSelector, state => state.notificationDataLength)
export const showNotificationSelector = createSelector(dataSelector, state => state.showNotification)
export const isLangChangeSelector = createSelector(dataSelector, state => state.isLangChange)
export const rssFeedViewCategorySelector = createSelector(dataSelector, state => state.rssFeedViewCategory)
export const newsFontSizeSelector = createSelector(dataSelector, state => state.newsFontSize)
