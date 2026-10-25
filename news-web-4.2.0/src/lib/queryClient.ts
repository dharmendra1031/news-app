// src/lib/queryClient.ts
import { QueryClient } from "@tanstack/react-query";
import { queryConfig } from "./queryConfig";

function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        ...queryConfig,
        throwOnError: false,
      },
      mutations: {
        retry: 0,
      },
    },
  });
}

let browserQueryClient: QueryClient | undefined;

// The server must get a fresh QueryClient per request — a module-level
// singleton would be shared (and its cache mutated) across every concurrent
// SSR request, letting one request's response leak another's data into a
// third's rendered HTML. The browser gets one stable instance so client-side
// navigations keep their cache.
export function getQueryClient() {
  if (typeof window === "undefined") {
    return makeQueryClient();
  }
  if (!browserQueryClient) {
    browserQueryClient = makeQueryClient();
  }
  return browserQueryClient;
}
