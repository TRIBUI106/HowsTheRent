import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { useDocumentMeta } from '@/hooks/useDocumentMeta'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import PublicShell from '@/components/PublicShell'
import { Button } from '@/components/ui/button'

export default function BlogPostPage() {
  const { slug = '' } = useParams<{ slug: string }>()
  const { user } = useAuthStore()
  const qc = useQueryClient()
  const [commentText, setCommentText] = useState('')

  const { data: post } = useQuery({
    queryKey: ['blog-post', slug],
    queryFn: () => blogApi.getBySlug(slug),
    enabled: !!slug,
  })

  const { data: vacancy } = useQuery({
    queryKey: ['blog-post-vacancy', post?.propertyId],
    queryFn: () => blogApi.getVacancy(post!.propertyId),
    enabled: !!post?.propertyId,
  })

  const { data: comments } = useQuery({
    queryKey: ['blog-post-comments', slug],
    queryFn: () => blogApi.listComments(slug),
    enabled: !!slug,
  })

  useDocumentMeta(
    post ? `${post.title} · HowsTheRent` : 'HowsTheRent',
    post ? `${post.propertyName} — ${post.propertyAddress}` : ''
  )

  const addComment = useGuardedMutation({
    mutationFn: (content: string) => blogApi.addComment(slug, content),
    onSuccess: () => {
      setCommentText('')
      qc.invalidateQueries({ queryKey: ['blog-post-comments', slug] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Gửi bình luận thất bại'), type: 'error' }),
  })

  const toggleLike = useGuardedMutation({
    mutationFn: () => (post?.liked ? blogApi.unlike(slug) : blogApi.like(slug)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['blog-post', slug] }),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Không thể cập nhật lượt thích'), type: 'error' }),
  })

  if (!post) {
    return (
      <PublicShell>
        <p className="mx-auto max-w-3xl px-6 py-24 text-sm text-fg-muted">Đang tải…</p>
      </PublicShell>
    )
  }

  return (
    <PublicShell>
      <article className="mx-auto max-w-3xl px-6 py-24">
        {post.coverImageUrl && (
          <img src={post.coverImageUrl} alt="" className="mb-8 h-64 w-full rounded-2xl object-cover" />
        )}
        <h1 className="text-3xl font-semibold tracking-[-0.03em] text-fg">{post.title}</h1>
        <p className="mt-2 text-sm text-fg-muted">{post.propertyName} · {post.propertyAddress}</p>

        {vacancy && (
          <div className="mt-6 inline-flex items-center rounded-full bg-accent-surface px-3 py-1.5 text-sm font-medium text-accent">
            {vacancy.emptyCount}/{vacancy.totalCount} phòng còn trống
          </div>
        )}

        {/* Admin-authored rich-text HTML, not user-submitted — safe to render directly. */}
        <div className="prose mt-8 max-w-none" dangerouslySetInnerHTML={{ __html: post.content }} />

        <div className="mt-10 flex items-center gap-3 border-t border-border pt-6">
          <Button
            type="button"
            variant={post.liked ? 'primary' : 'secondary'}
            onClick={() => toggleLike.mutate(undefined)}
            loading={toggleLike.isPending}
          >
            {post.liked ? '♥ Đã thích' : '♡ Thích'} · {post.likeCount}
          </Button>
        </div>

        <section className="mt-12 border-t border-border pt-8">
          <h2 className="text-lg font-semibold text-fg">Bình luận</h2>

          <ul className="mt-4 space-y-4">
            {comments?.map(comment => (
              <li key={comment.id} className="rounded-xl border border-border bg-surface p-4">
                <p className="text-sm font-medium text-fg">{comment.userName}</p>
                <p className="mt-1 text-sm text-fg-muted">{comment.content}</p>
              </li>
            ))}
          </ul>

          {user ? (
            <form
              className="mt-6 flex flex-col gap-3"
              onSubmit={e => {
                e.preventDefault()
                if (commentText.trim()) addComment.mutate(commentText.trim())
              }}
            >
              <textarea
                className="min-h-[96px] rounded-xl border border-border bg-bg p-3 text-sm text-fg"
                value={commentText}
                onChange={e => setCommentText(e.target.value)}
                placeholder="Viết bình luận…"
              />
              <Button type="submit" loading={addComment.isPending} className="self-start">
                Gửi bình luận
              </Button>
            </form>
          ) : (
            <p className="mt-6 text-sm text-fg-muted">
              <Link to="/login" className="font-medium text-accent hover:text-accent-hover">Đăng nhập để bình luận</Link>.
            </p>
          )}
        </section>
      </article>
    </PublicShell>
  )
}
