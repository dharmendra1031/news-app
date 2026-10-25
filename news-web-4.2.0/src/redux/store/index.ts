import { combineReducers, configureStore } from "@reduxjs/toolkit";
import { persistStore, persistReducer } from "redux-persist";
import storage from "redux-persist/lib/storage";
import userReducer from "../reducers/userSlice";
import settingsReducer from "../reducers/settingsSlice";
import languagesReducer from "../reducers/languageSlice";
import helperReducer from "../reducers/helperSlice";
import createPodcastReducer from "../reducers/createPodcastSlice";
import createNewsReducer from "../reducers/createNewsSlice";
import categoriesReducer from "../reducers/categoriesSlice";
import morePagesReducer from "../reducers/morePagesSlice";
import checkThemeReducer from "../reducers/checkThemeSlice";
import checkPermissionsReducer from "../reducers/checkPermissionsSlice";

const persistConfig = {
  // Bump this suffix whenever a persisted slice's shape changes — redux-persist's
  // default reconciler replaces each slice wholesale on rehydrate rather than
  // deep-merging with initialState, so stale local storage from an older shape
  // leaves new fields undefined instead of falling back to their defaults.
  key: "news-ts-v2",
  storage,
  // Permission flags must reflect the browser's actual current grant on each
  // session rather than a stale cached value, so checkPermissions is excluded.
  blacklist: ["settings", "helper", "checkPermissions"],
};

const rootReducer = combineReducers({
  user: userReducer,
  settings: settingsReducer,
  languages: languagesReducer,
  helper: helperReducer,
  createPodcast: createPodcastReducer,
  createNews: createNewsReducer,
  categories: categoriesReducer,
  morePages: morePagesReducer,
  checkTheme: checkThemeReducer,
  checkPermissions: checkPermissionsReducer,
});

const persistedReducer = persistReducer(persistConfig, rootReducer);

export type RootState = ReturnType<typeof rootReducer>;

export const makeStore = (preloadedState?: Partial<RootState>) =>
  configureStore({
    reducer: persistedReducer,
    // redux-persist's wrapped reducer loses the CombinedState branding that lets
    // RTK infer a deep-partial PreloadedState — cast is safe, unset slices (and
    // the persist-only `_persist` field) still fall back to their own initial
    // state at runtime.
    preloadedState: preloadedState as ReturnType<typeof persistedReducer> | undefined,
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware({
        serializableCheck: {
          ignoredActions: ["persist/PERSIST", "persist/REHYDRATE"],
        },
      }),
  });

export type AppStore = ReturnType<typeof makeStore>;
export type AppDispatch = AppStore["dispatch"];

// Registry so non-React modules (axios interceptors, plain helpers) read/dispatch
// against the SAME store instance StoreProvider mounted for this browser session,
// instead of spinning up a disconnected one.
let browserStore: AppStore | undefined;

export const setBrowserStore = (instance: AppStore) => {
  browserStore = instance;
};

export const getStore = (): AppStore => {
  if (!browserStore) {
    browserStore = makeStore();
  }
  return browserStore;
};
