import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { CategoryApi } from '@/hooks/queries/general/useGetCategories'

interface CategoriesState {
    categories: CategoryApi[]
    limit: number
    offset: number
    totalCategories: number
    loadMoreCategories: boolean
}

const initialState: CategoriesState = {
    categories: [],
    limit: 20,
    offset: 0,
    totalCategories: 0,
    loadMoreCategories: false,
}

export const categoriesSlice = createSlice({
    name: 'categories',
    initialState,
    reducers: {
        setCategories: (state, action: PayloadAction<CategoryApi[]>) => {
            state.categories = action.payload
        },
        appendCategories: (state, action: PayloadAction<CategoryApi[]>) => {
            state.categories = [...state.categories, ...action.payload]
        },
        setCategoryOffset: (state, action: PayloadAction<number>) => {
            state.offset = action.payload
        },
        setLoadMoreCategories: (state, action: PayloadAction<boolean>) => {
            state.loadMoreCategories = action.payload
        },
        setTotalCategories: (state, action: PayloadAction<number>) => {
            state.totalCategories = action.payload
        },
        resetCategories: () => initialState,
    },
})

export const {
    setCategories,
    appendCategories,
    setCategoryOffset,
    setLoadMoreCategories,
    setTotalCategories,
    resetCategories,
} = categoriesSlice.actions
export default categoriesSlice.reducer

export const dataSelector = (state: RootState) => state.categories

export const categoriesSelector = createSelector(dataSelector, state => state.categories)
export const categoryLimitSelector = createSelector(dataSelector, state => state.limit)
export const categoryOffsetSelector = createSelector(dataSelector, state => state.offset)
export const totalCategoriesSelector = createSelector(dataSelector, state => state.totalCategories)
export const isLoadMoreCategoriesSelector = createSelector(dataSelector, state => state.loadMoreCategories)
