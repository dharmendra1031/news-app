import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit';
import { RootState } from '../store';
import { SettingsData } from '@/hooks/queries/general/useGetSettings';

export const initialState = {
    data: {} as SettingsData,
    lat: null as number | null,
    long: null as number | null,
    systemTimezone: '',
    lastFetch: null as number | null,
}

export const settingsSlice = createSlice({
    name: 'settings',
    initialState,
    reducers: {
        setSettings: (state, action: PayloadAction<SettingsData>) => {
            state.data = action.payload
        },
        setLocation: (state, action: PayloadAction<{ lat: number | null; long: number | null }>) => {
            state.lat = action.payload.lat
            state.long = action.payload.long
        },
        setSystemTimezone: (state, action: PayloadAction<string>) => {
            state.systemTimezone = action.payload
        },
        setSettingsLastFetch: (state, action: PayloadAction<number | null>) => {
            state.lastFetch = action.payload
        },
    },
});

export const { setSettings, setLocation, setSystemTimezone, setSettingsLastFetch } = settingsSlice.actions;
export default settingsSlice.reducer;

export const dataSelector = (state: RootState) => state.settings

export const settingsSelector = createSelector(dataSelector, state => state.data)
export const defaultLanguageSelector = createSelector(dataSelector, state => state.data?.default_language)
export const webSettingSelector = createSelector(dataSelector, state => state.data?.web_setting)
export const socialMediaSelector = createSelector(dataSelector, state => state.data?.social_media)
export const maintenanceModeSelector = createSelector(dataSelector, state => state.data?.maintenance_mode)
export const locationSelector = createSelector(dataSelector, state => ({ lat: state.lat, long: state.long }))
export const systemTimezoneSelector = createSelector(dataSelector, state => state.systemTimezone)
export const settingsLastFetchSelector = createSelector(dataSelector, state => state.lastFetch)
