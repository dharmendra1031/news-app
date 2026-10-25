import { useRef } from 'react';
import { persistStore } from 'redux-persist';
import { Provider } from 'react-redux';
import { makeStore, setBrowserStore, AppStore, RootState } from './index';

export function StoreProvider({
  children,
  preloadedState,
}: Readonly<{
  children: React.ReactNode;
  preloadedState?: Partial<RootState>;
}>) {
  const storeRef = useRef<AppStore | null>(null);

  if (!storeRef.current) {
    storeRef.current = makeStore(preloadedState);
    setBrowserStore(storeRef.current);
    persistStore(storeRef.current);
  }

  return (
    <Provider store={storeRef.current}>
      {children}
    </Provider>
  );
}
