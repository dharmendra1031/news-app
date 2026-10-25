import { Slider as SliderPrimitive } from "@base-ui/react/slider"
import { cn } from "cn"

type SliderProps = SliderPrimitive.Root.Props & {
  className?: string
  trackClassName?: string
  thumbClassName?: string
}

function Slider({ className, trackClassName, thumbClassName, ...props }: SliderProps) {
  return (
    <SliderPrimitive.Root data-slot="slider" {...props}>
      <SliderPrimitive.Control
        className={cn("flex w-full touch-none items-center py-2 select-none", className)}
      >
        <SliderPrimitive.Track
          className={cn("relative h-2 w-full rounded-full commonBg select-none", trackClassName)}
        >
          <SliderPrimitive.Indicator className="rounded-full primaryBg select-none" />
          <SliderPrimitive.Thumb
            className={cn(
              "size-4 rounded-full border-2 border-white primaryBg shadow-sm select-none focus-visible:outline-2 focus-visible:outline-offset-2",
              thumbClassName
            )}
          />
        </SliderPrimitive.Track>
      </SliderPrimitive.Control>
    </SliderPrimitive.Root>
  )
}

export { Slider }
