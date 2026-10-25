interface CarouselDotsProps {
  count: number
  activeIndex: number
  onSelect: (index: number) => void
}

const CarouselDots = ({ count, activeIndex, onSelect }: CarouselDotsProps) => {
  return (
    <div className='flex items-center justify-center gap-3 mt-10'>
      {
        Array.from({ length: count }).map((_, index) => (
          <button
            key={index}
            aria-label={`Go to slide ${index + 1}`}
            onClick={() => onSelect(index)}
            className={`w-4 h-4 sm:w-5 sm:h-5 rounded-full border-2 flexCenter transition-all duration-300 ${index === activeIndex ? 'border-(--primary-color)' : 'borderColor'}`}
          >
            <span className={`w-1.5 h-1.5 sm:w-2.5 sm:h-2.5 rounded-full transition-all duration-300 ${index === activeIndex ? 'primaryBg' : 'bg-(--border-color)'}`} />
          </button>
        ))
      }
    </div>
  )
}

export default CarouselDots
