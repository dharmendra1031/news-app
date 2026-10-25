'use client'
import { useState } from 'react'
import {
    Sheet,
    SheetContent,
    SheetHeader,
    SheetTitle,
} from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import CommentsCard from './CommentsCard'
import CommentsCardSkeleton from '@/components/skeletons/CommentsCardSkeleton'
import { useGetComments } from '@/hooks/queries/useGetComments'
import { useCommentActions } from '@/hooks/useCommentActions'
import { useTranslation } from '@/hooks/useTranslation'

interface CommnetsSidebarProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    newsId?: number
    languageCode: string
    isCommentEnabled?: number
}

const CommnetsSidebar = ({ open, onOpenChange, newsId, languageCode, isCommentEnabled }: CommnetsSidebarProps) => {
    const { t } = useTranslation()
    const { postComment, requireLogin } = useCommentActions()
    const [value, setValue] = useState('')
    const [submitting, setSubmitting] = useState(false)

    const { data, isLoading, refetch } = useGetComments({
        news_id: newsId ?? 0,
        enabled: open && !!newsId,
    })

    const comments = data?.data?.data ?? []
    const commentsDisabled = isCommentEnabled === 0

    const handlePostComment = async () => {
        if (!value.trim() || !newsId || submitting || commentsDisabled) return
        if (!requireLogin()) return

        setSubmitting(true)
        const success = await postComment(newsId, value, languageCode,)
        setSubmitting(false)

        if (success) {
            setValue('')
            refetch()
        }
    }

    return (
        <Sheet open={open} onOpenChange={onOpenChange}>
            <SheetContent side="right" className="w-full sm:max-w-md md:max-w-162.5! gap-0 p-0">
                <SheetHeader className="border-b borderColor p-4">
                    <SheetTitle>{t('comsLbl')}</SheetTitle>
                </SheetHeader>

                <div className="p-4 flex flex-col gap-6 overflow-y-auto customScrollBar">
                    {commentsDisabled ? (
                        <p className="textSecondary text-sm text-center py-4">{t('comDisable')}</p>
                    ) : (
                        <div className='commonBg p-4 rounded-xl border flexCol gap-6'>
                            <textarea
                                value={value}
                                onChange={(e) => setValue(e.target.value)}
                                placeholder={t('shareThoghtLbl')}
                                rows={4}
                                className="w-full min-h-40 bg-white dark:bodyBgColor resize-none rounded textPrimary text-sm p-3 outline-none"
                            />
                            <Button
                                onClick={handlePostComment}
                                disabled={submitting}
                                className="self-end commonBtn bg-black!"
                            >
                                {t('submitpost')}
                            </Button>
                        </div>
                    )}

                    <div className="flex flex-col gap-3 mt-1">
                        {isLoading && [...Array(3)].map((_, index) => (
                            <CommentsCardSkeleton key={`comment-skeleton-${index}`} />
                        ))}
                        {!isLoading && !comments.length && (
                            <div className='flexCenter'>
                                <p className="textSecondary text-xl text-center py-4">{t('noComments')}</p>
                            </div>
                        )}
                        {comments.map((comment) => (
                            <CommentsCard
                                key={comment.id}
                                comment={comment}
                                newsId={newsId ?? 0}
                                languageCode={languageCode}
                                onChanged={refetch}
                            />
                        ))}
                    </div>
                </div>
            </SheetContent>
        </Sheet>
    )
}

export default CommnetsSidebar
