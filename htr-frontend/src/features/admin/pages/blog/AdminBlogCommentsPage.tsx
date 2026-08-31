import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Dialog } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

export default function AdminBlogCommentsPage() {
  const qc = useQueryClient()
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null)

  const { data: comments, isLoading } = useQuery({
    queryKey: ['admin-blog-comments'],
    queryFn: adminBlogApi.listComments,
  })

  const deleteComment = useGuardedMutation({
    mutationFn: (id: string) => adminBlogApi.deleteComment(id),
    onSuccess: () => {
      setPendingDeleteId(null)
      qc.invalidateQueries({ queryKey: ['admin-blog-comments'] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Xóa bình luận thất bại'), type: 'error' }),
  })

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-fg">Kiểm duyệt bình luận</h1>

      {isLoading && <p className="mt-6 text-sm text-fg-muted">Đang tải…</p>}

      <ul className="mt-6 space-y-4">
        {comments?.map(comment => (
          <li key={comment.id} className="rounded-2xl border border-border bg-surface p-4">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm font-medium text-fg">
                  <span>{comment.userName}</span> · <span>{comment.postTitle}</span>
                </p>
                <p className="mt-1 text-sm text-fg-muted">{comment.content}</p>
              </div>
              <Button type="button" variant="danger" onClick={() => setPendingDeleteId(comment.id)}>
                Xóa
              </Button>
            </div>
          </li>
        ))}
      </ul>

      <Dialog open={!!pendingDeleteId} onClose={() => setPendingDeleteId(null)} title="Xóa bình luận này?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">Bình luận sẽ bị xóa vĩnh viễn và không thể khôi phục.</p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setPendingDeleteId(null)}>Hủy</Button>
            <Button
              type="button"
              variant="danger"
              onClick={() => pendingDeleteId && deleteComment.mutate(pendingDeleteId)}
              loading={deleteComment.isPending}
            >
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>
    </div>
  )
}
