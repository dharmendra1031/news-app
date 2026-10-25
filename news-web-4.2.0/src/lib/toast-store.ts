import type { ReactNode } from "react";

export type ToastType = "default" | "success" | "error" | "warning" | "info" | "loading";

export interface ToastAction {
  label: string;
  onClick: () => void;
}

export interface ToastOptions {
  description?: ReactNode;
  duration?: number;
  action?: ToastAction;
  onClick?: () => void;
  image?: string;
}

export interface ToastItem extends ToastOptions {
  id: string;
  type: ToastType;
  message: ReactNode;
}

type Listener = () => void;

let toasts: ToastItem[] = [];
const listeners = new Set<Listener>();

function notify() {
  listeners.forEach((l) => l());
}

let counter = 0;
function generateId() {
  return `toast-${++counter}-${Date.now()}`;
}

export const toastStore = {
  subscribe(listener: Listener) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },

  getSnapshot(): ToastItem[] {
    return toasts;
  },

  add(type: ToastType, message: ReactNode, options?: ToastOptions): string {
    const id = generateId();
    const duration = options?.duration ?? (type === "loading" ? 0 : 4000);
    toasts = [...toasts, { id, type, message, ...options, duration }];
    notify();

    return id;
  },

  dismiss(id?: string | number) {
    if (id !== undefined) {
      toasts = toasts.filter((t) => t.id !== String(id));
    } else {
      toasts = [];
    }
    notify();
  },
};
