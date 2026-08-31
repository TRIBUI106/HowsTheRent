import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { blogApi } from '@/api'
import PublicShell from '@/components/PublicShell'
import { cn, statusColor, statusLabel } from '@/lib/utils'

export default function BlogListPage() {
  const { data: posts, isLoading } = useQuery({
    queryKey: ['blog-posts'],
    queryFn: blogApi.list,
  })

  return (
    <PublicShell>
      <section className="mx-auto max-w-5xl px-6 py-24">
        <h1 className="text-3xl font-semibold tracking-[-0.03em] text-fg">Nhà trọ đang cho thuê</h1>
        <p className="mt-2 text-sm text-fg-muted">Xem bài viết và thông tin chi tiết về từng phòng trong các nhà trọ.</p>

        {isLoading && <p className="mt-10 text-sm text-fg-muted">Đang tải…</p>}

        <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {posts?.map(post => (
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
              </div>
            </Link>
          ))}
        </div>
      </section>
    </PublicShell>
  )
}
