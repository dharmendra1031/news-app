import { cn } from "cn"

type SkeletonProps = React.ComponentProps<"div"> & {
  circle?: boolean
  width?: number | string
  height?: number | string
  borderRadius?: number | string
}

function Skeleton({
  className,
  circle,
  width,
  height,
  borderRadius,
  style,
  ...props
}: SkeletonProps) {
  return (
    <div
      data-slot="skeleton"
      className={cn("animate-pulse rounded-md bg-gray-300 dark:bg-gray-600", circle && "rounded-full", className)}
      style={{
        width,
        height,
        borderRadius: circle ? "50%" : borderRadius,
        ...style,
      }}
      {...props}
    />
  )
}

export { Skeleton }
