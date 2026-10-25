interface CategoryBadgeProps {
    cate?: string | null
    isFloating?: boolean
    whiteBg?: boolean
}

const CategoryBadge = ({ cate, isFloating = false, whiteBg = true }: CategoryBadgeProps) => {
    if (!cate) return null

    return (
        <div className={`${isFloating ? 'absolute top-2 left-2 sm:top-3 sm:left-3 border' : ''} max-sm:text-sm first-letter:capitalize ${whiteBg ? 'bg-white! border border-(--primary-color)/10' : ''} categoryTag dark:bg-white!`}>
            <span className=''>{cate}</span>
        </div>
    )
}

export default CategoryBadge
