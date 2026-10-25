import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { UserDataType, userDetailsType, UserSliceType } from '@/types/GlobalTypes'

const initialState: UserSliceType = {
    token: '',
    user: {} as userDetailsType,
    isLogin: false,
    isNewsUser: false,
    firebaseToken: '',
}

export const userSlice = createSlice({
    name: 'user',
    initialState,
    reducers: {
        setToken: (state, action: PayloadAction<string>) => {
            state.token = action.payload;
        },
        setUserData: (state, action: PayloadAction<userDetailsType>) => {
            state.user = action.payload
            if (action.payload) {
                state.isLogin = true
            }
        },
        // Stashes the username typed during signup so it's available as a
        // displayName fallback once the (not-yet-logged-in) user verifies
        // their email and completes login — Firebase doesn't set displayName
        // for email/password accounts the way it does for Google sign-in.
        setUserName: (state, action: PayloadAction<string>) => {
            state.user = { ...state.user, name: action.payload }
        },
        setIsNewUser: (state, action: PayloadAction<boolean>) => {
            state.isNewsUser = action.payload
        },
        logoutSuccess: () => {
            return initialState;
        },
        setFirebaseToken: (state, action: PayloadAction<string>) => {
            state.firebaseToken = action.payload;
        },
    }
})

export const { setToken, setUserData, setUserName, setIsNewUser, setFirebaseToken, logoutSuccess } = userSlice.actions

export default userSlice.reducer

export const dataSelector = (state: RootState) => state?.user

export const userDataSelector = createSelector(dataSelector, state => state.user)
export const isLoginSelector = createSelector(dataSelector, state => state.isLogin)
export const firebaseTokenSelector = createSelector(dataSelector, state => state.firebaseToken)
export const tokenSelector = createSelector(dataSelector, state => state.token)

export const isNewUserSelector = createSelector(dataSelector, state => state.isNewsUser)
