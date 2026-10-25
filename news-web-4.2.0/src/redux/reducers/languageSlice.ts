import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { DefaultLanguage } from '@/hooks/queries/general/useGetSettings'

export type CurrentLanguage = Partial<DefaultLanguage>

interface CurrentLanguageLabels {
    data: Record<string, string>
    lastFetch: number | null
}

interface LanguagesState {
    list: DefaultLanguage[]
    currentLanguage: CurrentLanguage
    currentLanguageLabels: CurrentLanguageLabels
}

const initialState: LanguagesState = {
    list: [],
    currentLanguage: {},
    currentLanguageLabels: {
        data: {},
        lastFetch: null,
    },
}

export const languagesSlice = createSlice({
    name: 'languages',
    initialState,
    reducers: {
        setLanguagesList: (state, action: PayloadAction<DefaultLanguage[]>) => {
            state.list = action.payload
        },
        languageChange: (state, action: PayloadAction<CurrentLanguage>) => {
            state.currentLanguage = action.payload
        },
        setCurrentLanguageLabels: (state, action: PayloadAction<CurrentLanguageLabels>) => {
            state.currentLanguageLabels = action.payload
        },
    },
})

export const { setLanguagesList, languageChange, setCurrentLanguageLabels } = languagesSlice.actions
export default languagesSlice.reducer

export const dataSelector = (state: RootState) => state.languages

export const languagesListSelector = createSelector(dataSelector, state => state.list)

export const currentLanguageSelector = createSelector(dataSelector, state => state.currentLanguage)

export const currentLanguageLabelsSelector = createSelector(dataSelector, state => state.currentLanguageLabels ?? initialState.currentLanguageLabels)

export const currentTranslationsSelector = createSelector(dataSelector, state => state.currentLanguageLabels?.data ?? {})
