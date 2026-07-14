import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { Bell } from 'lucide-react'
import { resolveTitle } from './navItems'
import { useNotifications } from '@/hooks/useNotifications'

interface HeaderProps {
  title?: string
}

export default function Header({ title }: HeaderProps) {
  const { user } = useAuthStore()
  const location = useLocation()
  const role = user?.role ?? ''
  const { unreadCount } = useNotifications()

  const pageTitle = title ?? resolveTitle(location.pathname)
  const roleLabel =
    role === 'ADMIN' ? 'Quản trị vận hành' :
    role === 'TENANT' ? 'Cổng khách thuê' :
    'Bảng công việc kỹ thuật'

  const notifPath =
    role === 'ADMIN' ? '/admin/notifications' :
    role === 'TENANT' ? '/tenant/notifications' :
    '/tech/notifications'

  return (
    <header className="border-b border-border/80 bg-surface/92 px-6 py-3.5 backdrop-blur-sm shrink-0 lg:px-8 animate-fade-in">
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">{roleLabel}</p>
          <h1 className="mt-1 truncate text-lg font-semibold tracking-[-0.01em] text-fg">{pageTitle}</h1>
        </div>
        <div className="flex items-center gap-3">
          <Link to={notifPath} className="relative inline-flex h-9 w-9 items-center justify-center rounded-xl border border-border/80 bg-surface text-fg-muted hover:bg-sidebar hover:text-fg transition-colors">
            <Bell size={16} />
            {unreadCount > 0 && (
              <span className="absolute -right-1.5 -top-1.5 flex min-w-5 h-5 items-center justify-center rounded-full bg-error px-1 text-[10px] font-bold text-error-fg">
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            )}
          </Link>
        </div>
      </div>
    </header>
  )
}
