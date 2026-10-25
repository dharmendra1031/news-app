// src/providers.tsx
import { useState } from "react";
import { DehydratedState, HydrationBoundary, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { getQueryClient } from "@/lib/queryClient";

interface ProvidersProps {
  children: React.ReactNode;
  dehydratedState?: DehydratedState;
}

export function Providers({ children, dehydratedState }: ProvidersProps) {
  const [queryClient] = useState(getQueryClient);

  return (
    <QueryClientProvider client={queryClient}>
      <HydrationBoundary state={dehydratedState}>
        {children}
      </HydrationBoundary>
      {process.env.NODE_ENV === "development" && (
        <ReactQueryDevtools initialIsOpen={false} />
      )}
    </QueryClientProvider>
  );
}
