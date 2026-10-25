import type { ReactNode } from "react";
import { toastStore, type ToastOptions } from "./toast-store";

type ToastMessage = string | ReactNode;

const toast = Object.assign(
  (message: ToastMessage, options?: ToastOptions) =>
    toastStore.add("default", message, options),
  {
    success: (message: ToastMessage, options?: ToastOptions) =>
      toastStore.add("success", message, options),

    error: (message: ToastMessage, options?: ToastOptions) =>
      toastStore.add("error", message, options),

    warning: (message: ToastMessage, options?: ToastOptions) =>
      toastStore.add("warning", message, options),

    info: (message: ToastMessage, options?: ToastOptions) =>
      toastStore.add("info", message, options),

    loading: (message: ToastMessage, options?: ToastOptions) =>
      toastStore.add("loading", message, options),

    promise: <T>(
      promise: Promise<T>,
      options: {
        loading: ToastMessage;
        success: ToastMessage | ((data: T) => ToastMessage);
        error: ToastMessage | ((err: unknown) => ToastMessage);
      } & ToastOptions
    ): string => {
      const { loading, success, error, ...rest } = options;
      const id = toastStore.add("loading", loading, { ...rest, duration: 0 });

      promise
        .then((data) => {
          toastStore.dismiss(id);
          const msg = typeof success === "function" ? success(data) : success;
          toastStore.add("success", msg, rest);
        })
        .catch((err) => {
          toastStore.dismiss(id);
          const msg = typeof error === "function" ? error(err) : error;
          toastStore.add("error", msg, rest);
        });

      return id;
    },

    dismiss: (id?: string | number) => toastStore.dismiss(id),
  }
);

export { toast };
