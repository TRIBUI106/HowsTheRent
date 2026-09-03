import { NavLink } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Heart } from 'lucide-react'
import { cn } from '@/lib/utils'
import { adminBlogApi } from '@/api'

const tabs = [
  { to: '/admin/blog', label: 'Bài viết', end: true },
  { to: '/admin/blog/comments', label: 'Bình luận', end: false },
]

export default function AdminBlogTabs() {
  // Cùng queryKey với AdminBlogListPage nên khi vào từ trang Bài viết, dữ liệu đã có sẵn
  // trong cache — không tốn thêm request; khi vào thẳng trang Bình luận thì tự fetch riêng.
  const { data: posts } = useQuery({
    queryKey: ['admin-blog-posts'],
    queryFn: adminBlogApi.listAll,
  })
  const totalLikes = posts?.reduce((sum, post) => sum + post.likeCount, 0) ?? 0

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border">
      <div className="flex items-center gap-1" role="tablist" aria-label="Quản lý blog">
        {tabs.map(tab => (
          <NavLink
            key={tab.to}
            to={tab.to}
            end={tab.end}
            className={({ isActive }) =>
              cn(
                '-mb-px border-b-2 px-4 py-2.5 text-sm font-medium transition-colors',
                isActive ? 'border-accent text-accent' : 'border-transparent text-fg-muted hover:text-fg'
              )
            }
          >
            {tab.label}
          </NavLink>
        ))}
      </div>

      <div className="flex items-center gap-1.5 pb-2.5 text-xs font-medium text-fg-muted">
        <Heart size={13} />
        <span>Tổng lượt thích: {totalLikes}</span>
      </div>
    </div>
  )
}
