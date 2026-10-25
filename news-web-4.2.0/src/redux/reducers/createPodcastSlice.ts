import { createSelector, createSlice, PayloadAction } from '@reduxjs/toolkit'
import { RootState } from '../store'
import { PodcastApi } from '@/hooks/queries/podcast/useGetPodcasts'
import { EpisodeApi } from '@/hooks/queries/podcast/useGetEpisodes'

interface CreatePodcastState {
    createdPodcast: PodcastApi | Pick<PodcastApi, 'id' | 'title' | 'slug'> | null
    createdEpisode: EpisodeApi | null
}

const initialState: CreatePodcastState = {
    createdPodcast: null,
    createdEpisode: null,
}

export const createPodcastSlice = createSlice({
    name: 'createPodcast',
    initialState,
    reducers: {
        podcastCreated: (state, action: PayloadAction<CreatePodcastState['createdPodcast']>) => {
            state.createdPodcast = action.payload
        },
        episodeCreated: (state, action: PayloadAction<EpisodeApi>) => {
            state.createdEpisode = action.payload
        },
        resetCreatedPodcast: (state) => {
            state.createdPodcast = null
        },
        resetCreatedEpisode: (state) => {
            state.createdEpisode = null
        },
    },
})

export const { podcastCreated, episodeCreated, resetCreatedPodcast, resetCreatedEpisode } = createPodcastSlice.actions
export default createPodcastSlice.reducer

export const dataSelector = (state: RootState) => state.createPodcast

export const createdPodcastSelector = createSelector(dataSelector, state => state.createdPodcast)

export const createdEpisodeSelector = createSelector(dataSelector, state => state.createdEpisode)
