"use client";
import React, { useEffect, useState, useRef } from "react";
import ImagePlaceholder from "@/assets/images/placeholder.png";

import { useSelector } from "react-redux";
import { settingsSelector } from "@/redux/reducers/settingsSlice";
import { useDarkTheme } from "@/hooks/useDarkTheme";
import Image from "next/image";
import { canOptimizeImage } from "@/utils/imageConfig";

export interface ImagePreviewProps {
    /** Image source URL */
    src: string | { src: string } | null | undefined;
    /** Alt text for the image */
    alt: string;
    /** Size preset (used when no explicit width/height is applied via className) */
    size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
    /** Aspect ratio for the image container */
    aspectRatio?: 'square' | '4/3' | '16/9' | '3/2' | '2/1' | 'auto';
    /** Border radius variant */
    rounded?: 'none' | 'sm' | 'md' | 'lg' | 'xl' | '2xl' | 'full';
    /** Whether to show a border */
    bordered?: boolean;
    /** Border color variant */
    borderColor?: 'gray' | 'primary' | 'secondary' | 'success' | 'warning' | 'error';
    /** Shadow variant */
    shadow?: 'none' | 'sm' | 'md' | 'lg' | 'xl';
    /** Object fit behavior */
    objectFit?: 'contain' | 'cover' | 'fill' | 'none' | 'scale-down';
    /** Fade-in duration in milliseconds */
    fadeInDuration?: number;
    /** Custom CSS classes for the image */
    className?: string;
    /** Custom CSS classes for the container */
    containerClassName?: string;
    /** Callback when image loads successfully */
    onLoad?: (event: React.SyntheticEvent<HTMLImageElement>) => void;
    /** Callback when image fails to load */
    onError?: (event: React.SyntheticEvent<HTMLImageElement>) => void;
    /** Native loading attribute */
    loading?: 'lazy' | 'eager';
    /** Responsive `sizes` hint for srcset. Defaults to the size preset width, else 100vw */
    sizes?: string;
    /** Preload + high fetch priority (use for above-the-fold / LCP images) */
    preload?: boolean;
    /** Intrinsic width in px (defaults to size preset, else 0 = responsive) */
    width?: number;
    /** Intrinsic height in px (defaults to size preset, else 0 = responsive) */
    height?: number;
    /** Optimizer quality 1-100 */
    quality?: number;
}


// Size preset classes
const sizeClasses = {
    xs: "w-8 h-8",
    sm: "w-16 h-16",
    md: "w-24 h-24",
    lg: "w-32 h-32",
    xl: "w-48 h-48",
    "2xl": "w-64 h-64",
};

// Rendered px width per size preset — drives the default `sizes` hint
const sizePixels = {
    xs: 32,
    sm: 64,
    md: 96,
    lg: 128,
    xl: 192,
    "2xl": 256,
};

// Aspect ratio classes
const aspectRatioClasses = {
    square: "aspect-square",
    "4/3": "aspect-[4/3]",
    "16/9": "aspect-video",
    "3/2": "aspect-[3/2]",
    "2/1": "aspect-[2/1]",
    auto: "",
};

// Rounded classes
const roundedClasses = {
    none: "",
    sm: "rounded-sm",
    md: "rounded-md",
    lg: "rounded-lg",
    xl: "rounded-xl",
    '2xl': "rounded-2xl",
    full: "rounded-full",
};

// Border color classes
const borderColorClasses = {
    gray: "border-gray-300",
    primary: "border-primary-300",
    secondary: "border-gray-400",
    success: "border-green-300",
    warning: "border-yellow-300",
    error: "border-red-300",
};

// Shadow classes
const shadowClasses = {
    none: "",
    sm: "shadow-sm",
    md: "shadow-md",
    lg: "shadow-lg",
    xl: "shadow-xl",
};

// Object fit classes
const objectFitClasses = {
    contain: "object-contain",
    cover: "object-cover",
    fill: "object-fill",
    none: "object-none",
    "scale-down": "object-scale-down",
};

