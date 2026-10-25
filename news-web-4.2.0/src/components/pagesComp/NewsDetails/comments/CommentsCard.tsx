'use client'
import { useState } from 'react'
import { useSelector } from 'react-redux'
import ImagePreview from '@/components/common/ImagePreview'
import { Button } from '@/components/ui/button'
import { FiFlag, FiMessageSquare, FiTrash2 } from 'react-icons/fi'
import { BiDislike, BiLike, BiSolidDislike, BiSolidLike } from 'react-icons/bi'
import { userDataSelector } from '@/redux/reducers/userSlice'
import { useTranslation } from '@/hooks/useTranslation'
import { useCommentActions } from '@/hooks/useCommentActions'
import { formatTimeAgo } from '@/components/utils/helpers'
import { CommentApi } from '@/hooks/queries/useGetComments'
import ReportModal from './ReportModal'
import defaultUserImg from '@/assets/images/user.svg'

interface CommentsCardProps {
    comment: CommentApi
    newsId: number
    languageCode: string
    onChanged: () => void
    isReply?: boolean
}

const CommentsCard = ({ comment, newsId, languageCode, onChanged, isReply = false }: CommentsCardProps) => {
    const { t } = useTranslation()
    const userData = useSelector(userDataSelector)
    const { likeComment, dislikeComment, postComment, deleteComment, requireLogin } = useCommentActions()

    const [replyOpen, setReplyOpen] = useState(false)
    const [replyValue, setReplyValue] = useState('')
    const [reportOpen, setReportOpen] = useState(false)
    const [submitting, setSubmitting] = useState(false)

    const isOwnComment = !!userData?.id && userData?.id === comment?.user_id

    const handleLike = async () => {
        if (!requireLogin()) return
        const success = await likeComment(comment?.id, comment?.like !== 1, languageCode)
        if (success) onChanged()
    }

    const handleDislike = async () => {
        if (!requireLogin()) return
        const success = await dislikeComment(comment?.id, comment?.dislike !== 1, languageCode)
        if (success) onChanged()
    }

    const handleReplyClick = () => {
        if (!requireLogin()) return
        setReportOpen(false)
        setReplyOpen((prev) => !prev)
    }

    const handleCancelReply = () => {
        setReplyOpen(false)
        setReplyValue('')
    }

    const handlePostReply = async () => {
        if (!replyValue.trim() || submitting) return
        setSubmitting(true)
        const success = await postComment(newsId, replyValue, languageCode, comment?.id)
        setSubmitting(false)
        if (success) {
            setReplyValue('')
            setReplyOpen(false)
            onChanged()
        }
    }

    const handleReportClick = () => {
        if (!requireLogin()) return
        setReportOpen(true)
    }

    const handleDelete = async () => {
        if (!requireLogin()) return
        const success = await deleteComment(comment?.id)
        if (success) onChanged()
    }

    return (
        <div className={`border borderColor rounded-xl p-3 md:p-4 ${isReply ? 'ml-6 md:ml-10' : ''}`}>
            <div className="flex items-start justify-between border-b pb-2 borderColor">
                <div className="flex items-center gap-2">
                    <div className="h-8 w-8 md:h-10 md:w-10">
                        <ImagePreview
                            src={comment?.user?.profile || defaultUserImg}
                            alt={comment?.user?.name || 'userName'}
                            className="rounded-full object-cover"
                        />
                    </div>
                    <div>
                        <p className="textPrimary font-semibold md:text-lg">{comment?.user?.name}</p>
                        <p className="textPrimary text-sm">{formatTimeAgo(comment?.created_at)}</p>
                    </div>
                </div>
                {isOwnComment ? (
                    <button
                        type="button"
                        onClick={handleDelete}
                        className="textPrimary hover:primaryColor cursor-pointer"
                        aria-label="Delete comment"
                    >
                        <FiTrash2 size={16} />
                    </button>
                ) : (
                    <button
                        type="button"
                        onClick={handleReportClick}
                        className="textPrimary hover:primaryColor cursor-pointer"
                        aria-label="Report comment"
                    >
                        <FiFlag size={16} />
                    </button>
                )}
            </div>

            <p className="textPrimary text-sm mt-2 leading-relaxed">{comment?.message}</p>

            <div className="flex items-center gap-4 mt-3">
                <button
                    type="button"
                    onClick={handleLike}
                    className="hover:primaryColor cursor-pointer flex items-center gap-1 text-sm textPrimary"
                    aria-label="Like comment"
                >
                    {comment?.like === 1 ? <BiSolidLike size={16} /> : <BiLike size={16} />}
                    {comment?.total_like > 0 ? comment?.total_like : null}
                </button>
                <button
                    type="button"
                    onClick={handleDislike}
                    className="hover:primaryColor cursor-pointer flex items-center gap-1 text-sm textPrimary"
                    aria-label="Dislike comment"
                >
                    {comment?.dislike === 1 ? <BiSolidDislike size={16} /> : <BiDislike size={16} />}
                    {comment?.total_dislike > 0 ? comment?.total_dislike : null}
                </button>
                {!isReply && (
                    <button
                        type="button"
                        onClick={handleReplyClick}
                        className="textPrimary hover:primaryColor cursor-pointer flex items-center gap-1 text-sm"
                    >
                        <FiMessageSquare size={16} />
                        {t('reply')}
                    </button>
                )}
            </div>

            {replyOpen && (
                <div className="mt-3">
                    <textarea
                        value={replyValue}
                        onChange={(e) => setReplyValue(e.target.value)}
                        placeholder={t('addreplyhere')}
                        rows={4}
                        autoFocus
                        className="w-full resize-none rounded-lg commonBg textPrimary text-sm p-3 outline-none"
                    />
                    <div className="flex items-center justify-end gap-2 mt-2">
                        <Button variant="outline" onClick={handleCancelReply} disabled={submitting}>
                            {t('cancelBtn')}
                        </Button>
                        <Button onClick={handlePostReply} disabled={submitting}>
                            {t('submitreply')}
                        </Button>
                    </div>
                </div>
            )}

            <ReportModal
                open={reportOpen}
                onOpenChange={setReportOpen}
                commentId={comment?.id}
                newsId={newsId}
            />

            {!!comment?.reply?.length && (
                <div className="flex flex-col gap-3 mt-3">
                    {comment?.reply.map((reply) => (
                        <CommentsCard
                            key={reply.id}
                            comment={reply}
                            newsId={newsId}
                            languageCode={languageCode}
                            onChanged={onChanged}
                            isReply
                        />
                    ))}
                </div>
            )}
        </div>
    )
}

export default CommentsCard
