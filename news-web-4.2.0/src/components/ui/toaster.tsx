"use client";

import {
  useSyncExternalStore,
  useState,
  useEffect,
  useCallback,
  useRef,
} from "react";
import { createPortal } from "react-dom";
import {
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Info,
  Loader2,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { toastStore, type ToastItem, type ToastType } from "@/lib/toast-store";

export type ToastPosition =
  | "top-left"
  | "top-center"
  | "top-right"
  | "bottom-left"
  | "bottom-center"
  | "bottom-right";

export interface ToasterProps {
  position?: ToastPosition;
  maxToasts?: number;
}

// ─── Icons ───────────────────────────────────────────────────────────────────

const ICONS: Record<ToastType, React.ReactNode> = {
  success: <CheckCircle2 className="size-[18px] shrink-0 successColor" />,
  error: <XCircle className="size-[18px] shrink-0 errorColor" />,
  warning: <AlertTriangle className="size-[18px] shrink-0 warningColor" />,
  info: <Info className="size-[18px] shrink-0 text-blue-500" />,
  loading: (
    <Loader2 className="size-[18px] shrink-0 text-gray-400 animate-spin" />
  ),
  default: null,
};

// ─── Styles per type ─────────────────────────────────────────────────────────

const ACCENT: Record<ToastType, string> = {
  success: "border-l-emerald-500 before:bg-emerald-500",
  error: "border-l-red-500 before:bg-red-500",
  warning: "border-l-amber-500 before:bg-amber-500",
  info: "border-l-blue-500 before:bg-blue-500",
  loading: "border-l-gray-300 before:bg-gray-300",
  default: "border-l-gray-300 before:bg-gray-300",
};

const PROGRESS_COLOR: Record<ToastType, string> = {
  success: "bg-emerald-500",
  error: "bg-red-500",
  warning: "bg-amber-500",
  info: "bg-blue-500",
  loading: "bg-gray-400",
  default: "bg-gray-400",
};

// ─── Container position ───────────────────────────────────────────────────────

const CONTAINER_CLASS: Record<ToastPosition, string> = {
  "top-left": "top-4 left-4 items-start",
  "top-center": "top-4 left-1/2 -translate-x-1/2 items-center",
  "top-right": "top-4 right-4 items-end",
  "bottom-left": "bottom-4 left-4 items-start",
  "bottom-center": "bottom-4 left-1/2 -translate-x-1/2 items-center",
  "bottom-right": "bottom-4 right-4 items-end",
};

// ─── Progress bar ─────────────────────────────────────────────────────────────

function ProgressBar({
  duration,
  type,
  paused,
  getElapsed,
}: {
  duration: number;
  type: ToastType;
  paused: boolean;
  getElapsed: () => number;
}) {
  const [barStyle, setBarStyle] = useState<React.CSSProperties>({
    width: "100%",
    transitionProperty: "none",
  });

  // Initial: start full → animate to 0 over full duration
  useEffect(() => {
    const r1 = requestAnimationFrame(() => {
      const r2 = requestAnimationFrame(() => {
        setBarStyle({
          width: "0%",
          transitionProperty: "width",
          transitionTimingFunction: "linear",
          transitionDuration: `${duration}ms`,
        });
      });
      return () => cancelAnimationFrame(r2);
    });
    return () => cancelAnimationFrame(r1);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Pause / resume: recalculate from current elapsed
  useEffect(() => {
    const elapsed = getElapsed();
    const currentPct = Math.max(0, 100 - (elapsed / duration) * 100);

    if (paused) {
      // Freeze at current position, no transition
      setBarStyle({ width: `${currentPct}%`, transitionProperty: "none" });
    } else {
      const remaining = Math.max(0, duration - elapsed);
      // Snap to current position first, then animate remainder
      setBarStyle({ width: `${currentPct}%`, transitionProperty: "none" });
      const r1 = requestAnimationFrame(() => {
        const r2 = requestAnimationFrame(() => {
          setBarStyle({
            width: "0%",
            transitionProperty: "width",
            transitionTimingFunction: "linear",
            transitionDuration: `${remaining}ms`,
          });
        });
        return () => cancelAnimationFrame(r2);
      });
      return () => cancelAnimationFrame(r1);
    }
  }, [paused]); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="absolute bottom-0 left-0 right-0 h-[3px] rounded-b-xl overflow-hidden bg-black/5">
      <div
        className={cn("h-full rounded-full", PROGRESS_COLOR[type])}
        style={{ ...barStyle, opacity: 0.35 }}
      />
    </div>
  );
}

// ─── Single toast item ────────────────────────────────────────────────────────

interface ToastItemViewProps {
  toast: ToastItem;
  exiting: boolean;
  isBottom: boolean;
  onDismiss: () => void;
  onRemove: () => void;
}

function ToastItemView({
  toast,
  exiting,
  isBottom,
  onDismiss,
  onRemove,
}: ToastItemViewProps) {
  const [visible, setVisible] = useState(false);
  const [hovered, setHovered] = useState(false);
  const handledRef = useRef(false);

  // Timer management — owned here so hover can pause/resume
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const elapsedRef = useRef(0);       // ms elapsed while running
  const startTickRef = useRef(0);     // Date.now() at last resume

  const hasDuration =
    toast.type !== "loading" &&
    typeof toast.duration === "number" &&
    toast.duration > 0;

  const clearTimer = useCallback(() => {
    if (timerRef.current !== null) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
  }, []);

  const startTimer = useCallback(
    (remaining: number) => {
      clearTimer();
      startTickRef.current = Date.now();
      timerRef.current = setTimeout(onDismiss, remaining);
    },
    [clearTimer, onDismiss]
  );

  // Start auto-dismiss on mount
  useEffect(() => {
    if (hasDuration) startTimer(toast.duration!);
    return clearTimer;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Pause when exiting starts (avoid double-dismiss race)
  useEffect(() => {
    if (exiting) clearTimer();
  }, [exiting, clearTimer]);

  // Hover: pause / resume
  const handleMouseEnter = useCallback(() => {
    if (!hasDuration || exiting) return;
    elapsedRef.current += Date.now() - startTickRef.current;
    clearTimer();
    setHovered(true);
  }, [hasDuration, exiting, clearTimer]);

  const handleMouseLeave = useCallback(() => {
    if (!hasDuration || exiting) return;
    const remaining = Math.max(0, toast.duration! - elapsedRef.current);
    if (remaining > 0) startTimer(remaining);
    setHovered(false);
  }, [hasDuration, exiting, toast.duration, startTimer]);

  // getElapsed — stable fn passed to ProgressBar
  const getElapsed = useCallback((): number => {
    if (hovered) return elapsedRef.current;
    return elapsedRef.current + (Date.now() - startTickRef.current);
  }, [hovered]);

  // Enter animation
  useEffect(() => {
    const r1 = requestAnimationFrame(() => {
      const r2 = requestAnimationFrame(() => setVisible(true));
      return () => cancelAnimationFrame(r2);
    });
    return () => cancelAnimationFrame(r1);
  }, []);

  const handleTransitionEnd = useCallback(
    (e: React.TransitionEvent) => {
      if (e.propertyName === "opacity" && exiting && !handledRef.current) {
        handledRef.current = true;
        onRemove();
      }
    },
    [exiting, onRemove]
  );

  const shouldShow = visible && !exiting;
  const translateY = isBottom ? "12px" : "-12px";

  return (
    <div
      role="alert"
      aria-live={toast.type === "error" ? "assertive" : "polite"}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onClick={toast.onClick}
      className={cn(
        "relative w-[360px] max-w-[calc(100vw-2rem)] z-[99999]",
        "flex items-start gap-3 px-4 py-3.5",
        "bg-white rounded-xl shadow-lg shadow-black/8",
        "border border-gray-100 border-l-4",
        "pointer-events-auto select-none",
        toast.onClick ? "cursor-pointer" : "cursor-default",
        "transition-all duration-300 ease-out",
        ACCENT[toast.type],
        hasDuration && "pb-4"
      )}
      style={{
        opacity: shouldShow ? 1 : 0,
        transform: shouldShow ? "translateY(0px)" : `translateY(${translateY})`,
      }}
      onTransitionEnd={handleTransitionEnd}
    >
      {/* Icon or Thumbnail */}
      {toast.image ? (
        <img
          src={toast.image}
          alt=""
          className="shrink-0 w-10 h-10 rounded-md object-cover"
        />
      ) : ICONS[toast.type] ? (
        <span className="mt-0.5 shrink-0">{ICONS[toast.type]}</span>
      ) : null}

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900 leading-snug">
          {toast.message}
        </p>
        {toast.description && (
          <p className="mt-0.5 text-xs text-gray-500 leading-snug">
            {toast.description}
          </p>
        )}
        {toast.action && (
          <button
            onClick={toast.action.onClick}
            className="mt-2 text-xs font-semibold text-gray-900 underline underline-offset-2 hover:no-underline"
          >
            {toast.action.label}
          </button>
        )}
      </div>

      {/* Close */}
      <button
        onClick={onDismiss}
        className="mt-0.5 shrink-0 rounded-md p-0.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
        aria-label="Dismiss"
      >
        <X className="size-3.5" />
      </button>

      {/* Progress bar */}
      {hasDuration && (
        <ProgressBar  
          duration={toast.duration!}
          type={toast.type}
          paused={hovered}
          getElapsed={getElapsed}
        />
      )}
    </div>
  );
}

// ─── Toaster ──────────────────────────────────────────────────────────────────

interface DisplayToast extends ToastItem {
  exiting: boolean;
}

// Stable reference for SSR snapshot — avoids useSyncExternalStore infinite loop
const EMPTY_SNAPSHOT: ToastItem[] = [];

export function Toaster({
  position = "top-center",
  maxToasts = 5,
}: ToasterProps) {
  const storeToasts = useSyncExternalStore(
    toastStore.subscribe,
    toastStore.getSnapshot,
    () => EMPTY_SNAPSHOT
  );

  const [displayToasts, setDisplayToasts] = useState<DisplayToast[]>([]);
  const prevIdsRef = useRef(new Set<string>());
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  useEffect(() => {
    const newIds = new Set(storeToasts.map((t) => t.id));
    // Capture prevIds BEFORE updating the ref — the setState callback runs
    // asynchronously, so the ref would already point to newIds by then.
    const prevIds = prevIdsRef.current;
    prevIdsRef.current = newIds;

    setDisplayToasts((prev) => {
      const updated = prev.map((t) => ({
        ...t,
        exiting: t.exiting || !newIds.has(t.id),
      }));
      const added = storeToasts
        .filter((t) => !prevIds.has(t.id))
        .map((t) => ({ ...t, exiting: false }));

      return [...updated, ...added];
    });
  }, [storeToasts]);

  const handleDismiss = useCallback((id: string) => {
    setDisplayToasts((prev) =>
      prev.map((t) => (t.id === id ? { ...t, exiting: true } : t))
    );
    toastStore.dismiss(id);
  }, []);

  const handleRemove = useCallback((id: string) => {
    setDisplayToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  if (!mounted) return null;

  const isBottom = position.startsWith("bottom");
  const limited = displayToasts.slice(
    isBottom ? Math.max(0, displayToasts.length - maxToasts) : 0,
    isBottom ? undefined : maxToasts
  );
  // Top: newest first (closest to top edge). Bottom: oldest first (newest at bottom = closest to edge)
  const ordered = isBottom ? limited : [...limited].reverse();

  return createPortal(
    <div
      className={cn(
        "fixed z-[99999] flex flex-col gap-2 pointer-events-none",
        CONTAINER_CLASS[position]
      )}
    >
      {ordered.map((t) => (
        <ToastItemView
          key={t.id}
          toast={t}
          exiting={t.exiting}
          isBottom={isBottom}
          onDismiss={() => handleDismiss(t.id)}
          onRemove={() => handleRemove(t.id)}
        />
      ))}
    </div>,
    document.body
  );
}
