'use client'

const FormLoader = () => {
    return (
        <div className="flex gap-1 py-2.5">
            <span className="w-2 h-2 bg-white rounded-full animate-bounce"></span>
            <span className="w-2 h-2 bg-white rounded-full animate-bounce [animation-delay:0.1s]"></span>
            <span className="w-2 h-2 bg-white rounded-full animate-bounce [animation-delay:0.3s]"></span>
            <span className="w-2 h-2 bg-white rounded-full animate-bounce [animation-delay:0.5s]"></span>
        </div>
    )
}

export default FormLoader
