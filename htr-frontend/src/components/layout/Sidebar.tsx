import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { LogOut } from 'lucide-react'
import { cn } from '@/lib/utils'
import { navItems } from './navItems'

export default function Sidebar() {
  const { user, clearAuth } = useAuthStore()
  const location = useLocation()
  const role = user?.role ?? ''
  const filteredNav = navItems.filter(item => item.roles.includes(role))

  return (
    <aside className="w-60 bg-sidebar border-r border-border flex flex-col shrink-0">
      <div className="px-4 py-4 border-b border-border">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 bg-accent rounded-lg flex items-center justify-center shrink-0">
            <Link to="/" className="text-accent-fg font-bold text-xs">
              P
            </Link>
          </div>
          <div>
            <p className="font-semibold text-sm text-fg leading-none">How's The Rent</p>
            <p className="text-xs text-fg-subtle mt-0.5">Quản lý nhà trọ</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto py-2 px-2 space-y-0.5">
        {filteredNav.map(item => {
          const Icon = item.icon
          const isActive = item.exact
            ? location.pathname === item.to
            : location.pathname === item.to || location.pathname.startsWith(item.to + '/')
          return (
            <Link
              key={item.to + item.label}
              to={item.to}
              className={cn(
                'flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors duration-100',
                isActive
                  ? 'bg-accent-surface text-accent font-medium'
                  : 'text-fg-muted hover:bg-border/40 hover:text-fg'
              )}
            >
              <Icon
                size={15}
                className={cn('shrink-0', isActive ? 'text-accent' : 'text-fg-subtle')}
              />
              {item.label}
            </Link>
          )
        })}
      </nav>

      <div className="px-3 py-3 border-t border-border">
        <div className="flex items-center gap-2.5 mb-2.5">
          <div className="w-7 h-7 bg-accent-surface text-accent rounded-full flex items-center justify-center text-xs font-semibold shrink-0">
            {user?.fullName?.charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-medium text-fg truncate leading-none mb-0.5">{user?.fullName}</p>
            <p className="text-xs text-fg-subtle truncate">{user?.email}</p>
          </div>
        </div>
        <button
          onClick={clearAuth}
          className="flex items-center gap-2 text-xs text-fg-subtle hover:text-error transition-colors w-full py-1 rounded"
        >
          <LogOut size={13} />
          Đăng xuất
        </button>
      </div>
    </aside>
  )
}
