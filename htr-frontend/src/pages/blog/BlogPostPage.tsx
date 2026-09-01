import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { useDocumentMeta } from '@/hooks/useDocumentMeta'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { directionLabel, statusColor, statusLabel } from '@/lib/utils'
import PublicShell from '@/components/PublicShell'
import { Button } from '@/components/ui/button'
import { ImageWithSkeleton } from '@/components/ui/image-with-skeleton'

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

  const { data: allPosts } = useQuery({
    queryKey: ['blog-posts'],
    queryFn: blogApi.list,
    enabled: !!post,
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

  const relatedPosts = (allPosts ?? [])
    .filter(candidate => candidate.propertyId === post.propertyId && candidate.slug !== post.slug)
    .slice(0, 5)

  return (
    <PublicShell>
      <div className="mx-auto max-w-7xl px-6 py-24 lg:grid lg:grid-cols-[240px_minmax(0,1fr)_300px] lg:gap-8">
        <aside className="mb-8 space-y-6 lg:mb-0">
          <section className="rounded-2xl border border-border bg-surface p-5">
            <p className="text-xs font-semibold uppercase tracking-widest text-fg-subtle">Nhà trọ</p>
            <h2 className="mt-2 text-base font-semibold text-fg">{post.propertyName}</h2>
            <p className="mt-1 text-sm leading-6 text-fg-muted">{post.propertyAddress}</p>
          </section>

          {relatedPosts.length > 0 && (
            <section className="rounded-2xl border border-border bg-surface p-5">
              <h2 className="text-sm font-semibold text-fg">Các bài khác của tòa nhà này</h2>
              <ul className="mt-3 divide-y divide-border">
                {relatedPosts.map(related => (
                  <li key={related.id} className="py-3 first:pt-0 last:pb-0">
                    <Link to={`/blog/${related.slug}`} className="block hover:text-accent">
                      <p className="text-sm font-medium text-fg">{related.title}</p>
                      <p className="mt-1 text-xs text-fg-muted">Phòng {related.roomNumber} · {statusLabel(related.roomStatus)}</p>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          )}
        </aside>

        <article className="min-w-0">
          {post.coverImageUrl && (
            <ImageWithSkeleton src={post.coverImageUrl} alt="" className="mb-8 h-64 w-full rounded-2xl" objectFit="contain" />
          )}
          <p className="text-sm font-medium text-accent">Phòng {post.roomNumber} · {post.propertyName}</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-[-0.03em] text-fg">{post.title}</h1>
          <p className="mt-2 text-sm text-fg-muted">{post.propertyAddress}</p>

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

        <aside className="mt-8 space-y-6 lg:mt-0">
          <section className="rounded-2xl border border-border bg-surface p-5">
            <p className="text-xs font-semibold uppercase tracking-widest text-fg-subtle">Thông tin phòng</p>
            <h2 className="mt-2 text-lg font-semibold text-fg">Phòng {post.roomNumber}</h2>
            <dl className="mt-4 space-y-3 text-sm">
              <div className="flex justify-between gap-4"><dt className="text-fg-muted">Diện tích</dt><dd className="font-medium text-fg">{post.roomAreaM2 ? `${post.roomAreaM2} m²` : '—'}</dd></div>
              <div className="flex justify-between gap-4"><dt className="text-fg-muted">Hướng</dt><dd className="font-medium text-fg">{directionLabel(post.roomDirection)}</dd></div>
              <div className="flex justify-between gap-4"><dt className="text-fg-muted">Sức chứa</dt><dd className="font-medium text-fg">{post.roomMaxPeople ? `${post.roomMaxPeople} người` : '—'}</dd></div>
              <div className="flex items-center justify-between gap-4"><dt className="text-fg-muted">Trạng thái</dt><dd><span className={`inline-flex rounded-full px-2 py-1 text-xs font-medium ${statusColor(post.roomStatus)}`}>{statusLabel(post.roomStatus)}</span></dd></div>
            </dl>

            {!!post.roomImages.length && (
              <div className="mt-5 border-t border-border pt-4">
                <p className="text-sm font-medium text-fg">Ảnh phòng</p>
                <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
                  {post.roomImages.map(imageUrl => (
                    <ImageWithSkeleton key={imageUrl} src={imageUrl} alt="" className="h-16 w-16 shrink-0 rounded-lg" />
                  ))}
                </div>
              </div>
            )}
          </section>

          <section className="rounded-2xl border border-border bg-sidebar p-5">
            <h2 className="text-base font-semibold text-fg">Quan tâm đến phòng này?</h2>
            <p className="mt-2 text-sm leading-6 text-fg-muted">Đăng nhập để theo dõi thông tin nhà trọ và trao đổi trực tiếp trên hệ thống.</p>
            <Link to="/login" className="mt-4 inline-flex">
              <Button type="button">Đăng nhập để liên hệ</Button>
            </Link>
          </section>
        </aside>
      </div>
    </PublicShell>
  )
}
