interface NewsTitleProps {
    title?: string
}

const NewsTitle = ({ title }: NewsTitleProps) => {
    return (
        <h2 className={`max-[399px]:text-lg text-xl font-semibold line-clamp-3 h-22 first-letter:capitalize textPrimary commonTitle`}>
            {title}
        </h2>
    )
}

export default NewsTitle
