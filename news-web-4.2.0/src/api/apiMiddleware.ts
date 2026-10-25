import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios';
import { logoutSuccess } from '@/redux/reducers/userSlice';
import { getStore } from '@/redux/store';
import { getQueryClient } from '@/lib/queryClient';

const api = axios.create({
  baseURL: `${process.env.NEXT_PUBLIC_API_URL}/${process.env.NEXT_PUBLIC_END_POINT}/`,
});

const getStoredToken = (): string | null => {
  try {
    const state = getStore().getState();
    return state?.user?.token || null;
  } catch (error) {
    console.warn('Store not initialized yet:', error);
    return null;
  }
};

api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getStoredToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    if (!(config.data instanceof FormData)) {
      config.headers['Content-Type'] = 'application/json';
    } else {
      delete config.headers['Content-Type'];
    }
    return config;
  },
  (error: AxiosError) => {
    console.error('Error in request interceptor:', error);
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    const status = error.response?.status;

    if (status === 401) {
      console.warn("401 Unauthorized - Logging out user...");
      getStore().dispatch(logoutSuccess());
      getQueryClient().removeQueries({ queryKey: ['userDetails'] });
      return Promise.reject(error);
    }

    // For 4xx validation/business errors the API returns a structured body
    // { error: true, message: "...", data: ..., code: ... }
    // Resolve so callers receive the body normally and check response.error.
    // This prevents console.error in every catch block from triggering the
    // Next.js dev overlay on expected errors.
    if (status && status >= 400 && status < 500 && error.response?.data) {
      return Promise.resolve(error.response);
    }

    return Promise.reject(error);
  }
);

export default api;
