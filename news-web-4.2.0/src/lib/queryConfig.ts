// src/lib/queryConfig.ts

const CACHE_ENABLED = true
const STALE_TIME = 5 * 60 * 1000;  // 5 minutes
const GC_TIME = 10 * 60 * 1000; // 10 minutes
const RETRY_COUNT = 0
const REFETCH_ON_FOCUS = false
const REFETCH_ON_RECONNECT = true
const REFETCH_ON_MOUNT = false

const cacheEnabled = CACHE_ENABLED;

export interface QueryConfig {
    staleTime: number;
    gcTime: number;
    retry: number;
    refetchOnWindowFocus: boolean;
    refetchOnReconnect: boolean;
    refetchOnMount: boolean;
}

export const queryConfig: QueryConfig = {
    staleTime: cacheEnabled
        ? Number(STALE_TIME ?? 60_000)
        : 0,

    gcTime: cacheEnabled
        ? Number(GC_TIME ?? 300_000)
        : 0,

    retry: Number(RETRY_COUNT ?? 1),

    refetchOnWindowFocus: REFETCH_ON_FOCUS,

    refetchOnReconnect: REFETCH_ON_RECONNECT,

    refetchOnMount: REFETCH_ON_MOUNT,
};

export const isCacheEnabled: boolean = cacheEnabled;
