'use client'
import { useState } from 'react'
import { XIcon } from 'lucide-react'
import { Dialog, DialogClose, DialogContent, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { useCommentActions } from '@/hooks/useCommentActions'
import { useTranslation } from '@/hooks/useTranslation'

interface ReportModalProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    commentId: number
    newsId: number
    onReported?: () => void
}

const ReportModal = ({ open, onOpenChange, commentId, newsId, onReported }: ReportModalProps) => {
    const { t } = useTranslation()
    const { reportComment } = useCommentActions()
    const [message, setMessage] = useState('')
    const [submitting, setSubmitting] = useState(false)

    const handleSubmit = async () => {
        if (!message.trim() || submitting) return

        setSubmitting(true)
        const success = await reportComment(commentId, newsId, message)
        setSubmitting(false)

        if (success) {
            setMessage('')
            onOpenChange(false)
            onReported?.()
        }
    }

    return (
        <Dialog
            open={open}
            onOpenChange={(nextOpen) => {
                if (!nextOpen) setMessage('')
                onOpenChange(nextOpen)
            }}
        >
            <DialogContent showCloseButton={false} className="p-0 gap-0 sm:max-w-md">
                <div className="flex items-center justify-between p-4 border-b borderColor">
                    <DialogTitle className="text-lg font-semibold">{`${t('reportTxt')} ${t('comment')}`}</DialogTitle>
                    <DialogClose
                        className="bg-gray-100 dark:bg-gray-800 rounded-lg p-1.5 cursor-pointer"
                        aria-label="Close"
                    >
                        <XIcon size={18} />
                    </DialogClose>
                </div>

                <div className="p-4">
                    <textarea
                        value={message}
                        onChange={(e) => setMessage(e.target.value)}
                        placeholder="Add comment here......"
                        rows={6}
                        autoFocus
                        className="w-full resize-none rounded-lg commonBg textPrimary text-sm p-3 outline-none"
                    />
                </div>

                <div className="flex justify-end p-4 pt-0">
                    <Button onClick={handleSubmit} disabled={submitting} className="commonBtn bg-black!">
                        {t('submitBtn')}
                    </Button>
                </div>
            </DialogContent>
        </Dialog>
    )
}

export default ReportModal
