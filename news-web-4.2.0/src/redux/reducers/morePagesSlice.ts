import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { MorePageApi } from '@/hooks/queries/useGetMorePages'

interface MorePagesState {
    morePages: MorePageApi[]
    limit: number
    offset: number
    totalMorePages: number
    loadMoreMorePages: boolean
}

const initialState: MorePagesState = {
    morePages: [],
    limit: 20,
    offset: 0,
    totalMorePages: 0,
    loadMoreMorePages: false,
}

export const morePagesSlice = createSlice({
    name: 'morePages',
    initialState,
    reducers: {
        setMorePages: (state, action: PayloadAction<MorePageApi[]>) => {
            state.morePages = action.payload
        },
        appendMorePages: (state, action: PayloadAction<MorePageApi[]>) => {
            state.morePages = [...state.morePages, ...action.payload]
        },
        setMorePagesOffset: (state, action: PayloadAction<number>) => {
            state.offset = action.payload
        },
        setLoadMoreMorePages: (state, action: PayloadAction<boolean>) => {
            state.loadMoreMorePages = action.payload
        },
        setTotalMorePages: (state, action: PayloadAction<number>) => {
            state.totalMorePages = action.payload
        },
        resetMorePages: () => initialState,
    },
})

export const {
    setMorePages,
    appendMorePages,
    setMorePagesOffset,
    setLoadMoreMorePages,
    setTotalMorePages,
    resetMorePages,
} = morePagesSlice.actions
export default morePagesSlice.reducer

export const dataSelector = (state: RootState) => state.morePages

export const morePagesSelector = createSelector(dataSelector, state => state.morePages)
export const morePagesLimitSelector = createSelector(dataSelector, state => state.limit)
export const morePagesOffsetSelector = createSelector(dataSelector, state => state.offset)
export const totalMorePagesSelector = createSelector(dataSelector, state => state.totalMorePages)
export const isLoadMoreMorePagesSelector = createSelector(dataSelector, state => state.loadMoreMorePages)
