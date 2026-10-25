'use client'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip'
import { BsExclamationCircle } from 'react-icons/bs'

interface MetaInfoToolTipProps {
    info: string
}

const MetaInfoToolTip = ({ info }: MetaInfoToolTipProps) => {
    return (
        <TooltipProvider>
            <Tooltip>
                <TooltipTrigger className='text-primary inline-flex'>
                    <BsExclamationCircle />
                </TooltipTrigger>
                <TooltipContent>
                    <p>{info}</p>
                </TooltipContent>
            </Tooltip>
        </TooltipProvider>
    )
}

export default MetaInfoToolTip
