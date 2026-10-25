import { Progress as ProgressPrimitive } from "@base-ui/react/progress"
import { cn } from "cn"

type ProgressProps = ProgressPrimitive.Root.Props & {
  className?: string
  indicatorClassName?: string
}

function Progress({ className, indicatorClassName, ...props }: ProgressProps) {
  return (
    <ProgressPrimitive.Root data-slot="progress" {...props}>
      <ProgressPrimitive.Track
        className={cn("relative h-2 w-full overflow-hidden rounded-full bg-black/20", className)}
      >
        <ProgressPrimitive.Indicator
          className={cn("h-full primaryBg transition-[width] duration-500", indicatorClassName)}
        />
      </ProgressPrimitive.Track>
    </ProgressPrimitive.Root>
  )
}

export { Progress }
