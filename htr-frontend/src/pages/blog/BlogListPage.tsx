import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { blogApi } from '@/api'
import PublicShell from '@/components/PublicShell'
import { cn, statusColor, statusLabel } from '@/lib/utils'

export default function BlogListPage() {
  const [selectedTag, setSelectedTag] = useState<string | null>(null)
  const { data: posts, isLoading } = useQuery({
    queryKey: ['blog-posts'],
    queryFn: blogApi.list,
  })

  const allTags = [...new Set(posts?.flatMap(p => p.tags ?? []) ?? [])]
  const visiblePosts = selectedTag ? posts?.filter(p => (p.tags ?? []).includes(selectedTag)) : posts

  return (
    <PublicShell>
      <section className="mx-auto max-w-5xl px-6 py-24">
        <h1 className="text-3xl font-semibold tracking-[-0.03em] text-fg">Dự án đang cho thuê</h1>
        <p className="mt-2 text-sm text-fg-muted">Xem bài viết và thông tin chi tiết về từng phòng trong các dự án.</p>

        {isLoading && <p className="mt-10 text-sm text-fg-muted">Đang tải…</p>}

        {allTags.length > 0 && (
          <div className="mt-8 flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => setSelectedTag(null)}
              className={cn(
                'inline-flex items-center rounded-full px-3 py-1.5 text-xs font-medium transition-colors',
                selectedTag === null ? 'bg-accent text-white' : 'bg-surface border border-border text-fg-muted'
              )}
            >
              Tất cả
            </button>
            {allTags.map(tag => (
              <button
                key={tag}
                type="button"
                onClick={() => setSelectedTag(current => (current === tag ? null : tag))}
                className={cn(
                  'inline-flex items-center rounded-full px-3 py-1.5 text-xs font-medium transition-colors',
                  selectedTag === tag ? 'bg-accent text-white' : 'bg-surface border border-border text-fg-muted'
                )}
              >
                {tag}
              </button>
            ))}
          </div>
        )}

        <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {visiblePosts?.map(post => (
            <Link
              key={post.id}
              to={`/blog/${post.slug}`}
              className="block overflow-hidden rounded-2xl border border-border bg-surface transition-shadow hover:shadow-md"
            >
              {post.coverImageUrl && (
                <img src={post.coverImageUrl} alt="" className="h-40 w-full object-cover" />
              )}
              <div className="p-5">
                <h2 className="text-base font-semibold text-fg">{post.title}</h2>
                <p className="mt-1 text-sm text-fg-muted">{post.propertyName} · {post.propertyAddress}</p>
                <span
                  className={cn(
                    'mt-3 inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium',
                    statusColor(post.roomStatus)
                  )}
                >
                  Phòng {post.roomNumber} · {statusLabel(post.roomStatus)}
                </span>
                {!!post.tags?.length && (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {post.tags.map(tag => (
                      <span key={tag} className="inline-flex items-center rounded-full bg-sidebar px-2 py-0.5 text-[11px] font-medium text-fg-subtle">
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </Link>
          ))}
        </div>
      </section>
    </PublicShell>
  )
}
