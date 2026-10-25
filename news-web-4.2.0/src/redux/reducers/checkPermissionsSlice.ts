import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'

interface CheckPermissionsState {
    notificationPermission: string
    locationPermission: string
    notificationPermissionChecked: boolean
    locationPermissionChecked: boolean
    notificationRequest: string
}

const initialState: CheckPermissionsState = {
    notificationPermission: '',
    locationPermission: '',
    notificationPermissionChecked: false,
    locationPermissionChecked: false,
    notificationRequest: '',
}

export const checkPermissionsSlice = createSlice({
    name: 'checkPermissions',
    initialState,
    reducers: {
        setNotificationPermission: (state, action: PayloadAction<string>) => {
            state.notificationPermission = action.payload
        },
        setLocationPermission: (state, action: PayloadAction<string>) => {
            state.locationPermission = action.payload
        },
        setNotificationPermissionChecked: (state, action: PayloadAction<boolean>) => {
            state.notificationPermissionChecked = action.payload
        },
        setLocationPermissionChecked: (state, action: PayloadAction<boolean>) => {
            state.locationPermissionChecked = action.payload
        },
        setNotificationRequest: (state, action: PayloadAction<string>) => {
            state.notificationRequest = action.payload
        },
    },
})

export const {
    setNotificationPermission,
    setLocationPermission,
    setNotificationPermissionChecked,
    setLocationPermissionChecked,
    setNotificationRequest,
} = checkPermissionsSlice.actions
export default checkPermissionsSlice.reducer

export const dataSelector = (state: RootState) => state.checkPermissions

export const notificationPermissionSelector = createSelector(dataSelector, state => state.notificationPermission)
export const locationPermissionSelector = createSelector(dataSelector, state => state.locationPermission)
export const notificationPermissionCheckedSelector = createSelector(dataSelector, state => state.notificationPermissionChecked)
export const locationPermissionCheckedSelector = createSelector(dataSelector, state => state.locationPermissionChecked)
export const notificationRequestSelector = createSelector(dataSelector, state => state.notificationRequest)
