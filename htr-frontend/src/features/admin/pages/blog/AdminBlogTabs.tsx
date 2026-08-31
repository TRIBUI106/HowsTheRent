import { NavLink } from 'react-router-dom'
import { cn } from '@/lib/utils'

const tabs = [
  { to: '/admin/blog', label: 'Bài viết', end: true },
  { to: '/admin/blog/comments', label: 'Bình luận', end: false },
]

export default function AdminBlogTabs() {
  return (
    <div className="flex items-center gap-1 border-b border-border" role="tablist" aria-label="Quản lý blog">
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
  )
}
