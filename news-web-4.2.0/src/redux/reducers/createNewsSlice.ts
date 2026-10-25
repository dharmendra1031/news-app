import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { NewsApi } from '@/hooks/queries/useGetNews'

export interface CreateNewsLanguage {
    id: number
    code: string
    name: string
}

interface CreateNewsState {
    currentLanguage: CreateNewsLanguage | null
    createToEdit: NewsApi | null
}

const initialState: CreateNewsState = {
    currentLanguage: null,
    createToEdit: null,
}

export const createNewsSlice = createSlice({
    name: 'createNews',
    initialState,
    reducers: {
        setCreateNewsLanguage: (state, action: PayloadAction<CreateNewsLanguage>) => {
            state.currentLanguage = action.payload
        },
        // Stashed by ManageNews.tsx's Edit button so EditNews.tsx has the
        // article to edit without a second fetch — same flow as news-tailwind's
        // loadManageToEdit/selectManageNews.
        setNewsToEdit: (state, action: PayloadAction<NewsApi | null>) => {
            state.createToEdit = action.payload
        },
        resetCreateNews: () => initialState,
    },
})

export const { setCreateNewsLanguage, setNewsToEdit, resetCreateNews } = createNewsSlice.actions
export default createNewsSlice.reducer

export const dataSelector = (state: RootState) => state.createNews

export const createNewsLanguageSelector = createSelector(dataSelector, (state) => state.currentLanguage)
export const newsToEditSelector = createSelector(dataSelector, (state) => state.createToEdit)
