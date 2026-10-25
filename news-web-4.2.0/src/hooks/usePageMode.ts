import { useGetSettings, SettingsData } from '@/hooks/queries/general/useGetSettings'

export type ModeKey = {
    [K in keyof SettingsData]: K extends `${string}_mode` ? K : never
}[keyof SettingsData]

/**
 * Whether a `*_mode` settings flag (e.g. `podcast_mode`, `live_streaming_mode`) is enabled.
 * Reads react-query's `settings` cache (hydrated from SSR) rather than the Redux
 * mirror, which is only populated by a client-side effect and is empty during SSR —
 * gating on it there made sections like PodcastSect miss the server-rendered HTML.
 *
 * Returns `undefined` while settings are still loading (e.g. right after a hard
 * reload with no SSR data) so callers can tell "not known yet" apart from
 * "disabled" — redirecting on the former bounced every guarded page home on reload.
 */
export const usePageMode = (mode: ModeKey): boolean | undefined => {
    const { data, isError } = useGetSettings()
    if (!data?.data) return isError ? false : undefined
    return data.data[mode] === '1'
}
