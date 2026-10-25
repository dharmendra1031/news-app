import "@/styles/globals.css";
import "nprogress/nprogress.css";
import "@/styles/nprogress.css";
import { useEffect } from "react";
import Router from "next/router";
import NextApp from "next/app";
import type { AppContext, AppProps } from "next/app";
import { QueryClient, dehydrate, DehydratedState } from "@tanstack/react-query";
import NProgress from "nprogress";
import { Toaster } from "@/components/ui/toaster";
import { Providers } from "@/providers";
import { StoreProvider } from "@/redux/store/StoreProvider";
import { primaryFont } from "@/lib/fonts";
import { getCachedSettings } from "@/lib/settingsCache";
import { isStaticExport } from "@/lib/staticExport";
import PushNotificationLayout from "@/components/firebase/PushNotification";

NProgress.configure({ showSpinner: false });

Router.events.on("routeChangeStart", () => NProgress.start());
Router.events.on("routeChangeComplete", () => NProgress.done());
Router.events.on("routeChangeError", () => NProgress.done());

interface AppOwnProps {
  settingsDehydratedState?: DehydratedState;
}

const mergeDehydratedState = (
  a?: DehydratedState,
  b?: DehydratedState
): DehydratedState | undefined => {
  if (!a && !b) return undefined;
  return {
    queries: [...(a?.queries ?? []), ...(b?.queries ?? [])],
    mutations: [...(a?.mutations ?? []), ...(b?.mutations ?? [])],
  };
};

export default function App({ Component, pageProps, settingsDehydratedState }: AppProps & AppOwnProps) {
  const dehydratedState = mergeDehydratedState(pageProps.dehydratedState, settingsDehydratedState);

  useEffect(() => {
    if (process.env.NEXT_PUBLIC_PWA_ENABLED !== 'true') return;
    if (typeof window === 'undefined' || !('serviceWorker' in navigator)) return;

    const registerSw = () => {
      navigator.serviceWorker.register('/sw.js').catch((error) => {
        console.error('SW registration failed:', error);
      });
    };
    
    if (document.readyState === 'complete') {
      registerSw();
      return;
    }
    window.addEventListener('load', registerSw);
    return () => window.removeEventListener('load', registerSw);
  }, []);

  return (
    <StoreProvider>
      <Toaster position="top-right" />
      <Providers dehydratedState={dehydratedState}>
        <main className={`${primaryFont.variable} ${primaryFont.className}`}>
          <PushNotificationLayout>
            <Component {...pageProps} />
          </PushNotificationLayout>
        </main>
      </Providers>
    </StoreProvider>
  );
}

App.getInitialProps = async (appContext: AppContext) => {
  const appProps = await NextApp.getInitialProps(appContext);

  if (isStaticExport) return appProps;

  const queryClient = new QueryClient();
  await queryClient.prefetchQuery({
    queryKey: ["settings"],
    queryFn: getCachedSettings,
  });

  return {
    ...appProps,
    settingsDehydratedState: dehydrate(queryClient),
  };
};