const ImagePreview: React.FC<ImagePreviewProps> = ({
    src,
    alt = "",
    size,
    aspectRatio = "auto",
    rounded = "none",
    bordered = false,
    borderColor = "gray",
    shadow = "none",
    objectFit = "cover",
    fadeInDuration = 300,
    className = "",
    containerClassName = "",
    onLoad,
    onError,
    loading = "lazy",
    sizes,
    preload = false,
    width,
    height,
    quality,
}) => {

    const settingsData = useSelector(settingsSelector);
    const { isDarkMode } = useDarkTheme();
    const placeholderSrc: string = isDarkMode ? settingsData?.web_setting?.dark_placeholder_image : settingsData?.web_setting?.light_placeholder_image || ImagePlaceholder.src;

    // Extract the actual source URL
    const actualSrc: string | null =
        typeof src === "object" && src?.src
            ? src.src
            : typeof src === "string"
                ? src
                : null;

    // Start from the real src (a prop, so identical on server and client) so the
    // server HTML already points at the actual image and the browser can fetch it
    // before hydration — starting from the placeholder delayed LCP by seconds.
    const [imageSrc, setImageSrc] = useState<string>(actualSrc ?? ImagePlaceholder.src);
    const [isLoaded, setIsLoaded] = useState<boolean>(true);
    const [isLoading, setIsLoading] = useState<boolean>(false);
    const imgRef = useRef<HTMLImageElement>(null);

    // Keyed on actualSrc only: a theme switch changes placeholderSrc without
    // changing actualSrc, and resetting isLoading here would get stuck forever
    // since the <img>'s src wouldn't actually change and onLoad would never re-fire.
    useEffect(() => {
        if (!actualSrc) {
            setImageSrc(placeholderSrc);
            setIsLoaded(true);
            setIsLoading(false);
            return;
        }

        // Already rendering this src (initial mount) — nothing to reload
        if (imageSrc === actualSrc) return;

        setIsLoading(true);
        setIsLoaded(false);
        setImageSrc(actualSrc);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [actualSrc]);

    // Keep the placeholder itself fresh across theme switches when there's no
    // real image src to show (placeholder isn't a "loading" state, so no
    // need to touch isLoading/isLoaded here).
    useEffect(() => {
        if (!actualSrc) {
            setImageSrc(placeholderSrc);
        }
    }, [placeholderSrc, actualSrc]);

    // If browser already cached the image, onLoad never fires — check .complete after mount
    useEffect(() => {
        if (imgRef.current?.complete && actualSrc) {
            setIsLoaded(true);
            setIsLoading(false);
        }
    }, [actualSrc]);

    // Handle successful image load
    const handleLoad = (event: React.SyntheticEvent<HTMLImageElement>): void => {
        setIsLoaded(true);
        setIsLoading(false);
        onLoad?.(event);
    };

    // Handle image error — fall back to placeholder
    const handleError = (
        event: React.SyntheticEvent<HTMLImageElement>
    ): void => {
        setIsLoading(false);
        setIsLoaded(true);
        setImageSrc(placeholderSrc);
        onError?.(event);
    };

    // Build image class string
    const imageClasses = [
        "w-full h-full",
        objectFitClasses[objectFit],
        roundedClasses[rounded],
        bordered ? `border ${borderColorClasses[borderColor]}` : "",
        shadowClasses[shadow],
        className,
    ]
        .filter(Boolean)
        .join(" ");

    // Container class string — size preset overrides full-stretch when provided
    const containerClasses = [
        "relative flexCenter",
        size ? sizeClasses[size] : "w-full h-full",
        aspectRatioClasses[aspectRatio],
        containerClassName,
    ]
        .filter(Boolean)
        .join(" ");

    const displaySrc = imageSrc || placeholderSrc;
    const resolvedSizes = sizes ?? (size ? `${sizePixels[size]}px` : "100vw");

    return (
        <div className={containerClasses}>
            {/* Loading pulse overlay */}
            {isLoading && (
                <div className="absolute inset-0 flex items-center justify-center bg-gray-100 bg-opacity-80 z-10 rounded-inherit">
                    <img
                        src={placeholderSrc}
                        alt="loading"
                        className="w-full h-full object-contain animate-pulse"
                    />
                </div>
            )}

            {/* Main image */}
            {/* Normal flow (not `fill`) so callers' sizing classes keep working; width/height 0 + `sizes` gives a responsive srcset */}
            <Image
                ref={imgRef}
                src={displaySrc}
                alt={alt}
                width={width ?? (size ? sizePixels[size] : 0)}
                height={height ?? (size ? sizePixels[size] : 0)}
                sizes={resolvedSizes}
                quality={quality}
                unoptimized={!canOptimizeImage(displaySrc)}
                preload={preload}
                fetchPriority={preload ? "high" : undefined}
                className={imageClasses}
                style={{
                    opacity: isLoaded ? 1 : 0,
                    transition: `opacity ${fadeInDuration}ms ease-in-out`,
                }}
                loading={preload ? undefined : loading}
                onLoad={handleLoad}
                onError={handleError}
            />
        </div>
    );
};

export default ImagePreview;
