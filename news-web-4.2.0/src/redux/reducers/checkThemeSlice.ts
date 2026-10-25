import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'

interface CheckThemeState {
    isDarkMode: boolean
}

const initialState: CheckThemeState = {
    isDarkMode: false,
}

export const checkThemeSlice = createSlice({
    name: 'checkTheme',
    initialState,
    reducers: {
        setDarkMode: (state, action: PayloadAction<boolean>) => {
            state.isDarkMode = action.payload
        },
    },
})

export const { setDarkMode } = checkThemeSlice.actions
export default checkThemeSlice.reducer

export const dataSelector = (state: RootState) => state.checkTheme

export const themeSelector = createSelector(dataSelector, state => state.isDarkMode)
