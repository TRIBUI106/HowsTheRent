import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { Bell } from 'lucide-react'
import { resolveTitle } from './navItems'

interface HeaderProps {
  title?: string
}

export default function Header({ title }: HeaderProps) {
  const { user } = useAuthStore()
  const location = useLocation()
  const role = user?.role ?? ''

  const pageTitle = title ?? resolveTitle(location.pathname)

  const notifPath =
    role === 'ADMIN' ? '/admin/notifications' :
    role === 'TENANT' ? '/tenant/notifications' :
    '/tech/notifications'

  return (
    <header className="bg-surface border-b border-border px-6 py-3 flex items-center justify-between shrink-0">
      <h1 className="text-sm font-semibold text-fg">{pageTitle}</h1>
      <div className="flex items-center gap-3">
        <Link to={notifPath} className="p-1.5 rounded-lg hover:bg-sidebar transition-colors">
          <Bell size={16} className="text-fg-muted" />
        </Link>
      </div>
    </header>
  )
}
